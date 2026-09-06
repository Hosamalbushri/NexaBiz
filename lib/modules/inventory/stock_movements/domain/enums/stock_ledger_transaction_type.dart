enum StockLedgerTransactionType {
  opening('opening'),
  receipt('receipt'),
  issue('issue'),
  sale('sale'),
  purchaseReturn('purchase_return'),
  salesReturn('sales_return'),
  transferOut('transfer_out'),
  transferIn('transfer_in'),
  adjustmentIncrease('adjustment_increase'),
  adjustmentDecrease('adjustment_decrease'),
  stockCountAdjustment('stock_count_adjustment'),
  writeOff('write_off'),
  reversal('reversal');

  const StockLedgerTransactionType(this.storageValue);
  final String storageValue;

  static StockLedgerTransactionType fromStorageValue(String value) {
    switch (value) {
      case 'opening':
        return StockLedgerTransactionType.opening;
      case 'receipt':
      case 'stock_receipt':
        return StockLedgerTransactionType.receipt;
      case 'issue':
      case 'stock_issue':
        return StockLedgerTransactionType.issue;
      case 'sale':
        return StockLedgerTransactionType.sale;
      case 'purchase_return':
        return StockLedgerTransactionType.purchaseReturn;
      case 'sales_return':
        return StockLedgerTransactionType.salesReturn;
      case 'transfer_out':
        return StockLedgerTransactionType.transferOut;
      case 'transfer_in':
        return StockLedgerTransactionType.transferIn;
      case 'stock_transfer':
        return StockLedgerTransactionType.transferOut; // Default direction handled by direction field
      case 'adjustment_increase':
        return StockLedgerTransactionType.adjustmentIncrease;
      case 'adjustment_decrease':
        return StockLedgerTransactionType.adjustmentDecrease;
      case 'stock_count_adjustment':
        return StockLedgerTransactionType.stockCountAdjustment;
      case 'write_off':
        return StockLedgerTransactionType.writeOff;
      case 'reversal':
        return StockLedgerTransactionType.reversal;
      default:
        return StockLedgerTransactionType.values.firstWhere(
          (e) => e.storageValue == value || e.name == value,
          orElse: () => StockLedgerTransactionType.receipt,
        );
    }
  }
}

enum StockLedgerDirection {
  inbound('inbound'),
  outbound('outbound');

  const StockLedgerDirection(this.storageValue);
  final String storageValue;

  static StockLedgerDirection fromStorageValue(String value) {
    return StockLedgerDirection.values.firstWhere(
      (e) => e.storageValue == value || e.name == value,
      orElse: () => StockLedgerDirection.inbound,
    );
  }
}
