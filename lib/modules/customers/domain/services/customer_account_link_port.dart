/// Lightweight Chart of Accounts reference resolved outside this module.
///
/// [accountId] matches Account.uuid in the Accounting module.
class LinkedAccountRef {
  const LinkedAccountRef({
    required this.accountId,
    required this.code,
    required this.name,
    this.isPosting = true,
    this.isGroup = false,
  });

  final String accountId;
  final String code;
  final String name;
  final bool isPosting;
  final bool isGroup;
}

/// Vendor-/module-agnostic lookup for linking customers to accounts.
///
/// Default is [NoOpCustomerAccountLinkPort]. App overrides with an adapter
/// that uses Accounting's AccountRepository (modules must not import each other).
abstract class CustomerAccountLinkPort {
  /// Resolve by stable Account.uuid.
  Future<LinkedAccountRef?> findById(String accountId);

  /// Resolve by uuid or account code (e.g. `121001`) — posting accounts.
  Future<LinkedAccountRef?> resolve(String input);

  /// Search posting accounts for picker UI.
  Future<List<LinkedAccountRef>> search(String query, {int limit = 20});

  /// Default Chart of Accounts parent for customer accounts (`system:customers`).
  Future<LinkedAccountRef?> findSystemCustomersParent();

  /// Resolve a **group** account suitable as the customers parent.
  Future<LinkedAccountRef?> resolveParent(String input);

  /// Search group accounts for the parent-account picker.
  Future<List<LinkedAccountRef>> searchParentCandidates(
    String query, {
    int limit = 20,
  });

  /// Whether [accountId] is [parentId] or a descendant under that parent.
  Future<bool> isUnderParent({
    required String accountId,
    required String parentId,
  });
}

/// Safe default until App wires Accounting.
class NoOpCustomerAccountLinkPort implements CustomerAccountLinkPort {
  const NoOpCustomerAccountLinkPort();

  @override
  Future<LinkedAccountRef?> findById(String accountId) async => null;

  @override
  Future<LinkedAccountRef?> resolve(String input) async => null;

  @override
  Future<List<LinkedAccountRef>> search(String query, {int limit = 20}) async {
    return const [];
  }

  @override
  Future<LinkedAccountRef?> findSystemCustomersParent() async => null;

  @override
  Future<LinkedAccountRef?> resolveParent(String input) async => null;

  @override
  Future<List<LinkedAccountRef>> searchParentCandidates(
    String query, {
    int limit = 20,
  }) async {
    return const [];
  }

  @override
  Future<bool> isUnderParent({
    required String accountId,
    required String parentId,
  }) async {
    return false;
  }
}
