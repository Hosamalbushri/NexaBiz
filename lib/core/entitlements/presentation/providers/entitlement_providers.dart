import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/settings/company/company_cloud_providers.dart';
import '../../../../core/tenancy/tenant_context.dart';
import '../../data/entitlement_repository.dart';
import '../../domain/entities/entitlement.dart';
import '../../domain/services/entitlement_service.dart';

final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return EntitlementRepositoryImpl();
});

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  final repo = ref.watch(entitlementRepositoryProvider);
  return EntitlementServiceImpl(repository: repo);
});

/// Reactive provider exposing the current effective [Entitlement] for the active company.
final currentEntitlementProvider = StreamProvider<Entitlement>((ref) async* {
  final companyId = ref.watch(currentCompanyIdProvider);
  final cloudState = ref.watch(companyCloudStateProvider);
  final service = ref.watch(entitlementServiceProvider);

  // If local-only or not cloud-ready, return free local entitlement
  if (cloudState.isLocalOnly || (!cloudState.isCloudReady && !cloudState.isCloudLinked)) {
    yield Entitlement.freeLocal(companyId);
    return;
  }

  // Load entitlement for cloud-linked company
  final initial = await service.loadEntitlementForCompany(companyId);
  yield initial;

  // Stream updates
  await for (final entitlement in service.watchEntitlement()) {
    if (entitlement.companyId == companyId) {
      yield entitlement;
    }
  }
});
