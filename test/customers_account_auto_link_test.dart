import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/app/customers/accounting_customer_account_link_adapter.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/modules/accounting/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/customers/data/database/customers_database.dart';
import 'package:stock_count/modules/customers/data/repositories/customer_repository_impl.dart';
import 'package:stock_count/modules/customers/domain/entities/customer.dart';
import 'package:stock_count/modules/customers/domain/services/customer_code_generator.dart';
import 'package:stock_count/modules/customers/domain/usecases/ensure_customer_account_links.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();


  late Directory tempDir;
  late AccountingDatabase accountingDb;
  late CustomersDatabase customersDb;
  late AccountRepositoryImpl accounts;
  late CustomerRepositoryImpl customers;
  late AccountingCustomerAccountLinkAdapter linkPort;
  late SyncQueue syncQueue;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cust_coa_link_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    final syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    syncQueue = SyncQueue(box: syncBox);
    accountingDb = AccountingDatabase.memory();
    customersDb = CustomersDatabase.memory();
    accounts = AccountRepositoryImpl(accountingDb, syncQueue: syncQueue);
    customers = CustomerRepositoryImpl(customersDb, syncQueue: syncQueue);
    linkPort = AccountingCustomerAccountLinkAdapter(accounts);
    await accounts.ensureDefaultChartSeeded();
  });

  tearDown(() async {
    await accountingDb.close();
    await customersDb.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('ensurePostingUnderParent creates account under customers group', () async {
    final parent = await linkPort.findSystemCustomersParent();
    expect(parent, isNotNull);
    expect(parent!.code, '1221');
    expect(parent.isGroup, isTrue);

    final linked = await linkPort.ensurePostingUnderParent(
      parentId: parent.accountId,
      accountCode: '12210001',
      name: 'Acme Trading',
    );
    expect(linked, isNotNull);
    expect(linked!.code, '12210001');
    expect(linked.name, 'Acme Trading');
    expect(linked.isPosting, isTrue);

    final under = await linkPort.isUnderParent(
      accountId: linked.accountId,
      parentId: parent.accountId,
    );
    expect(under, isTrue);

    final account = await accounts.getByAccountCode('12210001');
    expect(account!.parentId, parent.accountId);
  });

  test('ensurePostingUnderParent reuses and renames existing under parent', () async {
    final parent = await linkPort.findSystemCustomersParent();
    final first = await linkPort.ensurePostingUnderParent(
      parentId: parent!.accountId,
      accountCode: '12210002',
      name: 'Old Name',
    );
    final second = await linkPort.ensurePostingUnderParent(
      parentId: parent.accountId,
      accountCode: '12210002',
      name: 'New Name',
    );
    expect(second!.accountId, first!.accountId);
    expect(second.name, 'New Name');
    expect(await accounts.getByAccountCode('12210002'), isNotNull);
  });

  test('customer create can store auto-linked account id', () async {
    final parent = await linkPort.findSystemCustomersParent();
    final code = await CustomerCodeGenerator(customers).generate(
      parentAccountCode: parent!.code,
    );
    final linked = await linkPort.ensurePostingUnderParent(
      parentId: parent.accountId,
      accountCode: code,
      name: 'Linked Customer',
    );

    final customer = await customers.insert(
      CustomerDraft(
        customerCode: code,
        name: 'Linked Customer',
        accountId: linked!.accountId,
      ),
    );
    expect(customer.accountId, linked.accountId);
    expect(customer.customerCode, code);
  });

  test('listUnderParent returns CoA children under customers group', () async {
    final parent = await linkPort.findSystemCustomersParent();
    expect(parent, isNotNull);

    await linkPort.ensurePostingUnderParent(
      parentId: parent!.accountId,
      accountCode: '12216601',
      name: 'ظاهر في حزمة العملاء',
    );

    final listed = await linkPort.listUnderParent(parent.accountId);
    expect(listed.any((a) => a.code == '12216601'), isTrue);
    expect(
      listed.firstWhere((a) => a.code == '12216601').name,
      'ظاهر في حزمة العملاء',
    );
  });

  test('EnsureCustomerAccountLinks fills drafts for import', () async {
    final parent = await linkPort.findSystemCustomersParent();
    final linker = EnsureCustomerAccountLinks(linkPort);
    final drafts = await linker.applyAll(
      const [
        CustomerDraft(customerCode: '12210901', name: 'Import A'),
        CustomerDraft(customerCode: '12210902', name: 'Import B'),
      ],
      parentId: parent!.accountId,
    );
    expect(
      drafts.every((d) => d.accountId != null && d.accountId!.isNotEmpty),
      isTrue,
    );
    expect(await accounts.getByAccountCode('12210901'), isNotNull);
    expect(await accounts.getByAccountCode('12210902'), isNotNull);
  });
}
