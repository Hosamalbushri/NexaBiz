import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/voucher_book_type.dart';
import '../providers/voucher_book_providers.dart';
import '../widgets/voucher_book_labels.dart';
import 'accounting_routes.dart';

/// Top-level list of voucher book sections (Sales, Receipts, …).
class VoucherBooksPage extends ConsumerWidget {
  const VoucherBooksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sectionsAsync = ref.watch(voucherBookSectionsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.accountingVoucherBooksTitle,
        showBackButton: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.pagePadding,
              AppSpacing.md,
              AppConstants.pagePadding,
              AppSpacing.sm,
            ),
            child: Text(
              l10n.accountingVoucherBooksSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
          Expanded(
            child: sectionsAsync.when(
              loading: () => const AppLoading(),
              error: (e, _) => AppErrorState(message: e.toString()),
              data: (sections) {
                if (sections.isEmpty) {
                  return AppEmptyState(
                    title: l10n.accountingVoucherBooksEmptyTitle,
                    subtitle: l10n.accountingVoucherBooksEmptyMessage,
                    icon: Icons.menu_book_outlined,
                  );
                }
                return ListView.separated(
                  padding: AppConstants.pageInsets(context),
                  itemCount: sections.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final node = sections[index];
                    final section = node.group.bookType.section;
                    final kinds = VoucherBookType.leafKindsFor(section);
                    return Material(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: () => AccountingRoutes.pushVoucherBookSection(
                          context,
                          section,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                  child: Icon(
                                    voucherBookTypeIcon(section),
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        voucherBookSectionLabel(l10n, section),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n.accountingVoucherBooksSectionKinds(
                                          kinds.length,
                                          node.children.length,
                                        ),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
