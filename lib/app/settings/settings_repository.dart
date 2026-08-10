import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../../core/database/hive_boxes.dart';

/// Keys used in the settings Hive box.
class SettingsKeys {
  const SettingsKeys._();

  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
  static const String dashboardServiceIds = 'dashboard_service_ids';
  static const String inventoryServiceIds = 'inventory_service_ids';
  static const String productsViewMode = 'products_view_mode';
  static const String quickActionIds = 'quick_action_ids';
}

/// Persists and loads platform settings from Hive.
class SettingsRepository {
  SettingsRepository({Box<dynamic>? box}) : _box = box;

  Box<dynamic>? _box;

  Future<Box<dynamic>> get _settingsBox async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox<dynamic>(HiveBoxes.settings);
    return _box!;
  }

  Future<ThemeMode> loadThemeMode() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.themeMode) as String?;
    return _themeModeFromString(value) ?? ThemeMode.system;
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final box = await _settingsBox;
    await box.put(SettingsKeys.themeMode, themeMode.name);
  }

  Future<Locale?> loadLocale() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.locale) as String?;
    if (value == null) {
      return null;
    }
    if (value == AppConstants.englishLocale.languageCode) {
      return AppConstants.englishLocale;
    }
    if (value == AppConstants.arabicLocale.languageCode) {
      return AppConstants.arabicLocale;
    }
    return null;
  }

  Future<void> saveLocale(Locale? locale) async {
    final box = await _settingsBox;
    if (locale == null) {
      await box.delete(SettingsKeys.locale);
      return;
    }
    await box.put(SettingsKeys.locale, locale.languageCode);
  }

  /// Returns `null` when the user has never customized the dashboard.
  Future<List<String>?> loadDashboardServiceIds() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.dashboardServiceIds);
    if (value == null) {
      return null;
    }
    if (value is List) {
      return [
        for (final item in value)
          if (item is String && item.isNotEmpty) item,
      ];
    }
    return const [];
  }

  Future<void> saveDashboardServiceIds(List<String> ids) async {
    final box = await _settingsBox;
    await box.put(SettingsKeys.dashboardServiceIds, ids);
  }

  /// Returns `null` when the user has never customized inventory services.
  Future<List<String>?> loadInventoryServiceIds() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.inventoryServiceIds);
    if (value == null) {
      return null;
    }
    if (value is List) {
      return [
        for (final item in value)
          if (item is String && item.isNotEmpty) item,
      ];
    }
    return const [];
  }

  Future<void> saveInventoryServiceIds(List<String> ids) async {
    final box = await _settingsBox;
    await box.put(SettingsKeys.inventoryServiceIds, ids);
  }

  /// `list` (default) or `grid`.
  Future<String> loadProductsViewMode() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.productsViewMode) as String?;
    if (value == 'grid' || value == 'list') {
      return value!;
    }
    return 'list';
  }

  Future<void> saveProductsViewMode(String mode) async {
    final box = await _settingsBox;
    await box.put(SettingsKeys.productsViewMode, mode);
  }

  /// Returns `null` when the user has never customized quick actions.
  Future<List<String>?> loadQuickActionIds() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.quickActionIds);
    if (value == null) {
      return null;
    }
    if (value is List) {
      return [
        for (final item in value)
          if (item is String && item.isNotEmpty) item,
      ];
    }
    return const [];
  }

  Future<void> saveQuickActionIds(List<String> ids) async {
    final box = await _settingsBox;
    await box.put(SettingsKeys.quickActionIds, ids);
  }

  Future<void> resetSettings() async {
    final settingsBox = await _settingsBox;
    await settingsBox.clear();
  }

  ThemeMode? _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }
}
