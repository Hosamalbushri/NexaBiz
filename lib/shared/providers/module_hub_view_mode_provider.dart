import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available view modes for module home / hub pages.
enum ModuleHubViewMode {
  grid,
  list,
}

/// Notifier managing user's preference for module hub view mode (grid vs list).
class ModuleHubViewModeNotifier extends Notifier<ModuleHubViewMode> {
  @override
  ModuleHubViewMode build() {
    return ModuleHubViewMode.grid;
  }

  void setMode(ModuleHubViewMode mode) {
    state = mode;
  }

  void toggle() {
    state = state == ModuleHubViewMode.grid
        ? ModuleHubViewMode.list
        : ModuleHubViewMode.grid;
  }
}

/// Global provider for module hub view mode.
final moduleHubViewModeProvider =
    NotifierProvider<ModuleHubViewModeNotifier, ModuleHubViewMode>(
      ModuleHubViewModeNotifier.new,
    );
