import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/errors/missing_account_exception.dart';
import 'package:stock_count/core/errors/journal_exception.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';
import 'package:stock_count/modules/system_setup/domain/services/initialization_guard.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';

class InventoryAccountingPosterAdapter implements InventoryAccountingPoster {
  InventoryAccountingPosterAdapter(
    this._accountingDb, {
    JournalPostingService? journalPostingService,
    this._readCompanyId,
    CompanyInitializationRepository? initRepository,
    InitializationGuard? initializationGuard,
  }) : _journalPostingService = journalPostingService,
       _initRepository = initRepository,
       _initializationGuard = initializationGuard;

  final AccountingDatabase _accountingDb;
  final JournalPostingService? _journalPostingService;
  final String Function()? _readCompanyId;
  final CompanyInitializationRepository? _initRepository;
  final InitializationGuard? _initializationGuard;

  String get _currentCompanyId =>
      _readCompanyId?.call() ?? LocalAuthDefaults.companyId;

  Future<String> _resolveCompanyAccount({
    required AccountRole role,
    String? explicitAccountId,
    required String voucherTypeStr,
  }) async {
    final companyId = _currentCompanyId;

    if (explicitAccountId != null && explicitAccountId.trim().isNotEmpty) {
      final target = explicitAccountId.trim();
      final byUuidOrCode =
          await (_accountingDb.select(_accountingDb.accounts)..where(
                (tbl) =>
                    (tbl.uuid.equals(target) | tbl.accountCode.equals(target)) &
                    tbl.companyId.equals(companyId) &
                    tbl.deletedAt.isNull() &
                    tbl.isGroup.equals(false) &
                    tbl.isActive.equals(true),
              ))
              .getSingleOrNull();
      if (byUuidOrCode != null) return byUuidOrCode.uuid;

      throw MissingAccountException(
        accountRole: role.name,
        expectedCode: target,
        systemKey: target,
        message:
            'خطأ محاسبي: الحساب المحاسبي المحدد ($target) غير موجود في الشركة الحالية أو غير نشط.',
      );
    }

    final companyConfig = await _initRepository?.getAccountingConfig();
    final configuredKey = companyConfig?.accountMappings[role]?.trim();

    if (configuredKey != null && configuredKey.isNotEmpty) {
      final acc =
          await (_accountingDb.select(_accountingDb.accounts)..where(
                (tbl) =>
                    (tbl.uuid.equals(configuredKey) |
                        tbl.accountCode.equals(configuredKey) |
                        tbl.description.equals('system:${role.name}')) &
                    tbl.companyId.equals(companyId) &
                    tbl.deletedAt.isNull() &
                    tbl.isGroup.equals(false) &
                    tbl.isActive.equals(true),
              ))
              .getSingleOrNull();
      if (acc != null) return acc.uuid;
    }

    final defaultCodes = {
      AccountRole.inventory: '1230',
      AccountRole.cogs: '5100',
      AccountRole.adjustment: '5200',
      AccountRole.payable: '2110',
      AccountRole.revenue: '4100',
      AccountRole.cash: '1110',
    };
    final defaultCode = defaultCodes[role] ?? '';

    final fallbackAcc =
        await (_accountingDb.select(_accountingDb.accounts)..where(
              (tbl) =>
                  (tbl.accountCode.equals(defaultCode) |
                      tbl.description.equals('system:${role.name}') |
                      tbl.description.equals(
                        'system:${_roleToSystemKey(role)}',
                      )) &
                  tbl.companyId.equals(companyId) &
                  tbl.deletedAt.isNull() &
                  tbl.isGroup.equals(false) &
                  tbl.isActive.equals(true),
            ))
            .getSingleOrNull();
    if (fallbackAcc != null) return fallbackAcc.uuid;

    throw MissingAccountException(
      accountRole: role.name,
      expectedCode: configuredKey ?? defaultCode,
      systemKey: role.name,
      message:
          'خطأ محاسبي: لم يتم إعداد حساب (${role.name}) لتهيئة الشركة ($companyId). يرجى ربط الحسابات المحاسبية أولاً.',
    );
  }

  String _roleToSystemKey(AccountRole role) {
    switch (role) {
      case AccountRole.inventory:
        return 'inventory';
      case AccountRole.cogs:
        return 'cost_of_goods';
      case AccountRole.adjustment:
        return 'inventory_adjustment';
      case AccountRole.payable:
        return 'accounts_payable';
      case AccountRole.revenue:
        return 'sales_revenue';
      case AccountRole.cash:
        return 'main_cash';
      default:
        return role.name;
    }
  }

  Future<String> _resolveCompanyBaseCurrency() async {
    final inventoryConfig = await _initRepository?.getInventoryConfig();
    if (inventoryConfig != null &&
        inventoryConfig.inventoryBaseCurrencyId.trim().isNotEmpty) {
      return inventoryConfig.inventoryBaseCurrencyId.trim().toUpperCase();
    }
    return 'YER';
  }

  @override
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    String? accountId,
    bool isPosted = true,
  }) async {
    await _initializationGuard?.assertInitialized();
    if (totalAmount <= 0) return;
    if (!isPosted) {
      await reverseAccountingEntry(document: document);
      return;
    }
    if (document.documentType == InventoryDocumentType.salesInvoice ||
        document.documentType == InventoryDocumentType.stockTransfer) {
      return;
    }

    final isReceipt =
        document.documentType == InventoryDocumentType.stockReceipt;
    final voucherTypeStr = isReceipt ? 'أمر توريد' : 'أمر صرف';

    final resolvedInventory = await _resolveCompanyAccount(
      role: AccountRole.inventory,
      voucherTypeStr: voucherTypeStr,
    );

    final offsetRole = isReceipt ? AccountRole.payable : AccountRole.cogs;
    final resolvedOffset = await _resolveCompanyAccount(
      role: offsetRole,
      explicitAccountId: accountId,
      voucherTypeStr: voucherTypeStr,
    );

    final sourceType = document.documentType.storageValue;
    final sourceId = document.documentId;

    final baseCurrency = await _resolveCompanyBaseCurrency();
    final String entryCurrency = isReceipt
        ? (document.currencyCode.trim().isNotEmpty
              ? document.currencyCode.trim().toUpperCase()
              : baseCurrency)
        : baseCurrency;
    final double entryRate = isReceipt
        ? (document.exchangeRate > 0 ? document.exchangeRate : 1.0)
        : 1.0;
    final double calculatedBaseDebit = isReceipt
        ? (totalAmount * entryRate)
        : totalAmount;

    if (_journalPostingService != null) {
      final draft = JournalEntryDraft(
        entryDate: document.documentDate,
        voucherNumber: document.documentNumber,
        voucherType: voucherTypeStr,
        currencyCode: entryCurrency,
        description:
            'قيد تلقائي للمستند $voucherTypeStr: ${document.documentNumber}',
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
      final existingEntry =
          await (_accountingDb.select(_accountingDb.journalEntries)..where(
                (tbl) =>
                    tbl.sourceType.equals(sourceType) &
                    tbl.sourceId.equals(sourceId) &
                    tbl.companyId.equals(_currentCompanyId) &
                    tbl.deletedAt.isNull(),
              ))
              .getSingleOrNull();

      final String entryUuid;

      if (existingEntry != null) {
        if (existingEntry.isPosted) {
          return;
        }
        entryUuid = existingEntry.uuid;
        await (_accountingDb.update(_accountingDb.journalEntries)..where(
              (tbl) =>
                  tbl.uuid.equals(entryUuid) &
                  tbl.companyId.equals(_currentCompanyId),
            ))
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

        await (_accountingDb.delete(
          _accountingDb.journalLines,
        )..where((tbl) => tbl.entryUuid.equals(entryUuid))).go();
      } else {
        entryUuid = generateUuidV4();
        await _accountingDb
            .into(_accountingDb.journalEntries)
            .insert(
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

      await _accountingDb
          .into(_accountingDb.journalLines)
          .insert(
            JournalLinesCompanion(
              uuid: Value(generateUuidV4()),
              entryUuid: Value(entryUuid),
              accountUuid: Value(
                isReceipt ? resolvedInventory : resolvedOffset,
              ),
              debit: Value(totalAmount),
              credit: const Value(0.0),
              baseDebit: Value(calculatedBaseDebit),
              baseCredit: const Value(0.0),
              currencyCode: Value(entryCurrency),
              exchangeRateToBase: Value(entryRate),
              lineDescription: Value('مخزون - ${document.documentNumber}'),
            ),
          );

      await _accountingDb
          .into(_accountingDb.journalLines)
          .insert(
            JournalLinesCompanion(
              uuid: Value(generateUuidV4()),
              entryUuid: Value(entryUuid),
              accountUuid: Value(
                isReceipt ? resolvedOffset : resolvedInventory,
              ),
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

    final existing =
        await (_accountingDb.select(_accountingDb.journalEntries)..where(
              (tbl) =>
                  tbl.sourceType.equals(document.documentType.storageValue) &
                  tbl.sourceId.equals(document.documentId) &
                  tbl.companyId.equals(_currentCompanyId) &
                  tbl.deletedAt.isNull(),
            ))
            .getSingleOrNull();

    if (existing != null && existing.isPosted && !isPosted) {
      throw const JournalException(JournalException.postedImmutable);
    }

    await (_accountingDb.update(_accountingDb.journalEntries)..where(
          (tbl) =>
              tbl.sourceType.equals(document.documentType.storageValue) &
              tbl.sourceId.equals(document.documentId) &
              tbl.companyId.equals(_currentCompanyId),
        ))
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
    await _initializationGuard?.assertInitialized();
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

    final existing =
        await (_accountingDb.select(_accountingDb.journalEntries)..where(
              (tbl) =>
                  tbl.sourceType.equals(sourceType) &
                  tbl.sourceId.equals(sourceId) &
                  tbl.companyId.equals(_currentCompanyId) &
                  tbl.deletedAt.isNull(),
            ))
            .getSingleOrNull();

    if (existing != null && existing.isPosted) {
      final existingLines = await (_accountingDb.select(
        _accountingDb.journalLines,
      )..where((tbl) => tbl.entryUuid.equals(existing.uuid))).get();

      final reverseUuid = generateUuidV4();
      await _accountingDb
          .into(_accountingDb.journalEntries)
          .insert(
            JournalEntriesCompanion(
              uuid: Value(reverseUuid),
              voucherNumber: Value('${existing.voucherNumber}-R'),
              voucherType: Value(existing.voucherType),
              entryDate: Value(existing.entryDate),
              description: Value(
                'عكس: ${existing.description ?? existing.voucherNumber}',
              ),
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
        await _accountingDb
            .into(_accountingDb.journalLines)
            .insert(
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

    await (_accountingDb.update(_accountingDb.journalEntries)..where(
          (tbl) =>
              tbl.sourceType.equals(sourceType) &
              tbl.sourceId.equals(sourceId) &
              tbl.companyId.equals(_currentCompanyId),
        ))
        .write(
          JournalEntriesCompanion(
            deletedAt: Value(now.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
          ),
        );
  }
}
