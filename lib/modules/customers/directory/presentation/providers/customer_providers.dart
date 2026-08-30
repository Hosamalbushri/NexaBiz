import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/database/tenant_database_name.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/tenancy/session_company.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/customers/shared/data/database/customers_database.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import 'package:stock_count/modules/customers/accounts/domain/services/customer_account_link_port.dart';
import '../../domain/services/customer_code_generator.dart';
import '../../domain/usecases/customer_usecases.dart';
import 'package:stock_count/modules/customers/accounts/domain/usecases/ensure_customer_account_links.dart';

final customersDatabaseProvider = Provider<CustomersDatabase>((ref) {
  final db = CustomersDatabase(
    name: tenantScopedName(
      'customers_master',
      ref.watch(sessionCompanyIdProvider),
    ),
  );
  ref.onDispose(db.close);
  ref.keepAlive();
  return db;
});

final customerRepositoryImplProvider = Provider<CustomerRepositoryImpl>((ref) {
  return CustomerRepositoryImpl(
    ref.watch(customersDatabaseProvider),
    syncQueue: ref.watch(syncQueueProvider),
    readCompanyId: () => ref.read(currentCompanyIdProvider),
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
  return CustomerCodeGenerator(
    ref.watch(customerRepositoryProvider),
    linkPort: ref.watch(customerAccountLinkPortProvider),
  );
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
  return CreateCustomer(
    ref.watch(customerRepositoryProvider),
    permissionGuard: ref.watch(permissionGuardProvider),
  );
});

final updateCustomerUseCaseProvider = Provider<UpdateCustomer>((ref) {
  return UpdateCustomer(
    ref.watch(customerRepositoryProvider),
    permissionGuard: ref.watch(permissionGuardProvider),
  );
});

final deleteCustomerUseCaseProvider = Provider<DeleteCustomer>((ref) {
  return DeleteCustomer(
    ref.watch(customerRepositoryProvider),
    permissionGuard: ref.watch(permissionGuardProvider),
  );
});

final upsertCustomersUseCaseProvider = Provider<UpsertCustomers>((ref) {
  return UpsertCustomers(
    ref.watch(customerRepositoryProvider),
    permissionGuard: ref.watch(permissionGuardProvider),
  );
});

final ensureCustomerAccountLinksProvider = Provider<EnsureCustomerAccountLinks>(
  (ref) {
    return EnsureCustomerAccountLinks(
      ref.watch(customerAccountLinkPortProvider),
    );
  },
);

/// Creates CoA posting accounts for customers that have no [Customer.accountId].
final linkMissingCustomerAccountsProvider =
    Provider<LinkMissingCustomerAccounts>((ref) {
      return LinkMissingCustomerAccounts(
        repository: ref.watch(customerRepositoryProvider),
        ensureLinks: ref.watch(ensureCustomerAccountLinksProvider),
        linkPort: ref.watch(customerAccountLinkPortProvider),
        settings: ref.watch(settingsRepositoryProvider),
      );
    });

class LinkMissingCustomerAccounts {
  const LinkMissingCustomerAccounts({
    required CustomerRepository repository,
    required EnsureCustomerAccountLinks ensureLinks,
    required CustomerAccountLinkPort linkPort,
    required SettingsRepository settings,
  }) : _repository = repository,
       _ensureLinks = ensureLinks,
       _linkPort = linkPort,
       _settings = settings;

  final CustomerRepository _repository;
  final EnsureCustomerAccountLinks _ensureLinks;
  final CustomerAccountLinkPort _linkPort;
  final SettingsRepository _settings;

  Future<LinkedAccountRef?> resolveParent() async {
    final savedId = await _settings.loadCustomersParentAccountId();
    if (savedId != null) {
      final linked = await _linkPort.findById(savedId);
      if (linked != null) {
        return linked;
      }
    }
    return _linkPort.findSystemCustomersParent();
  }

  /// Returns how many customers were newly linked.
  Future<int> call() async {
    final parent = await resolveParent();
    if (parent == null) {
      return 0;
    }
    final all = await _repository.getAll(includeInactive: true);
    var linkedCount = 0;
    for (final customer in all) {
      final existing = customer.accountId?.trim();
      if (existing != null && existing.isNotEmpty) {
        continue;
      }
      final draft = await _ensureLinks.apply(
        CustomerDraft(
          customerCode: customer.customerCode,
          name: customer.name,
          phone: customer.phone,
          email: customer.email,
          address: customer.address,
          notes: customer.notes,
          isActive: customer.isActive,
          externalId: customer.externalId,
          dataSource: customer.dataSource,
        ),
        parentId: parent.accountId,
      );
      final accountId = draft.accountId?.trim();
      if (accountId == null || accountId.isEmpty) {
        continue;
      }
      await _repository.update(
        customer.id,
        CustomerDraft(
          customerCode: customer.customerCode,
          name: customer.name,
          phone: customer.phone,
          email: customer.email,
          address: customer.address,
          notes: customer.notes,
          isActive: customer.isActive,
          accountId: accountId,
          externalId: customer.externalId,
          dataSource: customer.dataSource,
        ),
      );
      linkedCount++;
    }
    return linkedCount;
  }
}

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

/// Posting / group accounts nested under the configured customers parent CoA.
final customerAccountsUnderParentProvider =
    FutureProvider<List<LinkedAccountRef>>((ref) async {
      final parentAsync = ref.watch(customersParentAccountProvider);
      final parent = parentAsync.valueOrNull;
      if (parent == null) {
        return const [];
      }
      return ref
          .watch(customerAccountLinkPortProvider)
          .listUnderParent(parent.accountId);
    });

/// Whether customer save auto-creates a CoA posting account when none is set.
final customersAutoLinkAccountProvider =
    StateNotifierProvider<CustomersAutoLinkAccountController, AsyncValue<bool>>(
      (ref) {
        return CustomersAutoLinkAccountController(
          repository: ref.watch(settingsRepositoryProvider),
        );
      },
    );

class CustomersAutoLinkAccountController
    extends StateNotifier<AsyncValue<bool>> {
  CustomersAutoLinkAccountController({required SettingsRepository repository})
    : _repository = repository,
      super(const AsyncValue.loading()) {
    _load();
  }

  final SettingsRepository _repository;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.loadCustomersAutoLinkAccount);
  }

  Future<void> refresh() => _load();

  Future<void> setEnabled(bool enabled) async {
    await _repository.saveCustomersAutoLinkAccount(enabled);
    state = AsyncValue.data(enabled);
  }
}

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
