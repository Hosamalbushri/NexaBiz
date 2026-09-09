import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_responsive.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';

import 'currencies_manage_page.dart';
import 'currency_rates_page.dart';
import 'functional_currency_config_page.dart';
import 'package:stock_count/modules/inventory/cost_valuation/presentation/pages/cost_valuation_settings_page.dart';
import '../providers/functional_currency_providers.dart';

/// Currency module home page — displays core currency services & configuration options.
class CurrenciesHomePage extends ConsumerWidget {
  const CurrenciesHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final functionalCurrencyAsync = ref.watch(functionalCurrencyStateInfoProvider);
    final baseCurrency = functionalCurrencyAsync.valueOrNull?.currency;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isArabic ? 'إدارة العملات وسعر الصرف' : 'Currencies & FX Management',
        showBackButton: true,
      ),
      body: AppContentConstraint(
        child: ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            // Title & Description Section
            Text(
              isArabic ? 'خدمات وإعدادات العملات' : 'Currency Services & Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isArabic
                  ? 'إدارة قائمة العملات، أسعار صرف المصارفة، وتهيئة عملة النظام وعملة تقييم المخزون.'
                  : 'Manage currencies catalog, exchange rates, system functional currency, and inventory valuation currency.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Base Functional Currency Status Banner
            _BaseCurrencyStatusCard(
              baseCurrency: baseCurrency,
              isArabic: isArabic,
            )
                .animate()
                .fadeIn(duration: 200.ms)
                .moveY(begin: 6, end: 0, duration: 220.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: AppSpacing.lg),

            Text(
              isArabic ? 'الخدمات الرئيسية' : 'Primary Services',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Service 1: قائمة العملات (Currencies List & Management)
            _CurrencyServiceCard(
              icon: Icons.monetization_on_outlined,
              title: isArabic ? 'قائمة العملات' : 'Currencies List',
              subtitle: isArabic
                  ? 'عرض دليل وسجل العملات المتاحة وإضافة عملات جديدة وتعيين العملة الرئيسية'
                  : 'View currencies catalog, add master currencies, and configure primary currency',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CurrenciesManagePage(),
                  ),
                );
              },
            )
                .animate(delay: 40.ms)
                .fadeIn(duration: 220.ms)
                .moveY(begin: 8, end: 0, duration: 240.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: AppSpacing.md),

            // Service 2: خدمة المصارفة (Exchange Rates / FX Rates)
            _CurrencyServiceCard(
              icon: Icons.currency_exchange_rounded,
              title: isArabic ? 'خدمة المصارفة (أسعار الصرف)' : 'Exchange Rates Service',
              subtitle: isArabic
                  ? 'تحديد وتحديث أسعار صرف العملات الأجنبية مقابل العملة الرئيسية للمؤسسة'
                  : 'Manage foreign exchange rates against the functional base currency',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CurrencyRatesPage(),
                  ),
                );
              },
            )
                .animate(delay: 80.ms)
                .fadeIn(duration: 220.ms)
                .moveY(begin: 8, end: 0, duration: 240.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: AppSpacing.lg),

            Text(
              isArabic ? 'خيارات إعدادات العملة' : 'Currency Configuration Options',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Setting 1: إعدادات عملة النظام (العملة الوظيفية)
            _CurrencyServiceCard(
              icon: Icons.settings_applications_outlined,
              title: isArabic ? 'إعدادات عملة النظام (العملة الوظيفية)' : 'System Functional Currency Settings',
              subtitle: isArabic
                  ? 'مراجعة وتهيئة العملة الدفترية الأساسية للنظام المستند إليها القيود المحاسبية'
                  : 'Review and configure functional base currency used across accounting entries',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FunctionalCurrencyConfigPage(),
                  ),
                );
              },
            )
                .animate(delay: 120.ms)
                .fadeIn(duration: 220.ms)
                .moveY(begin: 8, end: 0, duration: 240.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: AppSpacing.md),

            // Setting 2: إعدادات عملة تقييم المخزون
            _CurrencyServiceCard(
              icon: Icons.inventory_2_outlined,
              title: isArabic ? 'إعدادات عملة تقييم المخزون' : 'Inventory Valuation Currency Settings',
              subtitle: isArabic
                  ? 'تحديد عملة تقييم تكلفة طبقات المخزون وطريقة الحساب (FIFO / المتوسط)'
                  : 'Configure inventory cost layer valuation currency and costing methods',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CostValuationSettingsPage(),
                  ),
                );
              },
            )
                .animate(delay: 160.ms)
                .fadeIn(duration: 220.ms)
                .moveY(begin: 8, end: 0, duration: 240.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// Status Header Card highlighting current base currency
/// Status Header Card highlighting current base currency
class _BaseCurrencyStatusCard extends StatelessWidget {
  const _BaseCurrencyStatusCard({
    required this.baseCurrency,
    required this.isArabic,
  });

  final dynamic baseCurrency;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConfigured = baseCurrency != null;

    return Container(
      decoration: BoxDecoration(
        gradient: isConfigured
            ? LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  theme.colorScheme.surface,
                ],
              )
            : LinearGradient(
                colors: [
                  Colors.amber.shade50,
                  Colors.orange.shade50,
                ],
              ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isConfigured
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : Colors.amber.shade400,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isConfigured ? theme.colorScheme.primary : Colors.amber)
                .withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isConfigured
                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                    : Colors.amber.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isConfigured
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : Colors.amber.shade400,
                ),
              ),
              child: Icon(
                isConfigured ? Icons.verified_rounded : Icons.warning_amber_rounded,
                color: isConfigured
                    ? theme.colorScheme.primary
                    : Colors.amber.shade900,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConfigured
                        ? (isArabic
                            ? 'العملة الرئيسية: ${baseCurrency.localizedName(isArabic)} (${baseCurrency.code})'
                            : 'Base Currency: ${baseCurrency.code}')
                        : (isArabic
                            ? 'تنبيه: لم يتم تعيين العملة الرئيسية للنظام'
                            : 'Base Currency Not Configured'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isConfigured
                          ? theme.colorScheme.onSurface
                          : Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConfigured
                        ? (isArabic
                            ? 'العملة المعتمدة في النظام لترخيص وحساب القيود والمعاملات والقوائم المالية.'
                            : 'Primary functional currency used for posting entries and financial statements.')
                        : (isArabic
                            ? 'يرجى تحديد العملة الرئيسية من قائمة العملات لتفعيل كافة المعاملات والحركات.'
                            : 'Please configure base currency from the Currencies List to enable transactions.'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isConfigured
                          ? theme.colorScheme.onSurfaceVariant
                          : Colors.amber.shade900,
                      height: 1.35,
                    ),
                  ),
                  if (!isConfigured) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CurrenciesManagePage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                      label: Text(
                        isArabic ? 'إعداد العملة الرئيسية الآن' : 'Set Up Base Currency Now',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable Service Card widget
class _CurrencyServiceCard extends StatelessWidget {
  const _CurrencyServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompactLandscape = MediaQuery.of(context).size.height < 500;
    final boxSize = isCompactLandscape ? 42.0 : 52.0;
    final iconSize = isCompactLandscape ? 22.0 : 28.0;

    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(
              isCompactLandscape ? AppSpacing.sm : AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: iconSize,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: (isCompactLandscape
                                ? theme.textTheme.titleSmall
                                : theme.textTheme.titleMedium)
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: isCompactLandscape ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                          fontSize: isCompactLandscape ? 12 : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
