import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

/// Generic test entity ensuring 100% domain independence.
class TestDomainRecord {
  const TestDomainRecord({
    required this.id,
    required this.name,
    required this.amount,
  });

  final String id;
  final String name;
  final double amount;
}

/// Generic mock persistence handler recording database state and rollbacks.
class MockDomainPersistenceHandler implements ImportPersistenceHandler<TestDomainRecord> {
  final Map<String, TestDomainRecord> database = {};

  @override
  Future<void> persistRow(TestDomainRecord entity, {required String companyId}) async {
    database[entity.id] = entity;
  }

  @override
  Future<void> persistChunk(List<TestDomainRecord> entities, {required String companyId}) async {
    for (final e in entities) {
      database[e.id] = e;
    }
  }

  void removeKeys(Iterable<String> keys) {
    for (final k in keys) {
      database.remove(k);
    }
  }
}

void main() {
  group('Phase 13 — Universal Import Engine Transaction & Persistence Execution Tests', () {
    late InMemoryImportJobRepository jobRepo;
    late InMemoryImportCheckpointRepository cpRepo;
    late MockDomainPersistenceHandler persistenceHandler;
    late PersistenceExecutionEngine engine;

    setUp(() {
      jobRepo = InMemoryImportJobRepository();
      cpRepo = InMemoryImportCheckpointRepository();
      persistenceHandler = MockDomainPersistenceHandler();

      final txRunner = InMemoryImportTransactionRunner();

      engine = PersistenceExecutionEngine(
        transactionRunner: txRunner,
        jobRepository: jobRepo,
        checkpointRepository: cpRepo,
        defaultChunkSize: 50,
      );
    });

    List<ParsedRow> generateRows(int count) {
      return List.generate(
        count,
        (index) => ParsedRow(
          rowIndex: index,
          cells: [
            ParsedCell(headerName: 'id', rawValue: 'REC-$index', columnIndex: 0),
            ParsedCell(headerName: 'name', rawValue: 'Record #$index', columnIndex: 1),
            ParsedCell(headerName: 'amount', rawValue: '${(index + 1) * 10}.0', columnIndex: 2),
          ],
        ),
      );
    }

    ImportJob createJob(String id, int total) {
      return ImportJob(
        jobId: id,
        companyId: 'COMP-TX-1',
        userId: 'USER-1',
        source: 'data.csv',
        totalRows: total,
      );
    }

    test('1. ALL_OR_NOTHING Mode: Failure halfway through rolls back entire transaction', () async {
      final rows = generateRows(100);
      final job = createJob('JOB-ALL1', 100);

      // Setup transactional runner with state rollback callback
      final activeTxHandler = MockDomainPersistenceHandler();
      final rollbackTxRunner = InMemoryImportTransactionRunner(
        onRollback: () {
          activeTxHandler.database.clear();
        },
      );

      final customEngine = PersistenceExecutionEngine(
        transactionRunner: rollbackTxRunner,
        jobRepository: jobRepo,
        checkpointRepository: cpRepo,
        defaultChunkSize: 50,
      );

      try {
        await customEngine.executeWithPersistence<TestDomainRecord>(
          job: job,
          rows: rows,
          persistenceMode: ImportPersistenceMode.allOrNothing,
          persistenceHandler: activeTxHandler,
          idempotencyKeyExtractor: (row, idx) => 'REC-$idx',
          shouldSimulateFailureAtRow: (idx) => idx == 60, // Fail at row 60
          rowTransformer: (row, idx) async {
            return TestDomainRecord(
              id: 'REC-$idx',
              name: 'Record #$idx',
              amount: (idx + 1) * 10.0,
            );
          },
        );
      } catch (e) {
        // Expected rollback
      }

      // Zero records exist in DB due to complete transaction rollback
      expect(activeTxHandler.database.isEmpty, isTrue);
    });

    test('2. PER_CHUNK Mode: Chunk 2 failure rolls back only Chunk 2 while Chunk 1 remains committed', () async {
      final rows = generateRows(100);
      final job = createJob('JOB-CHK1', 100);

      final chunk2Keys = <String>[];
      final activeHandler = MockDomainPersistenceHandler();
      final chunkTxRunner = InMemoryImportTransactionRunner(
        onRollback: () {
          activeHandler.removeKeys(chunk2Keys);
        },
      );

      final customEngine = PersistenceExecutionEngine(
        transactionRunner: chunkTxRunner,
        jobRepository: jobRepo,
        checkpointRepository: cpRepo,
        defaultChunkSize: 50,
      );

      final resultJob = await customEngine.executeWithPersistence<TestDomainRecord>(
        job: job,
        rows: rows,
        chunkSize: 50,
        persistenceMode: ImportPersistenceMode.perChunk,
        persistenceHandler: activeHandler,
        idempotencyKeyExtractor: (row, idx) => 'REC-$idx',
        shouldSimulateFailureAtRow: (idx) => idx == 75, // Fail in Chunk 2 (rows 50..99)
        rowTransformer: (row, idx) async {
          if (idx >= 50) {
            chunk2Keys.add('REC-$idx');
          }
          return TestDomainRecord(id: 'REC-$idx', name: 'Record #$idx', amount: 100.0);
        },
      );

      expect(resultJob.status, equals(ImportJobStatus.completedWithErrors));
      // Chunk 1 (rows 0..49) remains committed in database
      expect(activeHandler.database.containsKey('REC-0'), isTrue);
      expect(activeHandler.database.containsKey('REC-49'), isTrue);
      // Chunk 2 (rows 50..99) rolled back cleanly
      expect(activeHandler.database.containsKey('REC-50'), isFalse);
      expect(activeHandler.database.containsKey('REC-75'), isFalse);
      expect(resultJob.successfulRows, equals(50));
      expect(resultJob.failedRows, equals(50));
    });


    test('3. PER_ROW Mode: Individual row failure rolls back only that row without affecting others', () async {
      final rows = generateRows(10);
      final job = createJob('JOB-ROW1', 10);

      final resultJob = await engine.executeWithPersistence<TestDomainRecord>(
        job: job,
        rows: rows,
        chunkSize: 10,
        persistenceMode: ImportPersistenceMode.perRow,
        persistenceHandler: persistenceHandler,
        idempotencyKeyExtractor: (row, idx) => 'REC-$idx',
        shouldSimulateFailureAtRow: (idx) => idx == 4, // Only row 4 fails
        rowTransformer: (row, idx) async {
          return TestDomainRecord(id: 'REC-$idx', name: 'Record #$idx', amount: 50.0);
        },
      );

      expect(resultJob.successfulRows, equals(9));
      expect(resultJob.failedRows, equals(1));

      // Row 3 and Row 5 committed, Row 4 omitted
      expect(persistenceHandler.database.containsKey('REC-3'), isTrue);
      expect(persistenceHandler.database.containsKey('REC-4'), isFalse);
      expect(persistenceHandler.database.containsKey('REC-5'), isTrue);
    });

    test('4. BEST_EFFORT Mode: Commits valid rows and logs failures without throwing exception', () async {
      final rows = generateRows(10);
      final job = createJob('JOB-BEST1', 10);

      final resultJob = await engine.executeWithPersistence<TestDomainRecord>(
        job: job,
        rows: rows,
        chunkSize: 10,
        persistenceMode: ImportPersistenceMode.bestEffort,
        persistenceHandler: persistenceHandler,
        idempotencyKeyExtractor: (row, idx) => 'REC-$idx',
        shouldSimulateFailureAtRow: (idx) => idx == 2 || idx == 7,
        rowTransformer: (row, idx) async {
          return TestDomainRecord(id: 'REC-$idx', name: 'Record #$idx', amount: 20.0);
        },
      );

      expect(resultJob.status, equals(ImportJobStatus.completedWithErrors));
      expect(resultJob.successfulRows, equals(8));
      expect(resultJob.failedRows, equals(2));
      expect(persistenceHandler.database.length, equals(8));
    });

    test('5. Retry & Duplicate Prevention: Retrying job re-processes cleanly without duplicate commits', () async {
      final rows = generateRows(50);
      final job = createJob('JOB-RETRY1', 50);

      // Pre-seed committed record REC-0
      persistenceHandler.database['REC-0'] = const TestDomainRecord(id: 'REC-0', name: 'Existing', amount: 99.0);

      final preCp = ImportCheckpoint(
        jobId: 'JOB-RETRY1',
        companyId: 'COMP-TX-1',
        lastProcessedRowIndex: -1,
        chunkSize: 50,
        committedKeys: {'REC-0'},
      );
      await cpRepo.save(preCp);

      final resultJob = await engine.executeWithPersistence<TestDomainRecord>(
        job: job,
        rows: rows,
        chunkSize: 50,
        persistenceMode: ImportPersistenceMode.perChunk,
        persistenceHandler: persistenceHandler,
        idempotencyKeyExtractor: (row, idx) => 'REC-$idx',
        rowTransformer: (row, idx) async {
          return TestDomainRecord(id: 'REC-$idx', name: 'Record #$idx', amount: 100.0);
        },
      );

      expect(resultJob.status, equals(ImportJobStatus.completed));
      expect(resultJob.skippedRows, equals(1));
      expect(persistenceHandler.database['REC-0']?.name, equals('Existing')); // Unchanged, not duplicated
      expect(persistenceHandler.database.length, equals(50));
    });
  });
}
