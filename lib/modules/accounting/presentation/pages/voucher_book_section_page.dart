import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/voucher_book.dart';
import '../../domain/entities/voucher_book_type.dart';
import '../../domain/models/voucher_book_exception.dart';
import '../providers/voucher_book_providers.dart';
import '../widgets/voucher_book_labels.dart';
import 'accounting_routes.dart';

/// Section hub: either a single book list, or a list of kinds to open.
class VoucherBookSectionPage extends ConsumerWidget {
  const VoucherBookSectionPage({super.key, required this.section});

  final VoucherBookType section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final kinds = VoucherBookType.leafKindsFor(section);
    final sectionsAsync = ref.watch(voucherBookSectionsProvider);

    return sectionsAsync.when(
      loading: () => Scaffold(
        appBar: CustomAppBar(
          title: voucherBookSectionLabel(l10n, section),
          showBackButton: true,
        ),
        body: const AppLoading(),
      ),
      error: (e, _) => Scaffold(
        appBar: CustomAppBar(
          title: voucherBookSectionLabel(l10n, section),
          showBackButton: true,
        ),
        body: AppErrorState(message: e.toString()),
      ),
      data: (sections) {
        VoucherBookSectionNode? node;
        for (final s in sections) {
          if (s.group.bookType.section == section.section) {
            node = s;
            break;
          }
        }
        if (node == null) {
          return Scaffold(
            appBar: CustomAppBar(
              title: voucherBookSectionLabel(l10n, section),
              showBackButton: true,
            ),
            body: AppEmptyState(
              title: l10n.accountingVoucherBooksEmptyTitle,
              subtitle: l10n.accountingVoucherBooksEmptyMessage,
              icon: Icons.menu_book_outlined,
            ),
          );
        }

        if (kinds.length == 1) {
          return _KindBooksScaffold(
            title: voucherBookSectionLabel(l10n, section),
            kind: kinds.first,
            parentId: node.group.uuid,
            books: node.children
                .where((b) => b.bookType == kinds.first)
                .toList(growable: false),
          );
        }

        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainerLowest,
          appBar: CustomAppBar(
            title: voucherBookSectionLabel(l10n, section),
            showBackButton: true,
          ),
          body: ListView.separated(
            padding: AppConstants.pageInsets(context),
            itemCount: kinds.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final kind = kinds[index];
              final books = node!.children
                  .where((b) => b.bookType == kind)
                  .toList(growable: false);
              return Material(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => AccountingRoutes.pushVoucherBookKind(
                    context,
                    section: section,
                    kind: kind,
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
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Icon(
                              voucherBookTypeIcon(kind),
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  voucherBookTypeLabel(l10n, kind),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.accountingVoucherBooksSectionCount(
                                    books.length,
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
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
          ),
        );
      },
    );
  }
}

/// Books list for one leaf kind under a section.
class VoucherBookKindPage extends ConsumerWidget {
  const VoucherBookKindPage({
    super.key,
    required this.section,
    required this.kind,
  });

  final VoucherBookType section;
  final VoucherBookType kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sectionsAsync = ref.watch(voucherBookSectionsProvider);
    final title = voucherBookTypeLabel(l10n, kind);

    return sectionsAsync.when(
      loading: () => Scaffold(
        appBar: CustomAppBar(title: title, showBackButton: true),
        body: const AppLoading(),
      ),
      error: (e, _) => Scaffold(
        appBar: CustomAppBar(title: title, showBackButton: true),
        body: AppErrorState(message: e.toString()),
      ),
      data: (sections) {
        VoucherBookSectionNode? node;
        for (final s in sections) {
          if (s.group.bookType.section == section.section) {
            node = s;
            break;
          }
        }
        if (node == null) {
          return Scaffold(
            appBar: CustomAppBar(title: title, showBackButton: true),
            body: AppEmptyState(
              title: l10n.accountingVoucherBooksEmptyTitle,
              subtitle: l10n.accountingVoucherBooksEmptyMessage,
              icon: voucherBookTypeIcon(kind),
            ),
          );
        }
        return _KindBooksScaffold(
          title: title,
          kind: kind,
          parentId: node.group.uuid,
          books: node.children
              .where((b) => b.bookType == kind)
              .toList(growable: false),
        );
      },
    );
  }
}

class _KindBooksScaffold extends StatelessWidget {
  const _KindBooksScaffold({
    required this.title,
    required this.kind,
    required this.parentId,
    required this.books,
  });

  final String title;
  final VoucherBookType kind;
  final String parentId;
  final List<VoucherBook> books;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(title: title, showBackButton: true),
      floatingActionButton: _AddBookFab(parentId: parentId, bookType: kind),
      body: _BooksList(books: books, parentId: parentId, bookType: kind),
    );
  }
}

class _AddBookFab extends StatelessWidget {
  const _AddBookFab({required this.parentId, required this.bookType});

  final String parentId;
  final VoucherBookType bookType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FloatingActionButton.extended(
      heroTag: 'add-voucher-book-${bookType.storageValue}',
      onPressed: () => AccountingRoutes.pushVoucherBookCreate(
        context,
        parentId: parentId,
        bookType: bookType,
      ),
      icon: const Icon(Icons.add),
      label: Text(
        l10n.accountingVoucherBooksAddOfType(
          voucherBookTypeLabel(l10n, bookType),
        ),
      ),
    );
  }
}

class _BooksList extends ConsumerWidget {
  const _BooksList({
    required this.books,
    required this.parentId,
    required this.bookType,
  });

  final List<VoucherBook> books;
  final String parentId;
  final VoucherBookType bookType;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    VoucherBook book,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppDialog(
      context: context,
      title: l10n.accountingVoucherBooksDeleteTitle,
      message: l10n.accountingVoucherBooksDeleteMessage(book.name),
      confirmLabel: l10n.accountingVoucherBooksDelete,
      cancelLabel: l10n.cancel,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await ref.read(voucherBookRepositoryProvider).delete(book.id);
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.accountingVoucherBooksDeleted,
        isSuccess: true,
      );
    } on VoucherBookException catch (e) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, message: e.toString(), isSuccess: false);
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, message: e.toString(), isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (books.isEmpty) {
      return AppEmptyState(
        title: l10n.accountingVoucherBooksTypeEmptyTitle(
          voucherBookTypeLabel(l10n, bookType),
        ),
        subtitle: l10n.accountingVoucherBooksTypeEmptyMessage,
        icon: voucherBookTypeIcon(bookType),
      );
    }

    return ListView.separated(
      padding: AppConstants.pageInsets(
        context,
      ).copyWith(bottom: AppConstants.pagePadding + 88),
      itemCount: books.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final book = books[index];
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => AccountingRoutes.pushVoucherBookEdit(context, book.id),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      voucherBookTypeIcon(book.bookType),
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.accountingVoucherBooksRangePreview(
                              '${book.currentNumber}',
                              '${book.endNumber}',
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppStatusBadge(
                      label: book.isActive
                          ? l10n.accountingVoucherBooksActive
                          : l10n.accountingVoucherBooksInactive,
                      tone: book.isActive
                          ? AppStatusTone.success
                          : AppStatusTone.neutral,
                      animate: false,
                    ),
                    IconButton(
                      tooltip: l10n.accountingVoucherBooksDelete,
                      onPressed: () => _confirmDelete(context, ref, book),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
