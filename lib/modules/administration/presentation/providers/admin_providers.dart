import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/admin_api_repository.dart';

final adminApiRepositoryProvider = Provider<AdminApiRepository>((ref) {
  return AdminApiRepository(ref.watch(authenticatedHttpClientProvider));
});

final adminUsersProvider =
    FutureProvider.autoDispose<List<AdminUserSummary>>((ref) async {
  return ref.watch(adminApiRepositoryProvider).listUsers();
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
