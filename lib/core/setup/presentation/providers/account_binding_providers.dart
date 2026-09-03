import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/ports/setup_account_lookup_port.dart';
import '../../data/repositories/hive_account_binding_repository.dart';
import '../../domain/repositories/account_binding_repository.dart';
import '../../domain/services/account_binding_resolver.dart';

/// Default account lookup port provider.
final setupAccountLookupPortProvider = Provider<SetupAccountLookupPort>((ref) {
  return const NoOpSetupAccountLookupPort();
});

/// Provider for the persistent [AccountBindingRepository].
final accountBindingRepositoryProvider = Provider<AccountBindingRepository>((ref) {
  return HiveAccountBindingRepository();
});

/// Provider for [AccountBindingResolver].
final accountBindingResolverProvider = Provider.family<AccountBindingResolver, SetupAccountLookupPort>((ref, lookupPort) {
  final repository = ref.watch(accountBindingRepositoryProvider);
  return AccountBindingResolver(
    accountLookupPort: lookupPort,
    bindingRepository: repository,
  );
});
