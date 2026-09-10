import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../../settings/settings_repository.dart';
import 'dashboard_services_provider.dart';

/// State representation of quick navigation user settings.
class QuickNavSettingsState {
  const QuickNavSettingsState({
    required this.enabled,
    this.position,
  });

  final bool enabled;
  final Offset? position;

  QuickNavSettingsState copyWith({
    bool? enabled,
    Offset? position,
    bool clearPosition = false,
  }) {
    return QuickNavSettingsState(
      enabled: enabled ?? this.enabled,
      position: clearPosition ? null : (position ?? this.position),
    );
  }
}

/// Notifier to manage persistent quick nav settings (enable/disable & position X, Y).
class QuickNavSettingsNotifier extends StateNotifier<QuickNavSettingsState> {
  QuickNavSettingsNotifier(this._repository)
      : super(const QuickNavSettingsState(enabled: true)) {
    loadSettings();
  }

  final SettingsRepository _repository;

  Future<void> loadSettings() async {
    try {
      final enabled = await _repository.loadQuickNavEnabled().catchError((_, __) => true);
      final position = await _repository.loadQuickNavPosition().catchError((_, __) => null);
      state = QuickNavSettingsState(enabled: enabled, position: position);
    } catch (_) {
      // Safe fallback when running in uninitialized or unit test environments
    }
  }

  Future<void> toggleEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await _repository.saveQuickNavEnabled(enabled);
  }

  Future<void> updatePosition(double x, double y) async {
    final newPos = Offset(x, y);
    state = state.copyWith(position: newPos);
    await _repository.saveQuickNavPosition(x, y);
  }

  Future<void> resetPosition() async {
    state = state.copyWith(clearPosition: true);
    await _repository.saveQuickNavPosition(null, null);
  }
}

/// Global provider for quick navigation floating button settings.
final quickNavSettingsProvider =
    StateNotifierProvider<QuickNavSettingsNotifier, QuickNavSettingsState>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return QuickNavSettingsNotifier(repository);
});
