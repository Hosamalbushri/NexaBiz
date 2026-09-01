/// Exception thrown when a required financial account mapping (inventory, cogs, adjustment, revenue, fxGainLoss)
/// is missing or unresolved during document posting.
class MissingAccountException implements Exception {
  const MissingAccountException({
    required this.accountRole,
    required this.expectedCode,
    required this.systemKey,
    required this.message,
  });

  final String accountRole;
  final String expectedCode;
  final String systemKey;
  final String message;

  @override
  String toString() => 'MissingAccountException($accountRole, code: $expectedCode, key: $systemKey): $message';
}
