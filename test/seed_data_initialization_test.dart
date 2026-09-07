import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../lib/app/settings/settings_repository.dart';
import '../lib/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';

void main() {
  late Directory tempDir;
  late SettingsRepository settingsRepository;
  late CompanyInitializationRepositoryImpl companyInitRepo;

  late String activeCompanyId;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_seed_test_');
    Hive.init(tempDir.path);
    activeCompanyId = 'company_01';
    companyInitRepo = CompanyInitializationRepositoryImpl(
      readCompanyId: () => activeCompanyId,
    );
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Seed / Data Initialization (SS-06)', () {
    test(
      'fresh initialization starts with empty company state and no silent business entities',
      () async {
        activeCompanyId = 'company_01';
        final state = await companyInitRepo.getState();
        expect(state.companyCreated, isFalse);
        expect(state.accountingConfigured, isFalse);
        expect(state.warehouseConfigured, isFalse);
      },
    );

    test(
      'saving company initialization state is idempotent and tenant isolated',
      () async {
        activeCompanyId = 'company_A';
        var stateCompanyA = await companyInitRepo.getState();
        expect(stateCompanyA.companyCreated, isFalse);

        await companyInitRepo.saveState(
          stateCompanyA.copyWith(
            companyId: 'company_A',
            companyCreated: true,
            accountingConfigured: true,
          ),
        );

        stateCompanyA = await companyInitRepo.getState();
        expect(stateCompanyA.companyCreated, isTrue);
        expect(stateCompanyA.accountingConfigured, isTrue);

        // Verify tenant isolation for company B
        activeCompanyId = 'company_B';
        final stateCompanyB = await companyInitRepo.getState();
        expect(stateCompanyB.companyCreated, isFalse);
        expect(stateCompanyB.accountingConfigured, isFalse);
      },
    );
  });
}
