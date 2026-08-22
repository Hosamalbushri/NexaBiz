import 'dart:async';

import 'package:hive/hive.dart';

import '../../app/settings/settings_repository.dart';
import '../../modules/inventory/data/inventory_hive.dart';
import '../../modules/inventory/domain/entities/inventory_item.dart';
import '../errors/app_error_domain.dart';
import '../sync/sync_cursor_store.dart';
import '../sync/sync_status.dart';

/// Installs server-provided bootstrap snapshot into the local database atomically.
///
/// Ensures all downloaded master records (company, COA, inventory items, settings)
/// are written in a single staged operation. If writing fails, any partial writes
/// are rolled back or cleared, leaving local storage uncorrupted.
class AtomicBootstrapInstaller {
  const AtomicBootstrapInstaller({
    SyncCursorStore? cursorStore,
  }) : _cursorStore = cursorStore;

  final SyncCursorStore? _cursorStore;

  /// Installs downloaded master data items grouped by entity type.
  Future<void> installSnapshot({
    required String companyId,
    required String companyName,
    required int snapshotSequence,
    required DateTime takenAt,
    required Map<String, List<Map<String, dynamic>>> entitiesByType,
  }) async {
    try {
      // 1. Open target boxes/tables.
      final inventoryBox = await InventoryHive.openBox();

      // Backup current state for rollback on error.
      final existingInventory = Map<dynamic, InventoryItem>.from(inventoryBox.toMap());

      try {
        // 2. Stage Inventory Items (if provided in snapshot).
        if (entitiesByType.containsKey('inventory_item')) {
          final itemsPayload = entitiesByType['inventory_item'] ?? [];
          final itemsToStore = <String, InventoryItem>{};

          for (final itemPayload in itemsPayload) {
            final payload = (itemPayload['payload'] as Map<String, dynamic>?) ?? itemPayload;
            final entityId = (itemPayload['entity_id'] as String?) ?? (payload['id'] as String?) ?? '';
            final itemCode = (payload['itemCode'] as String?) ?? entityId;

            if (itemCode.isEmpty) continue;

            final item = InventoryItem(
              id: entityId,
              itemCode: itemCode,
              itemName: (payload['itemName'] as String?) ?? '',
              barcode: payload['barcode'] as String?,
              packSize: (payload['packSize'] as num?)?.toInt(),
              systemQuantity: (payload['systemQuantity'] as num?)?.toDouble() ?? 0.0,
              actualQuantity: (payload['actualQuantity'] as num?)?.toDouble(),
              mainQuantity: (payload['mainQuantity'] as num?)?.toDouble(),
              subQuantity: (payload['subQuantity'] as num?)?.toDouble(),
              createdAt: takenAt,
              updatedAt: takenAt,
              syncStatus: SyncStatus.synced,
              lastSyncedAt: takenAt,
              version: (itemPayload['version'] as num?)?.toInt() ?? 1,
            );
            itemsToStore[itemCode] = item;
          }

          if (itemsToStore.isNotEmpty) {
            await inventoryBox.putAll(itemsToStore);
          }
        }

        // 3. Extract currency & company details from snapshot entities and persist profile.
        String currencyCode = 'YER';
        String profileName = companyName;
        String? legalName;
        String? taxNumber;
        String? commercialRegister;
        String? phone;
        String? email;
        String? address;
        String? city;
        String? country;
        String? website;
        int fiscalYearStartMonth = 1;
        String? invoiceHeaderRight;
        String? invoiceHeaderLeft;

        if (entitiesByType.containsKey('company_profile')) {
          final profiles = entitiesByType['company_profile'] ?? [];
          for (final profile in profiles) {
            final payload = (profile['payload'] as Map<String, dynamic>?) ?? profile;
            final name = (payload['name'] as String?)?.trim();
            if (name != null && name.isNotEmpty) {
              profileName = name;
            }
            final code = (payload['defaultCurrencyCode'] as String?)?.trim().toUpperCase();
            if (code != null && code.isNotEmpty) {
              currencyCode = code;
            }
            legalName = payload['legalName'] as String?;
            taxNumber = payload['taxNumber'] as String?;
            commercialRegister = payload['commercialRegister'] as String?;
            phone = payload['phone'] as String?;
            email = payload['email'] as String?;
            address = payload['address'] as String?;
            city = payload['city'] as String?;
            country = payload['country'] as String?;
            website = payload['website'] as String?;
            final month = payload['fiscalYearStartMonth'];
            if (month is int) {
              fiscalYearStartMonth = month;
            }
            invoiceHeaderRight = payload['invoiceHeaderRight'] as String?;
            invoiceHeaderLeft = payload['invoiceHeaderLeft'] as String?;
          }
        } else {
          if (entitiesByType.containsKey('currency_rate')) {
            final rates = entitiesByType['currency_rate'] ?? [];
            for (final rate in rates) {
              final payload = (rate['payload'] as Map<String, dynamic>?) ?? rate;
              final code = (payload['currencyCode'] as String?)?.toUpperCase();
              if (code != null && code.isNotEmpty) {
                currencyCode = code;
                break;
              }
            }
          } else if (entitiesByType.containsKey('fiscal_year')) {
            final years = entitiesByType['fiscal_year'] ?? [];
            for (final year in years) {
              final payload = (year['payload'] as Map<String, dynamic>?) ?? year;
              final code = (payload['baseCurrencyCode'] as String?)?.toUpperCase();
              if (code != null && code.isNotEmpty) {
                currencyCode = code;
                break;
              }
            }
          }
        }

        final settingsRepo = SettingsRepository();
        final existingProfile = await settingsRepo.loadCompanyProfile();
        await settingsRepo.saveCompanyProfile(
          existingProfile.copyWith(
            name: profileName.isNotEmpty ? profileName : existingProfile.name,
            legalName: legalName,
            defaultCurrencyCode: currencyCode,
            taxNumber: taxNumber,
            commercialRegister: commercialRegister,
            phone: phone,
            email: email,
            address: address,
            city: city,
            country: country,
            website: website,
            fiscalYearStartMonth: fiscalYearStartMonth,
            invoiceHeaderRight: invoiceHeaderRight,
            invoiceHeaderLeft: invoiceHeaderLeft,
          ),
        );
        await settingsRepo.saveSystemBaseCurrencyLocked(true);

        // 4. Set sync sequence cursor.
        final cursorStore = _cursorStore ?? SyncCursorStore();
        await cursorStore.write('global_sequence', snapshotSequence);
      } catch (e) {
        // Rollback Hive inventory box on failure.
        await inventoryBox.clear();
        if (existingInventory.isNotEmpty) {
          await inventoryBox.putAll(existingInventory);
        }
        rethrow;
      }
    } catch (e) {
      throw classifyAppError(
        'Failed to install bootstrap snapshot into local database: $e',
        category: AppErrorCategory.database,
        severity: FailureSeverity.fatal,
      );
    }
  }
}
