import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../data/database/accounting_database.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/models/account_tree_node.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/services/account_validator.dart';
import '../../domain/usecases/account_usecases.dart';

final accountingDatabaseProvider = Provider<AccountingDatabase>((ref) {
  final db = AccountingDatabase();
  ref.onDispose(db.close);
  ref.keepAlive();
  return db;
});

final accountRepositoryImplProvider = Provider<AccountRepositoryImpl>((ref) {
  return AccountRepositoryImpl(
    ref.watch(accountingDatabaseProvider),
    syncQueue: ref.watch(syncQueueProvider),
  );
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return ref.watch(accountRepositoryImplProvider);
});

final accountValidatorProvider = Provider<AccountValidator>((ref) {
  return const AccountValidator();
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
  return SoftDeleteAccount(ref.watch(accountRepositoryProvider));
});

final ensureDefaultChartUseCaseProvider =
    Provider<EnsureDefaultChartOfAccounts>((ref) {
      return EnsureDefaultChartOfAccounts(ref.watch(accountRepositoryProvider));
    });

final accountsIncludeInactiveProvider = StateProvider<bool>((ref) => false);

final accountTypeFilterProvider = StateProvider.autoDispose<AccountType?>(
  (ref) => null,
);

/// Ensures default COA exists, then exposes the reactive catalog stream.
final accountsProvider = StreamProvider<List<Account>>((ref) async* {
  await ref.watch(ensureDefaultChartUseCaseProvider).call();
  final includeInactive = ref.watch(accountsIncludeInactiveProvider);
  yield* ref
      .watch(watchAccountsUseCaseProvider)
      .call(includeInactive: includeInactive);
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
  return accountsAsync.whenData((accounts) {
    if (query.isEmpty) {
      return accounts;
    }
    return [
      for (final a in accounts)
        if (a.accountCode.toLowerCase().contains(query) ||
            a.name.toLowerCase().contains(query))
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

final accountByIdProvider = FutureProvider.autoDispose.family<Account?, int>((
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
