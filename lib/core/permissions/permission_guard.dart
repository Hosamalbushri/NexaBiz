/// Domain authorization gate for mutate use cases.
///
/// UI [PermissionGate] remains UX-only; use cases must call [requireAny] so
/// repository/service calls cannot bypass offline RBAC.
class PermissionDeniedException implements Exception {
  const PermissionDeniedException(
    this.requiredAny, {
    this.message,
  });

  static const code = 'permission_denied';

  /// Codes that would have satisfied the check (any-of).
  final List<String> requiredAny;
  final String? message;

  @override
  String toString() =>
      'PermissionDeniedException(${requiredAny.join(', ')}'
      '${message == null ? '' : ': $message'})';
}

/// Checks the current session permission snapshot.
abstract class PermissionGuard {
  /// Throws [PermissionDeniedException] when none of [codes] are granted.
  void requireAny(Iterable<String> codes);
}

/// Test / system jobs: never denies.
class AllowAllPermissionGuard implements PermissionGuard {
  const AllowAllPermissionGuard();

  @override
  void requireAny(Iterable<String> codes) {}
}

/// Production guard backed by a permission predicate (usually auth session).
class CallbackPermissionGuard implements PermissionGuard {
  const CallbackPermissionGuard(this._hasAny);

  final bool Function(Iterable<String> codes) _hasAny;

  @override
  void requireAny(Iterable<String> codes) {
    final required = [
      for (final code in codes)
        if (code.trim().isNotEmpty) code.trim(),
    ];
    if (required.isEmpty) {
      return;
    }
    if (!_hasAny(required)) {
      throw PermissionDeniedException(required);
    }
  }
}
