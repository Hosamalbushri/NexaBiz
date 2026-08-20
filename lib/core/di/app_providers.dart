import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Synchronous startup snapshot read before the first frame.
///
/// Populated in `main()` via ProviderContainer overrides so that
/// `MaterialApp.router` renders with the correct theme/locale immediately.
class AppStartupState {
  const AppStartupState({
    required this.themeMode,
    this.locale,
    required this.isFirstLaunch,
  });

  final ThemeMode themeMode;
  final Locale? locale;

  /// `true` when the Hive settings box has no prior configuration keys,
  /// meaning this is a fresh install that has never run setup.
  final bool isFirstLaunch;
}

/// Provides the pre-loaded startup snapshot.
///
/// Overridden in `main()` so it's available synchronously. Code that needs
/// the first-launch flag watches this provider instead of doing its own
/// Hive read.
final startupStateProvider = Provider<AppStartupState>((ref) {
  // Should never be reached in production — main() always overrides.
  return const AppStartupState(
    themeMode: ThemeMode.system,
    isFirstLaunch: true,
  );
});

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

final localeProvider = StateProvider<Locale?>((ref) {
  return null;
});
