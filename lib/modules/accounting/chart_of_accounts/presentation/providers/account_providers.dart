import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/core/auth/presentation/providers/auth_state_core.dart';
import 'package:stock_count/core/database/canonical_database_provider.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/sync/sync_core.dart';
import 'package:stock_count/core/tenancy/company_context_resolver.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/models/account_tree_node.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/services/account_code_generator.dart';
import '../../domain/services/account_validator.dart';
import '../../domain/usecases/account_usecases.dart';

final accountingDatabaseProvider = Provider<NexabizDatabase>((ref) {
  return ref.watch(nexabizDatabaseProvider);
});

final accountRepositoryImplProvider = Provider<AccountRepositoryImpl>((ref) {
  return AccountRepositoryImpl(
    ref.watch(accountingDatabaseProvider),
    syncQueue: ref.watch(syncQueueProvider),
    readCompanyId: () => ref.read(currentCompanyIdProvider),
  );
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return ref.watch(accountRepositoryImplProvider);
});

final accountValidatorProvider = Provider<AccountValidator>((ref) {
  return const AccountValidator();
});

final accountCodeGeneratorProvider = Provider<AccountCodeGenerator>((ref) {
  return AccountCodeGenerator(ref.watch(accountRepositoryProvider));
});

final watchAccountsUseCaseProvider = Provider<WatchAccounts>((ref) {
  return WatchAccounts(ref.watch(accountRepositoryProvider));
});

final searchAccountsUseCaseProvider = Provider<SearchAccounts>((ref) {
  return SearchAccounts(ref.watch(accountRepositoryProvider));
});

final getAccountByIdUseCaseProvider = Provider<GetAccountById>((ref) {
  return GetAccountById(ref.watch(accountRepositoryProvider));
});

final getAccountByUuidUseCaseProvider = Provider<GetAccountByUuid>((ref) {
  return GetAccountByUuid(ref.watch(accountRepositoryProvider));
});

final createAccountUseCaseProvider = Provider<CreateAccount>((ref) {
  return CreateAccount(ref.watch(accountRepositoryProvider));
});

final updateAccountUseCaseProvider = Provider<UpdateAccount>((ref) {
  return UpdateAccount(ref.watch(accountRepositoryProvider));
});

final deactivateAccountUseCaseProvider = Provider<DeactivateAccount>((ref) {
  return DeactivateAccount(ref.watch(accountRepositoryProvider));
});

final softDeleteAccountUseCaseProvider = Provider<SoftDeleteAccount>((ref) {
  return SoftDeleteAccount(
    ref.watch(accountRepositoryProvider),
    permissionGuard: ref.watch(permissionGuardProvider),
  );
});

final ensureDefaultChartUseCaseProvider =
    Provider<EnsureDefaultChartOfAccounts>((ref) {
      return EnsureDefaultChartOfAccounts(ref.watch(accountRepositoryProvider));
    });

final seedDefaultChartUseCaseProvider = Provider<SeedDefaultChartOfAccounts>((
  ref,
) {
  return SeedDefaultChartOfAccounts(ref.watch(accountRepositoryProvider));
});

final accountsIncludeInactiveProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

final accountTypeFilterProvider = StateProvider.autoDispose<AccountType?>(
  (ref) => null,
);

/// Ensures default COA exists, then exposes the reactive catalog stream.
final accountsProvider = StreamProvider<List<Account>>((ref) async* {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId.isEmpty) {
    yield [];
    return;
  }
  try {
    await ref.watch(ensureDefaultChartUseCaseProvider).call();
  } on MissingCompanyContextException {
    yield [];
    return;
  }
  final includeInactive = ref.watch(accountsIncludeInactiveProvider);
  yield* ref
      .watch(watchAccountsUseCaseProvider)
      .call(includeInactive: includeInactive);
});

/// All accounts in the chart of accounts (including inactive), ensuring full catalog search.
final allAccountsProvider = StreamProvider<List<Account>>((ref) async* {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId.isEmpty) {
    yield [];
    return;
  }
  try {
    await ref.watch(ensureDefaultChartUseCaseProvider).call();
  } on MissingCompanyContextException {
    yield [];
    return;
  }
  yield* ref.watch(watchAccountsUseCaseProvider).call(includeInactive: true);
});

final accountSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

final accountTreeExpandedIdsProvider = StateProvider.autoDispose<Set<String>>(
  (ref) => <String>{},
);

final filteredAccountsProvider = Provider<AsyncValue<List<Account>>>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  final query = ref.watch(accountSearchQueryProvider).trim().toLowerCase();
  final typeFilter = ref.watch(accountTypeFilterProvider);
  return accountsAsync.whenData((accounts) {
    if (query.isEmpty && typeFilter == null) {
      return accounts;
    }
    return [
      for (final a in accounts)
        if ((typeFilter == null || a.accountType == typeFilter) &&
            (query.isEmpty ||
                a.accountCode.toLowerCase().contains(query) ||
                a.name.toLowerCase().contains(query)))
          a,
    ];
  });
});

final accountForestProvider = Provider<AsyncValue<List<AccountTreeNode>>>((
  ref,
) {
  return ref
      .watch(filteredAccountsProvider)
      .whenData(AccountTreeNode.buildForest);
});

final accountByIdProvider = FutureProvider.autoDispose.family<Account?, String>((
  ref,
  id,
) {
  return ref.watch(getAccountByIdUseCaseProvider).call(id);
});

final accountByUuidProvider = FutureProvider.autoDispose
    .family<Account?, String>((ref, uuid) {
      return ref.watch(getAccountByUuidUseCaseProvider).call(uuid);
    });

/// Group accounts eligible as parents (active, not deleted).
final parentAccountOptionsProvider = Provider<AsyncValue<List<Account>>>((ref) {
  return ref.watch(accountsProvider).whenData((accounts) {
    return [
      for (final a in accounts)
        if (a.isGroup && a.isActive) a,
    ];
  });
});
