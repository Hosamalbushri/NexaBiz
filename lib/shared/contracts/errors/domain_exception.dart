/// Base domain exception class for NexaBiz business logic errors.
/// Decouples business logic errors from infrastructure / database errors.
abstract class DomainException implements Exception {
  final String message;
  final String? code;

  const DomainException(this.message, {this.code});

  @override
  String toString() => 'DomainException($code): $message';
}
