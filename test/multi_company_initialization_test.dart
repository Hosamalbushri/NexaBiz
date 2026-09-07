import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/ports/module_initializer.dart';
import 'package:stock_count/modules/system_setup/domain/services/default_module_initializers.dart';
import 'package:stock_count/modules/system_setup/domain/services/module_initialization_orchestrator.dart';

void main() {
  late Directory tempDir;
  late SettingsRepository settingsRepository;
  late String activeCompanyId;
  late CompanyInitializationRepositoryImpl companyRepo;
  late ModuleInitializationOrchestrator orchestrator;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_multi_company_test_');
    Hive.init(tempDir.path);
    activeCompanyId = 'company_A';
    settingsRepository = SettingsRepository();
    companyRepo = CompanyInitializationRepositoryImpl(
      readCompanyId: () => activeCompanyId,
    );
    orchestrator = ModuleInitializationOrchestrator(
      initializers: buildDefaultModuleInitializers(),
      settingsRepository: settingsRepository,
    );
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Multi-Company Initialization (SS-09)', () {
    test(
      'Company switching: A initialized -> switch B -> init B -> switch back A -> A unchanged',
      () async {
        // 1. Initialize Company A
        activeCompanyId = 'company_A';
        await orchestrator.initializeModules('company_A');

        var stateA = await companyRepo.getState();
        await companyRepo.saveState(
          stateA.copyWith(companyCreated: true, accountingConfigured: true),
        );

        expect(
          await orchestrator.isModuleInitialized(
            'company_A',
            ModuleId.accounting,
          ),
          isTrue,
        );

        // 2. Switch to Company B (uninitialized)
        activeCompanyId = 'company_B';
        expect(
          await orchestrator.isModuleInitialized(
            'company_B',
            ModuleId.accounting,
          ),
          isFalse,
        );
        var stateB = await companyRepo.getState();
        expect(stateB.companyCreated, isFalse);

        // 3. Initialize Company B
        await orchestrator.initializeModules('company_B');
        await companyRepo.saveState(
          stateB.copyWith(companyCreated: true, accountingConfigured: true),
        );

        expect(
          await orchestrator.isModuleInitialized(
            'company_B',
            ModuleId.accounting,
          ),
          isTrue,
        );

        // 4. Switch back to Company A
        activeCompanyId = 'company_A';
        stateA = await companyRepo.getState();

        expect(stateA.companyCreated, isTrue);
        expect(
          await orchestrator.isModuleInitialized(
            'company_A',
            ModuleId.accounting,
          ),
          isTrue,
        );
      },
    );

    test('Adversarial: Empty company ID throws ArgumentError', () async {
      expect(() => orchestrator.initializeModules('   '), throwsArgumentError);
    });

    test(
      'Adversarial: Restart after switching preserves company-specific initialization states',
      () async {
        activeCompanyId = 'company_A';
        await orchestrator.initializeModules('company_A');

        activeCompanyId = 'company_B';
        await orchestrator.initializeModules('company_B');

        // Simulate app restart
        final restoredOrchestrator = ModuleInitializationOrchestrator(
          initializers: buildDefaultModuleInitializers(),
          settingsRepository: settingsRepository,
        );

        expect(
          await restoredOrchestrator.isModuleInitialized(
            'company_A',
            ModuleId.accounting,
          ),
          isTrue,
        );
        expect(
          await restoredOrchestrator.isModuleInitialized(
            'company_B',
            ModuleId.accounting,
          ),
          isTrue,
        );
        expect(
          await restoredOrchestrator.isModuleInitialized(
            'company_C',
            ModuleId.accounting,
          ),
          isFalse,
        );
      },
    );
  });
}
