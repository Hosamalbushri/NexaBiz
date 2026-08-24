import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/accounting/presentation/providers/account_providers.dart';
import '../../modules/customers/presentation/providers/customer_providers.dart';
import '../../modules/inventory/presentation/providers/product_providers.dart';
import '../../modules/receipts_payments/presentation/providers/rp_providers.dart';
import '../../modules/sales/presentation/providers/sale_providers.dart';

/// Lightweight local dataset inspector to check if business data exists locally.
class LocalDatasetInspector {
  const LocalDatasetInspector(this._ref);

  final Ref _ref;

  /// Returns the total aggregated count of business domain records in local SQLite/Hive storage.
  ///
  /// Uses fast `COUNT(*)` queries across accounts, customers, products, sales,
  /// payments, and journal entries.
  Future<int> inspectLocalBusinessRecordCount() async {
    var total = 0;

    try {
      final accountsDb = _ref.read(accountingDatabaseProvider);
      final accountRows = await accountsDb.customSelect(
        'SELECT COUNT(*) as cnt FROM accounts WHERE deleted_at IS NULL',
      ).getSingleOrNull();
      total += (accountRows?.read<num>('cnt') ?? 0).toInt();

      final journalsRows = await accountsDb.customSelect(
        'SELECT COUNT(*) as cnt FROM journal_entries WHERE deleted_at IS NULL',
      ).getSingleOrNull();
      total += (journalsRows?.read<num>('cnt') ?? 0).toInt();
    } catch (_) {}

    try {
      final inventoryDb = _ref.read(inventoryDatabaseProvider);
      final productRows = await inventoryDb.customSelect(
        'SELECT COUNT(*) as cnt FROM products WHERE deleted_at IS NULL',
      ).getSingleOrNull();
      total += (productRows?.read<num>('cnt') ?? 0).toInt();

      final itemRows = await inventoryDb.customSelect(
        'SELECT COUNT(*) as cnt FROM inventory_items WHERE deleted_at IS NULL',
      ).getSingleOrNull();
      total += (itemRows?.read<num>('cnt') ?? 0).toInt();
    } catch (_) {}

    try {
      final customersDb = _ref.read(customersDatabaseProvider);
      final customerRows = await customersDb.customSelect(
        'SELECT COUNT(*) as cnt FROM customers WHERE deleted_at IS NULL',
      ).getSingleOrNull();
      total += (customerRows?.read<num>('cnt') ?? 0).toInt();

      final supplierRows = await customersDb.customSelect(
        'SELECT COUNT(*) as cnt FROM suppliers WHERE deleted_at IS NULL',
      ).getSingleOrNull();
      total += (supplierRows?.read<num>('cnt') ?? 0).toInt();
    } catch (_) {}

    try {
      final salesDb = _ref.read(salesDatabaseProvider);
      final saleRows = await salesDb.customSelect(
        'SELECT COUNT(*) as cnt FROM sales WHERE deleted_at IS NULL',
      ).getSingleOrNull();
      total += (saleRows?.read<num>('cnt') ?? 0).toInt();

      final purchaseRows = await salesDb.customSelect(
        'SELECT COUNT(*) as cnt FROM purchases WHERE deleted_at IS NULL',
      ).getSingleOrNull();
      total += (purchaseRows?.read<num>('cnt') ?? 0).toInt();
    } catch (_) {}

    try {
      final receiptsDb = _ref.read(receiptsPaymentsDatabaseProvider);
      final txRows = await receiptsDb.customSelect(
        'SELECT COUNT(*) as cnt FROM financial_transactions WHERE deleted_at IS NULL',
      ).getSingleOrNull();
      total += (txRows?.read<num>('cnt') ?? 0).toInt();
    } catch (_) {}

    return total;
  }
}

final localDatasetInspectorProvider = Provider<LocalDatasetInspector>((ref) {
  return LocalDatasetInspector(ref);
});
