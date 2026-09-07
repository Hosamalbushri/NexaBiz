import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../lib/app/settings/settings_repository.dart';
import '../lib/modules/system_setup/domain/ports/module_initializer.dart';
import '../lib/modules/system_setup/domain/services/default_module_initializers.dart';
import '../lib/modules/system_setup/domain/services/module_initialization_orchestrator.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_module_init_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ModuleInitializationOrchestrator', () {
    late SettingsRepository settingsRepository;

    setUp(() {
      settingsRepository = SettingsRepository();
    });

    test('executionOrder returns valid topological sort of modules', () {
      final initializers = buildDefaultModuleInitializers();
      final orchestrator = ModuleInitializationOrchestrator(
        initializers: initializers,
        settingsRepository: settingsRepository,
      );

      final order = orchestrator.executionOrder.map((m) => m.id).toList();

      expect(
        order.indexOf(ModuleId.administration),
        lessThan(order.indexOf(ModuleId.authentication)),
      );
      expect(
        order.indexOf(ModuleId.authentication),
        lessThan(order.indexOf(ModuleId.accounting)),
      );
      expect(
        order.indexOf(ModuleId.accounting),
        lessThan(order.indexOf(ModuleId.inventory)),
      );
      expect(
        order.indexOf(ModuleId.inventory),
        lessThan(order.indexOf(ModuleId.sales)),
      );
      expect(
        order.indexOf(ModuleId.sales),
        lessThan(order.indexOf(ModuleId.reports)),
      );
      expect(
        order.indexOf(ModuleId.reports),
        lessThan(order.indexOf(ModuleId.sync)),
      );
    });

    test('initializes modules in order and marks them complete', () async {
      final executed = <ModuleId>[];
      final initializers = [
        BaseModuleInitializer(
          id: ModuleId.administration,
          onInitialize: (c) async => executed.add(ModuleId.administration),
        ),
        BaseModuleInitializer(
          id: ModuleId.authentication,
          dependencies: {ModuleId.administration},
          onInitialize: (c) async => executed.add(ModuleId.authentication),
        ),
      ];

      final orchestrator = ModuleInitializationOrchestrator(
        initializers: initializers,
        settingsRepository: settingsRepository,
      );

      await orchestrator.initializeModules('company_1');

      expect(executed, [ModuleId.administration, ModuleId.authentication]);
      expect(
        await orchestrator.isModuleInitialized(
          'company_1',
          ModuleId.administration,
        ),
        isTrue,
      );
      expect(
        await orchestrator.isModuleInitialized(
          'company_1',
          ModuleId.authentication,
        ),
        isTrue,
      );
    });

    test('failed prerequisite stops dependent initialization', () async {
      final executed = <ModuleId>[];
      final initializers = [
        BaseModuleInitializer(
          id: ModuleId.administration,
          onInitialize: (c) async {
            executed.add(ModuleId.administration);
            throw StateError('Database connection error');
          },
        ),
        BaseModuleInitializer(
          id: ModuleId.authentication,
          dependencies: {ModuleId.administration},
          onInitialize: (c) async => executed.add(ModuleId.authentication),
        ),
      ];

      final orchestrator = ModuleInitializationOrchestrator(
        initializers: initializers,
        settingsRepository: settingsRepository,
      );

      await expectLater(
        orchestrator.initializeModules('company_1'),
        throwsA(isA<StateError>()),
      );

      expect(executed, [ModuleId.administration]);
      expect(
        await orchestrator.isModuleInitialized(
          'company_1',
          ModuleId.administration,
        ),
        isFalse,
      );
      expect(
        await orchestrator.isModuleInitialized(
          'company_1',
          ModuleId.authentication,
        ),
        isFalse,
      );
    });

    test(
      'retry resumes from failed module without re-running completed ones',
      () async {
        var adminAttempts = 0;
        var authAttempts = 0;
        var shouldFailAdmin = true;

        final initializers = [
          BaseModuleInitializer(
            id: ModuleId.administration,
            onInitialize: (c) async {
              adminAttempts++;
              if (shouldFailAdmin) {
                throw StateError('Transient error');
              }
            },
          ),
          BaseModuleInitializer(
            id: ModuleId.authentication,
            dependencies: {ModuleId.administration},
            onInitialize: (c) async => authAttempts++,
          ),
        ];

        final orchestrator = ModuleInitializationOrchestrator(
          initializers: initializers,
          settingsRepository: settingsRepository,
        );

        // Attempt 1 fails
        await expectLater(
          orchestrator.initializeModules('company_1'),
          throwsA(isA<StateError>()),
        );
        expect(adminAttempts, 1);
        expect(authAttempts, 0);

        // Attempt 2 succeeds
        shouldFailAdmin = false;
        await orchestrator.initializeModules('company_1');
        expect(adminAttempts, 2);
        expect(authAttempts, 1);

        // Attempt 3 re-runs (idempotent, skips completed modules)
        await orchestrator.initializeModules('company_1');
        expect(adminAttempts, 2);
        expect(authAttempts, 1);
      },
    );

    test(
      'multi-tenant isolation: company_1 completion does not mark company_2 complete',
      () async {
        final initializers = buildDefaultModuleInitializers();
        final orchestrator = ModuleInitializationOrchestrator(
          initializers: initializers,
          settingsRepository: settingsRepository,
        );

        await orchestrator.initializeModules('company_A');

        expect(
          await orchestrator.isModuleInitialized(
            'company_A',
            ModuleId.accounting,
          ),
          isTrue,
        );
        expect(
          await orchestrator.isModuleInitialized(
            'company_B',
            ModuleId.accounting,
          ),
          isFalse,
        );
      },
    );
  });
}
