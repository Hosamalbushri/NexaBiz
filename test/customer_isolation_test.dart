import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/modules/customers/accounts/domain/services/customer_account_link_port.dart';
import 'package:stock_count/modules/customers/directory/data/repositories/customer_repository_impl.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer.dart';
import 'package:stock_count/modules/customers/directory/domain/models/customer_exception.dart';
import 'package:stock_count/modules/customers/directory/domain/services/customer_validator.dart';
import 'package:stock_count/modules/customers/shared/data/database/customers_database.dart';
import 'package:stock_count/modules/sync/sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CU-07 — Multi-Company / Authorization / Isolation Bypass Tests', () {
    late Directory tempDir;
    late CustomersDatabase db;
    late SyncQueue queue;
    late CustomerRepositoryImpl repoCompanyA;
    late CustomerRepositoryImpl repoCompanyB;
    const validator = CustomerValidator();

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cu07_iso_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }
      final box = await Hive.openBox<SyncOperation>('sync_queue_cu07');
      queue = SyncQueue(box: box);
      db = CustomersDatabase.memory();

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
    });

    tearDown(() async {
      await db.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('1. DIRECT READ BYPASS: Company A cannot retrieve Company B customer by ID or UUID', () async {
      final custB = await repoCompanyB.insert(
        const CustomerDraft(
          customerCode: '12210050',
          name: 'عميل شركة ب السرية',
          phone: '+966509999999',
        ),
      );

      // Verify Company B can read its customer
      final fetchedByB = await repoCompanyB.getById(custB.id);
      expect(fetchedByB, isNotNull);
      expect(fetchedByB!.name, equals('عميل شركة ب السرية'));

      // Company A attempts read by internal ID
      final fetchedByA = await repoCompanyA.getById(custB.id);
      expect(fetchedByA, isNull);

      // Company A attempts read by UUID
      final fetchedByUuidA = await repoCompanyA.getByUuid(custB.uuid);
      expect(fetchedByUuidA, isNull);

      // Company A attempts read by customerCode
      final fetchedByCodeA = await repoCompanyA.getByCustomerCode(custB.customerCode);
      expect(fetchedByCodeA, isNull);
    });

    test('2. SEARCH BYPASS: Company A search does not leak Company B customers', () async {
      await repoCompanyB.insert(
        const CustomerDraft(
          customerCode: '12210051',
          name: 'مؤسسة الرياض الوطنية',
          phone: '+966508888888',
        ),
      );

      final searchResultsA = await repoCompanyA.search('الرياض');
      expect(searchResultsA, isEmpty);

      final allA = await repoCompanyA.getAll(includeInactive: true);
      expect(allA, isEmpty);
    });

    test('3. WRITE / UPDATE BYPASS: Company A cannot update Company B customer', () async {
      final custB = await repoCompanyB.insert(
        const CustomerDraft(
          customerCode: '12210052',
          name: 'عميل قبل التعديل',
        ),
      );

      expect(
        () => repoCompanyA.update(
          custB.id,
          custB.toDraft().copyWith(name: 'اختراق اسم جديد'),
        ),
        throwsA(isA<CustomerException>().having(
          (e) => e.code,
          'code',
          CustomerException.notFound,
        )),
      );

      // Ensure unchanged in DB for Company B
      final unchanged = await repoCompanyB.getById(custB.id);
      expect(unchanged!.name, equals('عميل قبل التعديل'));
    });

    test('4. DELETE BYPASS: Company A cannot delete Company B customer', () async {
      final custB = await repoCompanyB.insert(
        const CustomerDraft(
          customerCode: '12210053',
          name: 'عميل حماية الحذف',
        ),
      );

      expect(
        () => repoCompanyA.softDelete(custB.id),
        throwsA(isA<CustomerException>().having(
          (e) => e.code,
          'code',
          CustomerException.notFound,
        )),
      );

      final activeForB = await repoCompanyB.getById(custB.id);
      expect(activeForB, isNotNull);
      expect(activeForB!.isActive, isTrue);
    });

    test('5. RESTORE BYPASS: Company A cannot restore Company B customer', () async {
      final custB = await repoCompanyB.insert(
        const CustomerDraft(
          customerCode: '12210054',
          name: 'عميل محذوف لدى ب',
        ),
      );
      await repoCompanyB.softDelete(custB.id);

      expect(
        () => repoCompanyA.restore(custB.id),
        throwsA(isA<CustomerException>().having(
          (e) => e.code,
          'code',
          CustomerException.notFound,
        )),
      );
    });

    test('6. CREATION IMPERSONATION: CustomerDraft prevents companyId payload injection', () async {
      // CustomerDraft presentation API does not accept arbitrary companyId payload.
      // Insertion into repoCompanyA derives company context strictly from readCompanyId ('comp_A').
      final created = await repoCompanyA.insert(
        const CustomerDraft(
          customerCode: '12210055',
          name: 'عميل تجربة التزييف',
        ),
      );

      // Must be forced to comp_A
      expect(created.companyId, equals('comp_A'));

      // Company B cannot see it
      final notInB = await repoCompanyB.getById(created.id);
      expect(notInB, isNull);
    });

    test('7. ACCOUNT LINK ISOLATION: Rejects cross-company Chart of Accounts link', () {
      expect(
        () => validator.validateAccountLink(
          const LinkedAccountRef(
            accountId: 'acc_company_B_1221',
            code: '122100',
            name: 'ذمم مدينة شركة ب',
            companyId: 'comp_B',
          ),
          customerCompanyId: 'comp_A',
        ),
        throwsA(isA<CustomerException>().having(
          (e) => e.code,
          'code',
          CustomerException.accountCompanyMismatch,
        )),
      );
    });

    test('8. REMOTE SYNC ISOLATION: Remote payload for Company B is not exposed to Company A', () async {
      const remoteUuid = '11111111-2222-3333-4444-555555555555';
      // Apply remote payload with companyId 'comp_B'
      final remotePayload = <String, dynamic>{
        'uuid': remoteUuid,
        'companyId': 'comp_B',
        'customerCode': '12210056',
        'name': 'عميل مزامنة شركة ب',
        'status': 'active',
        'version': 1,
      };

      await repoCompanyB.applyRemotePayload(remotePayload);

      // Company A repository cannot read it
      final notInA = await repoCompanyA.getByUuid(remoteUuid);
      expect(notInA, isNull);

      // Company B repository reads it successfully
      final inB = await repoCompanyB.getByUuid(remoteUuid);
      expect(inB, isNotNull);
      expect(inB!.name, equals('عميل مزامنة شركة ب'));
    });
  });
}
