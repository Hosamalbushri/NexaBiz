import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_count/app/router/app_routes.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

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
          if (context.mounted) {
            context.push(AppRoutes.settingsSetup);
          }
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
  final iconData = switch (category) {
    StockPostingErrorCategory.configuration => Icons.settings_suggest_rounded,
    StockPostingErrorCategory.zeroCost => Icons.monetization_on_outlined,
    StockPostingErrorCategory.closedPeriod => Icons.edit_calendar_rounded,
    StockPostingErrorCategory.shortage => Icons.inventory_2_outlined,
    StockPostingErrorCategory.permission => Icons.lock_rounded,
    _ => Icons.error_outline_rounded,
  };

  final hasAction = actionLabel != null && onAction != null;

  await AppDialog.show<void>(
    context: context,
    title: title,
    description: subtitle,
    icon: iconData,
    isDestructive: true,
    size: AppDialogSize.medium,
    cancelLabel: 'إغلاق',
    confirmLabel: hasAction ? actionLabel : 'إغلاق',
    onConfirm: hasAction ? onAction : null,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
