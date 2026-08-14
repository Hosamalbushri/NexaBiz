import '../../modules/accounting/domain/entities/account.dart';
import '../../modules/accounting/domain/entities/journal_entry.dart';
import '../../modules/accounting/domain/models/journal_exception.dart';
import '../../modules/accounting/domain/repositories/account_repository.dart';
import '../../modules/accounting/domain/services/account_labels.dart';
import '../../modules/accounting/domain/services/journal_money.dart';
import '../../modules/accounting/domain/services/journal_posting_service.dart';
import '../../modules/sales/domain/entities/sale.dart';
import '../../modules/sales/domain/entities/sale_settlement_type.dart';
import '../../modules/sales/domain/entities/sale_status.dart';
import '../../modules/sales/domain/services/sale_ledger_posting_port.dart';

/// App adapter: sale save/post → local journal.
///
/// - Credit: Dr customer AR / Cr 4100
/// - Cash: Dr cash/treasury / Cr 4100
/// - Discount (item + sale): Dr 5170 / extra Cr 4100 so revenue is gross
class AccountingSaleLedgerAdapter implements SaleLedgerPostingPort {
  AccountingSaleLedgerAdapter({
    required JournalPostingService posting,
    required AccountRepository accounts,
  }) : _posting = posting,
       _accounts = accounts;

  final JournalPostingService _posting;
  final AccountRepository _accounts;

  static const sourceType = 'sale';
  static const salesRevenueCode = '4100';
  static const salesRevenueSystemKey = 'sales_revenue';
  static const salesDiscountsCode = '5170';
  static const salesDiscountsSystemKey = 'sales_discounts';
  static const voucherTypeCreditSale = 'بيع آجل';
  static const voucherTypeCashSale = 'بيع نقدي';

  @override
  Future<void> syncSale(Sale sale) async {
    final netAmount = sale.total;
    final discountAmount = _totalDiscount(sale);
    if (netAmount <= 0 && discountAmount <= 0) {
      return;
    }

    final debitAccountId = switch (sale.settlementType) {
      SaleSettlementType.credit => sale.customerAccountId?.trim(),
      SaleSettlementType.cash => sale.cashAccountId?.trim(),
    };
    if (netAmount > 0 &&
        (debitAccountId == null || debitAccountId.isEmpty)) {
      return;
    }

    await _accounts.ensureDefaultChartSeeded();

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

    final currency = sale.currencyCode.trim().toUpperCase();
    final customerLabel = sale.customerName?.trim() ?? '';
    final isCredit = sale.settlementType == SaleSettlementType.credit;
    final voucherType = isCredit
        ? voucherTypeCreditSale
        : voucherTypeCashSale;
    final description = customerLabel.isEmpty
        ? 'فاتورة $voucherType ${sale.saleNumber}'
        : 'فاتورة $voucherType ${sale.saleNumber} — $customerLabel';
    final revenueCredit = netAmount + discountAmount;

    final lines = <JournalLineDraft>[
      if (netAmount > 0 && debitAccountId != null)
        JournalLineDraft(
          accountUuid: debitAccountId,
          debit: netAmount,
          credit: 0,
          currencyCode: currency,
          lineDescription: description,
          sortOrder: 0,
        ),
      if (discountAmount > 0 && discountAccount != null)
        JournalLineDraft(
          accountUuid: discountAccount.uuid,
          debit: discountAmount,
          credit: 0,
          currencyCode: currency,
          lineDescription: 'خصم $description',
          sortOrder: 1,
        ),
      JournalLineDraft(
        accountUuid: revenue.uuid,
        debit: 0,
        credit: revenueCredit,
        currencyCode: currency,
        lineDescription: description,
        sortOrder: 2,
      ),
    ];

    await _posting.post(
      JournalEntryDraft(
        entryDate: sale.saleDate,
        voucherNumber: sale.saleNumber,
        voucherType: voucherType,
        currencyCode: currency,
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
    await _posting.softDeleteBySource(
      sourceType: sourceType,
      sourceId: sale.uuid,
    );
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
