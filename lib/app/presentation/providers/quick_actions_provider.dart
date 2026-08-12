import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/settings_repository.dart';
import '../models/quick_action_definition.dart';
import 'dashboard_services_provider.dart';

/// Ordered quick-action ids pinned on the shell add sheet.
///
/// Defaults to [defaultQuickActionIds] until the user customizes.
final quickActionsProvider =
    StateNotifierProvider<QuickActionsController, AsyncValue<List<String>>>((
      ref,
    ) {
      return QuickActionsController(
        repository: ref.watch(settingsRepositoryProvider),
      );
    });

class QuickActionsController extends StateNotifier<AsyncValue<List<String>>> {
  QuickActionsController({required SettingsRepository repository})
    : _repository = repository,
      super(const AsyncValue.loading()) {
    _load();
  }

  final SettingsRepository _repository;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final saved = await _repository.loadQuickActionIds();
      return _sanitize(saved ?? defaultQuickActionIds());
    });
  }

  List<String> _sanitize(List<String> ids) {
    final known = {for (final action in quickActionCatalog()) action.id};
    final seen = <String>{};
    final result = <String>[];
    for (final id in ids) {
      if (known.contains(id) && seen.add(id)) {
        result.add(id);
        if (result.length >= kMaxQuickActions) {
          break;
        }
      }
    }
    return result;
  }

  List<QuickActionDefinition> resolveActions() {
    final ids = state.valueOrNull ?? defaultQuickActionIds();
    final actions = <QuickActionDefinition>[];
    for (final id in ids) {
      final action = findQuickActionById(id);
      if (action != null) {
        actions.add(action);
      }
    }
    return actions;
  }

  Future<void> save(List<String> ids) async {
    final sanitized = _sanitize(ids);
    state = AsyncValue.data(sanitized);
    await _repository.saveQuickActionIds(sanitized);
  }

  Future<void> reload() => _load();
}
