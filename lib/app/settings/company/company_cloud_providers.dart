import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/di/app_providers.dart';
import '../../../core/entitlements/presentation/providers/entitlement_providers.dart';
import '../../../core/network/sync_api_config.dart';
import 'package:stock_count/modules/sync/sync.dart';
import '../../../core/tenancy/tenant_context.dart';
import '../../../modules/authentication/presentation/providers/auth_providers.dart';
import '../../presentation/providers/dashboard_services_provider.dart';
import '../settings_repository.dart';
import 'company_cloud_state.dart';

/// StateNotifier holding active [CompanyCloudState] for a specific local company.
class CompanyCloudStateNotifier extends StateNotifier<CompanyCloudState> {
  CompanyCloudStateNotifier(this._ref, this._localCompanyId)
      : super(CompanyCloudState.localDefault(_localCompanyId)) {
    _load();
  }

  final Ref _ref;
  final String _localCompanyId;

  Future<void> _load() async {
    final settingsRepo = _ref.read(settingsRepositoryProvider);
    final state = await settingsRepo.loadCompanyCloudState(_localCompanyId);
    if (mounted) {
      this.state = state;
    }
  }

  Future<void> updateState(CompanyCloudState newState) async {
    state = newState;
    final settingsRepo = _ref.read(settingsRepositoryProvider);
    await settingsRepo.saveCompanyCloudState(newState);
  }

  Future<void> setStatus(CompanyCloudStatus status, {String? serverCompanyId, String? planId, String? subscriptionId, String? error}) async {
    final updated = state.copyWith(
      cloudStatus: status,
      serverCompanyId: serverCompanyId ?? state.serverCompanyId,
      planId: planId ?? state.planId,
      subscriptionId: subscriptionId ?? state.subscriptionId,
      lastProvisioningError: error,
      clearLastProvisioningError: error == null,
      cloudLinkedAt: status == CompanyCloudStatus.cloudReady || status == CompanyCloudStatus.linked
          ? (state.cloudLinkedAt ?? DateTime.now().toUtc())
          : state.cloudLinkedAt,
    );
    await updateState(updated);
  }
}

/// Reactive provider exposing [CompanyCloudState] for the currently active company.
final companyCloudStateProvider =
    StateNotifierProvider<CompanyCloudStateNotifier, CompanyCloudState>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  return CompanyCloudStateNotifier(ref, companyId);
});

/// Async state for cloud provisioning workflow execution.
class ProvisioningStepProgress {
  const ProvisioningStepProgress({
    required this.status,
    required this.stepMessage,
    this.serverCompanyId,
    this.subscriptionId,
    this.planId,
    this.errorMessage,
    this.migrationProgress,
  });

  final CompanyCloudStatus status;
  final String stepMessage;
  final String? serverCompanyId;
  final String? subscriptionId;
  final String? planId;
  final String? errorMessage;
  final MigrationProgress? migrationProgress;

  bool get isProcessing =>
      status == CompanyCloudStatus.provisioning ||
      status == CompanyCloudStatus.cloudCompanyCreated ||
      status == CompanyCloudStatus.cloudAdminLinked ||
      status == CompanyCloudStatus.subscriptionPending ||
      status == CompanyCloudStatus.initialSyncing;

  bool get isSuccess => status == CompanyCloudStatus.cloudReady;
  bool get isFailed => status == CompanyCloudStatus.provisioningFailed;
}

class CompanyProvisioningController
    extends StateNotifier<AsyncValue<ProvisioningStepProgress>> {
  CompanyProvisioningController(this._ref)
      : super(const AsyncValue.data(ProvisioningStepProgress(
          status: CompanyCloudStatus.localOnly,
          stepMessage: 'Ready to upgrade',
        )));

  final Ref _ref;

  /// Full end-to-end cloud provisioning pipeline:
  /// LOCAL_ONLY -> PROVISIONING -> SERVER COMPANY -> CLOUD ADMIN -> PLAN SELECT -> SUBSCRIPTION -> ACTIVATION -> LINK -> INITIAL SYNC -> CLOUD_READY
  Future<void> runProvisioningAndActivation({
    required String companyName,
    required String planId,
    List<String> packageCodes = const [],
    String? paymentReference,
  }) async {
    final localCompanyId = _ref.read(currentCompanyIdProvider);
    final cloudNotifier = _ref.read(companyCloudStateProvider.notifier);
    final apiConfig = _ref.read(syncApiConfigProvider);
    final token = apiConfig.apiToken;
    final baseUrl = apiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');

    state = const AsyncValue.data(ProvisioningStepProgress(
      status: CompanyCloudStatus.provisioning,
      stepMessage: 'Creating cloud company & admin identity...',
    ));
    await cloudNotifier.setStatus(CompanyCloudStatus.provisioning);

    try {
      // 1. Backend Provisioning API
      final provisionUri = Uri.parse('$baseUrl/api/v1/companies/provision');
      final provisionRes = await http.post(
        provisionUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Company-Id': localCompanyId,
          'Idempotency-Key': 'prov_${localCompanyId}_${DateTime.now().millisecondsSinceEpoch}',
        },
        body: jsonEncode({
          'local_company_id': localCompanyId,
          'name': companyName,
        }),
      );

      if (provisionRes.statusCode < 200 || provisionRes.statusCode >= 300) {
        throw Exception('Server provisioning failed: ${provisionRes.body}');
      }

      final provisionJson = jsonDecode(provisionRes.body) as Map<String, dynamic>;
      final data = provisionJson['data'] as Map<String, dynamic>;
      final serverCompanyId = data['server_company_id'] as String;

      state = AsyncValue.data(ProvisioningStepProgress(
        status: CompanyCloudStatus.cloudAdminLinked,
        stepMessage: 'Cloud admin linked. Creating subscription...',
        serverCompanyId: serverCompanyId,
      ));
      await cloudNotifier.setStatus(
        CompanyCloudStatus.cloudAdminLinked,
        serverCompanyId: serverCompanyId,
      );

      // 2. Checkout Subscription API
      final checkoutUri = Uri.parse('$baseUrl/api/v1/companies/$serverCompanyId/subscription/checkout');
      final checkoutRes = await http.post(
        checkoutUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Company-Id': serverCompanyId,
        },
        body: jsonEncode({
          'plan_id': planId,
          'package_codes': packageCodes,
        }),
      );

      if (checkoutRes.statusCode < 200 || checkoutRes.statusCode >= 300) {
        throw Exception('Subscription checkout failed: ${checkoutRes.body}');
      }

      final checkoutJson = jsonDecode(checkoutRes.body) as Map<String, dynamic>;
      final checkoutData = checkoutJson['data'] as Map<String, dynamic>;
      final subscriptionId = checkoutData['subscription_id'] as String;

      state = AsyncValue.data(ProvisioningStepProgress(
        status: CompanyCloudStatus.subscriptionPending,
        stepMessage: 'Activating server subscription & entitlement...',
        serverCompanyId: serverCompanyId,
        subscriptionId: subscriptionId,
        planId: planId,
      ));
      await cloudNotifier.setStatus(
        CompanyCloudStatus.subscriptionPending,
        serverCompanyId: serverCompanyId,
        subscriptionId: subscriptionId,
        planId: planId,
      );

      // 3. Activate Subscription API
      final activateUri = Uri.parse('$baseUrl/api/v1/companies/$serverCompanyId/subscription/activate');
      final activateRes = await http.post(
        activateUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Company-Id': serverCompanyId,
          'Idempotency-Key': 'sub_act_${subscriptionId}_${DateTime.now().millisecondsSinceEpoch}',
        },
        body: jsonEncode({
          'subscription_id': subscriptionId,
          'payment_reference': paymentReference ?? 'PAY-LOCAL-ACTIVATE',
        }),
      );

      if (activateRes.statusCode < 200 || activateRes.statusCode >= 300) {
        throw Exception('Subscription activation failed: ${activateRes.body}');
      }

      state = AsyncValue.data(ProvisioningStepProgress(
        status: CompanyCloudStatus.linked,
        stepMessage: 'Server entitlement verified. Starting initial migration...',
        serverCompanyId: serverCompanyId,
        subscriptionId: subscriptionId,
        planId: planId,
      ));
      await cloudNotifier.setStatus(
        CompanyCloudStatus.linked,
        serverCompanyId: serverCompanyId,
        subscriptionId: subscriptionId,
        planId: planId,
      );

      // Invalidate entitlement provider to fetch remote signed snapshot
      _ref.invalidate(currentEntitlementProvider);

      // 4. Initial Cloud Data Migration
      state = AsyncValue.data(ProvisioningStepProgress(
        status: CompanyCloudStatus.initialSyncing,
        stepMessage: 'Migrating local workspace data to cloud...',
        serverCompanyId: serverCompanyId,
        subscriptionId: subscriptionId,
        planId: planId,
      ));
      await cloudNotifier.setStatus(CompanyCloudStatus.initialSyncing);

      final scanner = InitialCloudSyncScanner(_ref);
      final queue = _ref.read(syncQueueProvider);

      scanner.progress.listen((prog) {
        if (mounted) {
          state = AsyncValue.data(ProvisioningStepProgress(
            status: CompanyCloudStatus.initialSyncing,
            stepMessage: 'Uploading data: ${prog.processedCount} / ${prog.totalCount}',
            serverCompanyId: serverCompanyId,
            subscriptionId: subscriptionId,
            planId: planId,
            migrationProgress: prog,
          ));
        }
      });

      await scanner.runMigration(
        companyId: localCompanyId,
        deviceId: apiConfig.deviceId,
        queue: queue,
      );

      // 5. Final Transition -> CLOUD_READY
      await cloudNotifier.setStatus(
        CompanyCloudStatus.cloudReady,
        serverCompanyId: serverCompanyId,
        subscriptionId: subscriptionId,
        planId: planId,
      );

      // Start SyncManager background synchronization now that company is cloud ready
      final syncManager = _ref.read(syncManagerProvider);
      await syncManager.start(enabled: true);

      state = AsyncValue.data(ProvisioningStepProgress(
        status: CompanyCloudStatus.cloudReady,
        stepMessage: 'Cloud workspace ready!',
        serverCompanyId: serverCompanyId,
        subscriptionId: subscriptionId,
        planId: planId,
      ));
    } catch (e) {
      final errorMsg = e.toString();
      await cloudNotifier.setStatus(CompanyCloudStatus.provisioningFailed, error: errorMsg);
      state = AsyncValue.data(ProvisioningStepProgress(
        status: CompanyCloudStatus.provisioningFailed,
        stepMessage: 'Provisioning failed',
        errorMessage: errorMsg,
      ));
    }
  }

  /// Link an existing cloud company using admin account credentials:
  /// LOCAL_ONLY -> PROVISIONING -> LINKED -> INITIAL SYNC -> CLOUD_READY
  Future<void> linkExistingServerCompany({
    required String email,
    required String password,
    String? companyCode,
  }) async {
    final localCompanyId = _ref.read(currentCompanyIdProvider);
    final cloudNotifier = _ref.read(companyCloudStateProvider.notifier);
    final apiConfig = _ref.read(syncApiConfigProvider);
    final baseUrl = apiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');

    state = const AsyncValue.data(ProvisioningStepProgress(
      status: CompanyCloudStatus.provisioning,
      stepMessage: 'Authenticating cloud admin credentials...',
    ));
    await cloudNotifier.setStatus(CompanyCloudStatus.provisioning);

    try {
      final linkUri = Uri.parse('$baseUrl/api/v1/companies/link-existing');
      final response = await http.post(
        linkUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Idempotency-Key': 'link_${localCompanyId}_${DateTime.now().millisecondsSinceEpoch}',
        },
        body: jsonEncode({
          'local_company_id': localCompanyId,
          'email': email.trim(),
          'password': password,
          if (companyCode != null && companyCode.trim().isNotEmpty)
            'company_code': companyCode.trim(),
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errJson = jsonDecode(response.body);
        final message = errJson['message'] ?? response.body;
        throw Exception('Linking failed: $message');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      final serverCompanyId = data['server_company_id'] as String;

      state = AsyncValue.data(ProvisioningStepProgress(
        status: CompanyCloudStatus.linked,
        stepMessage: 'Server company linked. Verifying entitlement & starting migration...',
        serverCompanyId: serverCompanyId,
      ));
      await cloudNotifier.setStatus(
        CompanyCloudStatus.linked,
        serverCompanyId: serverCompanyId,
      );

      // Invalidate entitlement provider to fetch remote signed snapshot
      _ref.invalidate(currentEntitlementProvider);

      // Initial Cloud Data Migration
      state = AsyncValue.data(ProvisioningStepProgress(
        status: CompanyCloudStatus.initialSyncing,
        stepMessage: 'Migrating local workspace data to cloud...',
        serverCompanyId: serverCompanyId,
      ));
      await cloudNotifier.setStatus(CompanyCloudStatus.initialSyncing);

      final scanner = InitialCloudSyncScanner(_ref);
      final queue = _ref.read(syncQueueProvider);

      scanner.progress.listen((prog) {
        if (mounted) {
          state = AsyncValue.data(ProvisioningStepProgress(
            status: CompanyCloudStatus.initialSyncing,
            stepMessage: 'Uploading data: ${prog.processedCount} / ${prog.totalCount}',
            serverCompanyId: serverCompanyId,
            migrationProgress: prog,
          ));
        }
      });

      await scanner.runMigration(
        companyId: localCompanyId,
        deviceId: apiConfig.deviceId,
        queue: queue,
      );

      // Final Transition -> CLOUD_READY
      await cloudNotifier.setStatus(
        CompanyCloudStatus.cloudReady,
        serverCompanyId: serverCompanyId,
      );

      final syncManager = _ref.read(syncManagerProvider);
      await syncManager.start(enabled: true);

      state = AsyncValue.data(ProvisioningStepProgress(
        status: CompanyCloudStatus.cloudReady,
        stepMessage: 'Cloud workspace successfully linked!',
        serverCompanyId: serverCompanyId,
      ));
    } catch (e) {
      final errorMsg = e.toString();
      await cloudNotifier.setStatus(CompanyCloudStatus.provisioningFailed, error: errorMsg);
      state = AsyncValue.data(ProvisioningStepProgress(
        status: CompanyCloudStatus.provisioningFailed,
        stepMessage: 'Linking failed',
        errorMessage: errorMsg,
      ));
    }
  }
}

final companyProvisioningControllerProvider =
    StateNotifierProvider<CompanyProvisioningController, AsyncValue<ProvisioningStepProgress>>((ref) {
  return CompanyProvisioningController(ref);
});
