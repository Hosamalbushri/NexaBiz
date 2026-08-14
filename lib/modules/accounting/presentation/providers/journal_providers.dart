import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/journal_repository_impl.dart';
import '../../domain/repositories/journal_repository.dart';
import 'account_providers.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepositoryImpl(
    ref.watch(accountingDatabaseProvider),
    accounts: ref.watch(accountRepositoryProvider),
  );
});
