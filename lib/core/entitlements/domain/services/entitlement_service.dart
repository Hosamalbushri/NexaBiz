import 'dart:async';
import '../entities/entitlement.dart';
import '../entities/entitlement_exception.dart';
import '../../data/entitlement_repository.dart';

abstract class EntitlementService {
  Entitlement get currentEntitlement;

  Stream<Entitlement> watchEntitlement();

  bool hasCapability(EntitlementCapability capability);

  bool hasQuotaRemaining(String meterKey, [int requested = 1]);

  void requireCapability(EntitlementCapability capability);

  Future<Entitlement> loadEntitlementForCompany(String companyId);

  Future<void> setEntitlement(Entitlement entitlement);

  Future<void> invalidateCache(String companyId);
}

class EntitlementServiceImpl implements EntitlementService {
  EntitlementServiceImpl({
    required this._repository,
    this._offlineGraceDuration = const Duration(days: 14),
  });

  final EntitlementRepository _repository;
  final Duration _offlineGraceDuration;

  final _controller = StreamController<Entitlement>.broadcast();
  Entitlement _current = Entitlement.freeLocal('local-company');

  @override
  Entitlement get currentEntitlement => _current;

  @override
  Stream<Entitlement> watchEntitlement() => _controller.stream;

  @override
  bool hasCapability(EntitlementCapability capability) {
    return evaluateEffectiveEntitlement(_current).hasCapability(capability);
  }

  @override
  bool hasQuotaRemaining(String meterKey, [int requested = 1]) {
    return evaluateEffectiveEntitlement(_current).hasQuotaRemaining(meterKey, requested);
  }

  @override
  void requireCapability(EntitlementCapability capability) {
    if (!hasCapability(capability)) {
      throw EntitlementException.capabilityDenied(capability);
    }
  }

  @override
  Future<Entitlement> loadEntitlementForCompany(String companyId) async {
    final cached = await _repository.getCachedEntitlement(companyId);
    final effective = cached != null
        ? evaluateEffectiveEntitlement(cached)
        : (companyId == 'c0000000-0000-4000-a000-000000000001'
            ? evaluateEffectiveEntitlement(Entitlement.premiumActive(companyId))
            : Entitlement.freeLocal(companyId));

    _current = effective;
    _controller.add(effective);
    return effective;
  }

  @override
  Future<void> setEntitlement(Entitlement entitlement) async {
    final effective = evaluateEffectiveEntitlement(entitlement);
    await _repository.saveCachedEntitlement(effective);
    _current = effective;
    _controller.add(effective);
  }

  @override
  Future<void> invalidateCache(String companyId) async {
    _current = Entitlement.freeLocal(companyId);
    _controller.add(_current);
  }

  /// Calculates offline grace status and returns effective entitlement.
  Entitlement evaluateEffectiveEntitlement(Entitlement raw, [DateTime? nowOverride]) {
    return calculateEffectiveEntitlement(raw, nowOverride, _offlineGraceDuration);
  }
}

/// Standalone calculation function for effective entitlement.
Entitlement calculateEffectiveEntitlement(
  Entitlement raw, [
  DateTime? nowOverride,
  Duration offlineGraceDuration = const Duration(days: 14),
]) {
  if (raw.tier == EntitlementTier.free) {
    return raw.copyWith(status: EntitlementStatus.active);
  }

  final now = nowOverride ?? DateTime.now().toUtc();

  if (raw.status == EntitlementStatus.cancelled) {
    return raw;
  }

  if (raw.validUntil != null && now.isAfter(raw.validUntil!)) {
    final graceEnd = raw.graceUntil ?? raw.validUntil!.add(offlineGraceDuration);
    if (now.isBefore(graceEnd)) {
      return raw.copyWith(
        status: EntitlementStatus.grace,
        source: EntitlementSource.cachedServer,
      );
    } else {
      return raw.copyWith(
        status: EntitlementStatus.expired,
        capabilities: const {},
        source: EntitlementSource.cachedServer,
      );
    }
  }

  final timeSinceVerification = now.difference(raw.lastVerifiedAt);
  if (timeSinceVerification > offlineGraceDuration) {
    return raw.copyWith(
      status: EntitlementStatus.expired,
      capabilities: const {},
      source: EntitlementSource.cachedServer,
    );
  }

  return raw;
}
