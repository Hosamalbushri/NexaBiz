import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/database/canonical_database_provider.dart';
import 'package:stock_count/modules/accounting/journals/presentation/providers/journal_providers.dart';
import 'package:stock_count/modules/accounting/shared/presentation/providers/document_posting_providers.dart';
import 'package:stock_count/modules/inventory/stock_movements/presentation/providers/stock_movements_providers.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/entities/purchase_invoice.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/usecases/purchases_usecases.dart';
import '../../data/repositories/purchase_repository_impl.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final db = ref.watch(nexabizDatabaseProvider);
  return PurchaseRepositoryImpl(db);
});

final postPurchaseInvoiceUseCaseProvider =
    Provider<PostPurchaseInvoiceUseCase>((ref) {
  return PostPurchaseInvoiceUseCase(
    purchaseRepository: ref.watch(purchaseRepositoryProvider),
    postingCoordinator: ref.watch(postingCoordinatorProvider),
    journalPostingService: ref.watch(journalPostingServiceProvider),
    entryBuilder: ref.watch(accountingEntryBuilderProvider),
    orchestrator: ref.watch(canonicalTransactionOrchestratorProvider),
  );
});

final purchaseUsecasesProvider = Provider<PurchaseUsecases>((ref) {
  return PurchaseUsecases(
    ref.watch(purchaseRepositoryProvider),
    ref.watch(postPurchaseInvoiceUseCaseProvider),
  );
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

