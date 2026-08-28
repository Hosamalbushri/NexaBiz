import 'package:flutter/material.dart';
import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/core/widgets/app_dynamic_report_table.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/accounting/journals/presentation/pages/journal_entry_details_page.dart';
import 'package:stock_count/modules/accounting/journals/presentation/pages/journal_entry_form_page.dart';
import 'package:stock_count/modules/inventory/stock_movements/presentation/pages/stock_issue_form_page.dart';
import 'package:stock_count/modules/inventory/stock_movements/presentation/pages/stock_receipt_form_page.dart';
import 'package:stock_count/modules/receipts_payments/exchanges/presentation/pages/currency_exchange_form_page.dart';
import 'package:stock_count/modules/receipts_payments/transfers/presentation/pages/cash_box_transfer_form_page.dart';
import 'package:stock_count/modules/reports/shared/domain/services/account_statement_report_data_port.dart';
import 'package:stock_count/modules/sales/invoices/presentation/pages/sale_form_page.dart';

/// Standalone Dynamic Report Table Page for Account Statement.
class AccountStatementReportTablePage extends StatelessWidget {
  const AccountStatementReportTablePage({
    super.key,
    required this.payload,
    this.onExportPdf,
    this.onPrint,
  });

  final AccountStatementReportPayload payload;
  final VoidCallback? onExportPdf;
  final VoidCallback? onPrint;

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '0.00';
    return amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Map<String, List<AccountStatementLine>> _groupLinesByCurrency() {
    final Map<String, List<AccountStatementLine>> groups = {};
    for (final line in payload.lines) {
      final key = line.displayCurrencyCode ?? line.currencyCode ?? payload.currencyLabel;
      groups.putIfAbsent(key, () => []).add(line);
    }
    return groups;
  }

  double _getCurrencyTotalDebit(String currencyKey, List<AccountStatementLine> lines) {
    for (final b in payload.balancesByCurrency) {
      if (b.currencyCode == currencyKey || b.displayCurrencyCode == currencyKey) {
        return b.totalDebit;
      }
    }
    return lines.fold<double>(0, (sum, l) => sum + l.debit);
  }

  double _getCurrencyTotalCredit(String currencyKey, List<AccountStatementLine> lines) {
    for (final b in payload.balancesByCurrency) {
      if (b.currencyCode == currencyKey || b.displayCurrencyCode == currencyKey) {
        return b.totalCredit;
      }
    }
    return lines.fold<double>(0, (sum, l) => sum + l.credit);
  }

  double _getCurrencyClosingBalance(String currencyKey, List<AccountStatementLine> lines) {
    for (final b in payload.balancesByCurrency) {
      if (b.currencyCode == currencyKey || b.displayCurrencyCode == currencyKey) {
        return b.closingBalance;
      }
    }
    return lines.isNotEmpty ? lines.last.balance : 0;
  }

  String _resolveActualCurrencySymbol(String currencyKey, List<AccountStatementLine> linesList) {
    if (currencyKey.isNotEmpty &&
        currencyKey != payload.currencyLabel &&
        !currencyKey.contains('كل') &&
        !currencyKey.toLowerCase().contains('all')) {
      return currencyKey;
    }
    for (final line in linesList) {
      if (line.displayCurrencyCode != null && line.displayCurrencyCode!.trim().isNotEmpty) {
        return line.displayCurrencyCode!;
      }
      if (line.currencyCode != null && line.currencyCode!.trim().isNotEmpty) {
        return line.currencyCode!;
      }
    }
    if (payload.balancesByCurrency.isNotEmpty) {
      final b = payload.balancesByCurrency.first;
      return b.displayCurrencyCode ?? b.currencyCode;
    }
    return payload.baseCurrencyCode ?? payload.currencyCode ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final fromStr = payload.fromDate != null ? _formatDate(payload.fromDate!) : 'البداية';
    final toStr = payload.toDate != null ? _formatDate(payload.toDate!) : 'الآن';

    final currencyGroups = _groupLinesByCurrency();
    final isMultiCurrency = currencyGroups.keys.length > 1;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: 'كشف حساب',
        showBackButton: true,
        actions: [
          if (onExportPdf != null || onPrint != null)
            IconButton(
              icon: const Icon(Icons.print_rounded),
              tooltip: 'طباعة التقرير',
              onPressed: onExportPdf ?? onPrint,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppConstants.pageInsets(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isMultiCurrency)
              _buildTableForCurrencyGroup(
                context: context,
                theme: theme,
                scheme: scheme,
                currencyKey: payload.currencyLabel,
                linesList: payload.lines,
                totalDebit: payload.totalDebit,
                totalCredit: payload.totalCredit,
                closingBalance: payload.closingBalance,
                fromStr: fromStr,
                toStr: toStr,
                showSectionHeader: false,
              )
            else ...[
              for (var i = 0; i < currencyGroups.entries.length; i++) ...[
                if (i > 0) _buildCurrencyTableSeparator(theme, scheme),
                _buildTableForCurrencyGroup(
                  context: context,
                  theme: theme,
                  scheme: scheme,
                  currencyKey: currencyGroups.entries.elementAt(i).key,
                  linesList: currencyGroups.entries.elementAt(i).value,
                  totalDebit: _getCurrencyTotalDebit(
                    currencyGroups.entries.elementAt(i).key,
                    currencyGroups.entries.elementAt(i).value,
                  ),
                  totalCredit: _getCurrencyTotalCredit(
                    currencyGroups.entries.elementAt(i).key,
                    currencyGroups.entries.elementAt(i).value,
                  ),
                  closingBalance: _getCurrencyClosingBalance(
                    currencyGroups.entries.elementAt(i).key,
                    currencyGroups.entries.elementAt(i).value,
                  ),
                  fromStr: fromStr,
                  toStr: toStr,
                  showSectionHeader: true,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyHeaderBanner({
    required ThemeData theme,
    required ColorScheme scheme,
    required String currencyKey,
    required int itemCount,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHigh
            : scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'حركات العملة: $currencyKey',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'كشف الحركات والجدول الحصري لهذه العملة',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 14,
                  color: scheme.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  '$itemCount حركة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyTableSeparator(ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              thickness: 1.2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: scheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_vert_rounded,
                  size: 16,
                  color: scheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'جدول العملة التالية',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Divider(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              thickness: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableForCurrencyGroup({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme scheme,
    required String currencyKey,
    required List<AccountStatementLine> linesList,
    required double totalDebit,
    required double totalCredit,
    required double closingBalance,
    required String fromStr,
    required String toStr,
    required bool showSectionHeader,
  }) {
    final actualCurrency = _resolveActualCurrencySymbol(currencyKey, linesList);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSectionHeader)
          _buildCurrencyHeaderBanner(
            theme: theme,
            scheme: scheme,
            currencyKey: actualCurrency.isNotEmpty ? actualCurrency : currencyKey,
            itemCount: linesList.length,
          ),
        AppDynamicReportTable<AccountStatementLine>(
          title: payload.accountName.isNotEmpty
              ? '${payload.accountCode} — ${payload.accountName}'
              : payload.reportTitle,
          subtitle: showSectionHeader
              ? 'الفترة من $fromStr إلى $toStr | عملة التقرير: ${actualCurrency.isNotEmpty ? actualCurrency : currencyKey}'
              : (actualCurrency.isNotEmpty
                  ? 'الفترة من $fromStr إلى $toStr | العملة: $actualCurrency'
                  : 'الفترة من $fromStr إلى $toStr'),
          centerTitle: true,
          minTableWidth: 1100,
          columns: [
            ReportColumnSpec<AccountStatementLine>(
              id: 'actions',
              label: 'الإجراء',
              flex: 22,
              alignment: Alignment.center,
              cellBuilder: (context, line) {
                final isDark = theme.brightness == Brightness.dark;
                final actionColor = isDark ? Colors.white : scheme.primary;
                final containerBg = isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : scheme.primaryContainer.withValues(alpha: 0.4);
                final borderColor = isDark
                    ? Colors.white.withValues(alpha: 0.25)
                    : scheme.primary.withValues(alpha: 0.3);

                return InkWell(
                  onTap: () => _navigateToOriginalVoucher(context, line),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: containerBg,
                      borderRadius: BorderRadius.circular(AppRadius.xs + 2),
                      border: Border.all(
                        color: borderColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 13,
                          color: actionColor,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'فتح',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: actionColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ReportColumnSpec<AccountStatementLine>(
              id: 'date',
              label: 'التاريخ',
              flex: 25,
              alignment: Alignment.center,
              cellBuilder: (context, line) {
                return Text(
                  _formatDate(line.entryDate),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: !line.isPosted ? FontWeight.bold : FontWeight.w500,
                    color: !line.isPosted ? scheme.error : scheme.onSurface,
                  ),
                );
              },
            ),
            ReportColumnSpec<AccountStatementLine>(
              id: 'voucher_no',
              label: 'رقم السند',
              flex: 20,
              alignment: Alignment.center,
              getValue: (line) => line.voucherNumber.isEmpty ? '—' : line.voucherNumber,
            ),
            ReportColumnSpec<AccountStatementLine>(
              id: 'voucher_type',
              label: 'نوع الحركة',
              flex: 25,
              alignment: Alignment.center,
              getValue: (line) => line.voucherType,
            ),
            ReportColumnSpec<AccountStatementLine>(
              id: 'description',
              label: 'البيان (الوصف)',
              flex: 50,
              alignment: Alignment.center,
              getValue: (line) => line.description,
            ),
            ReportColumnSpec<AccountStatementLine>(
              id: 'debit',
              label: 'مدين',
              flex: 30,
              isNumeric: true,
              alignment: Alignment.center,
              cellBuilder: (context, line) {
                if (line.debit == 0) {
                  return Text(
                    '—',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  );
                }
                return Text(
                  _formatAmount(line.debit),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                );
              },
            ),
            ReportColumnSpec<AccountStatementLine>(
              id: 'credit',
              label: 'دائن',
              flex: 30,
              isNumeric: true,
              alignment: Alignment.center,
              cellBuilder: (context, line) {
                if (line.credit == 0) {
                  return Text(
                    '—',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  );
                }
                return Text(
                  _formatAmount(line.credit),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.error,
                  ),
                );
              },
            ),
                ReportColumnSpec<AccountStatementLine>(
                  id: 'balance',
                  label: 'الرصيد',
                  flex: 30,
                  isNumeric: true,
                  alignment: Alignment.center,
                  cellBuilder: (context, line) {
                    return Text(
                      _formatAmount(line.balance.abs()),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  },
                ),
                ReportColumnSpec<AccountStatementLine>(
                  id: 'side',
                  label: 'الجهة',
                  flex: 15,
                  alignment: Alignment.center,
                  cellBuilder: (context, line) {
                    final isDebit = line.sideLabel == 'م' || line.balance >= 0;
                    final sideColor = isDebit ? scheme.primary : const Color(0xFF2E7D32);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: sideColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        line.sideLabel.isNotEmpty ? line.sideLabel : (isDebit ? 'م' : 'د'),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: sideColor,
                        ),
                      ),
                    );
                  },
                  footerCellBuilder: (context) {
                    final isDebit = closingBalance >= 0;
                    final sideColor = isDebit ? scheme.primary : const Color(0xFF2E7D32);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: sideColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        isDebit ? 'م' : 'د',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: sideColor,
                        ),
                      ),
                    );
                  },
                ),
              ],
              onRowTap: (line) => _showVoucherDetailsBottomSheet(context, line),
              items: linesList,
              footerSummaries: [
                ReportFooterSummarySpec(
                  columnId: 'debit',
                  label: 'إجمالي المدين',
                  value: '${_formatAmount(totalDebit)}${actualCurrency.isNotEmpty ? ' $actualCurrency' : ''}',
                  color: scheme.primary,
                  icon: Icons.arrow_downward_rounded,
                ),
                ReportFooterSummarySpec(
                  columnId: 'credit',
                  label: 'إجمالي الدائن',
                  value: '${_formatAmount(totalCredit)}${actualCurrency.isNotEmpty ? ' $actualCurrency' : ''}',
                  color: scheme.error,
                  icon: Icons.arrow_upward_rounded,
                ),
                ReportFooterSummarySpec(
                  columnId: 'balance',
                  label: 'الرصيد النهائي',
                  value: '${_formatAmount(closingBalance.abs())}${actualCurrency.isNotEmpty ? ' $actualCurrency' : ''}',
                  color: closingBalance >= 0 ? scheme.primary : scheme.error,
                  icon: Icons.account_balance_rounded,
                ),
                ReportFooterSummarySpec(
                  columnId: 'side',
                  label: 'الجهة',
                  value: closingBalance >= 0 ? 'م' : 'د',
                  color: closingBalance >= 0 ? scheme.primary : const Color(0xFF2E7D32),
                ),
              ],
            ),
          ],
        );
      }

  void _navigateToOriginalVoucher(BuildContext context, AccountStatementLine line) {
    if (line.entryUuid != null && line.entryUuid!.trim().isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JournalEntryDetailsPage(entryUuid: line.entryUuid!),
        ),
      );
      return;
    }

    final type = line.voucherType.toLowerCase();

    Widget targetPage;

    if (type.contains('مبيعات') || type.contains('فاتورة') || type.contains('sale')) {
      targetPage = const SaleFormPage();
    } else if (type.contains('صرف') || type.contains('اخراج') || type.contains('issue')) {
      targetPage = const StockIssueFormPage();
    } else if (type.contains('استلام') || type.contains('توريد') || type.contains('receipt')) {
      targetPage = const StockReceiptFormPage();
    } else if (type.contains('تحويل') || type.contains('transfer')) {
      targetPage = const CashBoxTransferFormPage();
    } else if (type.contains('مصاريف') || type.contains('مصروف') || type.contains('صرفية')) {
      targetPage = const CurrencyExchangeFormPage();
    } else {
      targetPage = const JournalEntryFormPage();
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => targetPage),
    );
  }

  void _showVoucherDetailsBottomSheet(
    BuildContext context,
    AccountStatementLine line,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDebit = line.sideLabel == 'م' || line.balance >= 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: scheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.voucherNumber.isNotEmpty
                              ? 'سند رقم: ${line.voucherNumber}'
                              : line.voucherType,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(line.entryDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: line.isPosted
                          ? scheme.primaryContainer.withValues(alpha: 0.5)
                          : scheme.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Text(
                      line.isPosted ? 'مرحل' : 'غير مرحل',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: line.isPosted ? scheme.primary : scheme.error,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Details Grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailTile(
                      theme,
                      scheme,
                      'نوع الحركة',
                      line.voucherType,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDetailTile(
                      theme,
                      scheme,
                      'رقم الحركة',
                      line.voucherNumber.isNotEmpty ? line.voucherNumber : '—',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildDetailTile(
                theme,
                scheme,
                'البيان / الوصف',
                line.description.isNotEmpty ? line.description : 'بدون وصف',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailTile(
                      theme,
                      scheme,
                      'مدين',
                      line.debit > 0 ? _formatAmount(line.debit) : '—',
                      valueColor: line.debit > 0 ? scheme.primary : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDetailTile(
                      theme,
                      scheme,
                      'دائن',
                      line.credit > 0 ? _formatAmount(line.credit) : '—',
                      valueColor: line.credit > 0 ? scheme.error : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailTile(
                      theme,
                      scheme,
                      'الرصيد التراكمي',
                      _formatAmount(line.balance.abs()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDetailTile(
                      theme,
                      scheme,
                      'الجهة',
                      line.sideLabel.isNotEmpty ? line.sideLabel : (isDebit ? 'م (مدين)' : 'د (دائن)'),
                      valueColor: isDebit ? scheme.primary : const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action Buttons Layout
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _navigateToOriginalVoucher(context, line);
                      },
                      icon: const Icon(Icons.launch_rounded, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'فتح الحركة الأصل',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('طباعة السند: ${line.voucherNumber.isNotEmpty ? line.voucherNumber : line.voucherType}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('طباعة السند'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('إغلاق'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailTile(
    ThemeData theme,
    ColorScheme scheme,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
