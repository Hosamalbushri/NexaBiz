import 'dart:async';
import 'dart:io';

class SyncLoginErrorClassifier {
  static bool isTlsCertificateFailure(Object error) {
    final text = error.toString().toLowerCase();
    if (error is HandshakeException) return true;
    if (error is HttpException) {
      final message = error.message.toLowerCase();
      return message.contains('certificate') ||
          message.contains('ssl') ||
          message.contains('handshake') ||
          message.contains('tls') ||
          message.contains('hostname');
    }
    return text.contains('certificate_verify_failed') ||
        text.contains('unable to get local issuer certificate') ||
        text.contains('unable to verify the first certificate') ||
        text.contains('self signed certificate') ||
        text.contains('ssl') ||
        text.contains('handshake') ||
        text.contains('hostname mismatch') ||
        text.contains('certificate');
  }

  static String uiMessageFor(Object error) {
    if (error is TimeoutException) {
      return 'The sync server timed out. Please try again.';
    }
    if (isTlsCertificateFailure(error)) {
      return 'Certificate validation failed. Check the backend certificate chain and hostname.';
    }
    if (error is SocketException || error is HttpException) {
      return 'Cannot reach the sync server. Check the network and server address.';
    }
    return 'Sign-in failed. Please try again.';
  }
}
