import 'domain_exception.dart';

/// Exception thrown when a required financial account mapping (inventory, cogs, adjustment, revenue, fxGainLoss)
/// is missing or unresolved during document posting.
class MissingAccountException extends DomainException {
  const MissingAccountException({
    required this.accountRole,
    required this.expectedCode,
    required this.systemKey,
    required String message,
  }) : super(message, code: 'missing_account');

  final String accountRole;
  final String expectedCode;
  final String systemKey;

  @override
  String toString() =>
      'MissingAccountException($accountRole, code: $expectedCode, key: $systemKey): $message';
}
