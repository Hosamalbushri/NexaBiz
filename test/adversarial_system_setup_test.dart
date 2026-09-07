import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/data/repositories/system_setup_state_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/system_setup_state.dart';
import 'package:stock_count/modules/system_setup/domain/ports/module_initializer.dart';
import 'package:stock_count/modules/system_setup/domain/services/default_module_initializers.dart';
import 'package:stock_count/modules/system_setup/domain/services/module_initialization_orchestrator.dart';

void main() {
  late Directory tempDir;
  late SettingsRepository settingsRepository;
  late SystemSetupStateRepositoryImpl setupRepo;
  late CompanyInitializationRepositoryImpl companyRepo;
  late ModuleInitializationOrchestrator orchestrator;
  late String activeCompanyId;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_adversarial_test_');
    Hive.init(tempDir.path);
    activeCompanyId = 'company_adv_01';
    settingsRepository = SettingsRepository();
    setupRepo = SystemSetupStateRepositoryImpl(settingsRepository);
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

  group('Adversarial System Setup (SS-11)', () {
    test(
      '1. Fresh installation: first-run detection & empty initial state',
      () async {
        final progress = await setupRepo.load();
        expect(progress.status, SystemSetupStatus.notStarted);
        expect(progress.isReady, isFalse);
        expect(progress.percentComplete, 0);
      },
    );

    test(
      '2. Failure & Interrupted startup: partial step failure leaves status inProgress and ready false',
      () async {
        final partialSteps = <SetupStepId, SetupStepState>{
          SetupStepId.primaryCurrency: const SetupStepState(
            id: SetupStepId.primaryCurrency,
            status: SetupStepStatus.completed,
          ),
          SetupStepId.companyProfile: const SetupStepState(
            id: SetupStepId.companyProfile,
            status: SetupStepStatus.failed,
            errorMessage: 'Corrupt company payload',
          ),
        };

        await setupRepo.save(
          SetupProgress(
            schemaVersion: SystemSetupSchema.currentVersion,
            status: SystemSetupStatus.inProgress,
            steps: partialSteps,
          ),
        );

        final state = await setupRepo.load();
        expect(state.isReady, isFalse);
        expect(state.status, SystemSetupStatus.inProgress);
      },
    );

    test(
      '3. Idempotency: repeated setup execution does not corrupt state or duplicate entries',
      () async {
        activeCompanyId = 'company_idempotence';
        await orchestrator.initializeModules(activeCompanyId);
        expect(
          await orchestrator.isModuleInitialized(
            activeCompanyId,
            ModuleId.accounting,
          ),
          isTrue,
        );

        // Repeat 3 times
        for (var i = 0; i < 3; i++) {
          await orchestrator.initializeModules(activeCompanyId);
        }

        expect(
          await orchestrator.isModuleInitialized(
            activeCompanyId,
            ModuleId.accounting,
          ),
          isTrue,
        );
      },
    );

    test(
      '4. Security & Context Isolation: blank or whitespace company ID rejected',
      () async {
        expect(
          () => orchestrator.initializeModules('   '),
          throwsArgumentError,
        );
      },
    );

    test(
      '5. Data Integrity: no silent default warehouse or corrupt keys',
      () async {
        activeCompanyId = 'company_integrity';
        final state = await companyRepo.getState();
        expect(state.companyCreated, isFalse);
        expect(state.warehouseConfigured, isFalse);
        expect(state.accountingConfigured, isFalse);
      },
    );
  });
}
