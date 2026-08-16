import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/system_setup/data/repositories/system_setup_state_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/system_setup_state.dart';
import 'package:stock_count/modules/system_setup/domain/ports/system_setup_seed_port.dart';
import 'package:stock_count/modules/system_setup/domain/services/system_initialization_coordinator.dart';

class _CountingSeedPort implements SystemSetupSeedPort {
  var localCalls = 0;
  var syncCalls = 0;
  var fail = false;

  @override
  Future<void> ensureLocalDefaults() async {
    localCalls += 1;
    if (fail) {
      throw StateError('seed failed');
    }
  }

  @override
  Future<void> pullRemoteDefaults() async {
    syncCalls += 1;
    if (fail) {
      throw StateError('sync seed failed');
    }
  }
}

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late SettingsRepository settings;
  late SystemSetupStateRepositoryImpl stateRepo;
  late _CountingSeedPort seedPort;
  late SystemInitializationCoordinator coordinator;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('system_setup_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>(HiveBoxes.settings);
    settings = SettingsRepository(box: box);
    stateRepo = SystemSetupStateRepositoryImpl(settings);
    seedPort = _CountingSeedPort();
    coordinator = SystemInitializationCoordinator(
      stateRepository: stateRepo,
      seedPort: seedPort,
    );
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SetupProgress', () {
    test('percent and readiness follow required steps only', () {
      final steps = <SetupStepId, SetupStepState>{
        for (final id in SetupStepId.allIds)
          id: SetupStepState(id: id, status: SetupStepStatus.pending),
      };
      for (final id in SetupStepId.requiredIds.take(2)) {
        steps[id] = SetupStepState(id: id, status: SetupStepStatus.completed);
      }
      final progress = SetupProgress(
        schemaVersion: 2,
        status: SystemSetupStatus.inProgress,
        steps: steps,
      );
      expect(progress.requiredDone, 2);
      expect(progress.percentComplete, 50);
      expect(progress.isReady, isFalse);
      expect(progress.allRequiredComplete, isFalse);
    });
  });

  group('SystemSetupStateRepositoryImpl', () {
    test('fresh empty install is not ready', () async {
      final progress = await stateRepo.load();
      expect(progress.status, SystemSetupStatus.notStarted);
      expect(progress.isReady, isFalse);
      expect(await settings.hasSystemSetupState(), isFalse);
    });

    test('grandfathers existing installs with prior settings', () async {
      await settings.saveThemeMode(ThemeMode.dark);
      final progress = await stateRepo.load();
      expect(progress.isReady, isTrue);
      expect(progress.status, SystemSetupStatus.ready);
      expect(await settings.hasSystemSetupState(), isTrue);
      expect(await settings.loadSystemBaseCurrencyLocked(), isTrue);
    });

    test('resumes persisted in-progress steps', () async {
      final mid = SetupProgress(
        schemaVersion: SystemSetupSchema.currentVersion,
        status: SystemSetupStatus.inProgress,
        steps: {
          for (final id in SetupStepId.allIds)
            id: SetupStepState(
              id: id,
              status: id == SetupStepId.locale
                  ? SetupStepStatus.completed
                  : SetupStepStatus.pending,
            ),
        },
        lastUpdated: DateTime.utc(2026, 8, 14),
      );
      await stateRepo.save(mid);
      final loaded = await stateRepo.load();
      expect(loaded.status, SystemSetupStatus.inProgress);
      expect(
        loaded.stateFor(SetupStepId.locale).status,
        SetupStepStatus.completed,
      );
      expect(loaded.currentStep, SetupStepId.primaryCurrency);
    });
  });

  group('SystemInitializationCoordinator', () {
    test('marks ready only after all required steps complete', () async {
      expect(await coordinator.isReady(), isFalse);

      await coordinator.markStepCompleted(SetupStepId.locale);
      await coordinator.markStepCompleted(SetupStepId.primaryCurrency);
      await coordinator.markStepCompleted(SetupStepId.companyProfile);
      expect(await coordinator.isReady(), isFalse);

      await coordinator.runSeedLocal();
      expect(seedPort.localCalls, 1);
      expect(await coordinator.isReady(), isTrue);
    });

    test('seed from sync completes the same setup step', () async {
      await coordinator.markStepCompleted(SetupStepId.locale);
      await coordinator.markStepCompleted(SetupStepId.primaryCurrency);
      await coordinator.markStepCompleted(SetupStepId.companyProfile);

      await coordinator.runSeedFromSync();
      expect(seedPort.syncCalls, 1);
      expect(seedPort.localCalls, 0);
      expect(await coordinator.isReady(), isTrue);
    });

    test('locks base currency when primary currency step completes', () async {
      await coordinator.runStep(SetupStepId.primaryCurrency, () async {
        await settings.saveSystemBaseCurrencyLocked(true);
      });
      expect(await settings.loadSystemBaseCurrencyLocked(), isTrue);
      expect(
        (await coordinator.loadProgress())
            .stateFor(SetupStepId.primaryCurrency)
            .status,
        SetupStepStatus.completed,
      );
    });

    test('failed seed stays failed and is retryable', () async {
      seedPort.fail = true;
      await expectLater(coordinator.runSeedLocal(), throwsStateError);
      var progress = await coordinator.loadProgress();
      expect(
        progress.stateFor(SetupStepId.seedLocal).status,
        SetupStepStatus.failed,
      );

      seedPort.fail = false;
      progress = await coordinator.runSeedLocal();
      expect(
        progress.stateFor(SetupStepId.seedLocal).status,
        SetupStepStatus.completed,
      );
      expect(seedPort.localCalls, 2);
    });
  });
}
