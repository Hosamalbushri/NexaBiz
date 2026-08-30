import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import '../../domain/services/inventory_accounting_poster.dart';

import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';

class InventoryAccountingPosterImpl implements InventoryAccountingPoster {
  InventoryAccountingPosterImpl(
    this._accountingDb, {
    JournalPostingService? journalPostingService,
    this._readCompanyId,
  }) : _journalPostingService = journalPostingService;

  final AccountingDatabase _accountingDb;
  final JournalPostingService? _journalPostingService;
  final String Function()? _readCompanyId;

  String get _currentCompanyId =>
      _readCompanyId?.call() ?? LocalAuthDefaults.companyId;

  Future<String?> _resolveAccountUuid({
    required String code,
    required String systemKey,
  }) async {
    // 1. Match by exact accountCode & current companyId (active, non-deleted, leaf account)
    final byCode = await (_accountingDb.select(_accountingDb.accounts)
          ..where((tbl) =>
              tbl.accountCode.equals(code) &
              tbl.companyId.equals(_currentCompanyId) &
              tbl.deletedAt.isNull() &
              tbl.isGroup.equals(false) &
              tbl.isActive.equals(true)))
        .getSingleOrNull();
    if (byCode != null) return byCode.uuid;

    // 2. Match by system key in description & current companyId (active, non-deleted, leaf account)
    final bySystem = await (_accountingDb.select(_accountingDb.accounts)
          ..where((tbl) =>
              tbl.description.equals('system:$systemKey') &
              tbl.companyId.equals(_currentCompanyId) &
              tbl.deletedAt.isNull() &
              tbl.isGroup.equals(false) &
              tbl.isActive.equals(true)))
        .getSingleOrNull();
    if (bySystem != null) return bySystem.uuid;

    // Strict security: NO arbitrary fallback via limit(1) or un-tenanted accounts.
    return null;
  }

  Future<String> _resolveSelectedAccountRequired({
    required String? accountId,
    required String voucherTypeStr,
  }) async {
    if (accountId != null && accountId.trim().isNotEmpty) {
      final target = accountId.trim();

      // 1. Match by exact UUID in current tenant accounts (active, non-deleted, leaf account)
      final byUuid = await (_accountingDb.select(_accountingDb.accounts)
            ..where((tbl) =>
                tbl.uuid.equals(target) &
                tbl.companyId.equals(_currentCompanyId) &
                tbl.deletedAt.isNull() &
                tbl.isGroup.equals(false) &
                tbl.isActive.equals(true)))
          .getSingleOrNull();
      if (byUuid != null) return byUuid.uuid;

      // 2. Match by exact Account Code in current tenant accounts (active, non-deleted, leaf account)
      final byCode = await (_accountingDb.select(_accountingDb.accounts)
            ..where((tbl) =>
                tbl.accountCode.equals(target) &
                tbl.companyId.equals(_currentCompanyId) &
                tbl.deletedAt.isNull() &
                tbl.isGroup.equals(false) &
                tbl.isActive.equals(true)))
          .getSingleOrNull();
      if (byCode != null) return byCode.uuid;

      // Strict security: If target accountId was specified but is not found in current tenant, or is inactive/group,
      // STOP posting immediately! Never substitute global or arbitrary accounts.
      throw StateError(
        'خطأ محاسبي: الحساب المحاسبي المحدد ($target) لم يتم العثور عليه في الشركة الحالية أو غير نشط أو حساب رئيسي.',
      );
    }

    // Fallback match to default system account for inventory movement when no account specified
    final fallbackCode = voucherTypeStr.contains('صرف') ? '5100' : '1230';
    final fallbackKey = voucherTypeStr.contains('صرف') ? 'cost_of_goods' : 'inventory';
    final fallbackUuid = await _resolveAccountUuid(code: fallbackCode, systemKey: fallbackKey);
    if (fallbackUuid != null) {
      return fallbackUuid;
    }

    // No default fallback account found! Throw explicit error.
    throw StateError(
      'خطأ محاسبي: لم يتم تحديد حساب محاسبي صالح للمستند ($voucherTypeStr). يرجى اختيار الحساب أولاً.',
    );
  }

  @override
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    String? accountId,
    bool isPosted = true,
  }) async {
    if (totalAmount <= 0) return;
    if (!isPosted) {
      await reverseAccountingEntry(document: document);
      return;
    }
    if (document.documentType == InventoryDocumentType.salesInvoice) {
      // Sales invoices post their accounting entries centrally through DocumentPostingOrchestrator
      return;
    }

    final isReceipt = document.documentType == InventoryDocumentType.stockReceipt;
    final voucherTypeStr = isReceipt ? 'أمر توريد' : 'أمر صرف';

    // 1. Dynamically resolve valid account UUIDs
    final inventoryUuid = await _resolveAccountUuid(code: '1230', systemKey: 'inventory');
    if (inventoryUuid == null) {
      throw StateError('خطأ محاسبي: لم يتم العثور على حساب المخزون (1230) في الدليل المحاسبي.');
    }

    final resolvedOffset = await _resolveSelectedAccountRequired(
      accountId: accountId,
      voucherTypeStr: voucherTypeStr,
    );

    final resolvedInventory = inventoryUuid;
    final sourceType = document.documentType.storageValue;
    final sourceId = document.documentId;

    final String entryCurrency = isReceipt ? document.currencyCode : 'YER';
    final double entryRate = isReceipt ? document.exchangeRate : 1.0;
    final double calculatedBaseDebit = isReceipt ? (totalAmount * document.exchangeRate) : totalAmount;

    if (_journalPostingService != null) {
      final draft = JournalEntryDraft(
        entryDate: document.documentDate,
        voucherNumber: document.documentNumber,
        voucherType: voucherTypeStr,
        currencyCode: entryCurrency,
        description: 'قيد تلقائي للمستند $voucherTypeStr: ${document.documentNumber}',
        isPosted: isPosted,
        sourceType: sourceType,
        sourceId: sourceId,
        lines: [
          JournalLineDraft(
            accountUuid: isReceipt ? resolvedInventory : resolvedOffset,
            debit: totalAmount,
            credit: 0.0,
            currencyCode: entryCurrency,
            exchangeRateToBase: entryRate,
            lineDescription: 'مخزون - ${document.documentNumber}',
            sortOrder: 1,
          ),
          JournalLineDraft(
            accountUuid: isReceipt ? resolvedOffset : resolvedInventory,
            debit: 0.0,
            credit: totalAmount,
            currencyCode: entryCurrency,
            exchangeRateToBase: entryRate,
            lineDescription: 'مخزون - ${document.documentNumber}',
            sortOrder: 2,
          ),
        ],
      );
      await _journalPostingService.post(draft);
      return;
    }

    final now = DateTime.now().toUtc();

    await _accountingDb.transaction(() async {
      final existingEntry = await (_accountingDb.select(_accountingDb.journalEntries)
            ..where((tbl) =>
                tbl.sourceType.equals(sourceType) &
                tbl.sourceId.equals(sourceId) &
                tbl.companyId.equals(_currentCompanyId) &
                tbl.deletedAt.isNull()))
          .getSingleOrNull();

      final String entryUuid;

      if (existingEntry != null) {
        if (existingEntry.isPosted) {
          // Posted accounting records are immutable. Preserve existing record untouched.
          return;
        }
        entryUuid = existingEntry.uuid;
        // 1a. Update existing Journal Entry Header
        await (_accountingDb.update(_accountingDb.journalEntries)
              ..where((tbl) =>
                  tbl.uuid.equals(entryUuid) &
                  tbl.companyId.equals(_currentCompanyId)))
            .write(
          JournalEntriesCompanion(
            voucherNumber: Value(document.documentNumber),
            voucherType: Value(voucherTypeStr),
            entryDate: Value(document.documentDate.millisecondsSinceEpoch),
            description: Value(
              'قيد تلقائي للمستند $voucherTypeStr: ${document.documentNumber}',
            ),
            currencyCode: Value(entryCurrency),
            isPosted: Value(isPosted),
            companyId: Value(_currentCompanyId),
            deletedAt: const Value(null),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );

        // Clear existing lines for re-inserting
        await (_accountingDb.delete(_accountingDb.journalLines)
              ..where((tbl) => tbl.entryUuid.equals(entryUuid)))
            .go();
      } else {
        entryUuid = generateUuidV4();
        // 1b. Create new Journal Entry Header
        await _accountingDb.into(_accountingDb.journalEntries).insert(
              JournalEntriesCompanion(
                uuid: Value(entryUuid),
                voucherNumber: Value(document.documentNumber),
                voucherType: Value(voucherTypeStr),
                entryDate: Value(document.documentDate.millisecondsSinceEpoch),
                description: Value(
                  'قيد تلقائي للمستند $voucherTypeStr: ${document.documentNumber}',
                ),
                currencyCode: Value(entryCurrency),
                isPosted: Value(isPosted),
                sourceType: Value(sourceType),
                sourceId: Value(sourceId),
                createdAt: Value(now.millisecondsSinceEpoch),
                updatedAt: Value(now.millisecondsSinceEpoch),
                companyId: Value(_currentCompanyId),
              ),
            );
      }

      // Line 1: Debit Line
      await _accountingDb.into(_accountingDb.journalLines).insert(
            JournalLinesCompanion(
              uuid: Value(generateUuidV4()),
              entryUuid: Value(entryUuid),
              accountUuid: Value(isReceipt ? resolvedInventory : resolvedOffset),
              debit: Value(totalAmount),
              credit: const Value(0.0),
              baseDebit: Value(calculatedBaseDebit),
              baseCredit: const Value(0.0),
              currencyCode: Value(entryCurrency),
              exchangeRateToBase: Value(entryRate),
              lineDescription: Value('مخزون - ${document.documentNumber}'),
            ),
          );

      // Line 2: Credit Line
      await _accountingDb.into(_accountingDb.journalLines).insert(
            JournalLinesCompanion(
              uuid: Value(generateUuidV4()),
              entryUuid: Value(entryUuid),
              accountUuid: Value(isReceipt ? resolvedOffset : resolvedInventory),
              debit: const Value(0.0),
              credit: Value(totalAmount),
              baseDebit: const Value(0.0),
              baseCredit: Value(calculatedBaseDebit),
              currencyCode: Value(entryCurrency),
              exchangeRateToBase: Value(entryRate),
              lineDescription: Value('مخزون - ${document.documentNumber}'),
            ),
          );
    });
  }

  @override
  Future<void> setAccountingEntryPostingStatus({
    required InventoryDocumentRef document,
    required bool isPosted,
  }) async {
    final now = DateTime.now().toUtc();

    final existing = await (_accountingDb.select(_accountingDb.journalEntries)
          ..where((tbl) =>
              tbl.sourceType.equals(document.documentType.storageValue) &
              tbl.sourceId.equals(document.documentId) &
              tbl.companyId.equals(_currentCompanyId) &
              tbl.deletedAt.isNull()))
        .getSingleOrNull();

    if (existing != null && existing.isPosted && !isPosted) {
      // Unposting a posted accounting record is blocked to preserve historical integrity.
      throw const JournalException(JournalException.postedImmutable);
    }

    await (_accountingDb.update(_accountingDb.journalEntries)
          ..where((tbl) =>
              tbl.sourceType.equals(document.documentType.storageValue) &
              tbl.sourceId.equals(document.documentId) &
              tbl.companyId.equals(_currentCompanyId)))
        .write(
      JournalEntriesCompanion(
        isPosted: Value(isPosted),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<void> reverseAccountingEntry({
    required InventoryDocumentRef document,
  }) async {
    final sourceType = document.documentType.storageValue;
    final sourceId = document.documentId;

    if (_journalPostingService != null) {
      await _journalPostingService.voidBySource(
        sourceType: sourceType,
        sourceId: sourceId,
      );
      return;
    }

    final now = DateTime.now().toUtc();

    final existing = await (_accountingDb.select(_accountingDb.journalEntries)
          ..where((tbl) =>
              tbl.sourceType.equals(sourceType) &
              tbl.sourceId.equals(sourceId) &
              tbl.companyId.equals(_currentCompanyId) &
              tbl.deletedAt.isNull()))
        .getSingleOrNull();

    if (existing != null && existing.isPosted) {
      // Fallback path when _journalPostingService is null:
      // Posted journal entries must NOT be soft-deleted. Create an offsetting reversal entry instead.
      final existingLines = await (_accountingDb.select(_accountingDb.journalLines)
            ..where((tbl) => tbl.entryUuid.equals(existing.uuid)))
          .get();

      final reverseUuid = generateUuidV4();
      await _accountingDb.into(_accountingDb.journalEntries).insert(
            JournalEntriesCompanion(
              uuid: Value(reverseUuid),
              voucherNumber: Value('${existing.voucherNumber}-R'),
              voucherType: Value(existing.voucherType),
              entryDate: Value(existing.entryDate),
              description: Value('عكس: ${existing.description ?? existing.voucherNumber}'),
              currencyCode: Value(existing.currencyCode),
              isPosted: const Value(true),
              sourceType: const Value(JournalPostingService.reverseSourceType),
              sourceId: Value(existing.uuid),
              createdAt: Value(now.millisecondsSinceEpoch),
              updatedAt: Value(now.millisecondsSinceEpoch),
              companyId: Value(_currentCompanyId),
            ),
          );

      for (final line in existingLines) {
        await _accountingDb.into(_accountingDb.journalLines).insert(
              JournalLinesCompanion(
                uuid: Value(generateUuidV4()),
                entryUuid: Value(reverseUuid),
                accountUuid: Value(line.accountUuid),
                debit: Value(line.credit),
                credit: Value(line.debit),
                baseDebit: Value(line.baseCredit),
                baseCredit: Value(line.baseDebit),
                currencyCode: Value(line.currencyCode),
                exchangeRateToBase: Value(line.exchangeRateToBase),
                lineDescription: Value(line.lineDescription),
                sortOrder: Value(line.sortOrder),
              ),
            );
      }
      return;
    }

    // Soft delete DRAFT journal entry for this source document
    await (_accountingDb.update(_accountingDb.journalEntries)
          ..where((tbl) =>
              tbl.sourceType.equals(sourceType) &
              tbl.sourceId.equals(sourceId) &
              tbl.companyId.equals(_currentCompanyId)))
        .write(
      JournalEntriesCompanion(
        deletedAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }
}
