import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import '../../domain/services/inventory_accounting_poster.dart';

class InventoryAccountingPosterImpl implements InventoryAccountingPoster {
  InventoryAccountingPosterImpl(
    this._accountingDb, {
    this._readCompanyId,
  });

  final AccountingDatabase _accountingDb;
  final String Function()? _readCompanyId;

  String get _currentCompanyId =>
      _readCompanyId?.call() ?? LocalAuthDefaults.companyId;

  Future<String?> _resolveAccountUuid({
    required String code,
    required String systemKey,
  }) async {
    // 1. Match by exact accountCode & companyId
    final byCode = await (_accountingDb.select(_accountingDb.accounts)
          ..where((tbl) =>
              tbl.accountCode.equals(code) &
              (tbl.companyId.equals(_currentCompanyId) | tbl.companyId.isNull()) &
              tbl.deletedAt.isNull() &
              tbl.isGroup.equals(false)))
        .getSingleOrNull();
    if (byCode != null) return byCode.uuid;

    // 2. Match by system key in description & companyId
    final bySystem = await (_accountingDb.select(_accountingDb.accounts)
          ..where((tbl) =>
              tbl.description.equals('system:$systemKey') &
              (tbl.companyId.equals(_currentCompanyId) | tbl.companyId.isNull()) &
              tbl.deletedAt.isNull() &
              tbl.isGroup.equals(false)))
        .getSingleOrNull();
    if (bySystem != null) return bySystem.uuid;

    // 3. Fallback: Any non-group active account in current tenant
    final fallback = await (_accountingDb.select(_accountingDb.accounts)
          ..where((tbl) =>
              (tbl.companyId.equals(_currentCompanyId) | tbl.companyId.isNull()) &
              tbl.deletedAt.isNull() &
              tbl.isGroup.equals(false) &
              tbl.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
    return fallback?.uuid;
  }

  Future<String> _resolveSelectedAccountRequired({
    required String? accountId,
    required String voucherTypeStr,
  }) async {
    if (accountId != null && accountId.trim().isNotEmpty) {
      final target = accountId.trim();

      // 1. Match by exact UUID in tenant accounts
      final byUuid = await (_accountingDb.select(_accountingDb.accounts)
            ..where((tbl) =>
                tbl.uuid.equals(target) &
                (tbl.companyId.equals(_currentCompanyId) | tbl.companyId.isNull()) &
                tbl.deletedAt.isNull() &
                tbl.isGroup.equals(false)))
          .getSingleOrNull();
      if (byUuid != null) return byUuid.uuid;

      // 2. Match by exact Account Code in tenant accounts
      final byCode = await (_accountingDb.select(_accountingDb.accounts)
            ..where((tbl) =>
                tbl.accountCode.equals(target) &
                (tbl.companyId.equals(_currentCompanyId) | tbl.companyId.isNull()) &
                tbl.deletedAt.isNull() &
                tbl.isGroup.equals(false)))
          .getSingleOrNull();
      if (byCode != null) return byCode.uuid;

      // 3. Fallback match by UUID across all accounts
      final byUuidGlobal = await (_accountingDb.select(_accountingDb.accounts)
            ..where((tbl) =>
                tbl.uuid.equals(target) &
                tbl.deletedAt.isNull() &
                tbl.isGroup.equals(false)))
          .getSingleOrNull();
      if (byUuidGlobal != null) return byUuidGlobal.uuid;

      // 4. Fallback match by Code across all accounts
      final byCodeGlobal = await (_accountingDb.select(_accountingDb.accounts)
            ..where((tbl) =>
                tbl.accountCode.equals(target) &
                tbl.deletedAt.isNull() &
                tbl.isGroup.equals(false)))
          .getSingleOrNull();
      if (byCodeGlobal != null) return byCodeGlobal.uuid;

      // 5. If target looks like a valid 36-char UUID, use it directly
      if (target.length == 36) {
        return target;
      }
    }

    // No default fallback account! Throw explicit error.
    throw StateError(
      'خطأ محاسبي: لم يتم تحديد حساب محاسبي للمستند ($voucherTypeStr). يرجى اختيار الحساب أولاً.',
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

    final now = DateTime.now().toUtc();

    await _accountingDb.transaction(() async {
      final sourceType = document.documentType.storageValue;
      final sourceId = document.documentId;

      // Check if entry already exists for this source document
      final existingEntry = await (_accountingDb.select(_accountingDb.journalEntries)
            ..where((tbl) =>
                tbl.sourceType.equals(sourceType) & tbl.sourceId.equals(sourceId)))
          .getSingleOrNull();

      final String entryUuid;
      final isReceipt = document.documentType == InventoryDocumentType.stockReceipt;
      final voucherTypeStr = isReceipt ? 'أمر توريد' : 'أمر صرف';

      if (existingEntry != null) {
        entryUuid = existingEntry.uuid;
        // 1a. Update existing Journal Entry Header
        await (_accountingDb.update(_accountingDb.journalEntries)
              ..where((tbl) => tbl.uuid.equals(entryUuid)))
            .write(
          JournalEntriesCompanion(
            voucherNumber: Value(document.documentNumber),
            voucherType: Value(voucherTypeStr),
            entryDate: Value(document.documentDate.millisecondsSinceEpoch),
            description: Value(
              'قيد تلقائي للمستند $voucherTypeStr: ${document.documentNumber}',
            ),
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
                currencyCode: const Value('SAR'),
                isPosted: Value(isPosted),
                sourceType: Value(sourceType),
                sourceId: Value(sourceId),
                createdAt: Value(now.millisecondsSinceEpoch),
                updatedAt: Value(now.millisecondsSinceEpoch),
                companyId: Value(_currentCompanyId),
              ),
            );
      }

      // 2. Dynamically resolve valid account UUIDs
      final inventoryUuid = await _resolveAccountUuid(code: '1230', systemKey: 'inventory');
      if (inventoryUuid == null) {
        throw StateError('خطأ محاسبي: لم يتم العثور على حساب المخزون (1230) في الدليل المحاسبي.');
      }

      final resolvedOffset = await _resolveSelectedAccountRequired(
        accountId: accountId,
        voucherTypeStr: voucherTypeStr,
      );

      final resolvedInventory = inventoryUuid;

      // Line 1: Debit Line
      await _accountingDb.into(_accountingDb.journalLines).insert(
            JournalLinesCompanion(
              uuid: Value(generateUuidV4()),
              entryUuid: Value(entryUuid),
              accountUuid: Value(isReceipt ? resolvedInventory : resolvedOffset),
              debit: Value(totalAmount),
              credit: const Value(0.0),
              baseDebit: Value(totalAmount),
              baseCredit: const Value(0.0),
              currencyCode: const Value('SAR'),
              exchangeRateToBase: const Value(1.0),
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
              baseCredit: Value(totalAmount),
              currencyCode: const Value('SAR'),
              exchangeRateToBase: const Value(1.0),
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

    await (_accountingDb.update(_accountingDb.journalEntries)
          ..where((tbl) =>
              tbl.sourceType.equals(document.documentType.storageValue) &
              tbl.sourceId.equals(document.documentId)))
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
    final now = DateTime.now().toUtc();

    // Soft delete journal entry for this source document
    await (_accountingDb.update(_accountingDb.journalEntries)
          ..where((tbl) =>
              tbl.sourceType.equals(document.documentType.storageValue) &
              tbl.sourceId.equals(document.documentId)))
        .write(
      JournalEntriesCompanion(
        deletedAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }
}
