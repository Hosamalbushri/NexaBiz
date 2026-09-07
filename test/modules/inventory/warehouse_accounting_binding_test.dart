import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse_accounting_binding.dart';

void main() {
  group('WarehouseAccountingBinding Domain Entity Tests', () {
    test(
      '1. WarehouseAccountingBinding validates required fields and optional account links',
      () {
        final now = DateTime.now();
        final binding = WarehouseAccountingBinding(
          id: 'wh_bind_01',
          warehouseId: 'wh_01',
          inventoryAssetAccountId: 'acc_asset_100',
          cogsAccountId: 'acc_cogs_200',
          inventoryAdjustmentAccountId: 'acc_adj_300',
          companyId: 'company_A',
          createdAt: now,
          updatedAt: now,
        );

        expect(binding.id, equals('wh_bind_01'));
        expect(binding.warehouseId, equals('wh_01'));
        expect(binding.inventoryAssetAccountId, equals('acc_asset_100'));
        expect(binding.cogsAccountId, equals('acc_cogs_200'));
        expect(binding.inventoryAdjustmentAccountId, equals('acc_adj_300'));
        expect(binding.companyId, equals('company_A'));
      },
    );

    test(
      '2. WarehouseAccountingBinding allows null account IDs for unmapped roles',
      () {
        final now = DateTime.now();
        final binding = WarehouseAccountingBinding(
          id: 'wh_bind_02',
          warehouseId: 'wh_02',
          companyId: 'company_A',
          createdAt: now,
          updatedAt: now,
        );

        expect(binding.inventoryAssetAccountId, isNull);
        expect(binding.cogsAccountId, isNull);
        expect(binding.inventoryAdjustmentAccountId, isNull);
      },
    );
  });
}
