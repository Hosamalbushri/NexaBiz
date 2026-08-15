/// App-wired port for idempotent local master-data seeds.
///
/// Implemented in App (must not import Accounting from this module).
abstract class SystemSetupSeedPort {
  /// Ensures default Chart of Accounts + voucher book sections exist.
  Future<void> ensureLocalDefaults();
}

/// No-op default until App overrides the provider.
class NoOpSystemSetupSeedPort implements SystemSetupSeedPort {
  const NoOpSystemSetupSeedPort();

  @override
  Future<void> ensureLocalDefaults() async {}
}
