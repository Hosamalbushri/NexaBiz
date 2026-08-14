import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../../core/database/hive_boxes.dart';
import 'company/company_profile.dart';

/// Keys used in the settings Hive box.
class SettingsKeys {
  const SettingsKeys._();

  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
  static const String dashboardServiceIds = 'dashboard_service_ids';
  static const String inventoryServiceIds = 'inventory_service_ids';
  static const String productsViewMode = 'products_view_mode';
  static const String quickActionIds = 'quick_action_ids';
  static const String accountingMode = 'accounting_mode';
  static const String accountingFiscalClosedThrough =
      'accounting_fiscal_closed_through';
  static const String customersParentAccountId = 'customers_parent_account_id';
  static const String customersAutoLinkAccount = 'customers_auto_link_account';
  static const String companyProfile = 'company_profile';
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

  /// `standalone` (default) or `integrated`.
  Future<String> loadAccountingMode() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.accountingMode) as String?;
    if (value == 'integrated' || value == 'standalone') {
      return value!;
    }
    return 'standalone';
  }

  Future<void> saveAccountingMode(String mode) async {
    final box = await _settingsBox;
    final normalized = mode == 'integrated' ? 'integrated' : 'standalone';
    await box.put(SettingsKeys.accountingMode, normalized);
  }

  /// Last closed fiscal business day (UTC date-only epoch ms), or null if none.
  Future<DateTime?> loadAccountingFiscalClosedThrough() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.accountingFiscalClosedThrough);
    if (value is! int) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  Future<void> saveAccountingFiscalClosedThrough(DateTime? day) async {
    final box = await _settingsBox;
    if (day == null) {
      await box.delete(SettingsKeys.accountingFiscalClosedThrough);
      return;
    }
    final utcDay = DateTime.utc(day.year, day.month, day.day);
    await box.put(
      SettingsKeys.accountingFiscalClosedThrough,
      utcDay.millisecondsSinceEpoch,
    );
  }

  /// Opaque Account.uuid for the Chart of Accounts parent of customer accounts.
  ///
  /// `null` means “use the system Customers account when available”.
  Future<String?> loadCustomersParentAccountId() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.customersParentAccountId) as String?;
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Future<void> saveCustomersParentAccountId(String? accountId) async {
    final box = await _settingsBox;
    final trimmed = accountId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await box.delete(SettingsKeys.customersParentAccountId);
      return;
    }
    await box.put(SettingsKeys.customersParentAccountId, trimmed);
  }

  /// When true (default), creating/updating a customer without an account link
  /// auto-creates a posting CoA account under the customers parent group.
  Future<bool> loadCustomersAutoLinkAccount() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.customersAutoLinkAccount);
    if (value is bool) {
      return value;
    }
    return true;
  }

  Future<void> saveCustomersAutoLinkAccount(bool enabled) async {
    final box = await _settingsBox;
    await box.put(SettingsKeys.customersAutoLinkAccount, enabled);
  }

  Future<CompanyProfile> loadCompanyProfile() async {
    final box = await _settingsBox;
    final raw = box.get(SettingsKeys.companyProfile);
    if (raw is Map) {
      return CompanyProfile.fromMap(Map<dynamic, dynamic>.from(raw));
    }
    return const CompanyProfile();
  }

  Future<void> saveCompanyProfile(CompanyProfile profile) async {
    final box = await _settingsBox;
    await box.put(SettingsKeys.companyProfile, profile.toMap());
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
