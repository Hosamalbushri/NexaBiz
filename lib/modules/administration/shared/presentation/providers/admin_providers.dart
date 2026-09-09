import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/core/auth/presentation/providers/auth_state_core.dart';
import '../../data/admin_api_repository.dart';
import '../../../domain/repositories/admin_repository.dart';
import '../../../domain/usecases/manage_admin_branches_usecase.dart';
import '../../../domain/usecases/manage_admin_companies_usecase.dart';
import '../../../domain/usecases/manage_admin_roles_usecase.dart';
import '../../../domain/usecases/manage_admin_users_usecase.dart';

import '../../data/local_admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return LocalAdminRepository(ref.watch(localAuthStoreProvider));
});

final adminApiRepositoryProvider = Provider<AdminRepository>((ref) {
  return ref.watch(adminRepositoryProvider);
});

final manageAdminUsersUseCaseProvider = Provider<ManageAdminUsersUseCase>((
  ref,
) {
  final authState = ref.watch(authStateProvider);
  return ManageAdminUsersUseCase(
    ref.watch(adminRepositoryProvider),
    permissionGuard: ref.watch(permissionGuardProvider),
  );
});

final manageAdminRolesUseCaseProvider = Provider<ManageAdminRolesUseCase>((
  ref,
) {
  final authState = ref.watch(authStateProvider);
  final isSuper = authState.session?.user.isSuperAdmin == true;
  return ManageAdminRolesUseCase(
    ref.watch(adminRepositoryProvider),
    permissionGuard: ref.watch(permissionGuardProvider),
    getUserPermissions: () => ref.watch(currentPermissionsProvider),
    isSuperAdmin: isSuper,
  );
});

final manageAdminCompaniesUseCaseProvider =
    Provider<ManageAdminCompaniesUseCase>((ref) {
      return ManageAdminCompaniesUseCase(
        ref.watch(adminRepositoryProvider),
        permissionGuard: ref.watch(permissionGuardProvider),
      );
    });

final manageAdminBranchesUseCaseProvider = Provider<ManageAdminBranchesUseCase>(
  (ref) {
    return ManageAdminBranchesUseCase(
      ref.watch(adminRepositoryProvider),
      permissionGuard: ref.watch(permissionGuardProvider),
    );
  },
);

final adminUsersProvider = FutureProvider.autoDispose<List<AdminUserSummary>>((
  ref,
) async {
  return ref.watch(manageAdminUsersUseCaseProvider).listUsers();
});

final adminRolesProvider = FutureProvider.autoDispose<List<AdminRoleSummary>>((
  ref,
) async {
  return ref.watch(manageAdminRolesUseCaseProvider).listRoles();
});

final adminCompaniesProvider =
    FutureProvider.autoDispose<List<AdminCompanySummary>>((ref) async {
      return ref.watch(manageAdminCompaniesUseCaseProvider).listCompanies();
    });

final adminBranchesProvider =
    FutureProvider.autoDispose<List<AdminBranchSummary>>((ref) async {
      return ref.watch(manageAdminBranchesUseCaseProvider).listBranches();
    });

final adminPermissionsCatalogProvider =
    FutureProvider.autoDispose<List<AdminPermissionInfo>>((ref) async {
      return ref.watch(manageAdminRolesUseCaseProvider).listPermissions();
    });

final adminSyncDisableRequestsProvider =
    FutureProvider.autoDispose<List<SyncDisableRequestSummary>>((ref) async {
      return ref
          .watch(adminApiRepositoryProvider)
          .listSyncDisableRequests(status: 'pending');
    });

final adminDevicesProvider =
    FutureProvider.autoDispose<List<AdminDeviceSummary>>((ref) async {
      return ref.watch(adminApiRepositoryProvider).listDevices();
    });
