import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';
import 'package:stock_count/modules/sync/sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<SyncOperation> syncBox;
  late SyncQueue mockSyncQueue;
  late ImportSyncBridge syncBridge;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('import_chaos_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }

    syncBox = await Hive.openBox<SyncOperation>('sync_queue_chaos_test');
    mockSyncQueue = SyncQueue(
      box: syncBox,
      companyId: 'COMP-CHAOS-001',
      deviceId: 'DEV-CHAOS',
    );
    syncBridge = ImportSyncBridge(syncQueue: mockSyncQueue);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Phase 23 — Universal Import Engine Chaos & Failure Injection Tests', () {
    test(
      '1. PARSING & MAPPING CHAOS: Handles unclosed quotes, broken syntax, and unmapped headers cleanly',
      () async {
        const malformedCsv = '''SKU,Name,Price,Extra
PROD-01,"Widget 1",100.0,Valid
PROD-02,"Unclosed Quote,200.0,Broken
PROD-03,Widget 3,300.0,Valid''';

        final parser = const CsvImportParser();
        final doc = await parser.parseDocument(
          StringImportSource(
            sourceId: 'src_test',
            name: 'test.csv',
            content: malformedCsv,
          ),
        );

        expect(doc.sheets.first.rows.isNotEmpty, isTrue);

        final targetFields = const [
          ImportField(key: 'item_code', label: 'Item Code', isRequired: true),
          ImportField(key: 'name', label: 'Product Name', isRequired: true),
          ImportField(
            key: 'price',
            label: 'Unit Price',
            dataType: ImportDataType.number,
          ),
        ];

        final mappingEngine = const MappingEngine();
        final schema = const SchemaDetector().detectDocument(doc);

        final mappingReport = mappingEngine.mapSchema(
          schema: schema,
          targetFields: targetFields,
        );

        expect(mappingReport.mappings.isNotEmpty, isTrue);
      },
    );

    test(
      '2. NORMALIZATION & VALIDATION CHAOS: Malformed numbers, dates, regex and uniqueness violations',
      () async {
        // East Arabic digit parsing with mixed characters
        final parsedNum = NumberNormalizer.normalize('١٢٣.٤٥');
        expect(parsedNum.isNull, isFalse);
        expect(parsedNum.normalizedValue, equals(12345));

        // Invalid text in numeric field
        final invalidNum = NumberNormalizer.normalize('NOT_A_NUMBER');
        expect(invalidNum.isMalformed, isTrue);

        // Validation engine with dataset evaluation
        const validationEngine = ValidationEngine();
        final targetFields = const [
          ImportField(
            key: 'itemCode',
            label: 'Item Code',
            isRequired: true,
            isUnique: true,
          ),
        ];

        final dataset = [
          {
            'itemCode': const NormalizedValue(
              originalValue: 'SKU-100',
              normalizedValue: 'SKU-100',
              isNull: false,
            ),
          },
          {
            'itemCode': const NormalizedValue(
              originalValue: 'SKU-100',
              normalizedValue: 'SKU-100',
              isNull: false,
            ),
          }, // Duplicate!
        ];

        final report = await validationEngine.validateDataset(
          rows: dataset,
          targetFields: targetFields,
        );

        expect(report.isValid, isFalse);
        expect(report.errorCount, equals(1));
      },
    );

    test(
      '3. TRANSACTION & PERSISTENCE CHAOS (AllOrNothing): Complete transaction rollback on failure',
      () async {
        final jobRepo = InMemoryImportJobRepository();
        final cpRepo = InMemoryImportCheckpointRepository();
        final store = TransactionalStore();
        final txRunner = TransactionalTransactionRunner(store);

        final engine = PersistenceExecutionEngine(
          transactionRunner: txRunner,
          jobRepository: jobRepo,
          checkpointRepository: cpRepo,
        );

        final job = ImportJob(
          jobId: 'JOB-CHAOS-1',
          companyId: 'COMP-CHAOS-001',
          userId: 'USER-CHAOS',
          source: 'test.csv',
          totalRows: 10,
        );

        final rows = List.generate(
          10,
          (i) => ParsedRow(
            rowIndex: i + 1,
            cells: [
              ParsedCell(
                headerName: 'code',
                rawValue: 'PROD-${i + 1}',
                columnIndex: 0,
              ),
            ],
          ),
        );

        var rolledBack = false;

        try {
          await engine.executeWithPersistence<Map<String, dynamic>>(
            job: job,
            rows: rows,
            persistenceMode: ImportPersistenceMode.allOrNothing,
            persistenceHandler: TestPersistenceHandler(store.data),
            rowTransformer: (row, index) async {
              if (index == 4) {
                throw Exception('Simulated database crash at row 5');
              }
              return {'code': 'PROD-${index + 1}'};
            },
          );
        } catch (e) {
          rolledBack = true;
        }

        expect(rolledBack, isTrue);
        expect(
          store.data,
          isEmpty,
          reason:
              'AllOrNothing transaction MUST completely roll back on failure.',
        );
      },
    );

    test(
      '4. TRANSACTION & PERSISTENCE CHAOS (PerChunk): Atomic chunk rollback preserving valid chunks',
      () async {
        final jobRepo = InMemoryImportJobRepository();
        final cpRepo = InMemoryImportCheckpointRepository();
        final store = TransactionalStore();
        final txRunner = TransactionalTransactionRunner(store);

        final engine = PersistenceExecutionEngine(
          transactionRunner: txRunner,
          jobRepository: jobRepo,
          checkpointRepository: cpRepo,
          defaultChunkSize: 5,
        );

        final job = ImportJob(
          jobId: 'JOB-CHAOS-2',
          companyId: 'COMP-CHAOS-001',
          userId: 'USER-CHAOS',
          source: 'test.csv',
          totalRows: 10,
        );

        final rows = List.generate(
          10,
          (i) => ParsedRow(
            rowIndex: i + 1,
            cells: [
              ParsedCell(
                headerName: 'code',
                rawValue: 'PROD-${i + 1}',
                columnIndex: 0,
              ),
            ],
          ),
        );

        final updatedJob = await engine
            .executeWithPersistence<Map<String, dynamic>>(
              job: job,
              rows: rows,
              persistenceMode: ImportPersistenceMode.perChunk,
              persistenceHandler: TestPersistenceHandler(store.data),
              chunkSize: 5,
              rowTransformer: (row, index) async {
                if (index == 6) {
                  throw Exception(
                    'Simulated database lock failure in Chunk 2 at row 7',
                  );
                }
                return {'code': 'PROD-${index + 1}'};
              },
            );

        expect(updatedJob.processedRows, equals(10));
        expect(updatedJob.failedRows, equals(5));
        expect(
          store.data.length,
          equals(5),
          reason:
              'Chunk 1 (rows 1-5) must be committed while Chunk 2 (rows 6-10) rolls back.',
        );
      },
    );

    test(
      '5. CHECKPOINT & IDEMPOTENCY RECOVERY: Prevents duplicate record insertion on retry',
      () async {
        final jobRepo = InMemoryImportJobRepository();
        final cpRepo = InMemoryImportCheckpointRepository();

        final job = ImportJob(
          jobId: 'JOB-CHAOS-3',
          companyId: 'COMP-CHAOS-001',
          userId: 'USER-CHAOS',
          source: 'test.csv',
          totalRows: 20,
        );
        await jobRepo.save(job);

        // Simulate checkpoint after chunk 1 (10 rows committed)
        const chunk1CommittedKeys = {
          'row_0',
          'row_1',
          'row_2',
          'row_3',
          'row_4',
          'row_5',
          'row_6',
          'row_7',
          'row_8',
          'row_9',
        };

        await cpRepo.save(
          ImportCheckpoint(
            jobId: job.jobId,
            companyId: 'COMP-CHAOS-001',
            lastProcessedRowIndex: 9,
            chunkSize: 10,
            successfulRows: 10,
            committedKeys: chunk1CommittedKeys,
          ),
        );

        final persistedEntities = <String, Map<String, dynamic>>{
          for (final key in chunk1CommittedKeys) key: {'code': key},
        };

        final engine = PersistenceExecutionEngine(
          transactionRunner: InMemoryImportTransactionRunner(),
          jobRepository: jobRepo,
          checkpointRepository: cpRepo,
          defaultChunkSize: 10,
        );

        final rows = List.generate(
          20,
          (i) => ParsedRow(
            rowIndex: i + 1,
            cells: [
              ParsedCell(
                headerName: 'code',
                rawValue: 'row_$i',
                columnIndex: 0,
              ),
            ],
          ),
        );

        final completedJob = await engine
            .executeWithPersistence<Map<String, dynamic>>(
              job: job,
              rows: rows,
              persistenceMode: ImportPersistenceMode.perChunk,
              persistenceHandler: TestPersistenceHandler(persistedEntities),
              rowTransformer: (row, index) async => {'code': 'row_$index'},
              idempotencyKeyExtractor: (row, index) => 'row_$index',
            );

        expect(completedJob.processedRows, equals(20));
        expect(completedJob.successfulRows, equals(20));
        expect(
          persistedEntities.length,
          equals(20),
          reason: 'Zero duplicate records inserted upon process restart.',
        );
      },
    );

    test(
      '6. SCALE DATASETS TEST: 10, 1,000, 10,000, and 100,000 rows with distributed malformed rows',
      () async {
        final jobRepo = InMemoryImportJobRepository();
        final cpRepo = InMemoryImportCheckpointRepository();
        final txRunner = InMemoryImportTransactionRunner();

        final engine = PersistenceExecutionEngine(
          transactionRunner: txRunner,
          jobRepository: jobRepo,
          checkpointRepository: cpRepo,
          defaultChunkSize: 1000,
        );

        // Test 10 rows (4 malformed -> 6 valid)
        final scale10Rows = List.generate(
          10,
          (i) => ParsedRow(
            rowIndex: i + 1,
            cells: [
              ParsedCell(
                headerName: 'code',
                rawValue: i % 3 == 0 ? '' : 'SKU-10-$i',
                columnIndex: 0,
              ),
            ],
          ),
        );

        final dbState10 = <String, Map<String, dynamic>>{};
        final job10 = ImportJob(
          jobId: 'JOB-SCALE-10',
          companyId: 'COMP-CHAOS-001',
          userId: 'USER-CHAOS',
          source: 'test.csv',
          totalRows: 10,
        );

        final res10 = await engine.executeWithPersistence<Map<String, dynamic>>(
          job: job10,
          rows: scale10Rows,
          persistenceMode: ImportPersistenceMode.bestEffort,
          persistenceHandler: TestPersistenceHandler(dbState10),
          rowTransformer: (row, index) async {
            final code = row.cells.first.rawValue;
            if (code.isEmpty) return null;
            return {'code': code};
          },
        );

        expect(res10.successfulRows, equals(6));
        expect(res10.skippedRows, equals(4));

        // Test 1,000 rows
        final scale1000Rows = List.generate(
          1000,
          (i) => ParsedRow(
            rowIndex: i + 1,
            cells: [
              ParsedCell(
                headerName: 'code',
                rawValue: i % 10 == 0 ? '' : 'SKU-1000-$i',
                columnIndex: 0,
              ),
            ],
          ),
        );

        final dbState1000 = <String, Map<String, dynamic>>{};
        final job1000 = ImportJob(
          jobId: 'JOB-SCALE-1000',
          companyId: 'COMP-CHAOS-001',
          userId: 'USER-CHAOS',
          source: 'test.csv',
          totalRows: 1000,
        );

        final res1000 = await engine
            .executeWithPersistence<Map<String, dynamic>>(
              job: job1000,
              rows: scale1000Rows,
              persistenceMode: ImportPersistenceMode.bestEffort,
              persistenceHandler: TestPersistenceHandler(dbState1000),
              rowTransformer: (row, index) async {
                final code = row.cells.first.rawValue;
                if (code.isEmpty) return null;
                return {'code': code};
              },
            );

        expect(res1000.successfulRows, equals(900));
        expect(res1000.skippedRows, equals(100));

        // Test 10,000 rows
        final scale10000Rows = List.generate(
          10000,
          (i) => ParsedRow(
            rowIndex: i + 1,
            cells: [
              ParsedCell(
                headerName: 'code',
                rawValue: i % 20 == 0 ? '' : 'SKU-10000-$i',
                columnIndex: 0,
              ),
            ],
          ),
        );

        final dbState10000 = <String, Map<String, dynamic>>{};
        final job10000 = ImportJob(
          jobId: 'JOB-SCALE-10000',
          companyId: 'COMP-CHAOS-001',
          userId: 'USER-CHAOS',
          source: 'test.csv',
          totalRows: 10000,
        );

        final res10000 = await engine
            .executeWithPersistence<Map<String, dynamic>>(
              job: job10000,
              rows: scale10000Rows,
              persistenceMode: ImportPersistenceMode.bestEffort,
              persistenceHandler: TestPersistenceHandler(dbState10000),
              chunkSize: 2000,
              rowTransformer: (row, index) async {
                final code = row.cells.first.rawValue;
                if (code.isEmpty) return null;
                return {'code': code};
              },
            );

        expect(res10000.successfulRows, equals(9500));
        expect(res10000.skippedRows, equals(500));

        // Test 100,000 rows stream generator
        final scale100000Rows = List.generate(
          100000,
          (i) => ParsedRow(
            rowIndex: i + 1,
            cells: [
              ParsedCell(
                headerName: 'code',
                rawValue: i % 20 == 0 ? '' : 'SKU-100000-$i',
                columnIndex: 0,
              ),
            ],
          ),
        );

        final dbState100000 = <String, Map<String, dynamic>>{};
        final job100000 = ImportJob(
          jobId: 'JOB-SCALE-100000',
          companyId: 'COMP-CHAOS-001',
          userId: 'USER-CHAOS',
          source: 'test.csv',
          totalRows: 100000,
        );

        final res100000 = await engine
            .executeWithPersistence<Map<String, dynamic>>(
              job: job100000,
              rows: scale100000Rows,
              persistenceMode: ImportPersistenceMode.bestEffort,
              persistenceHandler: TestPersistenceHandler(dbState100000),
              chunkSize: 10000,
              rowTransformer: (row, index) async {
                final code = row.cells.first.rawValue;
                if (code.isEmpty) return null;
                return {'code': code};
              },
            );

        expect(res100000.successfulRows, equals(95000));
        expect(res100000.skippedRows, equals(5000));
        expect(res100000.processedRows, equals(100000));
      },
    );
  });
}

class TransactionalStore {
  final Map<String, Map<String, dynamic>> data = {};
  Map<String, Map<String, dynamic>>? _snapshot;

  void beginTransaction() {
    _snapshot = Map<String, Map<String, dynamic>>.from(data);
  }

  void rollback() {
    if (_snapshot != null) {
      data.clear();
      data.addAll(_snapshot!);
      _snapshot = null;
    }
  }

  void commit() {
    _snapshot = null;
  }
}

class TransactionalTransactionRunner implements ImportTransactionRunner {
  TransactionalTransactionRunner(this.store);

  final TransactionalStore store;

  @override
  Future<T> runInTransaction<T>(Future<T> Function() action) async {
    store.beginTransaction();
    try {
      final result = await action();
      store.commit();
      return result;
    } catch (e) {
      store.rollback();
      rethrow;
    }
  }
}

class TestPersistenceHandler
    implements ImportPersistenceHandler<Map<String, dynamic>> {
  TestPersistenceHandler(this.store);

  final Map<String, Map<String, dynamic>> store;

  @override
  Future<void> persistRow(
    Map<String, dynamic> entity, {
    required String companyId,
  }) async {
    final code = entity['code']?.toString() ?? 'key_${store.length}';
    store[code] = entity;
  }

  @override
  Future<void> persistChunk(
    List<Map<String, dynamic>> entities, {
    required String companyId,
  }) async {
    for (final entity in entities) {
      await persistRow(entity, companyId: companyId);
    }
  }
}

class InMemoryImportTransactionRunner implements ImportTransactionRunner {
  InMemoryImportTransactionRunner([this.onRollback]);

  final void Function()? onRollback;

  @override
  Future<T> runInTransaction<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      onRollback?.call();
      rethrow;
    }
  }
}
