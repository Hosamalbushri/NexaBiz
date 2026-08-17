import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/settings/company/company_profile_providers.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../data/repositories/fiscal_year_repository_impl.dart';
import '../../data/repositories/journal_repository_impl.dart';
import '../../domain/entities/fiscal_year.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/fiscal_year_repository.dart';
import '../../domain/repositories/journal_repository.dart';
import '../../domain/services/accounting_period_validator.dart';
import '../../domain/services/fiscal_period_policy.dart';
import '../../domain/services/journal_posting_service.dart';
import '../../domain/services/period_closing_service.dart';
import '../../domain/usecases/journal_usecases.dart';
import 'account_providers.dart';
import 'currency_rate_providers.dart';

export '../../domain/entities/fiscal_year.dart'
    show AccountingPeriod, FiscalYear, FiscalYearSummary, PeriodClosingRecord;

final journalRepositoryImplProvider = Provider<JournalRepositoryImpl>((ref) {
  return JournalRepositoryImpl(
    ref.watch(accountingDatabaseProvider),
    accounts: ref.watch(accountRepositoryProvider),
    rates: ref.watch(currencyRateRepositoryProvider),
    syncQueue: ref.watch(syncQueueProvider),
  );
});

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return ref.watch(journalRepositoryImplProvider);
});

/// Last closed fiscal day (nullable). Invalidate after settings save.
final accountingFiscalClosedThroughProvider =
    FutureProvider<DateTime?>((ref) async {
      return ref
          .watch(settingsRepositoryProvider)
          .loadAccountingFiscalClosedThrough();
    });

final fiscalPeriodPolicyProvider = Provider<FiscalPeriodPolicy>((ref) {
  final profile = ref.watch(companyProfileProvider).valueOrNull;
  final closed = ref.watch(accountingFiscalClosedThroughProvider).valueOrNull;
  return FiscalPeriodPolicy(
    fiscalYearStartMonth: profile?.fiscalYearStartMonth ?? 1,
    closedThrough: closed,
  );
});

final fiscalYearRepositoryProvider = Provider<FiscalYearRepository>((ref) {
  return FiscalYearRepositoryImpl(ref.watch(accountingDatabaseProvider));
});

final accountingPeriodValidatorProvider =
    Provider<AccountingPeriodValidator>((ref) {
  return AccountingPeriodValidator(
    repository: ref.watch(fiscalYearRepositoryProvider),
    legacyPolicyReader: () => ref.read(fiscalPeriodPolicyProvider),
  );
});

final journalPostingServiceProvider = Provider<JournalPostingService>((ref) {
  return JournalPostingService(
    journals: ref.watch(journalRepositoryProvider),
    periodValidator: ref.watch(accountingPeriodValidatorProvider),
  );
});

final createFiscalYearUseCaseProvider = Provider<CreateFiscalYear>((ref) {
  return CreateFiscalYear(
    repository: ref.watch(fiscalYearRepositoryProvider),
    accounts: ref.watch(accountRepositoryProvider),
  );
});

final openAccountingPeriodUseCaseProvider = Provider<OpenAccountingPeriod>((
  ref,
) {
  return OpenAccountingPeriod(ref.watch(fiscalYearRepositoryProvider));
});

final reopenAccountingPeriodUseCaseProvider = Provider<ReopenAccountingPeriod>((
  ref,
) {
  return ReopenAccountingPeriod(ref.watch(fiscalYearRepositoryProvider));
});

final periodClosingServiceProvider = Provider<PeriodClosingService>((ref) {
  return PeriodClosingService(
    repository: ref.watch(fiscalYearRepositoryProvider),
    rates: ref.watch(currencyRateRepositoryProvider),
    posting: ref.watch(journalPostingServiceProvider),
    journals: ref.watch(journalRepositoryProvider),
  );
});

final fiscalYearSummariesProvider =
    FutureProvider.autoDispose<List<FiscalYearSummary>>((ref) {
      return ref.watch(fiscalYearRepositoryProvider).listSummaries();
    });

final fiscalYearByUuidProvider = FutureProvider.autoDispose
    .family<FiscalYear?, String>((ref, uuid) {
      return ref.watch(fiscalYearRepositoryProvider).getByUuid(uuid);
    });

final fiscalYearPeriodsProvider = FutureProvider.autoDispose
    .family<List<AccountingPeriod>, String>((ref, fyUuid) {
      return ref.watch(fiscalYearRepositoryProvider).listPeriods(fyUuid);
    });

final fiscalYearClosingsProvider = FutureProvider.autoDispose
    .family<List<PeriodClosingRecord>, String>((ref, fyUuid) {
      return ref
          .watch(fiscalYearRepositoryProvider)
          .listClosingsForFiscalYear(fyUuid);
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
