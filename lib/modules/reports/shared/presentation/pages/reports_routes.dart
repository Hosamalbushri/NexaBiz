import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Routes owned by the Reports module.
class ReportsRoutes {
  const ReportsRoutes._();

  static const String root = '/reports';
  static const String salesPeriod = '/reports/sales-period';
  static const String accountStatement = '/reports/account-statement';
  static const String accountStatementTable =
      '/reports/account-statement/table';
  static const String trialBalance = '/reports/trial-balance';
  static const String journalBook = '/reports/journal-book';
  static const String generalLedger = '/reports/general-ledger';
  static const String incomeStatement = '/reports/income-statement';
  static const String balanceSheet = '/reports/balance-sheet';
  static const String receivables = '/reports/receivables';
  static const String payables = '/reports/payables';
  static const String cashFlow = '/reports/cash-flow';
  static const String rpReceipts = '/reports/rp-receipts';
  static const String rpPayments = '/reports/rp-payments';
  static const String rpCashMovement = '/reports/rp-cash-movement';
  static const String rpBankMovement = '/reports/rp-bank-movement';
  static const String rpCustomerReceipts = '/reports/rp-customer-receipts';
  static const String rpDailySummary = '/reports/rp-daily-summary';
  static const String rpPeriodSummary = '/reports/rp-period-summary';
  static const String productStockMovement = '/reports/product-stock-movement';
  static const String preview = '/reports/preview';

  static void goRoot(BuildContext context) => context.go(root);

  static void pushProductStockMovement(BuildContext context) =>
      context.push(productStockMovement);

  static void pushSalesPeriod(BuildContext context) =>
      context.push(salesPeriod);

  static void pushAccountStatement(BuildContext context) =>
      context.push(accountStatement);

  static void pushTrialBalance(BuildContext context) =>
      context.push(trialBalance);

  static void pushJournalBook(BuildContext context) =>
      context.push(journalBook);

  static void pushGeneralLedger(BuildContext context) =>
      context.push(generalLedger);

  static void pushIncomeStatement(BuildContext context) =>
      context.push(incomeStatement);

  static void pushBalanceSheet(BuildContext context) =>
      context.push(balanceSheet);

  static void pushReceivables(BuildContext context) =>
      context.push(receivables);

  static void pushPayables(BuildContext context) => context.push(payables);

  static void pushCashFlow(BuildContext context) => context.push(cashFlow);

  static void pushPreview(BuildContext context) => context.push(preview);
}
