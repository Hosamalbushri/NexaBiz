import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/shared/contracts/errors/currency_exception.dart';
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
    required AccountRepository accountRepository,
    required CurrencyRateRepository currencyRateRepository,
    String Function()? readCompanyId,
    CompanyInitializationRepository? initRepository,
    WarehouseAccountingBindingRepository? bindingRepo,
    WarehouseAccountingValidationService? validationService,
    FunctionalCurrencyService? functionalCurrencyService,
  }) : _accountRepository = accountRepository,
       _readCompanyId = readCompanyId,
       _initRepository = initRepository,
       _bindingRepo = bindingRepo,
       _validationService = validationService,
       _functionalCurrencyService = functionalCurrencyService;

  final AccountRepository _accountRepository;
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
        return byUuid.uuid;
      }
      final byCode = await _accountRepository.getByAccountCode(target);
      if (byCode != null && !byCode.isGroup && byCode.isActive) {
        return byCode.uuid;
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
            return accByUuid.uuid;
          }
          final accByCode = await _accountRepository.getByAccountCode(
            targetCandidate,
          );
          if (accByCode != null && !accByCode.isGroup && accByCode.isActive) {
            return accByCode.uuid;
          }
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
    return 'SAR';
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

    final inventoryLine = JournalLineDraft(
      accountUuid: resolvedInventory,
      debit: calculatedBaseValuation,
      credit: 0.0,
      currencyCode: baseCurrency,
      exchangeRateToBase: 1.0,
      lineDescription: 'مخزون - ${document.documentNumber}',
      sortOrder: 1,
    );

    final offsetLine = JournalLineDraft(
      accountUuid: resolvedOffset,
      debit: 0.0,
      credit: offsetAmount,
      currencyCode: docCurrency,
      exchangeRateToBase: docRate,
      lineDescription: 'مخزون - ${document.documentNumber}',
      sortOrder: 2,
    );

    return JournalEntryDraft(
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

    final double offsetAmount = valuationAmount ?? totalAmount;
    final double calculatedBaseValuation = offsetAmount;

    final inventoryLine = JournalLineDraft(
      accountUuid: resolvedInventory,
      debit: 0.0,
      credit: calculatedBaseValuation,
      currencyCode: baseCurrency,
      exchangeRateToBase: 1.0,
      lineDescription: 'مخزون - ${document.documentNumber}',
      sortOrder: 2,
    );

    final offsetLine = JournalLineDraft(
      accountUuid: resolvedOffset,
      debit: offsetAmount,
      credit: 0.0,
      currencyCode: baseCurrency,
      exchangeRateToBase: 1.0,
      lineDescription: 'مخزون - ${document.documentNumber}',
      sortOrder: 1,
    );

    return JournalEntryDraft(
      entryDate: document.documentDate,
      voucherNumber: document.documentNumber,
      voucherType: voucherTypeStr,
      currencyCode: baseCurrency,
      baseCurrencyCode: baseCurrency,
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

    final debitAccount = destAssetAccount;
    final creditAccount = sourceAssetAccount;

    return JournalEntryDraft(
      entryDate: document.documentDate,
      voucherNumber: document.documentNumber,
      voucherType: voucherTypeStr,
      currencyCode: baseCurrency,
      baseCurrencyCode: baseCurrency,
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
        sourceId: originalEntry.uuid,
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
