import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/widgets/settings_chrome.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

import '../providers/cost_valuation_providers.dart';

class CostValuationSettingsPage extends ConsumerWidget {
  const CostValuationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentMethod = ref.watch(costValuationMethodProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.localeName == 'ar' ? 'تقييم تكلفة المخزون' : 'Inventory Cost Valuation',
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              l10n.localeName == 'ar'
                  ? 'اختر طريقة احتساب تكلفة البضاعة المباعة (COGS) وقيمة المخزون المتبقي في المستودعات'
                  : 'Select the inventory valuation method used for COGS calculation and balance valuation',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SettingsGroupLabel(
            l10n.localeName == 'ar' ? 'طريقة احتساب التكلفة الحالية' : 'Valuation Methods',
          ),
          _ValuationMethodCard(
            method: CostValuationMethod.fifo,
            title: l10n.localeName == 'ar' ? 'FIFO - الوارد أولاً يصرف أولاً' : 'FIFO - First In, First Out',
            subtitle: l10n.localeName == 'ar'
                ? 'يتم صرف وتحديد تكلفة المنتجات بناءً على أقدم طبقات تكلفة تم توريدها. يعطي تقييماً دقيقاً للمخزون المتبقي بأسعار السوق الحديثة.'
                : 'Consumes oldest cost layers first. Provides modern balance sheet valuation.',
            icon: Icons.filter_1_rounded,
            isSelected: currentMethod == CostValuationMethod.fifo,
            onTap: () {
              ref.read(costValuationMethodProvider.notifier).setMethod(CostValuationMethod.fifo);
              showAppSnackBar(context, message: l10n.localeName == 'ar' ? 'تم اختيار طريقة FIFO' : 'FIFO method selected', isSuccess: true);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _ValuationMethodCard(
            method: CostValuationMethod.lifo,
            title: l10n.localeName == 'ar' ? 'LIFO - الوارد أخيراً يصرف أولاً' : 'LIFO - Last In, First Out',
            subtitle: l10n.localeName == 'ar'
                ? 'يتم صرف المنتجات بناءً على أحدث شحنات تم استلامها، مما يعكس تكلفة البضاعة المباعة وفقاً لأحدث الأسعار.'
                : 'Consumes newest cost layers first. Matches recent purchase costs with current revenues.',
            icon: Icons.filter_3_rounded,
            isSelected: currentMethod == CostValuationMethod.lifo,
            onTap: () {
              ref.read(costValuationMethodProvider.notifier).setMethod(CostValuationMethod.lifo);
              showAppSnackBar(context, message: l10n.localeName == 'ar' ? 'تم اختيار طريقة LIFO' : 'LIFO method selected', isSuccess: true);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _ValuationMethodCard(
            method: CostValuationMethod.weightedAverage,
            title: l10n.localeName == 'ar' ? 'Weighted Average - المتوسط المرجح' : 'Weighted Average',
            subtitle: l10n.localeName == 'ar'
                ? 'يحسب متوسط تكلفة للوحدة بناءً على إجمالي تكلفة الطبقات المتاحة مقسوماً على إجمالي الكمية. يقلل من تقلبات الأسعار.'
                : 'Calculates average unit cost by total layer cost divided by available quantity.',
            icon: Icons.functions_rounded,
            isSelected: currentMethod == CostValuationMethod.weightedAverage,
            onTap: () {
              ref.read(costValuationMethodProvider.notifier).setMethod(CostValuationMethod.weightedAverage);
              showAppSnackBar(context, message: l10n.localeName == 'ar' ? 'تم اختيار طريقة المتوسط المرجح' : 'Weighted Average selected', isSuccess: true);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsGroupLabel(
            l10n.localeName == 'ar' ? 'توضيح وحالة التتبع' : 'Valuation Details',
          ),
          SettingsGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.verified_outlined, color: Colors.green),
                title: Text(l10n.localeName == 'ar' ? 'تتبع محرك طبقات التكلفة (Cost Layers Engine)' : 'Cost Layers Engine Active'),
                subtitle: Text(
                  l10n.localeName == 'ar'
                      ? 'يتم تسريع وتأمين كافة حركات الإيصال الصرف والارتجاع والتحويلات مخزنياً مع تتبع رصيد الطبقات المتبقي'
                      : 'All movement lines accurately consume and generate cost layers automatically.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValuationMethodCard extends StatelessWidget {
  const _ValuationMethodCard({
    required this.method,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final CostValuationMethod method;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected ? colorScheme.primaryContainer.withOpacity(0.4) : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                child: Icon(
                  icon,
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Radio<CostValuationMethod>(
                value: method,
                groupValue: isSelected ? method : null,
                onChanged: (_) => onTap(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
