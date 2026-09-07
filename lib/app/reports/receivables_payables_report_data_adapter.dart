import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/reports/shared/domain/services/receivables_payables_report_data_port.dart';

/// Concrete adapter for [ReceivablesPayablesReportDataPort].
class ReceivablesPayablesReportDataAdapter
    implements ReceivablesPayablesReportDataPort {
  ReceivablesPayablesReportDataAdapter({
    required this.journals,
    required this.accounts,
    required this.loadCompanyProfile,
  });

  final JournalRepository journals;
  final AccountRepository accounts;
  final Future<CompanyProfile> Function() loadCompanyProfile;

  @override
  Future<ReceivablesPayablesReportPayload> loadFromFilter({
    required ReportQueryFilter filter,
    required ReceivablesPayablesType type,
    required ReceivablesPayablesReportLabels labels,
  }) async {
    final profile = await loadCompanyProfile();
    final baseCurrency = filter.currencyCode == 'ALL'
        ? profile.defaultCurrencyCode
        : filter.currencyCode;

    final isPostedFilter = filter.postingScope == PostingScope.postedOnly
        ? true
        : (filter.postingScope == PostingScope.unpostedOnly ? false : null);

    final allAccounts = await accounts.getAll();

    // Accounts filtering:
    // Receivables: Accounts with code starting 12 (Accounts Receivable / العملاء / Madinun)
    // Payables: Accounts with code starting 21 (Accounts Payable / الموردين / Da'inun)
    final targetPrefix = type == ReceivablesPayablesType.receivables
        ? '12'
        : '21';
    final targetAccounts = allAccounts
        .where((a) => a.accountCode.startsWith(targetPrefix))
        .toList();

    final rows = <ReceivablesPayablesSummaryRow>[];

    double totalOpening = 0.0;
    double totalInvoices = 0.0;
    double totalPayments = 0.0;
    double totalAdjustments = 0.0;
    double totalEnding = 0.0;

    for (final acc in targetAccounts) {
      final opening = filter.fromDate != null
          ? await journals.sumNetBefore(
              accountUuid: acc.uuid,
              beforeDate: filter.fromDate!,
              isPosted: isPostedFilter,
            )
          : 0.0;

      final movements = await journals.listMovementsForAccount(
        accountUuid: acc.uuid,
        fromDate: filter.fromDate,
        toDate: filter.toDate,
        isPosted: isPostedFilter,
      );

      double invoices = 0.0;
      double payments = 0.0;
      double adjustments = 0.0;

      for (final m in movements) {
        if (type == ReceivablesPayablesType.receivables) {
          // Debit increases receivable (Invoices), Credit reduces receivable (Payments)
          if (m.debit > 0) invoices += m.debit;
          if (m.credit > 0) payments += m.credit;
        } else {
          // Credit increases payable (Invoices/Bills), Debit reduces payable (Payments)
          if (m.credit > 0) invoices += m.credit;
          if (m.debit > 0) payments += m.debit;
        }
      }

      final ending = type == ReceivablesPayablesType.receivables
          ? opening + invoices - payments + adjustments
          : opening + invoices - payments + adjustments;

      if (opening != 0 || invoices != 0 || payments != 0 || ending != 0) {
        totalOpening += opening;
        totalInvoices += invoices;
        totalPayments += payments;
        totalAdjustments += adjustments;
        totalEnding += ending;

        rows.add(
          ReceivablesPayablesSummaryRow(
            entityCode: acc.accountCode,
            entityName: acc.name,
            openingBalance: opening,
            invoicesAmount: invoices,
            paymentsAmount: payments,
            adjustmentsAmount: adjustments,
            endingBalance: ending,
          ),
        );
      }
    }

    return ReceivablesPayablesReportPayload(
      type: type,
      labels: labels,
      baseCurrencyCode: baseCurrency,
      fromDate: filter.fromDate,
      toDate: filter.toDate,
      rows: rows,
      totalOpening: totalOpening,
      totalInvoices: totalInvoices,
      totalPayments: totalPayments,
      totalAdjustments: totalAdjustments,
      totalEnding: totalEnding,
    );
  }
}
