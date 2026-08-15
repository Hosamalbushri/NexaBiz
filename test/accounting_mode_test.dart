import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/accounting/domain/entities/accounting_mode.dart';
import 'package:stock_count/modules/accounting/domain/entities/operational_accounting_status.dart';
import 'package:stock_count/modules/accounting/domain/services/accounting_integration_port.dart';
import 'package:stock_count/modules/accounting/domain/services/accounting_mode_policy.dart';
import 'package:stock_count/modules/accounting/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/accounting/domain/services/journal_money.dart';
import 'package:stock_count/modules/accounting/domain/entities/fiscal_period.dart';
import 'package:stock_count/modules/accounting/domain/models/journal_exception.dart';

void main() {
  group('AccountingMode', () {
    test('always resolves to standalone', () {
      expect(AccountingMode.fromStorage(null), AccountingMode.standalone);
      expect(AccountingMode.fromStorage('nope'), AccountingMode.standalone);
      expect(
        AccountingMode.fromStorage('integrated'),
        AccountingMode.standalone,
      );
      expect(AccountingMode.standalone.isStandalone, isTrue);
      expect(AccountingMode.standalone.isIntegrated, isFalse);
    });
  });

  group('FiscalPeriod', () {
    test('containing spans fiscal year from start month', () {
      final period = FiscalPeriod.containing(
        DateTime.utc(2026, 3, 15),
        fiscalYearStartMonth: 4,
      );
      expect(period.start, DateTime.utc(2025, 4, 1));
      expect(period.endInclusive, DateTime.utc(2026, 3, 31));
      expect(period.contains(DateTime.utc(2026, 3, 15)), isTrue);
      expect(period.contains(DateTime.utc(2026, 4, 1)), isFalse);
    });
  });

  group('FiscalPeriodPolicy', () {
    test('rejects entry on or before closedThrough', () {
      final policy = FiscalPeriodPolicy(
        fiscalYearStartMonth: 1,
        closedThrough: DateTime.utc(2026, 8, 1),
      );
      expect(
        () => policy.assertEntryAllowed(DateTime.utc(2026, 8, 1)),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.periodClosed,
          ),
        ),
      );
      expect(
        () => policy.assertEntryAllowed(DateTime.utc(2026, 8, 2)),
        returnsNormally,
      );
    });
  });

  group('JournalMoney', () {
    test('rounds to cents and clamps negatives', () {
      expect(JournalMoney.round(10.006), 10.01);
      expect(JournalMoney.round(10.004), 10.0);
      expect(JournalMoney.clampNonNegative(-0.5), 0);
      expect(JournalMoney.toCents(1.23), 123);
    });
  });

  group('AccountingModePolicy', () {
    test('local product always owns ledger and auto-journals sales', () {
      const policy = AccountingModePolicy(AccountingMode.standalone);
      expect(policy.ownsLocalAccountingData, isTrue);
      expect(policy.mayImportExternalMasterData, isFalse);
      expect(policy.mayExportOperationalDocuments, isFalse);
      expect(policy.autoCreatesJournalEntries, isTrue);
      expect(policy.supportsLocalLedgerFeatures, isTrue);

      const legacy = AccountingModePolicy(AccountingMode.integrated);
      expect(legacy.ownsLocalAccountingData, isTrue);
      expect(legacy.autoCreatesJournalEntries, isTrue);
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

    test('accounting mode is fixed to standalone', () async {
      expect(await repository.loadAccountingMode(), 'standalone');
      await repository.saveAccountingMode('integrated');
      expect(await repository.loadAccountingMode(), 'standalone');
    });
  });
}
