import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_card.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';

import '../providers/functional_currency_providers.dart';
import 'currencies_manage_page.dart';

/// Dedicated page for displaying the company's functional (accounting base) currency status.
///
/// Enforces CURRENCY-UI-15:
/// 1. Displays functional currency state and details read-only.
/// 2. Directs currency modifications to Currency Master (`CurrenciesManagePage`) via `[Manage Currencies]`.
/// 3. NEVER displays or infers YER as a default when unconfigured.
class FunctionalCurrencyConfigPage extends ConsumerStatefulWidget {
  const FunctionalCurrencyConfigPage({super.key});

  @override
  ConsumerState<FunctionalCurrencyConfigPage> createState() =>
      _FunctionalCurrencyConfigPageState();
}

class _FunctionalCurrencyConfigPageState
    extends ConsumerState<FunctionalCurrencyConfigPage> {
  @override
  Widget build(BuildContext context) {
    final stateInfoAsync = ref.watch(functionalCurrencyStateInfoProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: CustomAppBar(
        title: isArabic
            ? 'تكوين العملة الوظيفية (الدفترية)'
            : 'Functional Currency Configuration',
      ),
      body: stateInfoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppCard(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isArabic
                        ? 'حدث خطأ أثناء تحميل تكوين العملة الوظيفية'
                        : 'Error loading functional currency configuration',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(err.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: isArabic ? 'إعادة المحاولة' : 'Retry',
                    onPressed: () => ref.refresh(functionalCurrencyStateInfoProvider),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (info) => _buildContent(context, info),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    FunctionalCurrencyStateInfo info,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusHeaderCard(context, info),
          const SizedBox(height: AppSpacing.md),
          if (info.configState == FunctionalCurrencyConfigState.currencyInactive)
            _buildAlertBanner(
              context: context,
              icon: Icons.warning_amber_rounded,
              color: Colors.orange.shade800,
              bgColor: Colors.orange.shade50,
              title: isArabic
                  ? 'تحذير: العملة الوظيفية الحالية غير نشطة'
                  : 'Warning: Current functional currency is inactive',
              message: isArabic
                  ? 'تم إلغاء تنشيط العملة المحددة كعملة وظيفية في سجل العملات. يُرجى مراجعة سجل العملات الرئيسي.'
                  : 'The currency configured as functional is inactive in Currency Master.',
            )
          else if (info.configState == FunctionalCurrencyConfigState.notConfigured)
            _buildAlertBanner(
              context: context,
              icon: Icons.info_outline_rounded,
              color: Colors.blue.shade800,
              bgColor: Colors.blue.shade50,
              title: isArabic
                  ? 'العملة الوظيفية غير مضبوطة'
                  : 'Functional Currency Not Configured',
              message: isArabic
                  ? 'لم يتم اختيار عملة وظيفية للشركة بعد. يمكنك تعيين العملة الوظيفية من صفحة إدارة العملات.'
                  : 'No functional currency set yet. You can assign it from Currency Master.',
            )
          else if (info.configState == FunctionalCurrencyConfigState.invalidConfig)
            _buildAlertBanner(
              context: context,
              icon: Icons.error_outline_rounded,
              color: Colors.red.shade800,
              bgColor: Colors.red.shade50,
              title: isArabic
                  ? 'تكوين العملة غير صالح'
                  : 'Invalid Currency Configuration',
              message: isArabic
                  ? 'كود العملة الوظيفية المسجل غير موجود في سجل العملات الرئيسي.'
                  : 'Configured functional currency code does not exist in Currency Master.',
            ),
          const SizedBox(height: AppSpacing.md),
          _buildCurrencySummaryCard(context, info),
          const SizedBox(height: AppSpacing.lg),

          // Central Navigation Action to Currency Master UI
          AppButton(
            label: isArabic
                ? 'إدارة العملات والتعيينات (سجل العملات)'
                : 'Manage Currencies & Roles (Currency Master)',
            icon: Icons.account_balance_wallet_outlined,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CurrenciesManagePage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeaderCard(
    BuildContext context,
    FunctionalCurrencyStateInfo info,
  ) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    String statusTitle;
    AppStatusTone tone;

    switch (info.configState) {
      case FunctionalCurrencyConfigState.configured:
        statusTitle = isArabic ? 'مكتمل ومضبوط' : 'Configured';
        tone = AppStatusTone.success;
        break;
      case FunctionalCurrencyConfigState.changeRestricted:
        statusTitle = isArabic ? 'مضبوط ومقيد (توجد معاملات)' : 'Configured & Locked (Has Transactions)';
        tone = AppStatusTone.info;
        break;
      case FunctionalCurrencyConfigState.currencyInactive:
        statusTitle = isArabic ? 'العملة غير نشطة' : 'Currency Inactive';
        tone = AppStatusTone.warning;
        break;
      case FunctionalCurrencyConfigState.invalidConfig:
        statusTitle = isArabic ? 'تكوين غير صالح' : 'Invalid Config';
        tone = AppStatusTone.error;
        break;
      case FunctionalCurrencyConfigState.notConfigured:
        statusTitle = isArabic ? 'غير مضبوطة' : 'Not Configured';
        tone = AppStatusTone.neutral;
        break;
    }

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_outlined,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'حالة العملة الوظيفية' : 'Functional Currency Status',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    isArabic
                        ? 'العملة الأساسية المستخدمة في الحسابات والتقارير المالية'
                        : 'Base currency used for financial accounting and reporting',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppStatusBadge(
              label: statusTitle,
              tone: tone,
              animate: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: TextStyle(fontSize: 13, color: color.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySummaryCard(
    BuildContext context,
    FunctionalCurrencyStateInfo info,
  ) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final currency = info.currency;

    if (currency == null) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Text(
              isArabic
                  ? 'لم يتم تكوين عملة وظيفية بعد'
                  : 'No functional currency configured',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'تفاصيل العملة الوظيفية الحالية' : 'Current Functional Currency Details',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    currency.code,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            _buildDetailRow(
              context,
              label: isArabic ? 'الاسم بالعرية' : 'Arabic Name',
              value: currency.nameAr,
            ),
            _buildDetailRow(
              context,
              label: isArabic ? 'الاسم بالإنجليزية' : 'English Name',
              value: currency.nameEn,
            ),
            _buildDetailRow(
              context,
              label: isArabic ? 'رمز العملة' : 'Symbol',
              value: currency.symbol.isNotEmpty ? currency.symbol : currency.code,
            ),
            _buildDetailRow(
              context,
              label: isArabic ? 'الخانات العشرية' : 'Decimal Digits',
              value: currency.decimalDigits.toString(),
            ),
            _buildDetailRow(
              context,
              label: isArabic ? 'حالة التنشيط' : 'Active Status',
              value: currency.isActive
                  ? (isArabic ? 'نشط' : 'Active')
                  : (isArabic ? 'غير نشط' : 'Inactive'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
