import 'package:flutter/material.dart';

import '../../../core/modules/quick_nav_definition.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../providers/quick_nav_items_provider.dart';

/// Structured result returned from customization sheet.
class QuickNavCustomizationResult {
  const QuickNavCustomizationResult({
    required this.selectedIds,
    required this.sectionOrder,
  });

  final List<String> selectedIds;
  final List<String> sectionOrder;
}

/// Modal bottom sheet to customize section module order and choose/reorder quick navigation shortcuts.
class QuickNavCustomizeSheet extends StatefulWidget {
  const QuickNavCustomizeSheet({
    super.key,
    required this.availableItems,
    required this.initiallySelectedIds,
    required this.initialSectionOrder,
  });

  final List<QuickNavDefinition> availableItems;
  final List<String> initiallySelectedIds;
  final List<String> initialSectionOrder;

  static Future<QuickNavCustomizationResult?> show(
    BuildContext context, {
    required List<QuickNavDefinition> availableItems,
    required List<String> initiallySelectedIds,
    required List<String> initialSectionOrder,
  }) {
    return showModalBottomSheet<QuickNavCustomizationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.of(ctx).padding.bottom + AppSpacing.md,
          ),
          child: QuickNavCustomizeSheet(
            availableItems: availableItems,
            initiallySelectedIds: initiallySelectedIds,
            initialSectionOrder: initialSectionOrder,
          ),
        ),
      ),
    );
  }

  @override
  State<QuickNavCustomizeSheet> createState() => _QuickNavCustomizeSheetState();
}

class _QuickNavCustomizeSheetState extends State<QuickNavCustomizeSheet> {
  late List<String> _selectedIds;
  late List<String> _sectionOrder;

  @override
  void initState() {
    super.initState();
    _selectedIds = List<String>.from(widget.initiallySelectedIds)
        .take(kMaxQuickNavItems)
        .toList(growable: true);
    _sectionOrder = List<String>.from(widget.initialSectionOrder);
  }

  void _toggle(QuickNavDefinition item) {
    if (_selectedIds.contains(item.id)) {
      setState(() => _selectedIds.remove(item.id));
      return;
    }
    if (_selectedIds.length >= kMaxQuickNavItems) {
      showAppSnackBar(
        context,
        message: 'عذراً، الحد الأقصى للاختصارات السريعة هو $kMaxQuickNavItems',
        isSuccess: false,
      );
      return;
    }
    setState(() => _selectedIds.add(item.id));
  }

  void _onReorderItems(int oldIndex, int newIndex) {
    setState(() {
      var targetIndex = newIndex;
      if (oldIndex < targetIndex) {
        targetIndex -= 1;
      }
      final id = _selectedIds.removeAt(oldIndex);
      _selectedIds.insert(targetIndex, id);
    });
  }

  void _onReorderSections(int oldIndex, int newIndex) {
    setState(() {
      var targetIndex = newIndex;
      if (oldIndex < targetIndex) {
        targetIndex -= 1;
      }
      final modId = _sectionOrder.removeAt(oldIndex);
      _sectionOrder.insert(targetIndex, modId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    final atLimit = _selectedIds.length >= kMaxQuickNavItems;

    final byId = {
      for (final item in widget.availableItems) item.id: item,
    };
    final selected = [
      for (final id in _selectedIds)
        if (byId[id] != null) byId[id]!,
    ];
    final unselected = [
      for (final item in widget.availableItems)
        if (!_selectedIds.contains(item.id)) item,
    ];

    // Group unselected by moduleId
    final unselectedGrouped = <String?, List<QuickNavDefinition>>{};
    for (final item in unselected) {
      final modId = item.isPrimary ? 'dashboard' : item.moduleId;
      unselectedGrouped.putIfAbsent(modId, () => []).add(item);
    }

    return DefaultTabController(
      length: 2,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.tune_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr
                            ? 'تخصيص التنقل السريع والأقسام'
                            : 'Customize Quick Nav & Sections',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isAr
                            ? 'ترتيب الأقسام والاختصارات المحفوظة'
                            : 'Order sections & manage pinned shortcuts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            TabBar(
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              tabs: [
                Tab(
                  icon: const Icon(Icons.reorder_rounded, size: 18),
                  text: isAr ? 'ترتيب الأقسام' : 'Section Order',
                ),
                Tab(
                  icon: const Icon(Icons.star_outline_rounded, size: 18),
                  text: isAr ? 'اختيار الاختصارات' : 'Select Shortcuts',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Section Order
                  _buildSectionOrderTab(context, colorScheme, theme, isAr),
                  // Tab 2: Shortcuts Customization
                  _buildShortcutsTab(
                    context,
                    colorScheme,
                    theme,
                    isAr,
                    atLimit,
                    selected,
                    unselectedGrouped,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: isAr ? 'حفظ التخصيص وترتيب الأقسام' : 'Save Customization & Order',
              expand: true,
              onPressed: () {
                Navigator.pop(
                  context,
                  QuickNavCustomizationResult(
                    selectedIds: List<String>.from(_selectedIds),
                    sectionOrder: List<String>.from(_sectionOrder),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionOrderTab(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
    bool isAr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            isAr
                ? 'اسحب القسم لأعلى أو أسفل لتقديم أو تأخير ظهوره (مثال: تقديم المحاسبة على المبيعات)'
                : 'Drag sections up or down to reorder them (e.g. Move Accounting above Sales)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            itemCount: _sectionOrder.length,
            onReorder: _onReorderSections,
            itemBuilder: (context, index) {
              final modId = _sectionOrder[index];
              return Material(
                key: ValueKey<String>(modId),
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        _getModuleIcon(modId),
                        size: 18,
                        color: colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      _getModuleName(modId, isAr),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      isAr ? 'الترتيب الحادي: #${index + 1}' : 'Priority Position: #${index + 1}',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.xs),
                        child: Icon(Icons.drag_handle_rounded),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutsTab(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
    bool isAr,
    bool atLimit,
    List<QuickNavDefinition> selected,
    Map<String?, List<QuickNavDefinition>> unselectedGrouped,
  ) {
    return ListView(
      children: [
        Text(
          isAr
              ? 'المثبتة حالياً: ${_selectedIds.length} من $kMaxQuickNavItems'
              : 'Pinned: ${_selectedIds.length} of $kMaxQuickNavItems',
          style: theme.textTheme.labelMedium?.copyWith(
            color: atLimit ? colorScheme.error : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (selected.isNotEmpty) ...[
          Text(
            isAr ? 'الاختصارات المثبتة (اسحب للتغيير)' : 'Pinned Shortcuts (Drag to reorder)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: selected.length,
            onReorder: _onReorderItems,
            itemBuilder: (context, index) {
              final item = selected[index];
              return Material(
                key: ValueKey<String>('sel_${item.id}'),
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(item.icon, color: colorScheme.primary),
                    title: Text(
                      item.title(context),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: isAr ? 'إزالة' : 'Remove',
                          onPressed: () => _toggle(item),
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: colorScheme.error,
                          ),
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.all(AppSpacing.xs),
                            child: Icon(Icons.drag_handle_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        if (unselectedGrouped.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            isAr ? 'الاختصارات المتاحة للإضافة (مقسمة بالأقسام)' : 'Available Shortcuts to Add (By Module)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final entry in unselectedGrouped.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                _getModuleName(entry.key, isAr),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            for (final item in entry.value)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: ListTile(
                  enabled: !atLimit,
                  leading: Icon(
                    item.icon,
                    color: atLimit
                        ? colorScheme.onSurface.withValues(alpha: 0.38)
                        : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(item.title(context)),
                  subtitle: Text(
                    item.subtitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: isAr ? 'إضافة' : 'Add',
                    onPressed: atLimit ? null : () => _toggle(item),
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }

  IconData _getModuleIcon(String? moduleId) {
    switch (moduleId) {
      case 'sales':
        return Icons.shopping_bag_outlined;
      case 'inventory':
        return Icons.inventory_2_outlined;
      case 'accounting':
        return Icons.account_balance_outlined;
      case 'receipts_payments':
        return Icons.payments_outlined;
      case 'customers':
        return Icons.people_outline;
      case 'reports':
        return Icons.bar_chart_outlined;
      default:
        return Icons.grid_view_rounded;
    }
  }

  String _getModuleName(String? moduleId, bool isAr) {
    switch (moduleId) {
      case 'sales':
        return isAr ? 'المبيعات' : 'Sales';
      case 'inventory':
        return isAr ? 'المخزون' : 'Inventory';
      case 'accounting':
        return isAr ? 'المحاسبة' : 'Accounting';
      case 'receipts_payments':
        return isAr ? 'المقبوضات والمدفوعات' : 'Receipts & Payments';
      case 'customers':
        return isAr ? 'العملاء' : 'Customers';
      case 'reports':
        return isAr ? 'التقارير' : 'Reports';
      case 'dashboard':
      default:
        return isAr ? 'الرئيسية والخروج' : 'Main & Exit';
    }
  }
}
