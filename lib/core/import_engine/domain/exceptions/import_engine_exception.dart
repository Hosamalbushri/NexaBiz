/// Base exception for all Universal Import Engine errors.
class ImportEngineException implements Exception {
  const ImportEngineException(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() =>
      'ImportEngineException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Thrown when an operational context is missing required company scoping.
class ImportContextException extends ImportEngineException {
  const ImportContextException(super.message, [super.code]);
}

/// Thrown when an invalid status transition is attempted on an [ImportJob] or pipeline stage.
class ImportStatusTransitionException extends ImportEngineException {
  const ImportStatusTransitionException(String fromStatus, String toStatus)
    : super(
        'Invalid status transition from "$fromStatus" to "$toStatus".',
        'INVALID_STATUS_TRANSITION',
      );
}

/// Thrown when an [ImportProfile] or field metadata definition fails validation.
class ImportProfileValidationException extends ImportEngineException {
  const ImportProfileValidationException(super.message, [super.code]);
}
