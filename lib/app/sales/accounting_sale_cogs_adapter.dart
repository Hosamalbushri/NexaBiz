import '../../modules/accounting/domain/entities/account.dart';
import '../../modules/accounting/domain/entities/journal_entry.dart';
import '../../modules/accounting/domain/models/journal_exception.dart';
import '../../modules/accounting/domain/repositories/account_repository.dart';
import '../../modules/accounting/domain/services/account_labels.dart';
import '../../modules/accounting/domain/services/journal_money.dart';
import '../../modules/accounting/domain/services/journal_posting_service.dart';
import '../../modules/inventory/domain/models/stock_quantity_line.dart';
import '../../modules/inventory/domain/services/product_stock_service.dart';
import '../../modules/sales/domain/entities/sale.dart';
import '../../modules/sales/domain/entities/sale_status.dart';
import 'perpetual_sale_inventory_effect_adapter.dart';

/// App adapter: sale post → COGS journal (Dr 5100 / Cr inventory asset).
class AccountingSaleCogsAdapter implements SaleCogsEffectPort {
  AccountingSaleCogsAdapter({
    required JournalPostingService posting,
    required AccountRepository accounts,
    required ProductStockService stock,
  }) : _posting = posting,
       _accounts = accounts,
       _stock = stock;

  final JournalPostingService _posting;
  final AccountRepository _accounts;
  final ProductStockService _stock;

  static const sourceType = 'sale_cogs';
  static const inventoryCode = '1230';
  static const inventorySystemKey = 'inventory';
  static const cogsCode = '5100';
  static const cogsSystemKey = 'cost_of_goods_sold';

  @override
  Future<void> syncSale(Sale sale) async {
    final lines = _stockLines(sale);
    if (lines.isEmpty) {
      return;
    }

    final amount = JournalMoney.round(await _stock.costForLines(lines));
    if (amount <= 0) {
      return;
    }

    await _accounts.ensureDefaultChartSeeded();

    final inventory = await _resolveSystemAccount(
      code: inventoryCode,
      systemKey: inventorySystemKey,
    );
    final cogs = await _resolveSystemAccount(
      code: cogsCode,
      systemKey: cogsSystemKey,
    );
    if (inventory == null || cogs == null) {
      throw const JournalException(JournalException.accountNotFound);
    }

    final currency = sale.currencyCode.trim().toUpperCase();
    final baseCurrency = sale.baseCurrencyCode.trim().toUpperCase().isEmpty
        ? currency
        : sale.baseCurrencyCode.trim().toUpperCase();
    final rate = sale.exchangeRate <= 0 ? 1.0 : sale.exchangeRate;
    final description = 'تكلفة مبيعات ${sale.saleNumber}';

    await _posting.post(
      JournalEntryDraft(
        entryDate: sale.saleDate,
        voucherNumber: sale.saleNumber,
        voucherType: 'تكلفة مبيعات',
        currencyCode: currency,
        baseCurrencyCode: baseCurrency,
        description: description,
        isPosted: sale.saleStatus.isPosted,
        sourceType: sourceType,
        sourceId: sale.uuid,
        lines: [
          JournalLineDraft(
            accountUuid: cogs.uuid,
            debit: amount,
            credit: 0,
            currencyCode: currency,
            exchangeRateToBase: rate,
            lineDescription: description,
            sortOrder: 0,
          ),
          JournalLineDraft(
            accountUuid: inventory.uuid,
            debit: 0,
            credit: amount,
            currencyCode: currency,
            exchangeRateToBase: rate,
            lineDescription: description,
            sortOrder: 1,
          ),
        ],
      ),
    );
  }

  @override
  Future<void> voidSale(Sale sale) async {
    await _posting.voidBySource(
      sourceType: sourceType,
      sourceId: sale.uuid,
    );
  }

  List<StockQuantityLine> _stockLines(Sale sale) {
    return [
      for (final item in sale.items)
        if (item.quantity > 0 && item.productId.trim().isNotEmpty)
          StockQuantityLine(
            productUuid: item.productId,
            quantity: item.quantity,
          ),
    ];
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
