import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/settings/settings_repository.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../data/database/customers_database.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/services/customer_account_link_port.dart';
import '../../domain/services/customer_code_generator.dart';
import '../../domain/usecases/customer_usecases.dart';

final customersDatabaseProvider = Provider<CustomersDatabase>((ref) {
  final db = CustomersDatabase();
  ref.onDispose(db.close);
  ref.keepAlive();
  return db;
});

final customerRepositoryImplProvider = Provider<CustomerRepositoryImpl>((ref) {
  return CustomerRepositoryImpl(
    ref.watch(customersDatabaseProvider),
    syncQueue: ref.watch(syncQueueProvider),
  );
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return ref.watch(customerRepositoryImplProvider);
});

/// Override in App with Accounting-backed adapter (modules ↛ modules).
final customerAccountLinkPortProvider = Provider<CustomerAccountLinkPort>((
  ref,
) {
  return const NoOpCustomerAccountLinkPort();
});

final customerCodeGeneratorProvider = Provider<CustomerCodeGenerator>((ref) {
  return CustomerCodeGenerator(ref.watch(customerRepositoryProvider));
});

final watchCustomersUseCaseProvider = Provider<WatchCustomers>((ref) {
  return WatchCustomers(ref.watch(customerRepositoryProvider));
});

final searchCustomersUseCaseProvider = Provider<SearchCustomers>((ref) {
  return SearchCustomers(ref.watch(customerRepositoryProvider));
});

final getCustomerByIdUseCaseProvider = Provider<GetCustomerById>((ref) {
  return GetCustomerById(ref.watch(customerRepositoryProvider));
});

final createCustomerUseCaseProvider = Provider<CreateCustomer>((ref) {
  return CreateCustomer(ref.watch(customerRepositoryProvider));
});

final updateCustomerUseCaseProvider = Provider<UpdateCustomer>((ref) {
  return UpdateCustomer(ref.watch(customerRepositoryProvider));
});

final deleteCustomerUseCaseProvider = Provider<DeleteCustomer>((ref) {
  return DeleteCustomer(ref.watch(customerRepositoryProvider));
});

final upsertCustomersUseCaseProvider = Provider<UpsertCustomers>((ref) {
  return UpsertCustomers(ref.watch(customerRepositoryProvider));
});

final customersProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(watchCustomersUseCaseProvider).call(includeInactive: true);
});

final customerSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredCustomersProvider = Provider<AsyncValue<List<Customer>>>((ref) {
  final query = ref.watch(customerSearchQueryProvider).trim().toLowerCase();
  final async = ref.watch(customersProvider);
  return async.whenData((customers) {
    if (query.isEmpty) {
      return customers;
    }
    return customers
        .where((c) {
          return c.customerCode.toLowerCase().contains(query) ||
              c.name.toLowerCase().contains(query) ||
              (c.phone?.toLowerCase().contains(query) ?? false) ||
              (c.email?.toLowerCase().contains(query) ?? false) ||
              (c.externalId?.toLowerCase().contains(query) ?? false);
        })
        .toList(growable: false);
  });
});

final customerByIdProvider = FutureProvider.family<Customer?, int>((
  ref,
  id,
) async {
  return ref.watch(getCustomerByIdUseCaseProvider).call(id);
});

final linkedAccountByIdProvider =
    FutureProvider.family<LinkedAccountRef?, String>((ref, accountId) async {
      return ref.watch(customerAccountLinkPortProvider).findById(accountId);
    });

/// Chart of Accounts group under which customer accounts nest.
final customersParentAccountProvider =
    StateNotifierProvider<
      CustomersParentAccountController,
      AsyncValue<LinkedAccountRef?>
    >((ref) {
      return CustomersParentAccountController(
        repository: ref.watch(settingsRepositoryProvider),
        linkPort: ref.watch(customerAccountLinkPortProvider),
      );
    });

class CustomersParentAccountController
    extends StateNotifier<AsyncValue<LinkedAccountRef?>> {
  CustomersParentAccountController({
    required SettingsRepository repository,
    required CustomerAccountLinkPort linkPort,
  }) : _repository = repository,
       _linkPort = linkPort,
       super(const AsyncValue.loading()) {
    _load();
  }

  final SettingsRepository _repository;
  final CustomerAccountLinkPort _linkPort;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final savedId = await _repository.loadCustomersParentAccountId();
      if (savedId != null) {
        final linked = await _linkPort.findById(savedId);
        if (linked != null) {
          return linked;
        }
      }
      final systemParent = await _linkPort.findSystemCustomersParent();
      if (systemParent != null) {
        await _repository.saveCustomersParentAccountId(systemParent.accountId);
      }
      return systemParent;
    });
  }

  Future<void> refresh() => _load();

  Future<bool> setFromInput(String input) async {
    final linked = await _linkPort.resolveParent(input);
    if (linked == null) {
      return false;
    }
    await _repository.saveCustomersParentAccountId(linked.accountId);
    state = AsyncValue.data(linked);
    return true;
  }

  Future<void> useSystemDefault() async {
    final systemParent = await _linkPort.findSystemCustomersParent();
    if (systemParent == null) {
      await _repository.saveCustomersParentAccountId(null);
      state = const AsyncValue.data(null);
      return;
    }
    await _repository.saveCustomersParentAccountId(systemParent.accountId);
    state = AsyncValue.data(systemParent);
  }
}
