import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/database/canonical_database_provider.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/entities/purchase_invoice.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../data/repositories/purchase_repository_impl.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final db = ref.watch(nexabizDatabaseProvider);
  return PurchaseRepositoryImpl(db);
});

final suppliersListProvider = FutureProvider.family<List<Supplier>, String>((
  ref,
  companyId,
) async {
  final repository = ref.watch(purchaseRepositoryProvider);
  return repository.getSuppliers(companyId);
});

final purchaseInvoicesListProvider =
    FutureProvider.family<List<PurchaseInvoice>, String>((
      ref,
      companyId,
    ) async {
      final repository = ref.watch(purchaseRepositoryProvider);
      return repository.getPurchaseInvoices(companyId);
    });
