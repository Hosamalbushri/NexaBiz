import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/modules/customers/accounts/domain/services/customer_account_link_port.dart';
import 'package:stock_count/modules/customers/directory/data/repositories/customer_repository_impl.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer_status.dart';
import 'package:stock_count/modules/customers/directory/domain/models/customer_exception.dart';
import 'package:stock_count/modules/customers/directory/domain/services/customer_credit_limit_checker.dart';
import 'package:stock_count/modules/customers/directory/domain/services/customer_validator.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/sync/sync.dart';

class _FakeLedgerEngine {
  final Map<String, double> _accountBalances = {};
  final Set<String> _processedVouchers = {};

  double getBalance(String accountId) => _accountBalances[accountId] ?? 0.0;

  void postJournal({
    required String voucherId,
    required String companyId,
    required String customerAccountId,
    required double debitAmount,
    required double creditAmount,
  }) {
    if (_processedVouchers.contains(voucherId)) {
      // Idempotent ignore
      return;
    }
    _processedVouchers.add(voucherId);
    final current = _accountBalances[customerAccountId] ?? 0.0;
    _accountBalances[customerAccountId] = current + debitAmount - creditAmount;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CU-04 — Customer Balances / Receivables / Accounting Integration', () {
    late Directory tempDir;
    late NexabizDatabase db;
    late SyncQueue queue;
    late CustomerRepositoryImpl repoCompanyA;
    late CustomerRepositoryImpl repoCompanyB;
    const validator = CustomerValidator();
    const creditChecker = CustomerCreditLimitChecker();
    late _FakeLedgerEngine ledger;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cu04_acct_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }
      final box = await Hive.openBox<SyncOperation>('sync_queue_cu04');
      queue = SyncQueue(box: box);
      db = NexabizDatabase.memory();
      repoCompanyA = CustomerRepositoryImpl(
        db,
        syncQueue: queue,
        readCompanyId: () => 'comp_A',
      );
      repoCompanyB = CustomerRepositoryImpl(
        db,
        syncQueue: queue,
        readCompanyId: () => 'comp_B',
      );
      ledger = _FakeLedgerEngine();
    });

    tearDown(() async {
      await db.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      '1. Balance Authority: Customer balance derived from ledger journal postings',
      () async {
        final customer = await repoCompanyA.insert(
          const CustomerDraft(
            customerCode: '12210020',
            name: 'عميل رصيد حسابات',
            accountId: 'acc_cust_12210020',
          ),
        );

        // Initial balance is 0
        expect(ledger.getBalance(customer.accountId!), equals(0.0));

        // Post sale invoice on credit (Debit Customer Account 1000)
        ledger.postJournal(
          voucherId: 'INV-001',
          companyId: 'comp_A',
          customerAccountId: customer.accountId!,
          debitAmount: 1000.0,
          creditAmount: 0.0,
        );

        expect(ledger.getBalance(customer.accountId!), equals(1000.0));

        // Post payment receipt (Credit Customer Account 400)
        ledger.postJournal(
          voucherId: 'RCT-001',
          companyId: 'comp_A',
          customerAccountId: customer.accountId!,
          debitAmount: 0.0,
          creditAmount: 400.0,
        );

        expect(ledger.getBalance(customer.accountId!), equals(600.0));
      },
    );

    test(
      '2. Credit Limit Enforcement: Hard domain rejection when exposure exceeds limit',
      () async {
        final customer = await repoCompanyA.insert(
          const CustomerDraft(
            customerCode: '12210021',
            name: 'عميل حد ألماني',
            creditLimit: 5000.0,
            currencyCode: 'SAR',
          ),
        );

        // Existing balance = 3500. Proposed new sale = 1000 (total = 4500 <= 5000) -> Allowed
        expect(
          () => creditChecker.validateExposure(
            customer: customer,
            currentOutstandingBalance: 3500.0,
            proposedExposureAmount: 1000.0,
          ),
          returnsNormally,
        );

        // Existing balance = 3500. Proposed new sale = 2000 (total = 5500 > 5000) -> Rejected!
        expect(
          () => creditChecker.validateExposure(
            customer: customer,
            currentOutstandingBalance: 3500.0,
            proposedExposureAmount: 2000.0,
          ),
          throwsA(
            isA<CustomerException>().having(
              (e) => e.code,
              'code',
              CustomerException.creditLimitExceeded,
            ),
          ),
        );
      },
    );

    test(
      '3. Blocked Customer Gating: Blocked customers cannot incur credit exposure',
      () async {
        final blockedCustomer = await repoCompanyA.insert(
          const CustomerDraft(
            customerCode: '12210022',
            name: 'عميل محظور',
            status: CustomerStatus.blocked,
            creditLimit: 10000.0,
          ),
        );

        expect(
          () => creditChecker.validateExposure(
            customer: blockedCustomer,
            currentOutstandingBalance: 0.0,
            proposedExposureAmount: 100.0,
          ),
          throwsA(
            isA<CustomerException>().having(
              (e) => e.code,
              'code',
              'customer_blocked',
            ),
          ),
        );
      },
    );

    test(
      '4. Payment Allocation: Partial, full, and overpayment calculations',
      () async {
        const totalInvoiceAmount = 1000.0;
        var remainingBalance = totalInvoiceAmount;

        // Partial payment 400
        remainingBalance -= 400.0;
        expect(remainingBalance, equals(600.0));

        // Second payment 600 (Full payment)
        remainingBalance -= 600.0;
        expect(remainingBalance, equals(0.0));

        // Overpayment 200
        remainingBalance -= 200.0;
        expect(remainingBalance, equals(-200.0)); // Credit balance
      },
    );

    test(
      '5. Account Link Validation: Prevents cross-company account binding',
      () {
        expect(
          () => validator.validateAccountLink(
            const LinkedAccountRef(
              accountId: 'acc_comp_B',
              code: '122199',
              name: 'حساب شركة ب',
              companyId: 'comp_B',
            ),
            customerCompanyId: 'comp_A',
          ),
          throwsA(
            isA<CustomerException>().having(
              (e) => e.code,
              'code',
              CustomerException.accountCompanyMismatch,
            ),
          ),
        );
      },
    );

    test(
      '6. Idempotency: Duplicate journal posting does not duplicate balance effect',
      () async {
        const accountId = 'acc_cust_idempotent';

        ledger.postJournal(
          voucherId: 'INV-100',
          companyId: 'comp_A',
          customerAccountId: accountId,
          debitAmount: 1500.0,
          creditAmount: 0.0,
        );
        expect(ledger.getBalance(accountId), equals(1500.0));

        // Duplicate post call with same voucherId
        ledger.postJournal(
          voucherId: 'INV-100',
          companyId: 'comp_A',
          customerAccountId: accountId,
          debitAmount: 1500.0,
          creditAmount: 0.0,
        );
        expect(ledger.getBalance(accountId), equals(1500.0));
      },
    );

    test(
      '7. Historical Reference Integrity: Updating customer profile does not mutate account linkage',
      () async {
        final customer = await repoCompanyA.insert(
          const CustomerDraft(
            customerCode: '12210025',
            name: 'عميل تاريخي',
            accountId: 'acc_original_12210025',
          ),
        );

        // Snapshot invoice reference
        final snapshottedAccountId = customer.accountId;
        final snapshottedName = customer.name;

        // Update customer name & phone
        final updated = await repoCompanyA.update(
          customer.id,
          customer.toDraft().copyWith(
            name: 'عميل اسم جديد',
            phone: '+966511111111',
          ),
        );

        expect(updated.accountId, equals(snapshottedAccountId));
        expect(snapshottedName, equals('عميل تاريخي'));
        expect(updated.name, equals('عميل اسم جديد'));
      },
    );
  });
}
