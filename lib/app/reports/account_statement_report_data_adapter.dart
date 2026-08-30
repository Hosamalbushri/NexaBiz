import 'package:intl/intl.dart';
import '../../core/reporting/arabic_amount_words.dart';
import '../../core/report_engine/domain/models/report_cursor.dart';
import '../../core/report_engine/domain/models/report_dataset.dart';
import '../../core/report_engine/domain/models/report_execution_context.dart';
import '../../core/report_engine/domain/models/report_page.dart';
import '../../core/report_engine/domain/models/report_summary.dart';
import '../../core/report_engine/domain/services/paged_report_data_provider.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/shared/domain/repositories/currency_rate_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import 'package:stock_count/modules/reports/shared/domain/services/account_statement_report_data_port.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_ledger_posting_port.dart';
import '../settings/company/app_currency.dart';
import '../settings/company/company_profile.dart';

/// App adapter: account statement ← Accounting COA + journal lines.
///
/// Implements both legacy [AccountStatementReportDataPort] and new SQL-native
/// [PagedReportDataProvider] for keyset pagination.
class AccountStatementReportDataAdapter
    implements AccountStatementReportDataPort, PagedReportDataProvider<ReportRowData> {
  const AccountStatementReportDataAdapter({
    required this.accounts,
    required this.currencyRates,
    required this.journals,
    required this.loadCompanyProfile,
    this.loadSalesForAccount,
    this.ledger,
  });

  final AccountRepository accounts;
  final CurrencyRateRepository currencyRates;
  final JournalRepository journals;
  final Future<CompanyProfile> Function() loadCompanyProfile;
  final Future<List<Sale>> Function(String accountUuid)? loadSalesForAccount;
  final SaleLedgerPostingPort? ledger;

  @override
  String get reportId => 'ACCOUNT_STATEMENT';

  @override
  Future<ReportSummary> fetchSummary(ReportExecutionContext context) async {
    final accountUuid = context.filters['accountUuid'] as String? ?? '';
    final fromDate = context.fromDate;
    final toDate = context.toDate;
    final isPosted = context.postingScope == PostingScope.postedOnly
        ? true
        : (context.postingScope == PostingScope.unpostedOnly ? false : null);
    final singleCurrency = context.currencyScope == 'ALL' ? null : context.currencyScope;

    final moves = await journals.listMovementsForAccount(
      accountUuid: accountUuid,
      fromDate: fromDate,
      toDate: toDate,
      currencyCode: singleCurrency,
      isPosted: isPosted,
    );

    var totalDebit = 0.0;
    var totalCredit = 0.0;
    for (final m in moves) {
      totalDebit += m.debit;
      totalCredit += m.credit;
    }

    final opening = fromDate == null
        ? 0.0
        : await journals.sumNetBefore(
            accountUuid: accountUuid,
            beforeDate: fromDate,
            currencyCode: singleCurrency,
            isPosted: isPosted,
          );

    return ReportSummary(
      totalCount: moves.length,
      aggregates: {
        'openingBalance': opening,
        'totalDebit': totalDebit,
        'totalCredit': totalCredit,
        'closingBalance': opening + totalDebit - totalCredit,
      },
    );
  }

  @override
  Future<ReportPage<ReportRowData>> fetchPage(
    ReportExecutionContext context, {
    ReportCursor? cursor,
    int pageSize = 50,
  }) async {
    final accountUuid = context.filters['accountUuid'] as String? ?? '';
    final fromDate = context.fromDate;
    final toDate = context.toDate;
    final isPosted = context.postingScope == PostingScope.postedOnly
        ? true
        : (context.postingScope == PostingScope.unpostedOnly ? false : null);
    final singleCurrency = context.currencyScope == 'ALL' ? null : context.currencyScope;

    AccountLedgerCursor? afterCursor;
    if (cursor != null) {
      final dateMs = cursor.primarySortValue as int;
      final lineId = int.parse(cursor.uniqueId);
      afterCursor = AccountLedgerCursor(
        entryDateMs: dateMs,
        sortOrder: 0,
        lineId: lineId,
      );
    }

    final moves = await journals.listMovementsForAccount(
      accountUuid: accountUuid,
      fromDate: fromDate,
      toDate: toDate,
      currencyCode: singleCurrency,
      isPosted: isPosted,
      limit: pageSize,
      after: afterCursor,
    );

    final dateFormat = DateFormat('yyyy/MM/dd');
    final currencyFormat = NumberFormat('#,##0.00');

    final items = <ReportRowData>[];
    for (final m in moves) {
      items.add(ReportRowData(
        documentType: 'account_statement',
        documentUuid: m.entryUuid,
        values: {
          'entryDate': dateFormat.format(m.entryDate),
          'voucherNumber': m.voucherNumber,
          'voucherType': m.voucherType,
          'description': m.description,
          'debit': currencyFormat.format(m.debit),
          'credit': currencyFormat.format(m.credit),
          'currencyCode': m.currencyCode,
          'isPosted': m.isPosted ? 'مرحل' : 'غير مرحل',
          'entryUuid': m.entryUuid,
          'id': m.lineId.toString(),
          'dateMs': m.entryDate.toUtc().millisecondsSinceEpoch.toString(),
        },
      ));
    }

    ReportCursor? nextCursor;
    if (moves.length == pageSize) {
      final last = moves.last;
      nextCursor = ReportCursor(
        primarySortValue: last.entryDate.toUtc().millisecondsSinceEpoch,
        uniqueId: last.lineId.toString(),
      );
    }

    return ReportPage<ReportRowData>(
      items: items,
      nextCursor: nextCursor,
      hasNextPage: nextCursor != null,
    );
  }

  @override
  Future<List<AccountStatementAccountRef>> searchAccounts(String query) async {
    final list = await accounts.search(query, includeInactive: false);
    return [
      for (final account in list)
        if (account.isPostingAccount && account.isActive && !account.isDeleted)
          _toRef(account),
    ];
  }

  @override
  Future<List<AccountStatementCurrencyRef>> listCurrencies({
    required bool isArabic,
  }) async {
    final profile = await loadCompanyProfile();
    final base = profile.defaultCurrency;
    final rates = await currencyRates.getAll();
    final codes = <String>{base.code, for (final r in rates) r.currencyCode};
    final sorted = codes.toList()..sort();
    return [
      for (final code in sorted)
        AccountStatementCurrencyRef(
          code: code,
          displayName: AppCurrencies.byCode(code).localizedName(isArabic),
        ),
    ];
  }

  @override
  Future<AccountStatementReportPayload> load({
    required String accountUuid,
    String? currencyCode,
    DateTime? fromDate,
    DateTime? toDate,
    required AccountStatementType statementType,
    required AccountStatementPostingFilter postingFilter,
    required AccountStatementReportLabels labels,
  }) async {
    final account = await accounts.getByUuid(accountUuid);
    final typeTitle = labels.statementTypeLabelOf(statementType);

    if (account == null || account.isDeleted) {
      return _emptyPayload(
        labels: labels,
        reportTitle: typeTitle,
        accountCode: '—',
        accountName: '—',
        statementType: statementType,
        postingFilter: postingFilter,
        currencyCode: currencyCode,
        fromDate: fromDate,
        toDate: toDate,
      );
    }

    final ref = _toRef(account);
    final profile = await loadCompanyProfile();
    final baseCurrency = profile.defaultCurrencyCode.trim().toUpperCase();
    final postedFilter = switch (postingFilter) {
      AccountStatementPostingFilter.all => null,
      AccountStatementPostingFilter.posted => true,
      AccountStatementPostingFilter.unposted => false,
    };
    final singleCurrency = currencyCode?.trim().isEmpty == true
        ? null
        : currencyCode?.trim().toUpperCase();

    // Reports are strictly READ-ONLY. No inline syncSale writes occur during report generation.

    final periodMoves = await journals.listMovementsForAccount(
      accountUuid: accountUuid,
      fromDate: fromDate,
      toDate: toDate,
      currencyCode: singleCurrency,
      isPosted: postedFilter,
    );

    final currencyCodes = await _resolveCurrencyCodes(
      accountUuid: accountUuid,
      singleCurrency: singleCurrency,
      toDate: toDate,
      isPosted: postedFilter,
      baseCurrencyCode: baseCurrency,
    );

    final allLines = <AccountStatementLine>[];
    final balances = <AccountStatementCurrencyBalance>[];
    var aggregateDebit = 0.0;
    var aggregateCredit = 0.0;
    var aggregateOpening = 0.0;

    for (final code in currencyCodes) {
      final opening = fromDate == null
          ? 0.0
          : await journals.sumNetBefore(
              accountUuid: accountUuid,
              beforeDate: fromDate,
              currencyCode: code,
              isPosted: postedFilter,
            );

      final moves = singleCurrency != null
          ? periodMoves
          : [
              for (final m in periodMoves)
                if (m.currencyCode.toUpperCase() == code) m,
            ];

      var running = opening;
      var totalDebit = 0.0;
      var totalCredit = 0.0;
      final currencyLines = <AccountStatementLine>[];
      for (final m in moves) {
        totalDebit += m.debit;
        totalCredit += m.credit;
        running += m.debit - m.credit;
        currencyLines.add(
          AccountStatementLine(
            entryDate: m.entryDate,
            voucherNumber: m.voucherNumber,
            voucherType: m.voucherType,
            description: m.description,
            debit: m.debit,
            credit: m.credit,
            balance: running,
            sideLabel: m.debit >= m.credit ? 'م' : 'د',
            currencyCode: m.currencyCode,
            displayCurrencyCode: AppCurrencies.byCode(m.currencyCode).symbol,
            isPosted: m.isPosted,
            entryUuid: m.entryUuid,
          ),
        );
      }

      // Skip currencies with neither opening nor period activity.
      if (currencyLines.isEmpty && opening.abs() < 0.0001) {
        continue;
      }

      allLines.addAll(currencyLines);
      final closing = opening + totalDebit - totalCredit;
      balances.add(
        AccountStatementCurrencyBalance(
          currencyCode: code,
          openingBalance: opening,
          totalDebit: totalDebit,
          totalCredit: totalCredit,
          closingBalance: closing,
          displayCurrencyCode: AppCurrencies.byCode(code).symbol,
          amountInWords: ArabicAmountWords.forAmount(
            closing.abs(),
            AppCurrencies.byCode(code).nameAr,
          ),
        ),
      );
      aggregateDebit += totalDebit;
      aggregateCredit += totalCredit;
      aggregateOpening += opening;
    }

    final firstOpening = balances.isEmpty ? 0.0 : balances.first.openingBalance;
    final firstClosing = balances.isEmpty ? 0.0 : balances.first.closingBalance;

    return AccountStatementReportPayload(
      companyName: labels.companyName,
      reportTitle: typeTitle,
      printedByLabel: labels.printedByLabel,
      fromDateLabel: labels.fromDateLabel,
      toDateLabel: labels.toDateLabel,
      accountNameLabel: labels.accountNameLabel,
      accountNumberLabel: labels.accountNumberLabel,
      accountCode: account.accountCode,
      accountName: labels.accountDisplayNameOf(ref),
      statementTypeLabel: typeTitle,
      postingFilterLabel: labels.postingFilterLabelOf(postingFilter),
      currencyLabel: singleCurrency ?? labels.currencyAll,
      openingBalance: singleCurrency != null ? firstOpening : aggregateOpening,
      totalDebit: aggregateDebit,
      totalCredit: aggregateCredit,
      closingBalance: singleCurrency != null
          ? firstClosing
          : (balances.isEmpty
                ? 0.0
                : balances.fold<double>(0, (s, b) => s + b.closingBalance)),
      lines: statementType == AccountStatementType.summary
          ? const []
          : allLines,
      balancesByCurrency: balances,
      columnSide: labels.columnSide,
      columnDescription: labels.columnDescription,
      columnVoucherType: labels.columnVoucherType,
      columnVoucherNumber: labels.columnVoucherNumber,
      columnDate: labels.columnDate,
      columnDebit: labels.columnDebit,
      columnCredit: labels.columnCredit,
      columnBalance: labels.columnBalance,
      columnCurrency: labels.columnCurrency,
      columnInCurrency: labels.columnInCurrency,
      totalsDebitLabel: labels.totalsDebitLabel,
      totalsCreditLabel: labels.totalsCreditLabel,
      finalBalanceByCurrencyLabel: labels.finalBalanceByCurrencyLabel,
      disclaimer: labels.disclaimer,
      accountantLabel: labels.accountantLabel,
      reviewerLabel: labels.reviewerLabel,
      financeManagerLabel: labels.financeManagerLabel,
      fromDate: fromDate,
      toDate: toDate,
      currencyCode: singleCurrency,
      baseCurrencyCode: baseCurrency,
      emptyMessage: labels.emptyMessage,
    );
  }

  Future<List<String>> _resolveCurrencyCodes({
    required String accountUuid,
    required String? singleCurrency,
    required DateTime? toDate,
    required bool? isPosted,
    required String baseCurrencyCode,
  }) async {
    if (singleCurrency != null) {
      return [singleCurrency];
    }

    final sorted = await journals.listCurrencyCodesForAccount(
      accountUuid: accountUuid,
      toDate: toDate,
      isPosted: isPosted,
    );
    final base = baseCurrencyCode.trim().toUpperCase();
    if (base.isNotEmpty && sorted.remove(base)) {
      return [base, ...sorted];
    }
    return sorted;
  }

  AccountStatementReportPayload _emptyPayload({
    required AccountStatementReportLabels labels,
    required String reportTitle,
    required String accountCode,
    required String accountName,
    required AccountStatementType statementType,
    required AccountStatementPostingFilter postingFilter,
    required String? currencyCode,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) {
    return AccountStatementReportPayload(
      companyName: labels.companyName,
      reportTitle: reportTitle,
      printedByLabel: labels.printedByLabel,
      fromDateLabel: labels.fromDateLabel,
      toDateLabel: labels.toDateLabel,
      accountNameLabel: labels.accountNameLabel,
      accountNumberLabel: labels.accountNumberLabel,
      accountCode: accountCode,
      accountName: accountName,
      statementTypeLabel: labels.statementTypeLabelOf(statementType),
      postingFilterLabel: labels.postingFilterLabelOf(postingFilter),
      currencyLabel: currencyCode ?? labels.currencyAll,
      openingBalance: 0,
      totalDebit: 0,
      totalCredit: 0,
      closingBalance: 0,
      lines: const [],
      balancesByCurrency: const [],
      columnSide: labels.columnSide,
      columnDescription: labels.columnDescription,
      columnVoucherType: labels.columnVoucherType,
      columnVoucherNumber: labels.columnVoucherNumber,
      columnDate: labels.columnDate,
      columnDebit: labels.columnDebit,
      columnCredit: labels.columnCredit,
      columnBalance: labels.columnBalance,
      columnCurrency: labels.columnCurrency,
      columnInCurrency: labels.columnInCurrency,
      totalsDebitLabel: labels.totalsDebitLabel,
      totalsCreditLabel: labels.totalsCreditLabel,
      finalBalanceByCurrencyLabel: labels.finalBalanceByCurrencyLabel,
      disclaimer: labels.disclaimer,
      accountantLabel: labels.accountantLabel,
      reviewerLabel: labels.reviewerLabel,
      financeManagerLabel: labels.financeManagerLabel,
      fromDate: fromDate,
      toDate: toDate,
      currencyCode: currencyCode,
      baseCurrencyCode: null,
      emptyMessage: labels.emptyMessage,
    );
  }

  AccountStatementAccountRef _toRef(Account account) {
    return AccountStatementAccountRef(
      accountUuid: account.uuid,
      accountCode: account.accountCode,
      name: account.name,
      systemKey: AccountLabels.systemKeyOf(account),
    );
  }
}
