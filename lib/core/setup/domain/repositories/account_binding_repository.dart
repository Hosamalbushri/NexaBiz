import '../entities/account_binding.dart';

/// Repository interface for persisting and retrieving tenant-scoped account bindings.
abstract class AccountBindingRepository {
  /// Loads a specific account binding for [companyId], [packageId], and [requirementKey].
  Future<AccountBinding?> getBinding({
    required String companyId,
    required String packageId,
    required String requirementKey,
  });

  /// Loads all account bindings registered for [companyId] and [packageId].
  Future<List<AccountBinding>> getBindingsForPackage({
    required String companyId,
    required String packageId,
  });

  /// Saves an account binding.
  Future<void> saveBinding(AccountBinding binding);

  /// Removes an account binding.
  Future<void> removeBinding({
    required String companyId,
    required String packageId,
    required String requirementKey,
  });

  /// Clears all bindings (useful for testing or profile resets).
  Future<void> clear();
}

/// In-memory implementation of [AccountBindingRepository] enforcing company isolation.
class InMemoryAccountBindingRepository implements AccountBindingRepository {
  final Map<String, AccountBinding> _store = {};

  String _buildKey(String companyId, String packageId, String requirementKey) {
    return '${companyId.trim()}:${packageId.trim()}:${requirementKey.trim()}';
  }

  @override
  Future<AccountBinding?> getBinding({
    required String companyId,
    required String packageId,
    required String requirementKey,
  }) async {
    final key = _buildKey(companyId, packageId, requirementKey);
    return _store[key];
  }

  @override
  Future<List<AccountBinding>> getBindingsForPackage({
    required String companyId,
    required String packageId,
  }) async {
    final prefix = '${companyId.trim()}:${packageId.trim()}:';
    final list = _store.entries
        .where((e) => e.key.startsWith(prefix))
        .map((e) => e.value)
        .toList(growable: false);
    return List.unmodifiable(list);
  }

  @override
  Future<void> saveBinding(AccountBinding binding) async {
    final key = _buildKey(binding.companyId, binding.packageId, binding.requirementKey);
    _store[key] = binding;
  }

  @override
  Future<void> removeBinding({
    required String companyId,
    required String packageId,
    required String requirementKey,
  }) async {
    final key = _buildKey(companyId, packageId, requirementKey);
    _store.remove(key);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}
