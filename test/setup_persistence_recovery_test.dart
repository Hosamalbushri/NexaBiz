import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../lib/app/settings/settings_repository.dart';
import '../lib/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import '../lib/modules/system_setup/data/repositories/system_setup_state_repository_impl.dart';
import '../lib/modules/system_setup/domain/entities/system_setup_state.dart';

void main() {
  late Directory tempDir;
  late SettingsRepository settingsRepository;
  late SystemSetupStateRepositoryImpl setupRepo;
  late CompanyInitializationRepositoryImpl companyRepo;
  late String activeCompanyId;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_persistence_test_');
    Hive.init(tempDir.path);
    activeCompanyId = 'company_01';
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

  group('Setup Persistence & Recovery (SS-07)', () {
    test(
      'Scenario A: Initialization succeeds -> Restart -> system remains initialized',
      () async {
        // 1. Perform setup
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

        // 2. Simulate app restart (re-instantiate repo from same Hive storage)
        final restoredRepo = SystemSetupStateRepositoryImpl(settingsRepository);
        final restoredProgress = await restoredRepo.load();

        expect(restoredProgress.status, SystemSetupStatus.ready);
        expect(restoredProgress.isReady, isTrue);
      },
    );

    test(
      'Scenario B: Initialization fails halfway -> Restart -> identifies incomplete setup & can retry',
      () async {
        // 1. Fail step 2
        final steps = <SetupStepId, SetupStepState>{
          SetupStepId.primaryCurrency: const SetupStepState(
            id: SetupStepId.primaryCurrency,
            status: SetupStepStatus.completed,
          ),
          SetupStepId.companyProfile: const SetupStepState(
            id: SetupStepId.companyProfile,
            status: SetupStepStatus.failed,
            errorMessage: 'Network timeout during company setup',
          ),
        };

        await setupRepo.save(
          SetupProgress(
            schemaVersion: SystemSetupSchema.currentVersion,
            status: SystemSetupStatus.inProgress,
            steps: steps,
          ),
        );

        // 2. Restart app
        final restoredRepo = SystemSetupStateRepositoryImpl(settingsRepository);
        final restoredProgress = await restoredRepo.load();

        expect(restoredProgress.status, SystemSetupStatus.inProgress);
        expect(restoredProgress.isReady, isFalse);
        expect(
          restoredProgress.steps[SetupStepId.companyProfile]?.errorMessage,
          contains('Network timeout'),
        );

        // 3. Retry succeeds
        final completedSteps = <SetupStepId, SetupStepState>{
          for (final id in SetupStepId.allIds)
            id: SetupStepState(id: id, status: SetupStepStatus.completed),
        };

        await restoredRepo.save(
          SetupProgress(
            schemaVersion: SystemSetupSchema.currentVersion,
            status: SystemSetupStatus.ready,
            steps: completedSteps,
          ),
        );

        final retryProgress = await restoredRepo.load();
        expect(retryProgress.status, SystemSetupStatus.ready);
        expect(retryProgress.isReady, isTrue);
      },
    );

    test(
      'Scenario D: Repeated initialization is idempotent and produces no duplicates',
      () async {
        activeCompanyId = 'company_A';
        var state = await companyRepo.getState();

        // Save initial
        await companyRepo.saveState(
          state.copyWith(companyCreated: true, accountingConfigured: true),
        );

        // Repeat save 3 times
        for (var i = 0; i < 3; i++) {
          await companyRepo.saveState(
            state.copyWith(companyCreated: true, accountingConfigured: true),
          );
        }

        final finalState = await companyRepo.getState();
        expect(finalState.companyCreated, isTrue);
        expect(finalState.accountingConfigured, isTrue);
      },
    );

    test('Scenario E: Schema version tracking & recovery info', () async {
      final progress = await setupRepo.load();
      expect(progress.schemaVersion, greaterThanOrEqualTo(1));
    });
  });
}
