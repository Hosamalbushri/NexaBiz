import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_responsive.dart';
import 'package:stock_count/core/tenancy/company_context_resolver.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import '../../domain/models/account_tree_node.dart';
import '../../domain/services/account_labels.dart';
import '../providers/account_providers.dart';
import '../widgets/account_browse_toolbar.dart';
import '../widgets/account_expandable_search.dart';
import '../widgets/account_tree.dart';
import 'package:stock_count/modules/accounting/shared/presentation/pages/accounting_routes.dart';

/// Chart of Accounts — hierarchical, searchable, offline-capable.
class ChartOfAccountsPage extends ConsumerStatefulWidget {
  const ChartOfAccountsPage({super.key});

  @override
  ConsumerState<ChartOfAccountsPage> createState() =>
      _ChartOfAccountsPageState();
}

class _ChartOfAccountsPageState extends ConsumerState<ChartOfAccountsPage> {
  static const _searchDebounce = Duration(milliseconds: 300);

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  var _searchExpanded = false;
  Timer? _searchDebounceTimer;

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setSearchExpanded(bool value) {
    if (_searchExpanded == value) {
      return;
    }
    setState(() => _searchExpanded = value);
    if (!value) {
      _searchDebounceTimer?.cancel();
      _searchController.clear();
      ref.read(accountSearchQueryProvider.notifier).state = '';
    }
  }

  void _onQueryChanged(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (!mounted) {
        return;
      }
      ref.read(accountSearchQueryProvider.notifier).state = value;
      if (value.trim().isEmpty) {
        return;
      }
      // Expand groups so search hits are visible in the tree.
      final accounts = ref.read(accountsProvider).valueOrNull;
      if (accounts == null) {
        return;
      }
      final l10n = AppLocalizations.of(context);
      final typeFilter = ref.read(accountTypeFilterProvider);
      final filtered = [
        for (final account in accounts)
          if ((typeFilter == null || account.accountType == typeFilter) &&
              AccountLabels.matchesQuery(l10n, account, value))
            account,
      ];
      final roots = AccountTreeNode.buildForest(filtered);
      ref.read(accountTreeExpandedIdsProvider.notifier).state = _allGroupIds(
        roots,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(accountsProvider);
    final expandedIds = ref.watch(accountTreeExpandedIdsProvider);
    final includeInactive = ref.watch(accountsIncludeInactiveProvider);
    final query = ref.watch(accountSearchQueryProvider);
    final typeFilter = ref.watch(accountTypeFilterProvider);

    final forestAsync = accountsAsync.whenData((accounts) {
      final filtered = [
        for (final account in accounts)
          if ((typeFilter == null || account.accountType == typeFilter) &&
              AccountLabels.matchesQuery(l10n, account, query))
            account,
      ];
      return AccountTreeNode.buildForest(filtered);
    });

    final visibleCount = forestAsync.maybeWhen(
      data: (roots) => _countAccounts(roots),
      orElse: () => 0,
    );

    return PopScope(
      canPop: !_searchExpanded,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          return;
        }
        _setSearchExpanded(false);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: CustomAppBar(
          title: l10n.accountingChartOfAccounts,
          showBackButton: true,
          showSearch: !_searchExpanded,
          onSearch: () => _setSearchExpanded(true),
          showCloseSearch: _searchExpanded,
          onCloseSearch: () => _setSearchExpanded(false),
          actions: [
            IconButton(
              tooltip: l10n.accountingImportTitle,
              onPressed: () => AccountingRoutes.pushAccountsImport(context),
              icon: const Icon(Icons.upload_file_outlined),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => AccountingRoutes.pushAccountsCreate(context),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.accountingAddAccount),
        ),
        body: AppContentConstraint(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            AccountExpandableSearch(
              expanded: _searchExpanded,
              onExpandedChanged: _setSearchExpanded,
              controller: _searchController,
              focusNode: _searchFocusNode,
              onQueryChanged: _onQueryChanged,
            ),
            Padding(
              padding: AppConstants.pageInsets(
                context,
              ).copyWith(top: _searchExpanded ? 0 : AppSpacing.md, bottom: 0),
              child: AccountBrowseToolbar(
                accountsCount: forestAsync.hasValue ? visibleCount : null,
                typeFilter: typeFilter,
                includeInactive: includeInactive,
                showSubtitle: !_searchExpanded,
                onTypeFilterChanged: (type) {
                  ref.read(accountTypeFilterProvider.notifier).state = type;
                },
                onIncludeInactiveChanged: (value) {
                  ref.read(accountsIncludeInactiveProvider.notifier).state =
                      value;
                },
                onExpandAll: () {
                  final roots =
                      forestAsync.valueOrNull ?? const <AccountTreeNode>[];
                  ref.read(accountTreeExpandedIdsProvider.notifier).state =
                      _allGroupIds(roots);
                },
                onCollapseAll: () {
                  ref.read(accountTreeExpandedIdsProvider.notifier).state =
                      <String>{};
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: forestAsync.when(
                loading: () => const AppLoading(),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(l10n.somethingWentWrong),
                  ),
                ),
                data: (roots) {
                  if (roots.isEmpty) {
                    final isSearchEmpty = query.trim().isEmpty;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppEmptyState(
                          title: isSearchEmpty
                              ? l10n.accountingEmptyTitle
                              : l10n.accountingNoSearchResults,
                          subtitle: isSearchEmpty
                              ? l10n.accountingEmptyMessage
                              : l10n.accountingNoSearchResultsMessage,
                          icon: Icons.account_tree_outlined,
                        ),
                        if (isSearchEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final repo = ref.read(accountRepositoryProvider);
                                await repo.seedDefaultChart();
                                ref.invalidate(accountsProvider);
                                if (context.mounted) {
                                  showAppSnackBar(
                                    context,
                                    message: l10n.accountingChartSeedSuccess,
                                    isSuccess: true,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  showAppSnackBar(
                                    context,
                                    message: e is MissingCompanyContextException
                                        ? 'يرجى اختيار وتأكيد الشركة أولاً لتوليد شجرة الحسابات'
                                        : 'فشل توليد شجرة الحسابات: $e',
                                    isSuccess: false,
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.account_tree_rounded),
                            label: Text(l10n.accountingGenerateDefaultChart),
                          ),
                        ],
                      ],
                    );
                  }
                  return AccountTree(
                    roots: roots,
                    expandedIds: expandedIds,
                    padding: AppConstants.pageInsets(
                      context,
                    ).copyWith(top: 0, bottom: 96),
                    onToggleExpand: (uuid) {
                      final next = {...expandedIds};
                      if (!next.add(uuid)) {
                        next.remove(uuid);
                      }
                      ref.read(accountTreeExpandedIdsProvider.notifier).state =
                          next;
                    },
                    onOpenDetails: (account) {
                      AccountingRoutes.pushAccountDetails(context, account.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  int _countAccounts(List<AccountTreeNode> roots) {
    var count = 0;
    void walk(AccountTreeNode node) {
      count++;
      for (final child in node.children) {
        walk(child);
      }
    }

    for (final root in roots) {
      walk(root);
    }
    return count;
  }

  Set<String> _allGroupIds(List<AccountTreeNode> roots) {
    final ids = <String>{};
    void walk(AccountTreeNode node) {
      if (node.hasChildren) {
        ids.add(node.account.uuid);
      }
      for (final child in node.children) {
        walk(child);
      }
    }

    for (final root in roots) {
      walk(root);
    }
    return ids;
  }
}
