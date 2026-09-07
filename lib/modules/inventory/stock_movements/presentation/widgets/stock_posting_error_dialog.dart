import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_count/app/router/app_routes.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';

enum StockPostingErrorCategory {
  configuration,
  zeroCost,
  closedPeriod,
  shortage,
  permission,
  general,
}

class StockPostingErrorDetails {
  final String title;
  final String message;
  final String? subtitle;
  final StockPostingErrorCategory category;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StockPostingErrorDetails({
    required this.title,
    required this.message,
    this.subtitle,
    required this.category,
    this.actionLabel,
    this.onAction,
  });

  factory StockPostingErrorDetails.fromReason({
    required BuildContext context,
    required String reason,
    VoidCallback? onEditRequested,
  }) {
    if (reason.contains('لم يتم إعداد حساب') ||
        reason.contains('خطأ محاسبي') ||
        reason.contains('تهيئة') ||
        reason.contains('ربط الحسابات')) {
      return StockPostingErrorDetails(
        title: 'التهيئة المحاسبية غير مكتملة',
        message: reason,
        subtitle:
            'يلزم استكمال تهيئة الحسابات المحاسبية قبل إتمام ترحيل حركات المخزون.',
        category: StockPostingErrorCategory.configuration,
        actionLabel: 'الذهاب للتهيئة المحاسبية',
        onAction: () {
          Navigator.of(context).pop();
          context.push(AppRoutes.settingsSetup);
        },
      );
    }

    if (reason.contains('تكلفة صفرية') || reason.contains('إدخال التكلفة')) {
      return StockPostingErrorDetails(
        title: 'تكلفة أصناف غير مكتملة',
        message: reason,
        subtitle:
            'يرجى مراجعة وتحديث سعر التكلفة للأصناف ثم إعادة محاولة الترحيل.',
        category: StockPostingErrorCategory.zeroCost,
        actionLabel: onEditRequested != null ? 'تعديل المستند' : null,
        onAction: onEditRequested != null
            ? () {
                Navigator.of(context).pop();
                onEditRequested();
              }
            : null,
      );
    }

    if (reason.contains('الفترة المحاسبية مغلقة')) {
      return StockPostingErrorDetails(
        title: 'الفترة المحاسبية مغلقة',
        message: reason,
        subtitle: 'لا يمكن ترحيل مستندات في فترة محاسبية مغلقة.',
        category: StockPostingErrorCategory.closedPeriod,
      );
    }

    if (reason.contains('صلاحية') || reason.contains('مرفوض')) {
      return StockPostingErrorDetails(
        title: 'صلاحيات ترحيل غير كافية',
        message: reason,
        subtitle: 'يتطلب ترحيل المستند التوفر على صلاحيات الترحيل المناسبة.',
        category: StockPostingErrorCategory.permission,
      );
    }

    return StockPostingErrorDetails(
      title: 'تعذر ترحيل المستند',
      message: reason,
      category: StockPostingErrorCategory.general,
    );
  }
}

Future<void> showStockPostingErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? subtitle,
  StockPostingErrorCategory category = StockPostingErrorCategory.general,
  String? actionLabel,
  VoidCallback? onAction,
}) async {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;

  final (icon, iconColor, headerBg) = switch (category) {
    StockPostingErrorCategory.configuration => (
      Icons.settings_suggest_rounded,
      Colors.orange.shade800,
      Colors.orange.shade50,
    ),
    StockPostingErrorCategory.zeroCost => (
      Icons.monetization_on_outlined,
      Colors.amber.shade900,
      Colors.amber.shade50,
    ),
    StockPostingErrorCategory.closedPeriod => (
      Icons.edit_calendar_rounded,
      Colors.purple.shade800,
      Colors.purple.shade50,
    ),
    StockPostingErrorCategory.shortage => (
      Icons.inventory_2_outlined,
      Colors.red.shade800,
      Colors.red.shade50,
    ),
    StockPostingErrorCategory.permission => (
      Icons.lock_rounded,
      Colors.deepOrange.shade800,
      Colors.deepOrange.shade50,
    ),
    _ => (
      Icons.error_outline_rounded,
      scheme.error,
      scheme.errorContainer.withValues(alpha: 0.3),
    ),
  };

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      iconPadding: EdgeInsets.zero,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: headerBg, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: iconColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        OverflowBar(
          alignment: MainAxisAlignment.end,
          spacing: AppSpacing.xs,
          overflowSpacing: AppSpacing.xs,
          children: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إغلاق'),
            ),
            if (actionLabel != null && onAction != null)
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  actionLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
