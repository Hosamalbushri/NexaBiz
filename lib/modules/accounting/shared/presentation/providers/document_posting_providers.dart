import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/modules/accounting/journals/presentation/providers/journal_providers.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/document_entry_sync.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/document_lock_checker.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/document_posting_orchestrator.dart';
import 'package:stock_count/modules/accounting/shared/presentation/providers/account_mapping_providers.dart';
import 'package:stock_count/modules/inventory/stock_movements/presentation/providers/stock_movements_providers.dart';

final documentLockCheckerProvider = Provider<DocumentLockChecker>((ref) {
  return const DocumentLockChecker();
});

final accountingEntryBuilderProvider = Provider<AccountingEntryBuilder>((ref) {
  final mappingResolver = ref.watch(accountMappingResolverProvider);
  final validationService = ref.watch(accountValidationServiceProvider);
  return AccountingEntryBuilder(
    mappingResolver: mappingResolver,
    validationService: validationService,
  );
});

final documentPostingOrchestratorProvider = Provider<DocumentPostingOrchestrator>((ref) {
  final postingCoordinator = ref.watch(postingCoordinatorProvider);
  final journalPostingService = ref.watch(journalPostingServiceProvider);
  final entryBuilder = ref.watch(accountingEntryBuilderProvider);
  final lockChecker = ref.watch(documentLockCheckerProvider);

  return DocumentPostingOrchestrator(
    postingCoordinator: postingCoordinator,
    journalPostingService: journalPostingService,
    entryBuilder: entryBuilder,
    lockChecker: lockChecker,
  );
});

final documentEntrySyncProvider = Provider<DocumentEntrySync>((ref) {
  final journalRepo = ref.watch(journalRepositoryProvider);
  final entryBuilder = ref.watch(accountingEntryBuilderProvider);
  return DocumentEntrySync(
    journalRepository: journalRepo,
    entryBuilder: entryBuilder,
  );
});
