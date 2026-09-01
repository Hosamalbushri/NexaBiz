import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import '../../data/admin_api_repository.dart';
import '../../../domain/repositories/admin_repository.dart';
import '../../../domain/usecases/manage_admin_roles_usecase.dart';
import '../../../domain/usecases/manage_admin_users_usecase.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminApiRepository(ref.watch(authenticatedHttpClientProvider));
});

final adminApiRepositoryProvider = Provider<AdminApiRepository>((ref) {
  return ref.watch(adminRepositoryProvider) as AdminApiRepository;
});

final manageAdminUsersUseCaseProvider =
    Provider<ManageAdminUsersUseCase>((ref) {
  return ManageAdminUsersUseCase(ref.watch(adminRepositoryProvider));
});

final manageAdminRolesUseCaseProvider =
    Provider<ManageAdminRolesUseCase>((ref) {
  return ManageAdminRolesUseCase(ref.watch(adminRepositoryProvider));
});

final adminUsersProvider =
    FutureProvider.autoDispose<List<AdminUserSummary>>((ref) async {
  return ref.watch(manageAdminUsersUseCaseProvider).listUsers();
});


final adminRolesProvider =
    FutureProvider.autoDispose<List<AdminRoleSummary>>((ref) async {
  return ref.watch(adminApiRepositoryProvider).listRoles();
});

final adminPermissionsCatalogProvider =
    FutureProvider.autoDispose<List<AdminPermissionInfo>>((ref) async {
  return ref.watch(adminApiRepositoryProvider).listPermissions();
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
