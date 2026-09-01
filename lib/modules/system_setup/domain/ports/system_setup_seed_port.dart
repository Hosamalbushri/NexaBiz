import 'system_setup_seed_exception.dart';

/// App-wired port for Chart of Accounts / voucher-book bootstrap.
///
/// Implemented in App (must not import Accounting from this module).
abstract class SystemSetupSeedPort {
  /// First device / offline: create default CoA + voucher book sections locally.
  Future<void> ensureLocalDefaults({
    String? baseCurrency,
    String? defaultWarehouseName,
    String? defaultWarehouseCode,
  });

  /// Joining device: mark setup complete immediately and pull CoA in the
  /// background. Must not await network or heavy local seeds — only persist
  /// the "prefer remote chart" preference. Throws [SystemSetupSeedException]
  /// only when sync is not enabled yet.
  Future<void> pullRemoteDefaults();
}

/// No-op default until App overrides the provider.
class NoOpSystemSetupSeedPort implements SystemSetupSeedPort {
  const NoOpSystemSetupSeedPort();

  @override
  Future<void> ensureLocalDefaults({
    String? baseCurrency,
    String? defaultWarehouseName,
    String? defaultWarehouseCode,
  }) async {}

  @override
  Future<void> pullRemoteDefaults() async {}
}
