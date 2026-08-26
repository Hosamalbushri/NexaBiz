import 'dart:developer' as developer;

/// Structured logger for sensitive security events.
///
/// Ensures compliance with security requirements by redacting any secrets, tokens,
/// passwords, or sensitive credentials.
class SecurityLogger {
  const SecurityLogger._();

  /// Logs a security event with cleansed metadata.
  static void logEvent(String eventName, {Map<String, dynamic>? metadata}) {
    final cleanMetadata = <String, dynamic>{};
    if (metadata != null) {
      for (final entry in metadata.entries) {
        final key = entry.key.toLowerCase();
        if (key.contains('password') ||
            key.contains('token') ||
            key.contains('secret') ||
            key.contains('key') ||
            key.contains('auth') ||
            key.contains('credential')) {
          cleanMetadata[entry.key] = '[REDACTED]';
        } else {
          cleanMetadata[entry.key] = entry.value;
        }
      }
    }

    developer.log(
      'SECURITY EVENT: $eventName',
      name: 'nexabiz.security',
      error: cleanMetadata.isEmpty ? null : cleanMetadata,
      time: DateTime.now().toUtc(),
    );
  }
}
