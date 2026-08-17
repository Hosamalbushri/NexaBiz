import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import 'accounting_routes.dart';

/// Accounting module hub.
class AccountingHomePage extends ConsumerWidget {
  const AccountingHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else {
          router.go(AppRoutes.services);
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: CustomAppBar(
          title: l10n.moduleAccounting,
          showBackButton: true,
        ),
        body: ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            Text(
              l10n.servicesTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.moduleAccountingDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ServiceCard(
                  icon: Icons.account_tree_outlined,
                  title: l10n.accountingChartOfAccounts,
                  subtitle: l10n.accountingChartOfAccountsDescription,
                  onTap: () => AccountingRoutes.goAccounts(context),
                )
                .animate()
                .fadeIn(duration: 220.ms)
                .moveY(
                  begin: 8,
                  end: 0,
                  duration: 240.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: AppSpacing.md),
            _ServiceCard(
                  icon: Icons.upload_file_outlined,
                  title: l10n.accountingOpeningSetupCardTitle,
                  subtitle: l10n.accountingOpeningSetupCardSubtitle,
                  onTap: () => AccountingRoutes.pushOpeningSetup(context),
                )
                .animate(delay: 40.ms)
                .fadeIn(duration: 220.ms)
                .moveY(
                  begin: 8,
                  end: 0,
                  duration: 240.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: AppSpacing.md),
            _ServiceCard(
                  icon: Icons.receipt_long_outlined,
                  title: l10n.accountingJournalsTitle,
                  subtitle: l10n.accountingJournalsSubtitle,
                  onTap: () => AccountingRoutes.pushJournals(context),
                )
                .animate(delay: 80.ms)
                .fadeIn(duration: 220.ms)
                .moveY(
                  begin: 8,
                  end: 0,
                  duration: 240.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: AppSpacing.md),
            _ServiceCard(
                  icon: Icons.date_range_outlined,
                  title: l10n.accountingFiscalYearsTitle,
                  subtitle: l10n.accountingFiscalYearsSubtitle,
                  onTap: () => AccountingRoutes.pushFiscalYears(context),
                )
                .animate(delay: 100.ms)
                .fadeIn(duration: 220.ms)
                .moveY(
                  begin: 8,
                  end: 0,
                  duration: 240.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: AppSpacing.md),
            _ServiceCard(
                  icon: Icons.currency_exchange_outlined,
                  title: l10n.accountingCurrencyRatesTitle,
                  subtitle: l10n.accountingCurrencyRatesCardSubtitle,
                  onTap: () => AccountingRoutes.pushCurrencyRates(context),
                )
                .animate(delay: 120.ms)
                .fadeIn(duration: 220.ms)
                .moveY(
                  begin: 8,
                  end: 0,
                  duration: 240.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: AppSpacing.md),
            _ServiceCard(
                  icon: Icons.menu_book_outlined,
                  title: l10n.accountingVoucherBooksTitle,
                  subtitle: l10n.accountingVoucherBooksCardSubtitle,
                  onTap: () => AccountingRoutes.pushVoucherBooks(context),
                )
                .animate(delay: 160.ms)
                .fadeIn(duration: 220.ms)
                .moveY(
                  begin: 8,
                  end: 0,
                  duration: 240.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: AppSpacing.md),
            _ServiceCard(
                  icon: Icons.assessment_outlined,
                  title: l10n.accountingReportsTitle,
                  subtitle: l10n.accountingReportsSubtitle,
                  onTap: () => AccountingRoutes.pushReports(context),
                )
                .animate(delay: 200.ms)
                .fadeIn(duration: 220.ms)
                .moveY(
                  begin: 8,
                  end: 0,
                  duration: 240.ms,
                  curve: Curves.easeOutCubic,
                ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
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
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
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
