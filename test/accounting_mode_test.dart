import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/accounting/domain/entities/accounting_mode.dart';
import 'package:stock_count/modules/accounting/domain/entities/operational_accounting_status.dart';
import 'package:stock_count/modules/accounting/domain/services/accounting_integration_port.dart';
import 'package:stock_count/modules/accounting/domain/services/accounting_mode_policy.dart';

void main() {
  group('AccountingMode', () {
    test('defaults unknown storage to standalone', () {
      expect(AccountingMode.fromStorage(null), AccountingMode.standalone);
      expect(AccountingMode.fromStorage('nope'), AccountingMode.standalone);
      expect(
        AccountingMode.fromStorage('integrated'),
        AccountingMode.integrated,
      );
    });
  });

  group('AccountingModePolicy', () {
    test('standalone owns local data and never auto-journals', () {
      const policy = AccountingModePolicy(AccountingMode.standalone);
      expect(policy.ownsLocalAccountingData, isTrue);
      expect(policy.mayImportExternalMasterData, isFalse);
      expect(policy.mayExportOperationalDocuments, isFalse);
      expect(policy.autoCreatesJournalEntries, isFalse);
      expect(policy.supportsLocalLedgerFeatures, isTrue);
    });

    test('integrated may exchange with ERP and never auto-journals', () {
      const policy = AccountingModePolicy(AccountingMode.integrated);
      expect(policy.ownsLocalAccountingData, isFalse);
      expect(policy.mayImportExternalMasterData, isTrue);
      expect(policy.mayExportOperationalDocuments, isTrue);
      expect(policy.autoCreatesJournalEntries, isFalse);
      expect(policy.supportsLocalLedgerFeatures, isFalse);
    });
  });

  group('OperationalAccountingStatus', () {
    test('defaults to pendingAccounting', () {
      expect(
        OperationalAccountingStatus.fromStorage(null),
        OperationalAccountingStatus.pendingAccounting,
      );
    });
  });

  group('NoOpAccountingIntegrationPort', () {
    test('is safe default with empty pull and no-op submit', () async {
      const port = NoOpAccountingIntegrationPort();
      expect(port.connectorId, 'none');
      expect(port.isConfigured, isFalse);
      expect(await port.pullMasterData(entityType: 'customer'), isEmpty);
      await port.submitOperationalDocument(
        documentType: 'invoice',
        documentId: 'inv-1',
        payload: const {'total': 10},
      );
    });
  });

  group('SettingsRepository accounting mode', () {
    late Directory tempDir;
    late Box<dynamic> box;
    late SettingsRepository repository;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('accounting_mode_');
      Hive.init(tempDir.path);
      box = await Hive.openBox<dynamic>(HiveBoxes.settings);
      repository = SettingsRepository(box: box);
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('defaults to standalone and persists integrated', () async {
      expect(await repository.loadAccountingMode(), 'standalone');
      await repository.saveAccountingMode('integrated');
      expect(await repository.loadAccountingMode(), 'integrated');
      await repository.saveAccountingMode('invalid');
      expect(await repository.loadAccountingMode(), 'standalone');
    });
  });
}
