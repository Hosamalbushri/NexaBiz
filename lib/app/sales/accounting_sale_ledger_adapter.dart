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

/// App adapter: sale save/post → local journal.
///
/// - Credit: Dr customer AR / Cr 4100
/// - Cash: Dr cash/treasury / Cr 4100
/// - Discount (item + sale): Dr 5170 / extra Cr 4100 so revenue is gross
class AccountingSaleLedgerAdapter implements SaleLedgerPostingPort {
  AccountingSaleLedgerAdapter({
    required JournalPostingService posting,
    required AccountRepository accounts,
  })  : _posting = posting,
        _accounts = accounts;

  final JournalPostingService _posting;
  final AccountRepository _accounts;

  static const sourceType = 'sale';
  static const salesRevenueCode = '4100';
  static const salesRevenueSystemKey = 'sales_revenue';
  static const salesDiscountsCode = '5170';
  static const salesDiscountsSystemKey = 'sales_discounts';
  static const vatOutputCode = '2130';
  static const vatOutputSystemKey = 'vat_output';
  static const voucherTypeCreditSale = 'بيع آجل';
  static const voucherTypeCashSale = 'بيع نقدي';

  @override
  Future<void> syncSale(Sale sale) async {
    final netAmount = sale.total;
    final discountAmount = _totalDiscount(sale);
    final taxAmount = sale.taxAmount > 0 ? JournalMoney.round(sale.taxAmount) : 0.0;
    if (netAmount <= 0 && discountAmount <= 0 && taxAmount <= 0) {
      return;
    }

    await _accounts.ensureDefaultChartSeeded();

    var debitAccountId = switch (sale.settlementType) {
      SaleSettlementType.credit => sale.customerAccountId?.trim(),
      SaleSettlementType.cash => sale.cashAccountId?.trim(),
    };
    if (sale.settlementType == SaleSettlementType.credit && (debitAccountId == null || debitAccountId.isEmpty)) {
      final arAccount = await _resolveSystemAccount(
        code: '1220',
        systemKey: 'accounts_receivable',
      ) ?? await _resolveSystemAccount(
        code: '1221',
        systemKey: 'customers',
      );
      if (arAccount != null) {
        debitAccountId = arAccount.uuid;
      }
    }
    if (netAmount > 0 && (debitAccountId == null || debitAccountId.isEmpty)) {
      throw const JournalException(JournalException.debitAccountMissing);
    }

    final revenue = await _resolveSystemAccount(
      code: salesRevenueCode,
      systemKey: salesRevenueSystemKey,
    );
    if (revenue == null) {
      throw const JournalException(JournalException.revenueAccountMissing);
    }

    Account? discountAccount;
    if (discountAmount > 0) {
      discountAccount = await _resolveSystemAccount(
        code: salesDiscountsCode,
        systemKey: salesDiscountsSystemKey,
      );
      if (discountAccount == null) {
        throw const JournalException(JournalException.discountAccountMissing);
      }
    }

    Account? taxAccount;
    if (taxAmount > 0) {
      taxAccount = await _resolveSystemAccount(
        code: vatOutputCode,
        systemKey: vatOutputSystemKey,
      );
      if (taxAccount == null) {
        throw const JournalException(JournalException.taxAccountMissing);
      }
    }

    final currency = sale.currencyCode.trim().toUpperCase();
    final baseCurrency = sale.baseCurrencyCode.trim().toUpperCase().isEmpty
        ? currency
        : sale.baseCurrencyCode.trim().toUpperCase();
    final rate = sale.exchangeRate <= 0 ? 1.0 : sale.exchangeRate;
    final customerLabel = sale.customerName?.trim() ?? '';
    final isCredit = sale.settlementType == SaleSettlementType.credit;
    final voucherType = isCredit ? voucherTypeCreditSale : voucherTypeCashSale;
    final description = customerLabel.isEmpty
        ? 'فاتورة $voucherType ${sale.saleNumber}'
        : 'فاتورة $voucherType ${sale.saleNumber} — $customerLabel';
    final revenueCredit = JournalMoney.round(netAmount + discountAmount - taxAmount);

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

  Future<Account?> _resolveSystemAccount({
    required String code,
    required String systemKey,
  }) async {
    final byCode = await _accounts.getByAccountCode(code);
    if (byCode != null &&
        !byCode.isDeleted &&
        byCode.isPostingAccount &&
        byCode.isActive) {
      return byCode;
    }

    final all = await _accounts.getAll(includeInactive: false);
    for (final account in all) {
      if (AccountLabels.systemKeyOf(account) == systemKey &&
          account.isPostingAccount &&
          !account.isDeleted) {
        return account;
      }
    }
    return null;
  }
}
