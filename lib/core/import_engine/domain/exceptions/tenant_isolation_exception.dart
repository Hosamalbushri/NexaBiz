/// Exception thrown whenever cross-company tenant isolation is violated in the Universal Import Engine.
class TenantIsolationException implements Exception {
  final String message;
  final String? expectedCompanyId;
  final String? attemptedCompanyId;

  const TenantIsolationException(
    this.message, {
    this.expectedCompanyId,
    this.attemptedCompanyId,
  });

  @override
  String toString() {
    return 'TenantIsolationException: $message (Expected: $expectedCompanyId, Attempted: $attemptedCompanyId)';
  }
}
