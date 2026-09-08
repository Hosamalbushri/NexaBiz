import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/errors/invalid_exchange_rate_exception.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import 'package:stock_count/core/utils/journal_money.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_ledger_posting_port.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/repositories/warehouse_accounting_binding_repository.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

/// App adapter: sale save/post → local journal.
class AccountingSaleLedgerAdapter implements SaleLedgerPostingPort {
  AccountingSaleLedgerAdapter({
    required JournalPostingService posting,
    required AccountRepository accounts,
    CompanyInitializationRepository? initRepository,
    WarehouseAccountingBindingRepository? bindingRepo,
  }) : _posting = posting,
       _accounts = accounts,
       _initRepository = initRepository,
       _bindingRepo = bindingRepo;

  final JournalPostingService _posting;
  final AccountRepository _accounts;
  final CompanyInitializationRepository? _initRepository;
  final WarehouseAccountingBindingRepository? _bindingRepo;

  static const sourceType = 'sale';
  static const voucherTypeCreditSale = 'بيع آجل';
  static const voucherTypeCashSale = 'بيع نقدي';

  @override
  Future<void> syncSale(Sale sale) async {
    final netAmount = sale.total;
    final discountAmount = _totalDiscount(sale);
    final taxAmount = sale.taxAmount > 0
        ? JournalMoney.round(sale.taxAmount)
        : 0.0;
    if (netAmount <= 0 && discountAmount <= 0 && taxAmount <= 0) {
      return;
    }

    final companyConfig = await _initRepository?.getAccountingConfig();

    var debitAccountId = switch (sale.settlementType) {
      SaleSettlementType.credit => sale.customerAccountId?.trim(),
      SaleSettlementType.cash => sale.cashAccountId?.trim(),
    };
    if (sale.settlementType == SaleSettlementType.credit &&
        (debitAccountId == null || debitAccountId.isEmpty)) {
      final arAccount = await _resolveRoleAccount(
        companyConfig: companyConfig,
        role: AccountRole.receivable,
        warehouseId: sale.warehouseId,
      );
      if (arAccount != null) {
        debitAccountId = arAccount.uuid;
      }
    } else if (sale.settlementType == SaleSettlementType.cash &&
        (debitAccountId == null || debitAccountId.isEmpty)) {
      final cashAccount = await _resolveRoleAccount(
        companyConfig: companyConfig,
        role: AccountRole.cash,
        warehouseId: sale.warehouseId,
      );
      if (cashAccount != null) {
        debitAccountId = cashAccount.uuid;
      }
    }
    if (netAmount > 0 && (debitAccountId == null || debitAccountId.isEmpty)) {
      throw const JournalException(JournalException.debitAccountMissing);
    }

    final revenue = await _resolveRoleAccount(
      companyConfig: companyConfig,
      role: AccountRole.revenue,
      warehouseId: sale.warehouseId,
    );
    if (revenue == null) {
      throw const JournalException(JournalException.revenueAccountMissing);
    }

    Account? discountAccount;
    if (discountAmount > 0) {
      discountAccount =
          await _resolveRoleAccount(
            companyConfig: companyConfig,
            role: AccountRole.discount,
            warehouseId: sale.warehouseId,
          ) ??
          await _resolveRoleAccount(
            companyConfig: companyConfig,
            role: AccountRole.cogs,
            warehouseId: sale.warehouseId,
          );
      if (discountAccount == null) {
        throw const JournalException(JournalException.discountAccountMissing);
      }
    }

    Account? taxAccount;
    if (taxAmount > 0) {
      taxAccount = await _resolveRoleAccount(
        companyConfig: companyConfig,
        role: AccountRole.payable,
        warehouseId: sale.warehouseId,
      );
      if (taxAccount == null) {
        throw const JournalException(JournalException.taxAccountMissing);
      }
    }

    final currency = sale.currencyCode.trim().toUpperCase();
    final baseCurrency = sale.baseCurrencyCode.trim().toUpperCase().isEmpty
        ? currency
        : sale.baseCurrencyCode.trim().toUpperCase();
    final rate = ExchangeRateValidator.validate(
      currencyCode: currency,
      baseCurrencyCode: baseCurrency,
      exchangeRate: sale.exchangeRate,
    );
    final customerLabel = sale.customerName?.trim() ?? '';
    final isCredit = sale.settlementType == SaleSettlementType.credit;
    final voucherType = isCredit ? voucherTypeCreditSale : voucherTypeCashSale;
    final description = customerLabel.isEmpty
        ? 'فاتورة $voucherType ${sale.saleNumber}'
        : 'فاتورة $voucherType ${sale.saleNumber} — $customerLabel';
    final revenueCredit = JournalMoney.round(
      netAmount + discountAmount - taxAmount,
    );

    final lines = <JournalLineDraft>[
      if (netAmount > 0 && debitAccountId != null)
        JournalLineDraft(
          accountUuid: debitAccountId,
          debit: netAmount,
          credit: 0,
          currencyCode: currency,
          exchangeRateToBase: rate,
          lineDescription: description,
          sortOrder: 0,
        ),
      if (discountAmount > 0 && discountAccount != null)
        JournalLineDraft(
          accountUuid: discountAccount.uuid,
          debit: discountAmount,
          credit: 0,
          currencyCode: currency,
          exchangeRateToBase: rate,
          lineDescription: 'خصم $description',
          sortOrder: 1,
        ),
      if (revenueCredit > 0)
        JournalLineDraft(
          accountUuid: revenue.uuid,
          debit: 0,
          credit: revenueCredit,
          currencyCode: currency,
          exchangeRateToBase: rate,
          lineDescription: description,
          sortOrder: 2,
        ),
      if (taxAmount > 0 && taxAccount != null)
        JournalLineDraft(
          accountUuid: taxAccount.uuid,
          debit: 0,
          credit: taxAmount,
          currencyCode: currency,
          exchangeRateToBase: rate,
          lineDescription: 'ضريبة $description',
          sortOrder: 3,
        ),
    ];

    await _posting.post(
      JournalEntryDraft(
        entryDate: sale.saleDate,
        voucherNumber: sale.saleNumber,
        voucherType: voucherType,
        currencyCode: currency,
        baseCurrencyCode: baseCurrency,
        description: description,
        isPosted: sale.saleStatus.isPosted,
        sourceType: sourceType,
        sourceId: sale.uuid,
        lines: lines,
      ),
    );
  }

  @override
  Future<void> voidSale(Sale sale) async {
    await _posting.voidBySource(sourceType: sourceType, sourceId: sale.uuid);
  }

  double _totalDiscount(Sale sale) {
    final raw = sale.itemDiscountTotal + sale.discountAmount;
    if (raw <= 0) {
      return 0;
    }
    return JournalMoney.round(raw);
  }

  Future<Account?> _resolveRoleAccount({
    required CompanyAccountingConfig? companyConfig,
    required AccountRole role,
    String? warehouseId,
  }) async {
    if (warehouseId != null &&
        warehouseId.trim().isNotEmpty &&
        _bindingRepo != null) {
      final binding = await _bindingRepo!.getBindingForWarehouse(
        warehouseId.trim(),
      );
      if (binding != null) {
        final candidateId = switch (role) {
          AccountRole.revenue => binding.salesRevenueAccountId,
          AccountRole.discount => binding.salesDiscountAccountId,
          AccountRole.inventory => binding.inventoryAssetAccountId,
          AccountRole.cogs => binding.cogsAccountId,
          AccountRole.adjustment => binding.inventoryAdjustmentAccountId,
          _ => null,
        };

        if (candidateId != null && candidateId.trim().isNotEmpty) {
          final target = candidateId.trim();
          final acc =
              await _accounts.getByUuid(target) ??
              await _accounts.getByAccountCode(target);
          if (acc != null && acc.isPostingAccount && !acc.isDeleted) {
            return acc;
          }
        }
      }
    }

    final configuredKey =
        companyConfig?.bindingTargets[role]?.activeUuid ??
        companyConfig?.accountMappings[role]?.trim();
    if (configuredKey != null && configuredKey.isNotEmpty) {
      final acc =
          await _accounts.getByUuid(configuredKey) ??
          await _accounts.getByAccountCode(configuredKey) ??
          (int.tryParse(configuredKey) != null
              ? await _accounts.getById(int.parse(configuredKey))
              : null);
      if (acc != null && acc.isPostingAccount && !acc.isDeleted) {
        return acc;
      }
    }
    return null;
  }
}
