import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/models/transaction_list_filter.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/repositories/financial_transaction_repository.dart';
import 'package:stock_count/modules/reports/shared/domain/services/rp_report_data_port.dart';

class RpReportDataAdapter implements RpReportDataPort {
  const RpReportDataAdapter(this._repository);

  final FinancialTransactionRepository _repository;

  TransactionListFilter _filter(RpReportQuery query) {
    final base = TransactionListFilter(
      fromDate: query.from,
      toDate: query.to,
    );
    switch (query.kind) {
      case RpReportKind.receipts:
        return base.copyWith(transactionType: TransactionType.receipt);
      case RpReportKind.payments:
        return base.copyWith(transactionType: TransactionType.payment);
      case RpReportKind.cashMovement:
        return base.copyWith(cashAccountCodePrefix: '1211');
      case RpReportKind.bankMovement:
        return base.copyWith(cashAccountCodePrefix: '1212');
      case RpReportKind.customerReceipts:
        return base.copyWith(
          transactionType: TransactionType.receipt,
          customerId: query.customerId,
        );
      case RpReportKind.dailySummary:
      case RpReportKind.periodSummary:
        return base;
    }
  }

  @override
  Future<RpReportData> load(RpReportQuery query) async {
    final filter = _filter(query);
    final aggregates = await _repository.aggregateTotals(filter);
    final items = await _repository.listForReport(
      filter: filter,
      limit: query.rowLimit,
    );
    return RpReportData(
      totalAmount: aggregates.total,
      totalCount: aggregates.count,
      rows: [
        for (final item in items)
          RpReportRow(
            transactionNumber: item.transactionNumber,
            transactionDate: item.transactionDate,
            typeLabel: item.transactionType.storageValue,
            partyLabel: item.partyDisplayName?.trim() ?? '',
            amount: item.amount,
            currencyCode: item.currencyCode,
            statusLabel: item.documentStatus.storageValue,
          ),
      ],
    );
  }
}
