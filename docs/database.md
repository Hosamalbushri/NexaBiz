# Database & Local Storage

## Technology

- **Hive** + **hive_flutter**
- No SQL database is configured
- No remote database is configured

## Initialization

`lib/main.dart` calls:

```dart
await HiveInitializer.initialize();
```

`HiveInitializer` (`lib/core/database/hive_initializer.dart`):

1. `Hive.initFlutter()`
2. Opens platform settings box `app_settings`

## Boxes

| Box name | Owner | Contents |
| --- | --- | --- |
| `app_settings` | App / Core constants | Theme mode, locale (`SettingsRepository`) |
| `inventory_items` | Inventory module | `InventoryItem` entities |

Constants:

- Platform: `HiveBoxes.settings` in `lib/core/database/hive_boxes.dart`
- Inventory: `InventoryHive.boxName` in `lib/modules/inventory/data/inventory_hive.dart`

## Inventory persistence

- Adapter: `InventoryItemAdapter` (`typeId: 0`)
- Open path: `InventoryHive.openBox()`
- On open failure (corrupt/incompatible data): box is **deleted from disk** and recreated

### Entity fields persisted

`itemCode`, `itemName`, `barcode`, `packSize`, `systemQuantity`, `actualQuantity`, `mainQuantity`, `subQuantity`

Derived (not stored): `difference`, `status`, `availableQuantity`, `isCounted`

## Repository pattern

- Contract: `InventoryRepository` (domain)
- Implementation: `InventoryRepositoryImpl` (data)
- UI/providers depend on the contract via Riverpod

**Rule:** UI must never open Hive boxes directly.

## Migrations

**Unknown / Not configured** as a formal migration framework.

Practical rules:

1. Prefer additive adapter fields with safe defaults.
2. Changing typeIds / field indexes can wipe data (current recovery deletes the box).
3. Document any schema change here and in an ADR when significant.
4. Do not rename boxes casually.

## Transactions

No explicit Hive transaction API usage found. Writes use `put` / `clear` / `replaceAll` style operations.

## Validation

- Domain counting validation: `CountingCalculator`
- Import validation: `ExcelImportDatasource` + `ImportValidationException`
- Adapter coerces numeric types defensively when reading legacy values

## Settings storage keys

`SettingsKeys.themeMode`, `SettingsKeys.locale` in `settings_repository.dart`.
