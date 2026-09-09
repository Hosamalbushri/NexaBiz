import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_button.dart';

import '../providers/inventory_valuation_currency_providers.dart';

import 'package:stock_count/modules/accounting/shared/presentation/pages/currencies_manage_page.dart';

class InventoryValuationCurrencyCard extends ConsumerWidget {
  const InventoryValuationCurrencyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(inventoryValuationCurrencyStateProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';

    return stateAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: const Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.errorContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: scheme.error),
        ),
        child: Text('خطأ في تحميل عملة تقييم المخزون: $err'),
      ),
      data: (info) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: scheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr
                                ? 'عملة تقييم المخزون'
                                : 'Inventory Valuation Currency',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            info.scopeLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(context, info),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Warning / State Banners
                if (info.isNotConfigured) ...[
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
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber.shade900,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            isAr
                                ? 'لم يتم تحديد عملة تقييم المخزون! يرجى تحديد عملة التقييم عبر دليل العملات (Currency Master).'
                                : 'Inventory valuation currency is not configured. Please assign a currency in Currency Master.',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (info.isLocked) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_rounded, color: Colors.blue.shade900),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            isAr
                                ? 'تغيير عملة التقييم مقفل لوجود حركات مخزنية أو طبقات تكلفة مسجلة سابقاً لحماية نزاهة الدفاتر.'
                                : 'Valuation currency is locked due to historical inventory transactions.',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Current Valuation Currency Card Details
                if (info.currency != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: scheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          child: Text(
                            info.currency!.symbol,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${info.currency!.code} - ${info.currency!.localizedName(isAr)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAr
                                    ? 'الدقة العشرية: ${info.currency!.decimalDigits} خانات'
                                    : 'Precision: ${info.currency!.decimalDigits} decimals',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Manage Currencies Button to Central Master UI
                AppButton(
                  label: isAr ? 'إدارة العملات' : 'Manage Currencies',
                  icon: Icons.account_balance_wallet_outlined,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CurrenciesManagePage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    InventoryValuationCurrencyStateInfo info,
  ) {
    final theme = Theme.of(context);
    String label;
    Color bg;
    Color fg;

    if (info.isLocked) {
      label = 'مقفلة (Locked)';
      bg = Colors.blue.shade100;
      fg = Colors.blue.shade900;
    } else if (info.isConfigured) {
      label = 'محددة (Configured)';
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
    } else if (info.isNotConfigured) {
      label = 'غير محددة';
      bg = Colors.amber.shade100;
      fg = Colors.amber.shade900;
    } else if (info.isInactive) {
      label = 'غير نشطة';
      bg = Colors.red.shade100;
      fg = Colors.red.shade900;
    } else {
      label = 'غير صالحة';
      bg = Colors.red.shade100;
      fg = Colors.red.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
