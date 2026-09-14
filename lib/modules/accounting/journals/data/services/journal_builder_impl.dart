import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/core/errors/invalid_exchange_rate_exception.dart';
import 'package:stock_count/shared/contracts/errors/account_exception.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_builder_service.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/domain/repositories/currency_rate_repository.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/currency/domain/services/functional_currency_service.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/repositories/warehouse_accounting_binding_repository.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/services/warehouse_accounting_validation_service.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_money.dart';

class MissingCompanyContextException implements Exception {
  const MissingCompanyContextException([
    this.message = 'مطلوب سياق شركة صالح لتنفيذ العملية المحاسبية.',
  ]);
  final String message;

  @override
  String toString() => message;
}

/// Implementation of [JournalBuilderService] that builds domain [JournalEntryDraft] instances
/// using domain repositories without direct database persistence or Drift access.
class JournalBuilderImpl implements JournalBuilderService {
  JournalBuilderImpl({
    required this._accountRepository,
    required this._currencyRateRepository,
    this._readCompanyId,
    this._initRepository,
    this._bindingRepo,
    this._validationService,
    this._functionalCurrencyService,
  });

  final AccountRepository _accountRepository;
  final CurrencyRateRepository _currencyRateRepository;
  final String Function()? _readCompanyId;
  final CompanyInitializationRepository? _initRepository;
  final WarehouseAccountingBindingRepository? _bindingRepo;
  final WarehouseAccountingValidationService? _validationService;
  final FunctionalCurrencyService? _functionalCurrencyService;

  String get _currentCompanyId {
    final id = _readCompanyId?.call();
    if (id != null && id.trim().isNotEmpty) return id.trim();
    throw const MissingCompanyContextException();
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
      final valService = _validationService;
      if (valService != null) {
        final valRes = await valService.validateAccount(
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

      final byUuid = await _accountRepository.getByUuid(target);
      if (byUuid != null && !byUuid.isGroup && byUuid.isActive) {
        return byUuid.id;
      }
      final byCode = await _accountRepository.getByAccountCode(target);
      if (byCode != null && !byCode.isGroup && byCode.isActive) {
        return byCode.id;
      }

      throw MissingAccountException(
        accountRole: role.name,
        expectedCode: target,
        systemKey: target,
        message:
            'خطأ محاسبي: الحساب المحاسبي المحدد ($target) غير موجود في الشركة الحالية أو غير نشط.',
      );
    }

    // Strict Warehouse-Centric Accounting Binding
    final bindingRepository = _bindingRepo;
    if (bindingRepository != null) {
      final binding = await bindingRepository.getBindingForWarehouse(
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
          final valService = _validationService;
          if (valService != null) {
            final valRes = await valService.validateAccount(
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

          final accByUuid = await _accountRepository.getByUuid(targetCandidate);
          if (accByUuid != null && !accByUuid.isGroup && accByUuid.isActive) {
            return accByUuid.id;
          }
          final accByCode = await _accountRepository.getByAccountCode(
            targetCandidate,
          );
          if (accByCode != null && !accByCode.isGroup && accByCode.isActive) {
            return accByCode.id;
          }
        }
      }
    }

    final defaultCode = switch (role) {
      AccountRole.inventory => '1230',
      AccountRole.cogs => '5100',
      AccountRole.revenue => '4100',
      AccountRole.receivable => '1220',
      AccountRole.payable => '2110',
      AccountRole.cash => '1211',
      AccountRole.adjustment => '5150',
      AccountRole.discount => '4120',
      _ => null,
    };
    if (defaultCode != null) {
      final acc = await _accountRepository.getByAccountCode(defaultCode);
      if (acc != null && !acc.isGroup && acc.isActive) {
        return acc.id;
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
    return 'YER';
  }

  Future<String> _resolveInventoryCurrency() async {
    final inventoryConfig = await _initRepository?.getInventoryConfig();
    if (inventoryConfig != null &&
        inventoryConfig.inventoryBaseCurrencyId.trim().isNotEmpty) {
      return inventoryConfig.inventoryBaseCurrencyId.trim().toUpperCase();
    }
    return await _resolveCompanyBaseCurrency();
  }

  Future<double> _resolveRateToBase({
    required String currencyCode,
    required String baseCurrencyCode,
    double? fallbackRate,
  }) async {
    final code = currencyCode.trim().toUpperCase();
    final base = baseCurrencyCode.trim().toUpperCase();
    if (code == base) return 1.0;
    try {
      final rateObj = await _currencyRateRepository.getByCode(code);
      if (rateObj != null && rateObj.rateToBase > 0) {
        return rateObj.rateToBase;
      }
    } catch (_) {}
    return ExchangeRateValidator.validate(
      currencyCode: code,
      baseCurrencyCode: base,
      exchangeRate: fallbackRate,
    );
  }

  @override
  Future<JournalEntryDraft> buildReceiptJournal({
    required InventoryDocumentRef document,
    required double totalAmount,
    double? valuationAmount,
    String? accountId,
    bool isPosted = true,
    bool useBaseCurrencyForPosting = false,
  }) async {
    final sourceType = document.documentType.storageValue;
    final sourceId = document.documentId;
    final baseCurrency = await _resolveCompanyBaseCurrency();
    final invCurrency = await _resolveInventoryCurrency();
    const voucherTypeStr = 'أمر توريد';

    final resolvedInventory = await _resolveCompanyAccount(
      role: AccountRole.inventory,
      warehouseId: document.warehouseId,
      voucherTypeStr: voucherTypeStr,
    );

    final resolvedOffset = await _resolveCompanyAccount(
      role: AccountRole.payable,
      explicitAccountId: accountId,
      warehouseId: document.warehouseId,
      voucherTypeStr: voucherTypeStr,
    );

    final String rawDocCurrency = document.currencyCode.trim().isNotEmpty
        ? document.currencyCode.trim().toUpperCase()
        : baseCurrency;

    final bool isBasePosting = useBaseCurrencyForPosting;
    final String docCurrency = isBasePosting ? baseCurrency : rawDocCurrency;
    final double docRate = isBasePosting
        ? 1.0
        : await _resolveRateToBase(
            currencyCode: docCurrency,
            baseCurrencyCode: baseCurrency,
            fallbackRate: document.exchangeRate,
          );

    final double invRate = await _resolveRateToBase(
      currencyCode: invCurrency,
      baseCurrencyCode: baseCurrency,
    );

    // --- Multi-Currency Amount Resolution ---
    // totalAmount & valuationAmount from PostingCoordinator are ALWAYS in document currency.
    // baseTotal = total expressed in base/functional currency (YER).
    // invAmount = total expressed in inventory valuation currency (SAR).
    // Both sides (inventory debit, offset credit) must have equal baseDebit/baseCredit.

    final double docTotal = JournalMoney.round(valuationAmount ?? totalAmount);

    final double baseTotal = isBasePosting
        ? docTotal
        : JournalMoney.round(docTotal * docRate);

    final double offsetAmount = isBasePosting ? baseTotal : docTotal;
    final double offsetBaseCredit = baseTotal;

    // Convert document-currency total into inventory valuation currency
    final double invAmount = (invCurrency == docCurrency)
        ? docTotal
        : (invCurrency == baseCurrency)
            ? baseTotal
            : JournalMoney.round(baseTotal / (invRate > 0 ? invRate : 1.0));

    // Base equivalent for inventory line MUST equal baseTotal for balance
    final double invBaseDebit = baseTotal;

    final inventoryLine = JournalLineDraft(
      accountUuid: resolvedInventory,
      debit: invAmount,
      credit: 0.0,
      currencyCode: invCurrency,
      exchangeRateToBase: invRate,
      baseDebit: invBaseDebit,
      baseCredit: 0.0,
      lineDescription: 'مخزون - ${document.documentNumber}',
      sortOrder: 1,
    );

    final offsetLine = JournalLineDraft(
      accountUuid: resolvedOffset,
      debit: 0.0,
      credit: offsetAmount,
      currencyCode: docCurrency,
      exchangeRateToBase: docRate,
      baseDebit: 0.0,
      baseCredit: offsetBaseCredit,
      lineDescription: 'مخزون - ${document.documentNumber}',
      sortOrder: 2,
    );

    final isMultiCurrency = (docCurrency != invCurrency) || (docCurrency != baseCurrency) || (invCurrency != baseCurrency);

    return JournalEntryDraft(
      entryDate: document.documentDate,
      voucherNumber: document.documentNumber,
      voucherType: voucherTypeStr,
      currencyCode: docCurrency,
      baseCurrencyCode: baseCurrency,
      allowUnbalancedMultiCurrency: isMultiCurrency,
      description:
          'قيد تلقائي للمستند $voucherTypeStr: ${document.documentNumber}',
      isPosted: isPosted,
      sourceType: sourceType,
      sourceId: sourceId,
      lines: [inventoryLine, offsetLine],
    );
  }

  @override
  Future<JournalEntryDraft> buildIssueJournal({
    required InventoryDocumentRef document,
    required double totalAmount,
    double? valuationAmount,
    String? accountId,
    bool isPosted = true,
    bool useBaseCurrencyForPosting = false,
  }) async {
    final sourceType = document.documentType.storageValue;
    final sourceId = document.documentId;
    final baseCurrency = await _resolveCompanyBaseCurrency();
    final invCurrency = await _resolveInventoryCurrency();

    final isAdjustment =
        document.documentType == InventoryDocumentType.stockAdjustment;
    final voucherTypeStr = isAdjustment ? 'تسوية مخزنية' : 'أمر صرف';

    final resolvedInventory = await _resolveCompanyAccount(
      role: AccountRole.inventory,
      warehouseId: document.warehouseId,
      voucherTypeStr: voucherTypeStr,
    );

    final offsetRole = isAdjustment ? AccountRole.adjustment : AccountRole.cogs;
    final resolvedOffset = await _resolveCompanyAccount(
      role: offsetRole,
      explicitAccountId: accountId,
      warehouseId: document.warehouseId,
      voucherTypeStr: voucherTypeStr,
    );

    final String rawDocCurrency = document.currencyCode.trim().isNotEmpty
        ? document.currencyCode.trim().toUpperCase()
        : baseCurrency;

    final bool isBasePosting = useBaseCurrencyForPosting;
    final String docCurrency = isBasePosting ? baseCurrency : rawDocCurrency;
    final double docRate = isBasePosting
        ? 1.0
        : await _resolveRateToBase(
            currencyCode: docCurrency,
            baseCurrencyCode: baseCurrency,
            fallbackRate: document.exchangeRate,
          );

    final double invRate = await _resolveRateToBase(
      currencyCode: invCurrency,
      baseCurrencyCode: baseCurrency,
    );

    // --- Multi-Currency Amount Resolution ---
    // totalAmount & valuationAmount from PostingCoordinator are ALWAYS in document currency.
    // baseTotal = total in base/functional currency (YER).
    // invAmount = total in inventory valuation currency (SAR).
    // Both sides must have equal baseDebit/baseCredit.

    final double docTotal = JournalMoney.round(valuationAmount ?? totalAmount);

    final double baseTotal = isBasePosting
        ? docTotal
        : JournalMoney.round(docTotal * docRate);

    // Convert document-currency total into inventory valuation currency
    final double invAmount = (invCurrency == docCurrency)
        ? docTotal
        : (invCurrency == baseCurrency)
            ? baseTotal
            : JournalMoney.round(baseTotal / (invRate > 0 ? invRate : 1.0));

    // Base equivalent for inventory line MUST equal baseTotal for balance
    final double invBaseCredit = baseTotal;

    final double offsetAmount = (docCurrency == baseCurrency)
        ? baseTotal
        : (docCurrency == invCurrency
            ? invAmount
            : docTotal);

    final double offsetBaseDebit = baseTotal;

    final inventoryLine = JournalLineDraft(
      accountUuid: resolvedInventory,
      debit: 0.0,
      credit: invAmount,
      currencyCode: invCurrency,
      exchangeRateToBase: invRate,
      baseDebit: 0.0,
      baseCredit: invBaseCredit,
      lineDescription: 'مخزون - ${document.documentNumber}',
      sortOrder: 2,
    );

    final offsetLine = JournalLineDraft(
      accountUuid: resolvedOffset,
      debit: offsetAmount,
      credit: 0.0,
      currencyCode: docCurrency,
      exchangeRateToBase: docRate,
      baseDebit: offsetBaseDebit,
      baseCredit: 0.0,
      lineDescription: 'مخزون - ${document.documentNumber}',
      sortOrder: 1,
    );

    final isMultiCurrency = (docCurrency != invCurrency) || (docCurrency != baseCurrency) || (invCurrency != baseCurrency);

    return JournalEntryDraft(
      entryDate: document.documentDate,
      voucherNumber: document.documentNumber,
      voucherType: voucherTypeStr,
      currencyCode: docCurrency,
      baseCurrencyCode: baseCurrency,
      allowUnbalancedMultiCurrency: isMultiCurrency,
      description:
          'قيد تلقائي للمستند $voucherTypeStr: ${document.documentNumber}',
      isPosted: isPosted,
      sourceType: sourceType,
      sourceId: sourceId,
      lines: [offsetLine, inventoryLine],
    );
  }

  @override
  Future<JournalEntryDraft> buildTransferJournal({
    required InventoryDocumentRef document,
    required double totalAmount,
    double? valuationAmount,
    bool isPosted = true,
  }) async {
    final sourceType = document.documentType.storageValue;
    final sourceId = document.documentId;
    final baseCurrency = await _resolveCompanyBaseCurrency();
    final invCurrency = await _resolveInventoryCurrency();
    const voucherTypeStr = 'أمر تحويل مخزني';

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

    final double invRate = await _resolveRateToBase(
      currencyCode: invCurrency,
      baseCurrencyCode: baseCurrency,
    );

    // --- Multi-Currency Amount Resolution ---
    // valuationAmount from PostingCoordinator is in document currency.
    final double docTotal = JournalMoney.round(valuationAmount ?? totalAmount);
    final double docRate = ExchangeRateValidator.validate(
      currencyCode: document.currencyCode,
      baseCurrencyCode: baseCurrency,
      exchangeRate: document.exchangeRate,
    );

    final double baseTotal = JournalMoney.round(docTotal * docRate);

    // Convert to inventory valuation currency
    final double invAmount = (invCurrency == baseCurrency)
        ? baseTotal
        : JournalMoney.round(baseTotal / (invRate > 0 ? invRate : 1.0));

    // Base equivalent MUST equal baseTotal for balance
    final double invBaseAmount = baseTotal;

    return JournalEntryDraft(
      entryDate: document.documentDate,
      voucherNumber: document.documentNumber,
      voucherType: voucherTypeStr,
      currencyCode: invCurrency,
      baseCurrencyCode: baseCurrency,
      description:
          'قيد نقل مخزني محايد قيمياً للمستند: ${document.documentNumber}',
      isPosted: isPosted,
      sourceType: sourceType,
      sourceId: sourceId,
      lines: [
        JournalLineDraft(
          accountUuid: destAssetAccount,
          debit: invAmount,
          credit: 0.0,
          currencyCode: invCurrency,
          exchangeRateToBase: invRate,
          baseDebit: invBaseAmount,
          baseCredit: 0.0,
          lineDescription: 'تحويل مخزني (إلى) - ${document.documentNumber}',
          sortOrder: 1,
        ),
        JournalLineDraft(
          accountUuid: sourceAssetAccount,
          debit: 0.0,
          credit: invAmount,
          currencyCode: invCurrency,
          exchangeRateToBase: invRate,
          baseDebit: 0.0,
          baseCredit: invBaseAmount,
          lineDescription: 'تحويل مخزني (من) - ${document.documentNumber}',
          sortOrder: 2,
        ),
      ],
    );
  }

  @override
  Future<JournalEntryDraft> buildReverseJournal({
    required InventoryDocumentRef document,
    JournalEntry? originalEntry,
  }) async {
    final sourceType = document.documentType.storageValue;
    final sourceId = document.documentId;

    if (originalEntry != null) {
      final description = originalEntry.description?.trim();
      final reverseDescription = (description == null || description.isEmpty)
          ? 'عكس قيد ${originalEntry.voucherNumber}'
          : 'عكس: $description';

      return JournalEntryDraft(
        entryDate: originalEntry.entryDate,
        voucherNumber: '${originalEntry.voucherNumber}-R',
        voucherType: originalEntry.voucherType,
        currencyCode: originalEntry.currencyCode,
        baseCurrencyCode: originalEntry.currencyCode,
        description: reverseDescription,
        isPosted: true,
        sourceType: JournalPostingService.reverseSourceType,
        sourceId: originalEntry.id,
        lines: [
          for (final line in originalEntry.lines)
            JournalLineDraft(
              accountUuid: line.accountUuid,
              debit: line.credit,
              credit: line.debit,
              currencyCode: line.currencyCode,
              exchangeRateToBase: line.exchangeRateToBase,
              baseDebit: line.baseCredit,
              baseCredit: line.baseDebit,
              lineDescription: line.lineDescription,
              sortOrder: line.sortOrder,
            ),
        ],
      );
    }

    final voucherTypeStr = switch (document.documentType) {
      InventoryDocumentType.stockReceipt => 'أمر توريد',
      InventoryDocumentType.stockIssue => 'أمر صرف',
      InventoryDocumentType.stockAdjustment => 'تسوية مخزنية',
      InventoryDocumentType.stockTransfer => 'أمر تحويل مخزني',
      _ => 'مستند مخزني',
    };

    final baseCurrency = await _resolveCompanyBaseCurrency();
    return JournalEntryDraft(
      entryDate: document.documentDate,
      voucherNumber: '${document.documentNumber}-R',
      voucherType: voucherTypeStr,
      currencyCode: baseCurrency,
      baseCurrencyCode: baseCurrency,
      description: 'عكس قيد: ${document.documentNumber}',
      isPosted: true,
      sourceType: sourceType,
      sourceId: sourceId,
      lines: const [],
    );
  }
}
