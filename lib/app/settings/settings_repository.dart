import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../../core/database/hive_boxes.dart';

/// Keys used in the settings Hive box.
class SettingsKeys {
  const SettingsKeys._();

  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
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
