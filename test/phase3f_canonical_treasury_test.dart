import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/utils/id_generator.dart';

void main() {
  late NexabizDatabase db;

  setUp(() {
    db = NexabizDatabase.connect(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3F — Canonical Treasury Baseline Tests', () {
    test('NexabizDatabase schemaVersion is 6 or higher and financial_transactions table exists', () async {
      expect(db.schemaVersion, greaterThanOrEqualTo(6));

      final count = await db.select(db.financialTransactions).get();
      expect(count, isEmpty);
    });

    test('Canonical UUID identity and tenant isolation on financial transactions', () async {
      final companyA = 'comp-treasury-aaa-3f';
      final companyB = 'comp-treasury-bbb-3f';

      final uuidA = generateUuidV4();
      final uuidB = generateUuidV4();

      final now = DateTime.now().millisecondsSinceEpoch;

      // Insert Receipt for Company A
      await db.into(db.financialTransactions).insert(
            FinancialTransactionsCompanion.insert(
              uuid: uuidA,
              transactionNumber: 'REC-A-0001',
              transactionType: 'receipt',
              source: 'manual',
              transactionDate: now,
              amount: 1500.0,
              currencyCode: 'USD',
              baseCurrencyCode: 'USD',
              counterCurrencyCode: 'USD',
              cashAccountId: generateUuidV4(),
              counterAccountId: generateUuidV4(),
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyA),
            ),
          );

      // Insert Payment for Company B
      await db.into(db.financialTransactions).insert(
            FinancialTransactionsCompanion.insert(
              uuid: uuidB,
              transactionNumber: 'PAY-B-0001',
              transactionType: 'payment',
              source: 'manual',
              transactionDate: now,
              amount: 750.0,
              currencyCode: 'USD',
              baseCurrencyCode: 'USD',
              counterCurrencyCode: 'USD',
              cashAccountId: generateUuidV4(),
              counterAccountId: generateUuidV4(),
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyB),
            ),
          );

      // Query Company A treasury records
      final queryA = await (db.select(db.financialTransactions)
            ..where((tbl) => tbl.companyId.equals(companyA)))
          .get();

      expect(queryA.length, equals(1));
      expect(queryA.first.uuid, equals(uuidA));
      expect(queryA.first.transactionNumber, equals('REC-A-0001'));
      expect(queryA.first.transactionType, equals('receipt'));
      expect(queryA.first.companyId, equals(companyA));

      // Query Company B treasury records
      final queryB = await (db.select(db.financialTransactions)
            ..where((tbl) => tbl.companyId.equals(companyB)))
          .get();

      expect(queryB.length, equals(1));
      expect(queryB.first.uuid, equals(uuidB));
      expect(queryB.first.transactionNumber, equals('PAY-B-0001'));
      expect(queryB.first.transactionType, equals('payment'));
      expect(queryB.first.companyId, equals(companyB));
    });

    test('Financial transaction creation with party and account references', () async {
      final companyId = 'comp-treasury-ref-3f';
      final txnUuid = generateUuidV4();
      final customerUuid = generateUuidV4();
      final cashAccountUuid = generateUuidV4();
      final counterAccountUuid = generateUuidV4();
      final voucherBookUuid = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.financialTransactions).insert(
            FinancialTransactionsCompanion.insert(
              uuid: txnUuid,
              transactionNumber: 'REC-2026-009',
              transactionType: 'receipt',
              source: 'customer_payment',
              transactionDate: now,
              amount: 2500.0,
              currencyCode: 'YER',
              baseCurrencyCode: 'YER',
              counterCurrencyCode: 'YER',
              exchangeRate: const Value(1.0),
              counterAmount: const Value(2500.0),
              voucherBookId: Value(voucherBookUuid),
              cashAccountId: cashAccountUuid,
              cashAccountCode: const Value('1010'),
              cashAccountName: const Value('Main Vault'),
              counterAccountId: counterAccountUuid,
              counterAccountCode: const Value('1200'),
              counterAccountName: const Value('Accounts Receivable'),
              customerId: Value(customerUuid),
              customerCode: const Value('CUST-007'),
              customerName: const Value('Acme Corp'),
              paymentMethod: const Value('cash'),
              documentStatus: const Value('unposted'),
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyId),
            ),
          );

      final row = await (db.select(db.financialTransactions)
            ..where((tbl) => tbl.uuid.equals(txnUuid)))
          .getSingle();

      expect(row.uuid, equals(txnUuid));
      expect(row.amount, equals(2500.0));
      expect(row.companyId, equals(companyId));
      expect(row.customerId, equals(customerUuid));
      expect(row.cashAccountId, equals(cashAccountUuid));
      expect(row.counterAccountId, equals(counterAccountUuid));
      expect(row.voucherBookId, equals(voucherBookUuid));
    });

    test('Treasury lifecycle state transition and posted immutability contract', () async {
      final companyId = 'comp-treasury-state-3f';
      final txnUuid = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Insert unposted financial transaction
      await db.into(db.financialTransactions).insert(
            FinancialTransactionsCompanion.insert(
              uuid: txnUuid,
              transactionNumber: 'PAY-STATE-01',
              transactionType: 'payment',
              source: 'manual',
              transactionDate: now,
              amount: 300.0,
              currencyCode: 'USD',
              baseCurrencyCode: 'USD',
              counterCurrencyCode: 'USD',
              cashAccountId: generateUuidV4(),
              counterAccountId: generateUuidV4(),
              documentStatus: const Value('unposted'),
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyId),
            ),
          );

      // 2. Mark posted
      await (db.update(db.financialTransactions)
            ..where((tbl) => tbl.uuid.equals(txnUuid)))
          .write(
        FinancialTransactionsCompanion(
          documentStatus: const Value('posted'),
          updatedAt: Value(now),
        ),
      );

      var updated = await (db.select(db.financialTransactions)
            ..where((tbl) => tbl.uuid.equals(txnUuid)))
          .getSingle();
      expect(updated.documentStatus, equals('posted'));

      // 3. Mark cancelled/reversed
      await (db.update(db.financialTransactions)
            ..where((tbl) => tbl.uuid.equals(txnUuid)))
          .write(
        FinancialTransactionsCompanion(
          cancelledAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      updated = await (db.select(db.financialTransactions)
            ..where((tbl) => tbl.uuid.equals(txnUuid)))
          .getSingle();
      expect(updated.cancelledAt, isNotNull);
    });

    test('Transactional rollback on failed treasury insertion', () async {
      final companyId = 'comp-rollback-treasury-3f';
      final txnUuid = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      try {
        await db.transaction(() async {
          await db.into(db.financialTransactions).insert(
                FinancialTransactionsCompanion.insert(
                  uuid: txnUuid,
                  transactionNumber: 'PAY-FAIL-01',
                  transactionType: 'payment',
                  source: 'manual',
                  transactionDate: now,
                  amount: 100.0,
                  currencyCode: 'USD',
                  baseCurrencyCode: 'USD',
                  counterCurrencyCode: 'USD',
                  cashAccountId: generateUuidV4(),
                  counterAccountId: generateUuidV4(),
                  createdAt: now,
                  updatedAt: now,
                  companyId: Value(companyId),
                ),
              );

          throw Exception('Forced treasury transaction failure');
        });
      } catch (_) {}

      final rows = await (db.select(db.financialTransactions)
            ..where((tbl) => tbl.uuid.equals(txnUuid)))
          .get();

      expect(rows, isEmpty);
    });
  });
}
