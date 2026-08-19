import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Extra public CA roots that Android/Dart may not ship yet.
///
/// `api.rawnaqq.com` chains to **SSL.com TLS RSA Root CA 2022**. Desktop
/// OpenSSL often already trusts that root; many Android system stores
/// (especially API 33 and below) do not, which surfaces as
/// `CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate`.
///
/// This only *adds* a well-known public root. It does not disable
/// hostname or chain verification.
class TrustedRootCertificates {
  TrustedRootCertificates._();

  static const assetPath = 'assets/certs/ssl_com_tls_rsa_root_ca_2022.pem';

  static bool _installed = false;

  /// Install extra roots into [SecurityContext.defaultContext] before HTTP.
  static Future<void> install() async {
    if (_installed || kIsWeb) {
      return;
    }
    final data = await rootBundle.load(assetPath);
    try {
      SecurityContext.defaultContext.setTrustedCertificatesBytes(
        data.buffer.asUint8List(),
      );
    } on TlsException {
      // Already present in this process (desktop / second call).
    }
    _installed = true;
  }
}
