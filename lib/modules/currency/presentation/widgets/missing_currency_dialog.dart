import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/modules/currency/presentation/providers/currency_rate_providers.dart';
import '../pages/currencies_manage_page.dart';

/// Displays a user-friendly modal dialog when a module requires a configured currency,
/// but no base functional currency has been set in the system yet.
Future<void> showMissingCurrencyDialog(BuildContext context) async {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final theme = Theme.of(context);

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(AppSpacing.lg),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber.shade400,
                  Colors.orange.shade700,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.currency_exchange_rounded,
              size: 34,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isArabic ? 'لم يتم تعيين العملة الرئيسية' : 'Base Currency Required',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isArabic
                ? 'لم يتم تهيئة أو تعيين العملة الرئيسية للشركة في النظام بعد. يُرجى إضافة وتهيئة العملة الرئيسية أولاً للتمكن من متابعة العمليات والمعاملات.'
                : 'The company base currency has not been set yet. Please configure the base currency first to proceed with operations.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CurrenciesManagePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: Text(
                    isArabic ? 'إعداد العملة' : 'Configure Currency',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// A highly-polished, prominent banner widget to display missing currency alerts.
class AppMissingCurrencyBanner extends StatelessWidget {
  const AppMissingCurrencyBanner({
    super.key,
    this.onConfigurePressed,
  });

  final VoidCallback? onConfigurePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade50,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Colors.amber.shade300,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade100.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.amber.shade400,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber.shade900,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic
                        ? 'تنبيه: لم يتم تعيين العملة الرئيسية للنظام'
                        : 'Warning: Base Currency Not Configured',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isArabic
                        ? 'لا يمكن إكمال المستندات أو إجراء الحركات حتى يتم تعيين العملة الرئيسية للنظام في دليل العملات.'
                        : 'Cannot process transactions until the system base currency is configured.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade900,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: onConfigurePressed ??
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CurrenciesManagePage(),
                            ),
                          );
                        },
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                    label: Text(
                      isArabic ? 'إضافة وتعيين العملة الرئيسية' : 'Set Up Base Currency',
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reactive guard banner that automatically listens to system base currency state.
/// Displays [AppMissingCurrencyBanner] if no functional base currency is configured.
class AppMissingCurrencyGuardBanner extends ConsumerWidget {
  const AppMissingCurrencyGuardBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseCurrency = ref.watch(accountingBaseCurrencyProvider);
    if (baseCurrency != null) {
      return const SizedBox.shrink();
    }
    return const AppMissingCurrencyBanner();
  }
}

