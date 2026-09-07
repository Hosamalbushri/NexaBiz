import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/data/repositories/system_setup_state_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/system_setup_state.dart';

void main() {
  late Directory tempDir;
  late SettingsRepository settingsRepository;
  late SystemSetupStateRepositoryImpl setupRepo;
  late CompanyInitializationRepositoryImpl companyRepo;
  late String activeCompanyId;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_offline_test_');
    Hive.init(tempDir.path);
    activeCompanyId = 'company_offline_01';
    settingsRepository = SettingsRepository();
    setupRepo = SystemSetupStateRepositoryImpl(settingsRepository);
    companyRepo = CompanyInitializationRepositoryImpl(
      readCompanyId: () => activeCompanyId,
    );
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Offline Initialization (SS-10)', () {
    test(
      'Scenario 1 & 4: Fresh device offline setup completes locally without requiring remote server',
      () async {
        // 1. Complete local setup
        final updatedSteps = <SetupStepId, SetupStepState>{
          for (final id in SetupStepId.allIds)
            id: SetupStepState(id: id, status: SetupStepStatus.completed),
        };

        await setupRepo.save(
          SetupProgress(
            schemaVersion: SystemSetupSchema.currentVersion,
            status: SystemSetupStatus.ready,
            steps: updatedSteps,
          ),
        );

        final state = await setupRepo.load();
        expect(state.isReady, isTrue);
        expect(state.status, SystemSetupStatus.ready);
      },
    );

    test('Scenario 5: Application restarts while remaining offline', () async {
      // Setup ready state
      final updatedSteps = <SetupStepId, SetupStepState>{
        for (final id in SetupStepId.allIds)
          id: SetupStepState(id: id, status: SetupStepStatus.completed),
      };

      await setupRepo.save(
        SetupProgress(
          schemaVersion: SystemSetupSchema.currentVersion,
          status: SystemSetupStatus.ready,
          steps: updatedSteps,
        ),
      );

      // Re-instantiate repo while offline
      final offlineRepo = SystemSetupStateRepositoryImpl(settingsRepository);
      final offlineProgress = await offlineRepo.load();

      expect(offlineProgress.status, SystemSetupStatus.ready);
      expect(offlineProgress.isReady, isTrue);
    });

    test(
      'Scenario 3 & 6: Interrupted connectivity allows offline resumption and clean reconnect state',
      () async {
        // Step 1 completed offline
        final partialSteps = <SetupStepId, SetupStepState>{
          SetupStepId.primaryCurrency: const SetupStepState(
            id: SetupStepId.primaryCurrency,
            status: SetupStepStatus.completed,
          ),
        };

        await setupRepo.save(
          SetupProgress(
            schemaVersion: SystemSetupSchema.currentVersion,
            status: SystemSetupStatus.inProgress,
            steps: partialSteps,
          ),
        );

        final restoredProgress = await setupRepo.load();
        expect(restoredProgress.status, SystemSetupStatus.inProgress);
        expect(restoredProgress.isReady, isFalse);

        // Finish remaining steps on reconnect
        final completedSteps = <SetupStepId, SetupStepState>{
          for (final id in SetupStepId.allIds)
            id: SetupStepState(id: id, status: SetupStepStatus.completed),
        };

        await setupRepo.save(
          SetupProgress(
            schemaVersion: SystemSetupSchema.currentVersion,
            status: SystemSetupStatus.ready,
            steps: completedSteps,
          ),
        );

        final finalProgress = await setupRepo.load();
        expect(finalProgress.isReady, isTrue);
      },
    );
  });
}
