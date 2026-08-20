import 'dart:async';

import 'package:http/http.dart' as http;

/// Lightweight pre-flight check for a sync server URL.
///
/// Does not authenticate — only verifies the server is reachable and
/// responds to a basic health probe.
class ServerValidator {
  const ServerValidator._();

  /// Validates [baseUrl] by issuing a short-lived GET to the server root.
  ///
  /// Returns [ServerValidationResult] with connectivity status.
  static Future<ServerValidationResult> validate(String baseUrl) async {
    final url = baseUrl.trim();
    if (url.isEmpty) {
      return const ServerValidationResult(
        healthy: false,
        error: 'Server address is empty',
      );
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return const ServerValidationResult(
        healthy: false,
        error: 'Invalid URL format',
      );
    }

    // Normalise: strip trailing slash.
    final base = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

    // Try a health endpoint first, fall back to root.
    final endpoints = ['/api/v1/health', '/health', '/'];
    for (final endpoint in endpoints) {
      final probeUri = Uri.parse('$base$endpoint');
      try {
        final response = await http
            .get(probeUri)
            .timeout(const Duration(seconds: 8));

        if (response.statusCode >= 200 && response.statusCode < 500) {
          // Server is alive (404 is fine — means server is up, just no health route).
          return ServerValidationResult(
            healthy: true,
            baseUrl: base,
            statusCode: response.statusCode,
          );
        }
      } on TimeoutException {
        continue;
      } on http.ClientException {
        continue;
      } catch (_) {
        continue;
      }
    }

    return const ServerValidationResult(
      healthy: false,
      error: 'Could not connect to server',
    );
  }
}

/// Result of a [ServerValidator.validate] probe.
class ServerValidationResult {
  const ServerValidationResult({
    required this.healthy,
    this.baseUrl,
    this.statusCode,
    this.error,
  });

  final bool healthy;
  final String? baseUrl;
  final int? statusCode;
  final String? error;
}
