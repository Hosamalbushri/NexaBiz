import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/auth/presentation/providers/auth_state_core.dart';
import '../../../core/modules/module_providers.dart';
import '../../../core/modules/module_registry.dart';
import '../../../core/modules/quick_nav_definition.dart';
import '../../../core/tenancy/session_company.dart';
import '../../router/app_routes.dart';
import '../../settings/settings_repository.dart';
import 'dashboard_services_provider.dart';

/// Default primary Dashboard navigation item.
String _dashboardTitle(AppLocalizations l10n) => l10n.localeName == 'ar' ? 'الشاشة الرئيسية' : 'Dashboard';
String _dashboardSubtitle(AppLocalizations l10n) => l10n.localeName == 'ar' ? 'العودة للواجهة الرئيسية' : 'Exit to main home dashboard';

const kDashboardQuickNav = QuickNavDefinition(
  id: 'quick_nav_dashboard',
  icon: Icons.grid_view_rounded,
  titleBuilder: _dashboardTitle,
  subtitleBuilder: _dashboardSubtitle,
  routePath: AppRoutes.dashboard,
  isPrimary: true,
);

/// Notifier to manage user-selected quick navigation items and module section ordering with RBAC and module enablement checks.
final quickNavItemsProvider = StateNotifierProvider.autoDispose<
    QuickNavItemsController, AsyncValue<List<QuickNavDefinition>>>((ref) {
  return QuickNavItemsController(
    repository: ref.watch(settingsRepositoryProvider),
    registry: ref.watch(moduleRegistryProvider),
    companyId: ref.watch(sessionCompanyIdProvider) ?? '',
    userPermissions: ref.watch(currentPermissionsProvider),
  );
});

class QuickNavItemsController
    extends StateNotifier<AsyncValue<List<QuickNavDefinition>>> {
  QuickNavItemsController({
    required this._repository,
    required this._registry,
    required this._companyId,
    required this._userPermissions,
  })  : super(const AsyncValue.loading()) {
    _load();
  }

  final SettingsRepository _repository;
  final ModuleRegistry _registry;
  final String _companyId;
  final Set<String> _userPermissions;

  List<String> _sectionOrder = const [];

  /// Current section (module) order preferred by user.
  List<String> get currentSectionOrder => _sectionOrder;

  /// Check if a quick nav item is available based on module enablement and RBAC permissions.
  bool isItemAvailable(QuickNavDefinition item) {
    if (item.isPrimary) return true;

    // Module enablement check
    if (item.moduleId != null) {
      final module = _registry.findById(item.moduleId!);
      if (module == null || !module.isEnabled) {
        return false;
      }
      // Module required permissions check
      if (module.requiredAnyPermissions.isNotEmpty &&
          !module.requiredAnyPermissions.any(_userPermissions.contains)) {
        return false;
      }
    }

    // Item specific required permissions check
    final permissions = item.requiredPermissions;
    if (permissions != null &&
        permissions.isNotEmpty &&
        !permissions.any(_userPermissions.contains)) {
      return false;
    }

    return true;
  }

  /// Default full list of module IDs in system registration order.
  List<String> get defaultModuleSectionOrder {
    final moduleIds = <String>[];
    for (final module in _registry.enabledModules) {
      if (module.quickNavItems.isNotEmpty) {
        moduleIds.add(module.id);
      }
    }
    return ['dashboard', ...moduleIds];
  }

  /// List of all registered items (including Dashboard) that pass module enablement and RBAC permission checks,
  /// sorted according to current section order.
  List<QuickNavDefinition> get availableItems {
    final moduleNavs = _registry.allQuickNavItems;
    final all = [kDashboardQuickNav, ...moduleNavs];
    final available = [
      for (final item in all)
        if (isItemAvailable(item)) item,
    ];

    return _sortItemsBySectionOrder(available);
  }

  List<QuickNavDefinition> _sortItemsBySectionOrder(List<QuickNavDefinition> items) {
    if (_sectionOrder.isEmpty) return items;

    int sectionIndex(QuickNavDefinition item) {
      final modId = item.isPrimary ? 'dashboard' : item.moduleId;
      final idx = _sectionOrder.indexOf(modId ?? '');
      return idx == -1 ? 999 : idx;
    }

    final sorted = List<QuickNavDefinition>.from(items);
    sorted.sort((a, b) {
      final sa = sectionIndex(a);
      final sb = sectionIndex(b);
      if (sa != sb) return sa.compareTo(sb);
      return 0;
    });
    return sorted;
  }

  Future<void> _load() async {
    final savedIds = await _repository.loadQuickNavItems(_companyId);
    final savedSectionOrder = await _repository.loadQuickNavSectionOrder(_companyId);

    _sectionOrder = savedSectionOrder ?? defaultModuleSectionOrder;

    final available = availableItems;

    List<QuickNavDefinition> selected;
    if (savedIds != null && savedIds.isNotEmpty) {
      final availableMap = {for (final item in available) item.id: item};
      selected = [
        for (final id in savedIds)
          if (availableMap.containsKey(id)) availableMap[id]!,
      ];
      selected = _sortItemsBySectionOrder(selected);
    } else {
      selected = available.take(kMaxQuickNavItems).toList();
    }

    state = AsyncValue.data(selected);
  }

  /// Saves customization for selected shortcut items and/or section (module) order.
  Future<void> saveCustomization({
    List<String>? selectedIds,
    List<String>? sectionOrder,
  }) async {
    if (sectionOrder != null) {
      _sectionOrder = List<String>.from(sectionOrder);
      await _repository.saveQuickNavSectionOrder(_sectionOrder, _companyId);
    }

    final available = availableItems;
    final availableMap = {for (final item in available) item.id: item};

    List<String> targetIds;
    if (selectedIds != null) {
      targetIds = selectedIds;
    } else {
      final currentList = state.valueOrNull ?? [];
      targetIds = currentList.map((e) => e.id).toList();
    }

    final sanitizedIds = <String>[];
    final selectedItems = <QuickNavDefinition>[];

    for (final id in targetIds) {
      if (sanitizedIds.length >= kMaxQuickNavItems) break;
      if (availableMap.containsKey(id) && !sanitizedIds.contains(id)) {
        sanitizedIds.add(id);
        selectedItems.add(availableMap[id]!);
      }
    }

    final sortedItems = _sortItemsBySectionOrder(selectedItems);

    state = AsyncValue.data(sortedItems);
    await _repository.saveQuickNavItems(sanitizedIds, _companyId);
  }

  Future<void> save(List<String> selectedIds) => saveCustomization(selectedIds: selectedIds);

  Future<void> reload() => _load();
}
