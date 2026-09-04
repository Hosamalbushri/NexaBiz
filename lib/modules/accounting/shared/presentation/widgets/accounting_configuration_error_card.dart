import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/accounting_configuration_error.dart';

class AccountingConfigurationErrorCard extends StatelessWidget {
  final AccountingConfigurationException error;
  final VoidCallback? onConfigurePressed;

  const AccountingConfigurationErrorCard({
    super.key,
    required this.error,
    this.onConfigurePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleLabel = error.accountingRole?.name ?? error.module;
    final expectedTypeLabel = error.expectedAccountType?.name ?? 'غير محدد';

    final actualTypeLabel = error.actualAccountType?.name;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5), width: 1.5),
      ),
      color: theme.colorScheme.errorContainer.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error.userMessage,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (error.userExplanation != null) ...[
              Text(
                error.userExplanation!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(context, 'الوحدة / القاعدة:', roleLabel),
                  _buildDetailRow(context, 'نوع الحساب المطلوب:', expectedTypeLabel),
                  if (actualTypeLabel != null)
                    _buildDetailRow(context, 'نوع الحساب المحدد حالياً:', actualTypeLabel),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: onConfigurePressed ?? () => _defaultNavigate(context),
                icon: const Icon(Icons.settings, size: 18),
                label: Text(_getActionLabel(error.errorCode)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getActionLabel(AccountingConfigurationErrorCode code) {
    switch (code) {
      case AccountingConfigurationErrorCode.accountTypeMismatch:
      case AccountingConfigurationErrorCode.accountScopeInvalid:
        return 'إصلاح التجهيز المحاسبي';
      case AccountingConfigurationErrorCode.entityAccountNotConfigured:
        return 'تعيين حساب المنشأة';
      case AccountingConfigurationErrorCode.accountInactive:
      case AccountingConfigurationErrorCode.accountDeleted:
        return 'مراجعة إعدادات الحسابات';
      default:
        return 'تجهيز المحاسبة';
    }
  }

  void _defaultNavigate(BuildContext context) {
    if (error.configurationRoute != null) {
      final route = error.configurationRoute!;
      try {
        context.push(route);
      } catch (_) {
        Navigator.of(context).pushNamed(route);
      }
    }
  }
}
