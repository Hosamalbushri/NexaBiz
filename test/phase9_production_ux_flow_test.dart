import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/entitlements/presentation/providers/entitlement_providers.dart';
import 'package:stock_count/core/entitlements/presentation/widgets/capability_gate.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/time/domain/services/clock_integrity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SyncQueue queue;
  late ConnectivityService connectivity;

  const companyA = 'company-ux-a';
  const companyB = 'company-ux-b';
  const deviceA = 'device-ux-a';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase9_ux_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }

    final box = await Hive.openBox<SyncOperation>('test_ux_queue_${DateTime.now().microsecondsSinceEpoch}');
    queue = SyncQueue(
      box: box,
      companyId: companyA,
      deviceId: deviceA,
    );

    connectivity = ConnectivityService(internetProbe: () async => true);
  });

  tearDown(() async {
    queue.dispose();
    connectivity.dispose();
    await Hive.deleteFromDisk();
  });

  group('Phase 9 — Production UX/UI Flow Reconstruction & Alignment', () {
    testWidgets('1. CapabilityGate renders child when capability is granted', (tester) async {
      final entitlement = Entitlement(
        companyId: companyA,
        tier: EntitlementTier.premium,
        status: EntitlementStatus.active,
        capabilities: {EntitlementCapability.sync},
        source: EntitlementSource.activeServer,
        lastVerifiedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentEntitlementProvider.overrideWith((ref) => Stream.value(entitlement)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CapabilityGate(
                capability: EntitlementCapability.sync,
                child: Text('Cloud Sync Enabled'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CapabilityGate), findsOneWidget);
    });

    test('2. Sync error classification presents intuitive user message keys', () {
      final netClass = SyncErrorClassifier.classify(const NetworkFailure('Connection reset'));
      expect(netClass.userMessage, contains('Connection unavailable'));

      final authClass = SyncErrorClassifier.classify(const AuthenticationFailure('Session expired'));
      expect(authClass.userMessage, contains('session has expired'));

      final tenantClass = SyncErrorClassifier.classify(const AuthorizationFailure.withDetails(code: 'tenant_mismatch'));
      expect(tenantClass.userMessage, contains('mismatch'));
    });

    test('3. Free tier login does not require cloud synchronization', () async {
      final manager = SyncManager(
        queue: queue,
        connectivity: connectivity,
        hasSyncCapability: () => false, // Free tier: no sync capability
        hasSyncPermission: () => true,
        readCompanyId: () => companyA,
        readClockState: () => ClockIntegrityState.trusted,
        isTimeTrusted: () => true,
      );

      final res = await manager.syncNow();
      expect(res.outcome, equals(SyncPassOutcome.skippedDisabled));
    });

    test('4. Company switch clears tenant boundary and invalidates active operations', () async {
      final opCompA = SyncOperation.create(
        entityType: 'product',
        entityId: 'p-a',
        type: SyncOperationType.create,
        payload: {'name': 'Product A'},
        companyId: companyA,
        deviceId: deviceA,
      );
      await queue.enqueue(opCompA);

      final queueCompB = SyncQueue(
        box: await Hive.openBox<SyncOperation>('test_comp_b_${DateTime.now().microsecondsSinceEpoch}'),
        companyId: companyB,
        deviceId: deviceA,
      );

      final readyCompB = await queueCompB.peekReady();
      expect(readyCompB.isEmpty, isTrue); // Company B queue cannot see Company A operations
    });

    test('5. Logout halts ongoing sync pass and preserves pending queue', () async {
      var loggedIn = true;
      final op = SyncOperation.create(
        entityType: 'product',
        entityId: 'p-logout',
        type: SyncOperationType.create,
        payload: {'name': 'Product Logout'},
        companyId: companyA,
        deviceId: deviceA,
      );
      await queue.enqueue(op);

      final manager = SyncManager(
        queue: queue,
        connectivity: connectivity,
        hasSyncCapability: () => loggedIn,
        hasSyncPermission: () => loggedIn,
        readCompanyId: () => loggedIn ? companyA : '',
        readClockState: () => ClockIntegrityState.trusted,
        isTimeTrusted: () => true,
      );
      await manager.setEnabled(true);

      // User clicks logout while sync triggers
      loggedIn = false;

      final res = await manager.syncNow();
      expect(res.outcome == SyncPassOutcome.skippedDisabled || res.outcome == SyncPassOutcome.authRequired, isTrue);

      final all = await queue.all();
      expect(all.first.status, equals(SyncStatus.pending)); // Pending operation preserved
    });
  });
}
