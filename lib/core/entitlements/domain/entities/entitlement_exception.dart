import 'entitlement.dart';

/// Exception thrown at domain boundaries when a requested capability is denied.
class EntitlementException implements Exception {
  const EntitlementException({
    required this.code,
    required this.message,
    this.capability,
  });

  final String code;
  final String message;
  final EntitlementCapability? capability;

  static const String capabilityDeniedCode = 'capability_denied';
  static const String entitlementExpiredCode = 'entitlement_expired';

  factory EntitlementException.capabilityDenied(EntitlementCapability capability) {
    return EntitlementException(
      code: capabilityDeniedCode,
      message: 'Capability "${capability.name}" is not granted under the active entitlement.',
      capability: capability,
    );
  }

  factory EntitlementException.expired(String companyId) {
    return EntitlementException(
      code: entitlementExpiredCode,
      message: 'Entitlement for company "$companyId" has expired. Online verification required.',
    );
  }

  @override
  String toString() => 'EntitlementException($code): $message';
}
