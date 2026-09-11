import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_colors.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/presentation/patterns/app_list_page_pattern.dart';
import 'package:stock_count/modules/accounting/shared/presentation/pages/accounting_routes.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/services/journal_source_category_resolver.dart';
import '../providers/journal_providers.dart';

enum AutomatedSourceCategory { all, sales, inventory, receiptsPayments }

extension AutomatedSourceCategoryX on AutomatedSourceCategory {
  String label(AppLocalizations l10n) {
    switch (this) {
      case AutomatedSourceCategory.all:
        return l10n.localeName == 'ar' ? 'جميع القيود الآلية' : 'All Automated';
      case AutomatedSourceCategory.sales:
        return l10n.moduleSales;
      case AutomatedSourceCategory.inventory:
        return l10n.moduleInventory;
      case AutomatedSourceCategory.receiptsPayments:
        return l10n.moduleReceiptsPayments;
    }
  }

  IconData get icon {
    switch (this) {
      case AutomatedSourceCategory.all:
        return Icons.auto_awesome_rounded;
      case AutomatedSourceCategory.sales:
        return Icons.shopping_bag_outlined;
      case AutomatedSourceCategory.inventory:
        return Icons.inventory_2_outlined;
      case AutomatedSourceCategory.receiptsPayments:
        return Icons.account_balance_wallet_outlined;
    }
  }

  AppStatusTone tone(ColorScheme scheme) {
    switch (this) {
      case AutomatedSourceCategory.all:
        return AppStatusTone.neutral;
      case AutomatedSourceCategory.sales:
        return AppStatusTone.success;
      case AutomatedSourceCategory.inventory:
        return AppStatusTone.warning;
      case AutomatedSourceCategory.receiptsPayments:
        return AppStatusTone.info;
    }
  }

  Color color(ColorScheme scheme) {
    switch (this) {
      case AutomatedSourceCategory.all:
        return scheme.primary;
      case AutomatedSourceCategory.sales:
        return scheme.tertiary;
      case AutomatedSourceCategory.inventory:
        return scheme.secondary;
      case AutomatedSourceCategory.receiptsPayments:
        return scheme.primary;
    }
  }
}

bool isManualJournalEntry(JournalEntryHeader entry) {
  return JournalSourceCategoryResolver.isManual(entry);
}

AutomatedSourceCategory resolveAutomatedCategory(JournalEntryHeader entry) {
  final category = JournalSourceCategoryResolver.resolve(entry);
  return switch (category) {
    JournalSourceCategory.sales => AutomatedSourceCategory.sales,
    JournalSourceCategory.inventory => AutomatedSourceCategory.inventory,
    JournalSourceCategory.receiptsPayments =>
      AutomatedSourceCategory.receiptsPayments,
    _ => AutomatedSourceCategory.all,
  };
}

/// Paginated-friendly journal entries page separated into Automated System Journals and Manual Journals.
class JournalEntriesPage extends ConsumerStatefulWidget {
  const JournalEntriesPage({super.key});

  @override
  ConsumerState<JournalEntriesPage> createState() => _JournalEntriesPageState();
}

class _JournalEntriesPageState extends ConsumerState<JournalEntriesPage> {
  static const _debounce = Duration(milliseconds: 300);

  final _searchController = TextEditingController();
  Timer? _timer;
  AutomatedSourceCategory _selectedAutoCategory = AutomatedSourceCategory.all;
  bool _isGroupedView = false;

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      ref.read(journalListQueryProvider.notifier).state = value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    final entriesAsync = ref.watch(journalEntriesProvider);
    final dateFormat = DateFormat.yMMMd();

    return DefaultTabController(
      length: 2,
      child: AppListPagePattern<JournalEntryHeader>(
        title: l10n.accountingJournalsTitle,
        searchController: _searchController,
        searchHint: l10n.accountingJournalsSearchHint,
        onSearchChanged: _onSearch,
        isLoading: entriesAsync.isLoading && !entriesAsync.hasValue,
        errorText: entriesAsync.error?.toString(),
        onRetry: () => ref.invalidate(journalEntriesProvider),
        emptyTitle: l10n.accountingJournalsEmptyTitle,
        emptySubtitle: l10n.accountingJournalsEmptyMessage,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => AccountingRoutes.pushJournalCreate(context),
          icon: const Icon(Icons.add_rounded),
          label: Text(isAr ? 'إضافة قيد يدوي' : 'Add Manual Entry'),
        ),
        items: entriesAsync.valueOrNull ?? const [],
        contentBuilder: (context, allEntries) {
          // Split manual vs automated entries
          final manualEntries = allEntries.where(isManualJournalEntry).toList();
          final autoEntries = allEntries
              .where((e) => !isManualJournalEntry(e))
              .toList();

          return Column(
            children: [
              TabBar(
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 13.5,
                ),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    text: isAr ? 'القيود اليومية واليدوية' : 'Daily & Manual',
                  ),
                  Tab(
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    text: isAr ? 'القيود الآلية (النظام)' : 'Automated System',
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 0 (Primary): Manual & Daily Journals
                    _buildManualTab(
                      context: context,
                      manualEntries: manualEntries,
                      isAr: isAr,
                      dateFormat: dateFormat,
                    ),

                    // Tab 1: Automated System Journals
                    _buildAutomatedTab(
                      context: context,
                      autoEntries: autoEntries,
                      isAr: isAr,
                      dateFormat: dateFormat,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAutomatedTab({
    required BuildContext context,
    required List<JournalEntryHeader> autoEntries,
    required bool isAr,
    required DateFormat dateFormat,
  }) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (autoEntries.isEmpty) {
      return AppEmptyState(
        title: isAr ? 'لا توجد قيود آلية' : 'No Automated Journals',
        subtitle: isAr
            ? 'لم يتم توليد أي قيود آلية من العمليات (مبيعات، مخزون، نقدية)'
            : 'No automated journals have been generated yet.',
        icon: Icons.auto_awesome_rounded,
      );
    }

    // Group automated entries
    final groupedAuto = <AutomatedSourceCategory, List<JournalEntryHeader>>{
      AutomatedSourceCategory.sales: [],
      AutomatedSourceCategory.inventory: [],
      AutomatedSourceCategory.receiptsPayments: [],
    };

    for (final e in autoEntries) {
      final cat = resolveAutomatedCategory(e);
      if (groupedAuto.containsKey(cat)) {
        groupedAuto[cat]!.add(e);
      } else {
        groupedAuto[AutomatedSourceCategory.sales]!.add(e);
      }
    }

    return Column(
      children: [
        // Controls bar: Category filter chips + toggle view
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: AutomatedSourceCategory.values.map((cat) {
                      final isSelected = _selectedAutoCategory == cat;
                      final color = cat.color(colorScheme);
                      final count = cat == AutomatedSourceCategory.all
                          ? autoEntries.length
                          : (groupedAuto[cat]?.length ?? 0);

                      return Padding(
                        padding: const EdgeInsetsDirectional.only(start: 6.0),
                        child: FilterChip(
                          selected: isSelected,
                          avatar: CircleAvatar(
                            backgroundColor: isSelected
                                ? Colors.white.withValues(alpha: 0.2)
                                : color.withValues(alpha: 0.15),
                            child: Icon(
                              cat.icon,
                              size: 14,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                          label: Text('${cat.label(l10n)} ($count)'),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : colorScheme.onSurface,
                          ),
                          selectedColor: color,
                          backgroundColor: color.withValues(alpha: 0.08),
                          side: BorderSide(
                            color: isSelected
                                ? color
                                : color.withValues(alpha: 0.3),
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedAutoCategory = cat;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                tooltip: _isGroupedView
                    ? (isAr ? 'قائمة واحدة' : 'List View')
                    : (isAr ? 'تجميع حسب المصدر' : 'Grouped View'),
                icon: Icon(
                  _isGroupedView
                      ? Icons.view_list_rounded
                      : Icons.account_tree_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _isGroupedView = !_isGroupedView;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // List View or Grouped View
        Expanded(
          child: _isGroupedView
              ? _buildGroupedAutoView(
                  context: context,
                  groupedAuto: groupedAuto,
                  isAr: isAr,
                  dateFormat: dateFormat,
                )
              : _buildListAutoView(
                  context: context,
                  autoEntries: autoEntries,
                  groupedAuto: groupedAuto,
                  isAr: isAr,
                  dateFormat: dateFormat,
                ),
        ),
      ],
    );
  }

  Widget _buildListAutoView({
    required BuildContext context,
    required List<JournalEntryHeader> autoEntries,
    required Map<AutomatedSourceCategory, List<JournalEntryHeader>> groupedAuto,
    required bool isAr,
    required DateFormat dateFormat,
  }) {
    final l10n = AppLocalizations.of(context);
    final filtered = _selectedAutoCategory == AutomatedSourceCategory.all
        ? autoEntries
        : (groupedAuto[_selectedAutoCategory] ?? []);

    if (filtered.isEmpty) {
      return AppEmptyState(
        title: isAr ? 'لا توجد قيود' : 'No entries',
        subtitle: isAr
            ? 'لا توجد قيود آلية ضمن تصنيف ${_selectedAutoCategory.label(l10n)}'
            : 'No automated entries under ${_selectedAutoCategory.label(l10n)}',
        icon: _selectedAutoCategory.icon,
      );
    }

    return ListView.separated(
      padding: AppConstants.pageInsets(context).copyWith(bottom: 96),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final entry = filtered[index];
        final cat = resolveAutomatedCategory(entry);
        return _JournalHeaderTile(
          entry: entry,
          icon: cat.icon,
          badgeColor: cat.color(Theme.of(context).colorScheme),
          dateLabel: dateFormat.format(entry.entryDate.toLocal()),
          onTap: () => AccountingRoutes.pushJournalDetails(context, entry.uuid),
        );
      },
    );
  }

  Widget _buildGroupedAutoView({
    required BuildContext context,
    required Map<AutomatedSourceCategory, List<JournalEntryHeader>> groupedAuto,
    required bool isAr,
    required DateFormat dateFormat,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeCategories = AutomatedSourceCategory.values
        .where(
          (c) =>
              c != AutomatedSourceCategory.all &&
              (groupedAuto[c]?.isNotEmpty ?? false),
        )
        .toList();

    if (activeCategories.isEmpty) {
      return AppEmptyState(
        title: isAr ? 'لا توجد قيود آلية' : 'No automated entries',
        subtitle: isAr
            ? 'لم تنشأ أي قيود آليه حتى الآن'
            : 'No entries generated yet.',
        icon: Icons.auto_awesome_rounded,
      );
    }

    return ListView.builder(
      padding: AppConstants.pageInsets(context).copyWith(bottom: 96),
      itemCount: activeCategories.length,
      itemBuilder: (context, idx) {
        final cat = activeCategories[idx];
        final catEntries = groupedAuto[cat]!;
        final catColor = cat.color(colorScheme);

        return _AutomatedCategoryCard(
          category: cat,
          entries: catEntries,
          catColor: catColor,
          isAr: isAr,
          dateFormat: dateFormat,
        );
      },
    );
  }

  Widget _buildManualTab({
    required BuildContext context,
    required List<JournalEntryHeader> manualEntries,
    required bool isAr,
    required DateFormat dateFormat,
  }) {
    final theme = Theme.of(context);
    final manualColor = AppColors.tertiaryIndigo;

    if (manualEntries.isEmpty) {
      return AppEmptyState(
        title: isAr ? 'لا توجد قيود يدويّة' : 'No Manual Entries',
        subtitle: isAr
            ? 'يمكنك إضافة قيد محاسبي يدوي جديد بالنقر على زر (إضافة قيد يدوي)'
            : 'Click "+ Add Manual Entry" to record manual journal entries.',
        icon: Icons.edit_note_rounded,
      );
    }

    final totalManualAmount = manualEntries.fold(
      0.0,
      (sum, e) => sum + e.totalDebit,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Summary Bar
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: manualColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: manualColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.edit_note_rounded, color: manualColor, size: 22),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${isAr ? 'عدد القيود اليدوية' : 'Total Manual Entries'}: ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${manualEntries.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: manualColor,
                ),
              ),
              const Spacer(),
              Text(
                '${totalManualAmount.toStringAsFixed(2)} SAR',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: manualColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        Expanded(
          child: ListView.separated(
            padding: AppConstants.pageInsets(context).copyWith(bottom: 96),
            itemCount: manualEntries.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final entry = manualEntries[index];
              return _JournalHeaderTile(
                entry: entry,
                icon: Icons.edit_note_rounded,
                badgeColor: manualColor,
                dateLabel: dateFormat.format(entry.entryDate.toLocal()),
                onTap: () =>
                    AccountingRoutes.pushJournalDetails(context, entry.uuid),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AutomatedCategoryCard extends StatefulWidget {
  const _AutomatedCategoryCard({
    required this.category,
    required this.entries,
    required this.catColor,
    required this.isAr,
    required this.dateFormat,
  });

  final AutomatedSourceCategory category;
  final List<JournalEntryHeader> entries;
  final Color catColor;
  final bool isAr;
  final DateFormat dateFormat;

  @override
  State<_AutomatedCategoryCard> createState() => _AutomatedCategoryCardState();
}

class _AutomatedCategoryCardState extends State<_AutomatedCategoryCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalDebit = widget.entries.fold(0.0, (sum, e) => sum + e.totalDebit);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: widget.catColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: shadcn.Collapsible(
            isExpanded: _expanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _expanded = !expanded;
              });
            },
            children: [
              shadcn.CollapsibleTrigger(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: widget.catColor.withValues(alpha: 0.12),
                        child: Icon(widget.category.icon, color: widget.catColor, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.category.label(l10n),
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: widget.catColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.catColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${widget.entries.length}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: widget.catColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.isAr ? 'إجمالي المبالغ' : 'Total Amount'}: ${totalDebit.toStringAsFixed(2)} SAR',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              shadcn.CollapsibleContent(
                child: Column(
                  children: widget.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      child: _JournalHeaderTile(
                        entry: entry,
                        icon: widget.category.icon,
                        badgeColor: widget.catColor,
                        dateLabel: widget.dateFormat.format(entry.entryDate.toLocal()),
                        onTap: () => AccountingRoutes.pushJournalDetails(
                          context,
                          entry.uuid,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JournalHeaderTile extends StatelessWidget {
  const _JournalHeaderTile({
    required this.entry,
    required this.icon,
    required this.badgeColor,
    required this.dateLabel,
    required this.onTap,
  });

  final JournalEntryHeader entry;
  final IconData icon;
  final Color badgeColor;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label:
          '${entry.voucherNumber}, ${entry.voucherType}, $dateLabel, ${l10n.accountingJournalDebit}: ${entry.totalDebit.toStringAsFixed(2)}, ${l10n.accountingJournalCredit}: ${entry.totalCredit.toStringAsFixed(2)}',
      hint: l10n.accountingJournalDetails,
      button: true,
      child: AppSurface(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Icon(icon, size: 16, color: badgeColor),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    entry.voucherNumber,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                AppStatusBadge(
                  label: entry.isPosted
                      ? l10n.accountingJournalPosted
                      : l10n.accountingJournalUnposted,
                  tone: entry.isPosted
                      ? AppStatusTone.success
                      : AppStatusTone.warning,
                  animate: false,
                ),
              ],
            ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.voucherType,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '·  $dateLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (entry.description != null &&
                      entry.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      entry.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${l10n.accountingJournalDebit}: ${entry.totalDebit.toStringAsFixed(2)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${l10n.accountingJournalCredit}: ${entry.totalCredit.toStringAsFixed(2)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        entry.currencyCode,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
