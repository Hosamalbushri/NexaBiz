import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/errors/missing_account_exception.dart';
import 'package:stock_count/core/errors/journal_exception.dart';
import 'package:stock_count/core/errors/invalid_exchange_rate_exception.dart';
import 'package:stock_count/core/errors/currency_exception.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';
import 'package:stock_count/modules/system_setup/domain/services/initialization_guard.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/repositories/warehouse_accounting_binding_repository.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/services/warehouse_accounting_validation_service.dart';
import 'package:stock_count/modules/currency/domain/services/functional_currency_service.dart';

class MissingCompanyContextException implements Exception {
  const MissingCompanyContextException([
    this.message = 'مطلوب سياق شركة صالح لتنفيذ العملية المحاسبية.',
  ]);
  final String message;

  @override
  String toString() => message;
}

class InventoryAccountingPosterAdapter implements InventoryAccountingPoster {
  InventoryAccountingPosterAdapter(
    AccountingDatabase? accountingDb, {
    this._journalPostingService,
    this._readCompanyId,
    this._initRepository,
    this._initializationGuard,
    this.bindingRepo,
    this.validationService,
    this._functionalCurrencyService,
  }) : _accountingDb = accountingDb;

  final AccountingDatabase? _accountingDb;
  final JournalPostingService? _journalPostingService;
  final String Function()? _readCompanyId;
  final CompanyInitializationRepository? _initRepository;
  final InitializationGuard? _initializationGuard;
  final WarehouseAccountingBindingRepository? bindingRepo;
  final WarehouseAccountingValidationService? validationService;
  final FunctionalCurrencyService? _functionalCurrencyService;

  String get _currentCompanyId {
    final id = _readCompanyId?.call();
    if (id != null && id.trim().isNotEmpty) return id.trim();
    throw const MissingCompanyContextException();
  }

  AccountingDatabase get db {
    if (_accountingDb == null) {
      throw StateError('AccountingDatabase unavailable');
    }
    return _accountingDb;
  }

  Future<String> _resolveCompanyAccount({
    required AccountRole role,
    String? explicitAccountId,
    String? warehouseId,
    required String voucherTypeStr,
  }) async {
    final companyId = _currentCompanyId;

    // Precedence Level 1: Explicit account ID provided
    if (explicitAccountId != null && explicitAccountId.trim().isNotEmpty) {
      final target = explicitAccountId.trim();
      if (validationService != null) {
        final valRes = await validationService!.validateAccount(
          accountIdOrCode: target,
          role: role,
          companyId: companyId,
        );
        if (valRes is WarehouseAccountingValidationSuccess) {
          return valRes.accountUuid;
        } else if (valRes is WarehouseAccountingValidationFailure) {
          throw MissingAccountException(
            accountRole: role.name,
            expectedCode: target,
            systemKey: target,
            message: valRes.reason,
          );
        }
      }

      final byUuidOrCode =
          await (db.select(db.accounts)..where(
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

    // Strict Warehouse-Centric Accounting Binding
    if (bindingRepo != null) {
      final binding = await bindingRepo!.getBindingForWarehouse(
        warehouseId ?? '',
      );
      if (binding != null) {
        final candidateId = switch (role) {
          AccountRole.inventory => binding.inventoryAssetAccountId,
          AccountRole.cogs => binding.cogsAccountId,
          AccountRole.adjustment => binding.inventoryAdjustmentAccountId,
          AccountRole.revenue => binding.salesRevenueAccountId,
          AccountRole.discount => binding.salesDiscountAccountId,
          _ => null,
        };

        if (candidateId != null && candidateId.trim().isNotEmpty) {
          final targetCandidate = candidateId.trim();
          if (validationService != null) {
            final valRes = await validationService!.validateAccount(
              accountIdOrCode: targetCandidate,
              role: role,
              companyId: companyId,
            );
            if (valRes is WarehouseAccountingValidationSuccess) {
              return valRes.accountUuid;
            } else if (valRes is WarehouseAccountingValidationFailure) {
              throw MissingAccountException(
                accountRole: role.name,
                expectedCode: targetCandidate,
                systemKey: targetCandidate,
                message: valRes.reason,
              );
            }
          }

          final acc =
              await (db.select(db.accounts)..where(
                    (tbl) =>
                        (tbl.uuid.equals(targetCandidate) |
                            tbl.accountCode.equals(targetCandidate)) &
                        tbl.deletedAt.isNull() &
                        tbl.isGroup.equals(false) &
                        tbl.isActive.equals(true),
                  ))
                  .getSingleOrNull();
          if (acc != null) return acc.uuid;
        }
      }
    }

    final roleNameAr = switch (role) {
      AccountRole.inventory => 'أصل المخزون',
      AccountRole.payable => 'الموردين / الحسابات الدائنة',
      AccountRole.cogs => 'تكلفة البضاعة المباعة',
      AccountRole.revenue => 'إيرادات المبيعات',
      AccountRole.receivable => 'العملاء / الحسابات المدينة',
      AccountRole.cash => 'الصندوق / النقدية',
      AccountRole.adjustment => 'تسويات وانحرافات المخزون',
      AccountRole.discount => 'الخصم المسموح به',
      _ => role.name,
    };

    throw MissingAccountException(
      accountRole: role.name,
      expectedCode: role.name,
      systemKey: role.name,
      message:
          'خطأ محاسبي: لم يتم ربط حساب ($roleNameAr) للمستودع المحدد. يرجى تهيئة الربط المحاسبي الخاص بهذا المستودع من صفحة إعدادات المستودعات.',
    );
  }

  Future<String> _resolveCompanyBaseCurrency() async {
    final inventoryConfig = await _initRepository?.getInventoryConfig();
    if (inventoryConfig != null &&
        inventoryConfig.inventoryBaseCurrencyId.trim().isNotEmpty) {
      return inventoryConfig.inventoryBaseCurrencyId.trim().toUpperCase();
    }
    final funcService = _functionalCurrencyService;
    if (funcService != null) {
      try {
        final func = await funcService.getFunctionalCurrency(
          _readCompanyId?.call(),
        );
        if (func.code.trim().isNotEmpty) {
          return func.code.trim().toUpperCase();
        }
      } catch (_) {}
    }
    throw const CurrencyRequiredException(
      'Company base currency or functional currency is required for inventory accounting posting.',
    );
  }

  @override
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    double? valuationAmount,
    String? accountId,
    bool isPosted = true,
    bool useBaseCurrencyForPosting = false,
  }) async {
    await _initializationGuard?.assertInitialized();
    if (totalAmount <= 0) return;
    if (!isPosted) {
      await reverseAccountingEntry(document: document);
      return;
    }

    // Skip invoices handled by Sales module
    if (document.documentType == InventoryDocumentType.salesInvoice) {
      return;
    }

    final sourceType = document.documentType.storageValue;
    final sourceId = document.documentId;
    final baseCurrency = await _resolveCompanyBaseCurrency();

    // Handle Stock Transfer: Value-Neutral transfer between Warehouse A and Warehouse B
    if (document.documentType == InventoryDocumentType.stockTransfer) {
      final voucherTypeStr = 'أمر تحويل مخزني';
      final sourceWarehouseId = document.warehouseId;
      final destWarehouseId = document.destinationWarehouseId;

      final sourceAssetAccount = await _resolveCompanyAccount(
        role: AccountRole.inventory,
        warehouseId: sourceWarehouseId,
        voucherTypeStr: voucherTypeStr,
      );

      final destAssetAccount = await _resolveCompanyAccount(
        role: AccountRole.inventory,
        warehouseId: destWarehouseId ?? sourceWarehouseId,
        voucherTypeStr: voucherTypeStr,
      );

      // If source and destination use same account, no artificial journal shift or profit/loss created!
      final debitAccount = destAssetAccount;
      final creditAccount = sourceAssetAccount;

      if (_journalPostingService != null) {
        final draft = JournalEntryDraft(
          entryDate: document.documentDate,
          voucherNumber: document.documentNumber,
          voucherType: voucherTypeStr,
          currencyCode: baseCurrency,
          description:
              'قيد نقل مخزني محايد قيمياً للمستند: ${document.documentNumber}',
          isPosted: isPosted,
          sourceType: sourceType,
          sourceId: sourceId,
          lines: [
            JournalLineDraft(
              accountUuid: debitAccount,
              debit: totalAmount,
              credit: 0.0,
              currencyCode: baseCurrency,
              exchangeRateToBase: 1.0,
              lineDescription: 'تحويل مخزني (إلى) - ${document.documentNumber}',
              sortOrder: 1,
            ),
            JournalLineDraft(
              accountUuid: creditAccount,
              debit: 0.0,
              credit: totalAmount,
              currencyCode: baseCurrency,
              exchangeRateToBase: 1.0,
              lineDescription: 'تحويل مخزني (من) - ${document.documentNumber}',
              sortOrder: 2,
            ),
          ],
        );
        await _journalPostingService.post(draft);
        return;
      }

      await _writeJournalDirectly(
        document: document,
        voucherTypeStr: voucherTypeStr,
        sourceType: sourceType,
        sourceId: sourceId,
        resolvedInventory: destAssetAccount,
        resolvedOffset: sourceAssetAccount,
        isReceipt: true,
        totalAmount: totalAmount,
        docCurrency: baseCurrency,
        docRate: 1.0,
        baseCurrency: baseCurrency,
        calculatedBaseDebit: totalAmount,
        isPosted: isPosted,
      );
      return;
    }

    final isReceipt =
        document.documentType == InventoryDocumentType.stockReceipt;
    final isAdjustment =
        document.documentType == InventoryDocumentType.stockAdjustment;
    final voucherTypeStr = isReceipt
        ? 'أمر توريد'
        : (isAdjustment ? 'تسوية مخزنية' : 'أمر صرف');

    final resolvedInventory = await _resolveCompanyAccount(
      role: AccountRole.inventory,
      warehouseId: document.warehouseId,
      voucherTypeStr: voucherTypeStr,
    );

    final offsetRole = isReceipt
        ? AccountRole.payable
        : (isAdjustment ? AccountRole.adjustment : AccountRole.cogs);
    final resolvedOffset = await _resolveCompanyAccount(
      role: offsetRole,
      explicitAccountId: accountId,
      warehouseId: document.warehouseId,
      voucherTypeStr: voucherTypeStr,
    );

    final String rawDocCurrency = document.currencyCode.trim().isNotEmpty
        ? document.currencyCode.trim().toUpperCase()
        : baseCurrency;

    final bool isBasePosting = useBaseCurrencyForPosting || !isReceipt;

    final String docCurrency = isBasePosting ? baseCurrency : rawDocCurrency;
    final double docRate = isBasePosting
        ? 1.0
        : ExchangeRateValidator.validate(
            currencyCode: docCurrency,
            baseCurrencyCode: baseCurrency,
            exchangeRate: document.exchangeRate,
          );

    final double offsetAmount = isBasePosting
        ? (valuationAmount ?? totalAmount)
        : totalAmount;

    final double calculatedBaseValuation = isBasePosting
        ? offsetAmount
        : (valuationAmount ?? (totalAmount * docRate));

    if (_journalPostingService != null) {
      final inventoryLine = JournalLineDraft(
        accountUuid: resolvedInventory,
        debit: isReceipt ? calculatedBaseValuation : 0.0,
        credit: isReceipt ? 0.0 : calculatedBaseValuation,
        currencyCode: baseCurrency,
        exchangeRateToBase: 1.0,
        lineDescription: 'مخزون - ${document.documentNumber}',
        sortOrder: isReceipt ? 1 : 2,
      );

      final offsetLine = JournalLineDraft(
        accountUuid: resolvedOffset,
        debit: isReceipt ? 0.0 : offsetAmount,
        credit: isReceipt ? offsetAmount : 0.0,
        currencyCode: docCurrency,
        exchangeRateToBase: docRate,
        lineDescription: 'مخزون - ${document.documentNumber}',
        sortOrder: isReceipt ? 2 : 1,
      );

      final draft = JournalEntryDraft(
        entryDate: document.documentDate,
        voucherNumber: document.documentNumber,
        voucherType: voucherTypeStr,
        currencyCode: docCurrency,
        baseCurrencyCode: baseCurrency,
        description:
            'قيد تلقائي للمستند $voucherTypeStr: ${document.documentNumber}',
        isPosted: isPosted,
        sourceType: sourceType,
        sourceId: sourceId,
        lines: isReceipt
            ? [inventoryLine, offsetLine]
            : [offsetLine, inventoryLine],
      );
      await _journalPostingService.post(draft);
      return;
    }

    await _writeJournalDirectly(
      document: document,
      voucherTypeStr: voucherTypeStr,
      sourceType: sourceType,
      sourceId: sourceId,
      resolvedInventory: resolvedInventory,
      resolvedOffset: resolvedOffset,
      isReceipt: isReceipt,
      totalAmount: offsetAmount,
      docCurrency: docCurrency,
      docRate: docRate,
      baseCurrency: baseCurrency,
      calculatedBaseDebit: calculatedBaseValuation,
      isPosted: isPosted,
    );
  }

  Future<void> _writeJournalDirectly({
    required InventoryDocumentRef document,
    required String voucherTypeStr,
    required String sourceType,
    required String sourceId,
    required String resolvedInventory,
    required String resolvedOffset,
    required bool isReceipt,
    required double totalAmount,
    required String docCurrency,
    required double docRate,
    required String baseCurrency,
    required double calculatedBaseDebit,
    required bool isPosted,
  }) async {
    final now = DateTime.now().toUtc();

    await db.transaction(() async {
      final existingEntry =
          await (db.select(db.journalEntries)..where(
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
        await (db.update(db.journalEntries)..where(
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
                currencyCode: Value(docCurrency),
                isPosted: Value(isPosted),
                companyId: Value(_currentCompanyId),
                deletedAt: const Value(null),
                updatedAt: Value(now.millisecondsSinceEpoch),
              ),
            );

        await (db.delete(
          db.journalLines,
        )..where((tbl) => tbl.entryUuid.equals(entryUuid))).go();
      } else {
        entryUuid = generateUuidV4();
        await db
            .into(db.journalEntries)
            .insert(
              JournalEntriesCompanion(
                uuid: Value(entryUuid),
                voucherNumber: Value(document.documentNumber),
                voucherType: Value(voucherTypeStr),
                entryDate: Value(document.documentDate.millisecondsSinceEpoch),
                description: Value(
                  'قيد تلقائي للمستند $voucherTypeStr: ${document.documentNumber}',
                ),
                currencyCode: Value(docCurrency),
                isPosted: Value(isPosted),
                sourceType: Value(sourceType),
                sourceId: Value(sourceId),
                createdAt: Value(now.millisecondsSinceEpoch),
                updatedAt: Value(now.millisecondsSinceEpoch),
                companyId: Value(_currentCompanyId),
              ),
            );
      }

      // 1. Inventory Account Line (in Inventory Base Currency, e.g. YER)
      await db
          .into(db.journalLines)
          .insert(
            JournalLinesCompanion(
              uuid: Value(generateUuidV4()),
              entryUuid: Value(entryUuid),
              accountUuid: Value(resolvedInventory),
              debit: Value(isReceipt ? calculatedBaseDebit : 0.0),
              credit: Value(isReceipt ? 0.0 : calculatedBaseDebit),
              baseDebit: Value(isReceipt ? calculatedBaseDebit : 0.0),
              baseCredit: Value(isReceipt ? 0.0 : calculatedBaseDebit),
              currencyCode: Value(baseCurrency),
              exchangeRateToBase: const Value(1.0),
              lineDescription: Value('مخزون - ${document.documentNumber}'),
            ),
          );

      // 2. Offset Account Line (in Document Currency, e.g. SAR/USD)
      await db
          .into(db.journalLines)
          .insert(
            JournalLinesCompanion(
              uuid: Value(generateUuidV4()),
              entryUuid: Value(entryUuid),
              accountUuid: Value(resolvedOffset),
              debit: Value(isReceipt ? 0.0 : totalAmount),
              credit: Value(isReceipt ? totalAmount : 0.0),
              baseDebit: Value(isReceipt ? 0.0 : calculatedBaseDebit),
              baseCredit: Value(isReceipt ? calculatedBaseDebit : 0.0),
              currencyCode: Value(docCurrency),
              exchangeRateToBase: Value(docRate),
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
        await (db.select(db.journalEntries)..where(
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

    await (db.update(db.journalEntries)..where(
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
        await (db.select(db.journalEntries)..where(
              (tbl) =>
                  tbl.sourceType.equals(sourceType) &
                  tbl.sourceId.equals(sourceId) &
                  tbl.companyId.equals(_currentCompanyId) &
                  tbl.deletedAt.isNull(),
            ))
            .getSingleOrNull();

    if (existing != null && existing.isPosted) {
      final existingLines = await (db.select(
        db.journalLines,
      )..where((tbl) => tbl.entryUuid.equals(existing.uuid))).get();

      final reverseUuid = generateUuidV4();
      await db
          .into(db.journalEntries)
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
        await db
            .into(db.journalLines)
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

    await (db.update(db.journalEntries)..where(
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
