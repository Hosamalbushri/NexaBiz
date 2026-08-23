import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../../core/database/hive_boxes.dart';
import '../../core/utils/id_generator.dart';
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
  static const String systemSetupVersion = 'system_setup_version';
  static const String systemSetupStatus = 'system_setup_status';
  static const String systemSetupSteps = 'system_setup_steps';
  static const String systemSetupLastUpdated = 'system_setup_last_updated';
  /// When true, company default currency cannot be changed.
  static const String systemBaseCurrencyLocked = 'system_base_currency_locked';
  /// Stable per-install device id for experimental multi-device sync.
  static const String syncDeviceId = 'sync_device_id';
  /// When false (default), the app runs fully local — no auto/manual sync.
  static const String syncEnabled = 'sync_enabled';
  /// User-entered sync server base URL (e.g. http://192.168.1.10:8000).
  static const String syncServerBaseUrl = 'sync_server_base_url';
  /// Optional API token for the sync server.
  static const String syncServerToken = 'sync_server_token';
  /// When true, sync runs automatically in the background (queue / interval).
  static const String syncAutoEnabled = 'sync_auto_enabled';
  /// Auto-sync interval in minutes (`0` = on pending changes / online only).
  static const String syncAutoIntervalMinutes = 'sync_auto_interval_minutes';
  /// Welcome / product tour completed before first System Setup.
  static const String onboardingCompleted = 'onboarding_completed';
  /// When true, do not locally seed CoA — awaiting remote pull (joining device).
  static const String chartBootstrapPreferRemote =
      'chart_bootstrap_prefer_remote';
  /// Device initialization mode ('server' or 'local').
  static const String deviceInitMode = 'device_init_mode';
  /// Whether the device has completed primary initialization.
  static const String deviceInitialized = 'device_initialized';
  /// Company ID associated with server initialization.
  static const String deviceInitCompanyId = 'device_init_company_id';
  /// UTC timestamp of initialization completion.
  static const String deviceInitAt = 'device_init_at';
}

/// Mode used to initialize the device database.
enum DeviceInitializationMode {
  local,
  server,
  none;

  static DeviceInitializationMode fromString(String? value) {
    switch (value) {
      case 'server':
        return DeviceInitializationMode.server;
      case 'local':
        return DeviceInitializationMode.local;
      default:
        return DeviceInitializationMode.none;
    }
  }
}

/// Durable record of device initialization status and source mode.
class DeviceInitializationRecord {
  const DeviceInitializationRecord({
    required this.mode,
    required this.initialized,
    this.companyId,
    this.initializedAt,
  });

  final DeviceInitializationMode mode;
  final bool initialized;
  final String? companyId;
  final DateTime? initializedAt;

  bool get isServerInitialized =>
      initialized && mode == DeviceInitializationMode.server;

  bool get isLocalInitialized =>
      initialized && mode == DeviceInitializationMode.local;
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

  /// Always local/standalone. Mode switch was removed; kept for settings compat.
  Future<String> loadAccountingMode() async => 'standalone';

  /// No-op — accounting always runs as local/standalone.
  Future<void> saveAccountingMode(String mode) async {}

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

  /// Base/system currency chosen during System Setup — immutable once locked.
  Future<bool> loadSystemBaseCurrencyLocked() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.systemBaseCurrencyLocked);
    return value == true;
  }

  Future<void> saveSystemBaseCurrencyLocked(bool locked) async {
    final box = await _settingsBox;
    await box.put(SettingsKeys.systemBaseCurrencyLocked, locked);
  }

  /// Per-install UUID used as X-Device-Id for experimental sync.
  Future<String> loadOrCreateSyncDeviceId() async {
    final box = await _settingsBox;
    final existing = box.get(SettingsKeys.syncDeviceId) as String?;
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final created = generateUuidV4();
    await box.put(SettingsKeys.syncDeviceId, created);
    return created;
  }

  /// Opt-in multi-device sync. Default is off (local-only installs).
  Future<bool> loadSyncEnabled() async {
    final box = await _settingsBox;
    return box.get(SettingsKeys.syncEnabled) == true;
  }

  Future<void> saveSyncEnabled(bool enabled) async {
    final box = await _settingsBox;
    await box.put(SettingsKeys.syncEnabled, enabled);
  }

  Future<String?> loadSyncServerBaseUrl() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.syncServerBaseUrl) as String?;
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  Future<void> saveSyncServerBaseUrl(String? url) async {
    final box = await _settingsBox;
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) {
      await box.delete(SettingsKeys.syncServerBaseUrl);
      return;
    }
    await box.put(SettingsKeys.syncServerBaseUrl, trimmed);
  }

  Future<String?> loadSyncServerToken() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.syncServerToken) as String?;
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  Future<void> saveSyncServerToken(String? token) async {
    final box = await _settingsBox;
    final trimmed = token?.trim() ?? '';
    if (trimmed.isEmpty) {
      await box.delete(SettingsKeys.syncServerToken);
      return;
    }
    await box.put(SettingsKeys.syncServerToken, trimmed);
  }

  /// Default true — background sync when the user has opted into sync.
  Future<bool> loadSyncAutoEnabled() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.syncAutoEnabled);
    if (value is bool) return value;
    return true;
  }

  Future<void> saveSyncAutoEnabled(bool enabled) async {
    final box = await _settingsBox;
    await box.put(SettingsKeys.syncAutoEnabled, enabled);
  }

  /// Default 15 minutes. `0` means change/online triggers only.
  Future<int> loadSyncAutoIntervalMinutes() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.syncAutoIntervalMinutes);
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 15;
  }

  Future<void> saveSyncAutoIntervalMinutes(int minutes) async {
    final box = await _settingsBox;
    await box.put(SettingsKeys.syncAutoIntervalMinutes, minutes);
  }

  Future<bool> loadOnboardingCompleted() async {
    final box = await _settingsBox;
    return box.get(SettingsKeys.onboardingCompleted) == true;
  }

  Future<void> saveOnboardingCompleted(bool completed) async {
    final box = await _settingsBox;
    await box.put(SettingsKeys.onboardingCompleted, completed);
  }

  /// True when the settings box already has runtime configuration keys.
  ///
  /// Used to grandfather System Setup for upgrades without forcing the wizard.
  Future<bool> appearsPreviouslyConfigured() async {
    final box = await _settingsBox;
    return box.containsKey(SettingsKeys.companyProfile) ||
        box.containsKey(SettingsKeys.themeMode) ||
        box.containsKey(SettingsKeys.locale) ||
        box.containsKey(SettingsKeys.accountingMode) ||
        box.containsKey(SettingsKeys.dashboardServiceIds) ||
        box.containsKey(SettingsKeys.quickActionIds) ||
        box.containsKey(SettingsKeys.inventoryServiceIds);
  }

  /// Raw System Setup persistence (owned conceptually by System Setup module).
  Future<bool> hasSystemSetupState() async {
    final box = await _settingsBox;
    return box.containsKey(SettingsKeys.systemSetupVersion);
  }

  Future<int?> loadSystemSetupVersion() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.systemSetupVersion);
    return value is int ? value : null;
  }

  Future<String?> loadSystemSetupStatus() async {
    final box = await _settingsBox;
    return box.get(SettingsKeys.systemSetupStatus) as String?;
  }

  Future<Map<String, Map<String, Object?>>> loadSystemSetupSteps() async {
    final box = await _settingsBox;
    final raw = box.get(SettingsKeys.systemSetupSteps);
    if (raw is! Map) {
      return const {};
    }
    final result = <String, Map<String, Object?>>{};
    raw.forEach((key, value) {
      if (key is! String || value is! Map) {
        return;
      }
      result[key] = {
        for (final entry in value.entries)
          if (entry.key is String)
            entry.key as String: entry.value as Object?,
      };
    });
    return result;
  }

  Future<DateTime?> loadSystemSetupLastUpdated() async {
    final box = await _settingsBox;
    final value = box.get(SettingsKeys.systemSetupLastUpdated);
    if (value is! int) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  Future<void> saveSystemSetupState({
    required int version,
    required String status,
    required Map<String, Map<String, Object?>> steps,
    required DateTime lastUpdated,
  }) async {
    final box = await _settingsBox;
    await box.put(SettingsKeys.systemSetupVersion, version);
    await box.put(SettingsKeys.systemSetupStatus, status);
    await box.put(SettingsKeys.systemSetupSteps, steps);
    await box.put(
      SettingsKeys.systemSetupLastUpdated,
      lastUpdated.toUtc().millisecondsSinceEpoch,
    );
  }

  /// Joining device: skip local CoA seed until remote accounts arrive.
  Future<bool> loadChartBootstrapPreferRemote() async {
    final box = await _settingsBox;
    return box.get(SettingsKeys.chartBootstrapPreferRemote) == true;
  }

  Future<void> saveChartBootstrapPreferRemote(bool preferRemote) async {
    final box = await _settingsBox;
    if (preferRemote) {
      await box.put(SettingsKeys.chartBootstrapPreferRemote, true);
    } else {
      await box.delete(SettingsKeys.chartBootstrapPreferRemote);
    }
  }

  /// Loads current device initialization record.
  Future<DeviceInitializationRecord> loadDeviceInitialization() async {
    final box = await _settingsBox;
    final initialized = box.get(SettingsKeys.deviceInitialized) == true;
    final modeStr = box.get(SettingsKeys.deviceInitMode) as String?;
    final mode = DeviceInitializationMode.fromString(modeStr);
    final companyId = box.get(SettingsKeys.deviceInitCompanyId) as String?;
    final atMs = box.get(SettingsKeys.deviceInitAt) as int?;
    final initializedAt = atMs != null
        ? DateTime.fromMillisecondsSinceEpoch(atMs, isUtc: true)
        : null;

    return DeviceInitializationRecord(
      mode: mode,
      initialized: initialized,
      companyId: companyId,
      initializedAt: initializedAt,
    );
  }

  /// Saves explicit device initialization state.
  Future<void> saveDeviceInitialization({
    required DeviceInitializationMode mode,
    required bool initialized,
    String? companyId,
    DateTime? initializedAt,
  }) async {
    final box = await _settingsBox;
    await box.put(SettingsKeys.deviceInitialized, initialized);
    await box.put(SettingsKeys.deviceInitMode, mode.name);
    if (companyId != null && companyId.isNotEmpty) {
      await box.put(SettingsKeys.deviceInitCompanyId, companyId);
    } else {
      await box.delete(SettingsKeys.deviceInitCompanyId);
    }
    if (initializedAt != null) {
      await box.put(
        SettingsKeys.deviceInitAt,
        initializedAt.toUtc().millisecondsSinceEpoch,
      );
    } else {
      await box.delete(SettingsKeys.deviceInitAt);
    }
  }

  /// Convenient helper to check if this device was initialized from a server.
  Future<bool> isServerInitialized() async {
    final record = await loadDeviceInitialization();
    return record.isServerInitialized;
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
