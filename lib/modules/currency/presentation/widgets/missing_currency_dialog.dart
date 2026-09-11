import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/modules/currency/presentation/providers/currency_rate_providers.dart';
import '../pages/currencies_manage_page.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

/// Displays a user-friendly modal dialog when a module requires a configured currency,
/// but no base functional currency has been set in the system yet.
Future<void> showMissingCurrencyDialog(BuildContext context) async {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';

  await AppDialog.show<void>(
    context: context,
    title: isArabic ? 'لم يتم تعيين العملة الرئيسية' : 'Base Currency Required',
    description: isArabic
        ? 'لم يتم تهيئة أو تعيين العملة الرئيسية للشركة في النظام بعد. يُرجى إضافة وتهيئة العملة الرئيسية أولاً للتمكن من متابعة العمليات والمعاملات.'
        : 'The company base currency has not been set yet. Please configure the base currency first to proceed with operations.',
    icon: Icons.currency_exchange_rounded,
    isDestructive: true,
    size: AppDialogSize.small,
    confirmLabel: isArabic ? 'إعداد العملة' : 'Configure',
    cancelLabel: isArabic ? 'إلغاء' : 'Cancel',
    onConfirm: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CurrenciesManagePage(),
        ),
      );
    },
    child: const SizedBox.shrink(),
  );
}

/// A highly-polished, prominent banner widget to display missing currency alerts using system theme tokens.
class AppMissingCurrencyBanner extends StatelessWidget {
  const AppMissingCurrencyBanner({
    super.key,
    this.onConfigurePressed,
  });

  final VoidCallback? onConfigurePressed;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: shadcn.Alert.destructive(
        leading: const Icon(Icons.warning_amber_rounded),
        title: Text(
          isArabic
              ? 'تنبيه: لم يتم تعيين العملة الرئيسية للنظام'
              : 'Warning: Base Currency Not Configured',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isArabic
                  ? 'لا يمكن إكمال المستندات أو إجراء الحركات حتى يتم تعيين العملة الرئيسية للنظام في دليل العملات.'
                  : 'Cannot process transactions until the system base currency is configured.',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: isArabic ? 'إضافة وتعيين العملة الرئيسية' : 'Set Up Base Currency',
              icon: Icons.add_circle_outline_rounded,
              onPressed: onConfigurePressed ??
                  () {
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
  }
}

/// Reactive guard banner that automatically listens to system base currency state.
/// Prevents false positive flickering while base currency state is loading.
class AppMissingCurrencyGuardBanner extends ConsumerWidget {
  const AppMissingCurrencyGuardBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isBaseCurrencyLoadingProvider);
    if (isLoading) {
      return const SizedBox.shrink();
    }

    final baseCurrency = ref.watch(accountingBaseCurrencyProvider);
    if (baseCurrency != null) {
      return const SizedBox.shrink();
    }
    return const AppMissingCurrencyBanner();
  }
}
