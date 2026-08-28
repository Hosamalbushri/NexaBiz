import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/utils/digit_normalization.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/services/account_labels.dart';
import '../providers/account_providers.dart';
import 'account_type_style.dart';

/// Shows the [AccountSearchPickerSheet] as a bottom sheet.
Future<Account?> showAccountSearchPicker(
  BuildContext context, {
  String? title,
  AccountType? initialTypeFilter,
  bool postingOnlyDefault = true,
  String? selectedUuid,
}) {
  return showModalBottomSheet<Account>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AccountSearchPickerSheet(
      title: title,
      initialTypeFilter: initialTypeFilter,
      postingOnlyDefault: postingOnlyDefault,
      selectedUuid: selectedUuid,
    ),
  );
}

/// Modal bottom sheet container for Chart of Accounts search & selection.
class AccountSearchPickerSheet extends StatelessWidget {
  const AccountSearchPickerSheet({
    super.key,
    this.title,
    this.initialTypeFilter,
    this.postingOnlyDefault = true,
    this.selectedUuid,
  });

  final String? title;
  final AccountType? initialTypeFilter;
  final bool postingOnlyDefault;
  final String? selectedUuid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.85;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sheet Drag Handle
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 38,
            height: 4.5,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Header Title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.account_tree_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title ?? l10n.accountingChartOfAccounts,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Core Search & Picker Body
          Expanded(
            child: AccountSearchPicker(
              initialTypeFilter: initialTypeFilter,
              postingOnlyDefault: postingOnlyDefault,
              selectedUuid: selectedUuid,
              onAccountSelected: (account) {
                Navigator.of(context).pop(account);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone / Embedded Chart of Accounts search & list component.
class AccountSearchPicker extends ConsumerStatefulWidget {
  const AccountSearchPicker({
    super.key,
    this.initialTypeFilter,
    this.postingOnlyDefault = false,
    this.selectedUuid,
    this.onAccountSelected,
  });

  final AccountType? initialTypeFilter;
  final bool postingOnlyDefault;
  final String? selectedUuid;
  final ValueChanged<Account>? onAccountSelected;

  @override
  ConsumerState<AccountSearchPicker> createState() =>
      _AccountSearchPickerState();
}

class _AccountSearchPickerState extends ConsumerState<AccountSearchPicker> {
  static const _searchDebounce = Duration(milliseconds: 250);

  late final TextEditingController _searchController;
  final _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  String _searchQuery = '';
  AccountType? _selectedType;
  late bool _postingOnly;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedType = widget.initialTypeFilter;
    _postingOnly = widget.postingOnlyDefault;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      setState(() {
        _searchQuery = normalizeDigitsToWestern(value).trim();
      });
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final accountsAsync = ref.watch(allAccountsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Search Bar & Filters Section
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              bottom: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Column(
            children: [
              // Search Input Field
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                inputFormatters: const [WesternDigitsInputFormatter()],
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'البحث باسم الحساب، الكود، أو الحساب الأب...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: scheme.primary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel_rounded, size: 18),
                          onPressed: _clearSearch,
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: scheme.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Filter Chips: Account Types & Posting Toggle
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // All Types Chip
                    FilterChip(
                      selected: _selectedType == null,
                      label: const Text('الكل'),
                      labelStyle: TextStyle(
                        fontWeight: _selectedType == null
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: _selectedType == null
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                      ),
                      selectedColor: scheme.primary,
                      backgroundColor:
                          scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _selectedType = null),
                    ),
                    const SizedBox(width: AppSpacing.xs),

                    // Account Type Filter Chips
                    for (final type in AccountType.values) ...[
                      _AccountTypeFilterChip(
                        type: type,
                        selected: _selectedType == type,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = selected ? type : null;
                          });
                        },
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Posting Accounts Only Switch Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'حسابات الترحيل فقط (المسموح بالقيد عليها)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: _postingOnly,
                      onChanged: (val) => setState(() => _postingOnly = val),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Accounts List View Section
        Expanded(
          child: accountsAsync.when(
            loading: () => const AppLoading(),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text('حدث خطأ أثناء تحميل الحسابات: $err'),
              ),
            ),
            data: (allAccounts) {
              // 1. Build lookup map for parent hierarchy path
              final uuidMap = {for (final a in allAccounts) a.uuid: a};

              // 2. Filter accounts across entire chart
              final filtered = allAccounts.where((account) {
                if (account.isDeleted) return false;
                if (_postingOnly && !account.isPostingAccount) return false;
                if (_selectedType != null &&
                    account.accountType != _selectedType) {
                  return false;
                }
                if (_searchQuery.isNotEmpty) {
                  final codeMatch = account.accountCode
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                  final nameMatch = AccountLabels.matchesQuery(
                    l10n,
                    account,
                    _searchQuery,
                  );
                  final descMatch = account.description != null &&
                      account.description!
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                  if (!codeMatch && !nameMatch && !descMatch) {
                    return false;
                  }
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return AppEmptyState(
                  title: l10n.accountingNoSearchResults,
                  subtitle: 'لم يتم العثور على حسابات تطابق معايير البحث',
                  icon: Icons.search_off_rounded,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.xs + 2),
                itemBuilder: (context, index) {
                  final account = filtered[index];
                  final isSelected = account.uuid == widget.selectedUuid;
                  final pathText = _buildBreadcrumbPath(account, uuidMap, l10n);

                  final cardWidget = _AccountResultCard(
                    account: account,
                    breadcrumbPath: pathText,
                    isSelected: isSelected,
                    onTap: () {
                      if (widget.onAccountSelected != null) {
                        widget.onAccountSelected!(account);
                      }
                    },
                  );

                  if (index < 12) {
                    return cardWidget
                        .animate(delay: (20 * (index % 12)).ms)
                        .fadeIn(duration: 180.ms)
                        .moveY(begin: 6, end: 0, duration: 200.ms);
                  }

                  return cardWidget;
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _buildBreadcrumbPath(
    Account account,
    Map<String, Account> uuidMap,
    AppLocalizations l10n,
  ) {
    final parts = <String>[];
    var currentParentId = account.parentId;

    while (currentParentId != null && uuidMap.containsKey(currentParentId)) {
      final parent = uuidMap[currentParentId]!;
      parts.insert(0, AccountLabels.displayName(l10n, parent));
      currentParentId = parent.parentId;
    }

    if (parts.isEmpty) return '';
    return parts.join(' ➔ ');
  }
}

class _AccountTypeFilterChip extends StatelessWidget {
  const _AccountTypeFilterChip({
    required this.type,
    required this.selected,
    required this.onSelected,
  });

  final AccountType type;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = accountTypeColor(theme.colorScheme, type);

    return FilterChip(
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(accountTypeIcon(type), size: 14, color: selected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(AccountLabels.typeLabel(l10n, type)),
        ],
      ),
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        color: selected ? Colors.white : theme.colorScheme.onSurface,
        fontSize: 12,
      ),
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.12),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      onSelected: onSelected,
    );
  }
}

class _AccountResultCard extends StatelessWidget {
  const _AccountResultCard({
    required this.account,
    required this.breadcrumbPath,
    required this.isSelected,
    required this.onTap,
  });

  final Account account;
  final String breadcrumbPath;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final typeColor = accountTypeColor(scheme, account.accountType);

    return Material(
      color: isSelected
          ? scheme.primaryContainer.withValues(alpha: 0.35)
          : scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.45),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Account Type Color Indicator Strip
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),

              // Account Details & Breadcrumb
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (breadcrumbPath.isNotEmpty) ...[
                      Text(
                        breadcrumbPath,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      AccountLabels.displayName(l10n, account),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: account.isActive
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AccountLabels.typeLabel(l10n, account.accountType),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: typeColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        if (account.isGroup)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'حساب رئيسي',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'حساب فرعي (مفرّحل)',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Tabular Monospace Code Badge
              Container(
                constraints: const BoxConstraints(minWidth: 42),
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: typeColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  account.accountCode,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: typeColor,
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
