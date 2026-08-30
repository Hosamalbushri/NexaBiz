import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/settings/company/app_currency.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_expandable_text.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/document_posting_orchestrator.dart';
import 'package:stock_count/modules/accounting/shared/presentation/providers/document_posting_providers.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/shared/presentation/pages/inventory_routes.dart';
import 'package:stock_count/modules/inventory/shared/presentation/widgets/inventory_status_badge.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/sales/invoices/domain/services/device_sale_number.dart';
import '../providers/stock_movements_providers.dart';

class StockIssueDetailsPage extends ConsumerStatefulWidget {
  const StockIssueDetailsPage({
    super.key,
    required this.issueId,
  });

  final String issueId;

  @override
  ConsumerState<StockIssueDetailsPage> createState() => _StockIssueDetailsPageState();
}

class _StockIssueDetailsPageState extends ConsumerState<StockIssueDetailsPage> {
  bool _isProcessing = false;

  Future<void> _handlePost(StockIssue issue) async {
    if (_isProcessing) return;
    final orchestrator = ref.read(documentPostingOrchestratorProvider);

    setState(() => _isProcessing = true);
    try {
      final result = await orchestrator.postIssue(issue: issue);
      if (!mounted) return;

      if (result is OrchestrationSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(stockIssueByIdProvider(widget.issueId));
        ref.invalidate(stockIssuesStreamProvider);
      } else if (result is OrchestrationFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.reason), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الترحيل: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleUnpost(StockIssue issue) async {
    if (_isProcessing) return;
    final orchestrator = ref.read(documentPostingOrchestratorProvider);

    setState(() => _isProcessing = true);
    try {
      final result = await orchestrator.unpostIssue(issue: issue);
      if (!mounted) return;

      if (result is OrchestrationSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.orange,
          ),
        );
        ref.invalidate(stockIssueByIdProvider(widget.issueId));
        ref.invalidate(stockIssuesStreamProvider);
      } else if (result is OrchestrationFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.reason), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء إلغاء الترحيل: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleEdit(StockIssue issue) {
    if (issue.isPosted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.lock_rounded, size: 48, color: Colors.orange),
          title: const Text('المستند مرحّل'),
          content: const Text(
            'لا يمكن تعديل أمر الصرف وهو في حالة (مرحّل).\n\nيرجى إلغاء الترحيل أولاً لتتمكن من التعديل.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _handleUnpost(issue);
              },
              icon: const Icon(Icons.undo),
              label: const Text('إلغاء الترحيل الآن'),
            ),
          ],
        ),
      );
      return;
    }

    InventoryRoutes.pushStockIssuesEdit(context, issue.id);
  }

  Future<void> _handleDelete(StockIssue issue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت تأكد من حذف أمر الصرف ${issue.issueNumber}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final useCases = ref.read(stockMovementUseCasesProvider);
      await useCases.deleteIssue(issue.id);
      if (mounted) {
        ref.invalidate(stockIssuesStreamProvider);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final issueAsync = ref.watch(stockIssueByIdProvider(widget.issueId));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return issueAsync.when(
      loading: () => Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: CustomAppBar(
          title: 'تفاصيل أمر صرف مخزني',
          showBackButton: true,
        ),
        body: const AppLoading(),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: CustomAppBar(
          title: 'تفاصيل أمر صرف مخزني',
          showBackButton: true,
        ),
        body: Center(child: Text('خطأ: $err')),
      ),
      data: (issue) {
        if (issue == null) {
          return Scaffold(
            backgroundColor: scheme.surfaceContainerLowest,
            appBar: CustomAppBar(
              title: 'تفاصيل أمر صرف مخزني',
              showBackButton: true,
            ),
            body: const Center(child: Text('لم يتم العثور على أمر الصرف')),
          );
        }

        final dateStr = '${issue.issueDate.year}-${issue.issueDate.month.toString().padLeft(2, '0')}-${issue.issueDate.day.toString().padLeft(2, '0')}';
        final totalCostSum = issue.lines.fold(0.0, (sum, line) => sum + line.totalCost);
        final destinationName = (issue.destination != null && issue.destination!.trim().isNotEmpty)
            ? issue.destination!.trim()
            : 'غير محدد';
        final warehouseName = (issue.warehouse != null && issue.warehouse!.trim().isNotEmpty)
            ? issue.warehouse!.trim()
            : 'المستودع الرئيسي';

        return Scaffold(
          backgroundColor: scheme.surfaceContainerLowest,
          appBar: CustomAppBar(
            title: formatSaleNumberPrimary(issue.issueNumber),
            showBackButton: true,
            actions: [
              CustomAppBarAction(
                icon: issue.isPosted ? Icons.lock_outlined : Icons.edit_outlined,
                tooltip: issue.isPosted ? 'تعديل (مرحّل)' : 'تعديل',
                onPressed: _isProcessing ? null : () => _handleEdit(issue),
              ),
              PopupMenuButton<String>(
                tooltip: 'خيارات أخرى',
                position: PopupMenuPosition.under,
                offset: const Offset(0, 8),
                onSelected: (value) {
                  switch (value) {
                    case 'post':
                      _handlePost(issue);
                      break;
                    case 'unpost':
                      _handleUnpost(issue);
                      break;
                    case 'delete':
                      _handleDelete(issue);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (issue.isDraft)
                    const PopupMenuItem(
                      value: 'post',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('ترحيل المستند'),
                        ],
                      ),
                    ),
                  if (issue.isPosted)
                    const PopupMenuItem(
                      value: 'unpost',
                      child: Row(
                        children: [
                          Icon(Icons.undo, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('إلغاء الترحيل'),
                        ],
                      ),
                    ),
                  if (issue.isDraft)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('حذف المستند'),
                        ],
                      ),
                    ),
                ],
                child: Material(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 22,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Material(
            color: scheme.surface,
            elevation: 8,
            shadowColor: scheme.shadow.withValues(alpha: 0.12),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: issue.isDraft
                    ? FilledButton.icon(
                        onPressed: _isProcessing ? null : () => _handlePost(issue),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('ترحيل أمر الصرف'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: _isProcessing ? null : () => _handleUnpost(issue),
                        icon: const Icon(Icons.undo),
                        label: const Text('إلغاء ترحيل أمر الصرف'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: Colors.orange.shade800,
                          side: BorderSide(color: Colors.orange.shade400),
                        ),
                      ),
              ),
            ),
          ),
          body: Stack(
            children: [
              ListView(
                padding: AppConstants.pageInsets(context),
                children: [
                  // Hero Header Card
                  _DocumentHero(
                    documentNumber: issue.issueNumber,
                    currencyCode: issue.currencyCode,
                    exchangeRate: issue.exchangeRate,
                    totalCost: totalCostSum,
                    status: issue.status,
                    documentTypeName: 'أمر صرف مخزني',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Posted Lock Warning Banner
                  if (issue.isPosted) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_rounded, color: Colors.amber.shade900),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'هذا المستند مرحّل. للتعديل أو الحذف يجب إلغاء ترحيله أولاً.',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Document Meta Info Tiles
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _MetaTile(
                            icon: Icons.calendar_month_rounded,
                            label: 'تاريخ المستند',
                            value: dateStr,
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _MetaTile(
                            icon: Icons.warehouse_rounded,
                            label: 'المستودع',
                            value: warehouseName,
                            emphasized: true,
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Destination / Account Card
                  _SurfaceCard(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                scheme.secondary.withValues(alpha: 0.18),
                                scheme.secondary.withValues(alpha: 0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            Icons.outbox_rounded,
                            color: scheme.secondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الجهة / المستفيد',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                destinationName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                              if (issue.accountName != null && issue.accountName!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'الحساب: ${issue.accountName}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Products Readonly Table
                  _ProductsReadonlyCard(
                    lines: issue.lines,
                    currencyCode: issue.currencyCode,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Summary Card
                  _SummaryCard(
                    totalLines: issue.lines.length,
                    totalCost: totalCostSum,
                    currencyCode: issue.currencyCode,
                  ),

                  // Notes Card
                  if (issue.notes != null && issue.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الملاحظات',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppExpandableText(
                            text: issue.notes!,
                            maxCollapsedLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
              if (_isProcessing)
                Container(
                  color: Colors.black26,
                  child: const Center(child: AppLoading()),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DocumentHero extends StatelessWidget {
  const _DocumentHero({
    required this.documentNumber,
    required this.currencyCode,
    required this.exchangeRate,
    required this.totalCost,
    required this.status,
    required this.documentTypeName,
  });

  final String documentNumber;
  final String currencyCode;
  final double exchangeRate;
  final double totalCost;
  final InventoryDocumentStatus status;
  final String documentTypeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appCurrency = AppCurrencies.byCode(currencyCode);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        documentNumber,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      InventoryStatusBadge(status: status),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${appCurrency.code} (${appCurrency.nameAr})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'إجمالي تكلفة المستند',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${totalCost.toStringAsFixed(2)} ${appCurrency.symbol}',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.primary,
                letterSpacing: -1.2,
                height: 1.05,
              ),
            ),
            if (exchangeRate != 1.0) ...[
              const SizedBox(height: 4),
              Text(
                'سعر الصرف: ${exchangeRate.toStringAsFixed(4)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasized = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasized;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconBox = compact ? 32.0 : 40.0;
    final iconSize = compact ? 16.0 : 20.0;
    final gap = compact ? AppSpacing.sm : AppSpacing.sm + 2;

    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: emphasized
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surface,
        borderRadius: BorderRadius.circular(
          compact ? AppRadius.sm : AppRadius.md,
        ),
        border: Border.all(
          color: emphasized
              ? scheme.primary.withValues(alpha: 0.16)
              : scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: iconBox,
            height: iconBox,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: emphasized
                    ? scheme.primary.withValues(alpha: 0.14)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(compact ? 8 : 12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: iconSize,
                  color: emphasized ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 10 : null,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: compact ? 2 : 3),
                Text(
                  value,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: (compact
                          ? theme.textTheme.labelLarge
                          : theme.textTheme.titleSmall)
                      ?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: emphasized ? scheme.primary : scheme.onSurface,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsReadonlyCard extends StatelessWidget {
  const _ProductsReadonlyCard({
    required this.lines,
    required this.currencyCode,
  });

  final List<dynamic> lines;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'الأصناف (${lines.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              headingRowColor: WidgetStatePropertyAll(
                scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              ),
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('كود الصنف')),
                DataColumn(label: Text('اسم الصنف')),
                DataColumn(label: Text('العبوة (كرتون)')),
                DataColumn(label: Text('العبوة (حبة)')),
                DataColumn(label: Text('إجمالي الكمية')),
                DataColumn(label: Text('التكلفة')),
                DataColumn(label: Text('الإجمالي')),
              ],
              rows: [
                for (int i = 0; i < lines.length; i++)
                  DataRow(
                    cells: [
                      DataCell(Text('${i + 1}')),
                      DataCell(Text(lines[i].itemCode)),
                      DataCell(Text(lines[i].itemName)),
                      DataCell(Text(lines[i].mainQuantity.toStringAsFixed(0))),
                      DataCell(Text(lines[i].subQuantity.toStringAsFixed(0))),
                      DataCell(Text(lines[i].quantity.toStringAsFixed(2))),
                      DataCell(Text(lines[i].unitCost.toStringAsFixed(2))),
                      DataCell(
                        Text(
                          lines[i].totalCost.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalLines,
    required this.totalCost,
    required this.currencyCode,
  });

  final int totalLines;
  final double totalCost;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appCurrency = AppCurrencies.byCode(currencyCode);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عدد البنود:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$totalLines أصناف',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي الكلي:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${totalCost.toStringAsFixed(2)} ${appCurrency.symbol} (${appCurrency.code})',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
