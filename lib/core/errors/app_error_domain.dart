import 'app_failure.dart';

/// Explicit error domains for classifying failures across the application lifecycle.
enum AppErrorCategory {
  /// Local storage, Hive, file system, or database startup errors.
  initialization,

  /// Network, server, or data synchronization errors.
  synchronization,

  /// Session, token, or permission errors.
  authentication,

  /// Network connectivity, DNS, or socket errors.
  network,

  /// Local database operation errors.
  database,

  /// Configuration parsing or invalid setup errors.
  configuration,

  /// TLS handshake, certificate pin, or security errors.
  tlsCertificate,

  /// Internal server error (500 range).
  server,

  /// Client input / payload validation error (400 / 422 range).
  validation,

  /// Unknown or unclassified errors.
  unknown,
}

/// Represents whether an error allows the application to operate in degraded / offline mode.
enum FailureSeverity {
  /// Application can still function offline or allow recovery (e.g. sync network down).
  recoverable,

  /// Application cannot function (e.g. unopenable database, corrupted storage).
  fatal,
}

/// Rich structured error containing category, severity, original exception, and user message.
class AppError implements Exception {
  const AppError({
    required this.category,
    required this.message,
    this.severity = FailureSeverity.recoverable,
    this.originalError,
    this.stackTrace,
    this.code,
  });

  final AppErrorCategory category;
  final String message;
  final FailureSeverity severity;
  final Object? originalError;
  final StackTrace? stackTrace;
  final String? code;

  bool get isFatal => severity == FailureSeverity.fatal;
  bool get isRecoverable => severity == FailureSeverity.recoverable;

  @override
  String toString() =>
      'AppError(category: $category, severity: $severity, code: $code, message: $message)';
}

/// Classifies any thrown exception into a structured [AppError].
AppError classifyAppError(
  Object error, {
  StackTrace? stackTrace,
  AppErrorCategory? category,
  FailureSeverity? severity,
}) {
  if (error is AppError) {
    return error;
  }
  if (error is AppFailure) {
    if (error is NetworkFailure) {
      return AppError(
        category: category ?? AppErrorCategory.network,
        message: error.message,
        severity: severity ?? FailureSeverity.recoverable,
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    if (error is AuthenticationFailure) {
      return AppError(
        category: category ?? AppErrorCategory.authentication,
        message: error.message,
        severity: severity ?? FailureSeverity.recoverable,
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    if (error is ServerFailure) {
      return AppError(
        category: category ?? AppErrorCategory.server,
        message: error.message,
        severity: severity ?? FailureSeverity.recoverable,
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  final msg = error.toString().toLowerCase();

  if (msg.contains('hive') || msg.contains('disk') || msg.contains('database') || msg.contains('sqlite') || msg.contains('drift')) {
    final isCorrupted = msg.contains('corrupt') || msg.contains('lock') || msg.contains('incompatible');
    return AppError(
      category: category ?? AppErrorCategory.database,
      message: 'Local database or storage error: $error',
      severity: severity ?? (isCorrupted ? FailureSeverity.fatal : FailureSeverity.recoverable),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  if (msg.contains('socket') || msg.contains('connect') || msg.contains('timeout') || msg.contains('dns')) {
    return AppError(
      category: category ?? AppErrorCategory.network,
      message: 'Network connectivity error: $error',
      severity: severity ?? FailureSeverity.recoverable,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  if (msg.contains('cert') || msg.contains('handshake') || msg.contains('tls') || msg.contains('ssl')) {
    return AppError(
      category: category ?? AppErrorCategory.tlsCertificate,
      message: 'Security/TLS error: $error',
      severity: severity ?? FailureSeverity.recoverable,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  return AppError(
    category: category ?? AppErrorCategory.unknown,
    message: error.toString(),
    severity: severity ?? FailureSeverity.recoverable,
    originalError: error,
    stackTrace: stackTrace,
  );
}
