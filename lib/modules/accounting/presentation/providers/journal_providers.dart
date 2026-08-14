import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/settings/company/company_profile_providers.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';
import '../../domain/services/fiscal_period_policy.dart';
import '../../domain/services/journal_posting_service.dart';
import '../../domain/usecases/journal_usecases.dart';
import '../../data/repositories/journal_repository_impl.dart';
import 'account_providers.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepositoryImpl(
    ref.watch(accountingDatabaseProvider),
    accounts: ref.watch(accountRepositoryProvider),
  );
});

/// Last closed fiscal day (nullable). Invalidate after settings save.
final accountingFiscalClosedThroughProvider =
    FutureProvider<DateTime?>((ref) async {
      return ref.watch(settingsRepositoryProvider).loadAccountingFiscalClosedThrough();
    });

final fiscalPeriodPolicyProvider = Provider<FiscalPeriodPolicy>((ref) {
  final profile = ref.watch(companyProfileProvider).valueOrNull;
  final closed = ref.watch(accountingFiscalClosedThroughProvider).valueOrNull;
  return FiscalPeriodPolicy(
    fiscalYearStartMonth: profile?.fiscalYearStartMonth ?? 1,
    closedThrough: closed,
  );
});

final journalPostingServiceProvider = Provider<JournalPostingService>((ref) {
  return JournalPostingService(
    journals: ref.watch(journalRepositoryProvider),
    fiscalPolicyReader: () => ref.read(fiscalPeriodPolicyProvider),
  );
});

final postJournalEntryUseCaseProvider = Provider<PostJournalEntry>((ref) {
  return PostJournalEntry(ref.watch(journalPostingServiceProvider));
});

final getJournalEntryByUuidUseCaseProvider = Provider<GetJournalEntryByUuid>((
  ref,
) {
  return GetJournalEntryByUuid(ref.watch(journalRepositoryProvider));
});

final listJournalEntryHeadersUseCaseProvider =
    Provider<ListJournalEntryHeaders>((ref) {
      return ListJournalEntryHeaders(ref.watch(journalRepositoryProvider));
    });

final softDeleteJournalEntryUseCaseProvider = Provider<SoftDeleteJournalEntry>((
  ref,
) {
  return SoftDeleteJournalEntry(ref.watch(journalPostingServiceProvider));
});

final journalListQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final journalEntriesProvider =
    FutureProvider.autoDispose<List<JournalEntryHeader>>((ref) async {
      final query = ref.watch(journalListQueryProvider);
      return ref
          .watch(listJournalEntryHeadersUseCaseProvider)
          .call(query: query.isEmpty ? null : query, limit: 100);
    });

final journalEntryByUuidProvider = FutureProvider.autoDispose
    .family<JournalEntry?, String>((ref, uuid) {
      return ref.watch(getJournalEntryByUuidUseCaseProvider).call(uuid);
    });
