import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sqlite3/open.dart';

import 'package:stock_count/app/customers/accounting_customer_account_link_adapter.dart';
import 'package:stock_count/app/customers/customer_remote_account_ensure.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/core/sync/sync_entity_handler.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/modules/accounting/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/domain/models/account_tree_node.dart';
import 'package:stock_count/modules/customers/data/database/customers_database.dart';
import 'package:stock_count/modules/customers/data/repositories/customer_repository_impl.dart';
import 'package:stock_count/modules/customers/data/sync/customers_sync_handlers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  open.overrideFor(OperatingSystem.linux, () {
    return DynamicLibrary.open('libsqlite3.so.0');
  });

  late Directory tempDir;
  late AccountingDatabase accountingDb;
  late AccountRepositoryImpl accounts;
  late AccountingCustomerAccountLinkAdapter linkPort;
  late SyncQueue syncQueue;
  late SettingsRepository settings;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cust_coa_sync_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    final syncBox = await Hive.openBox<SyncOperation>(
      'sync_queue_${DateTime.now().microsecondsSinceEpoch}',
    );
    final settingsBox = await Hive.openBox<dynamic>(
      'settings_${DateTime.now().microsecondsSinceEpoch}',
    );
    syncQueue = SyncQueue(box: syncBox);
    settings = SettingsRepository(box: settingsBox);
    accountingDb = AccountingDatabase.memory();
    accounts = AccountRepositoryImpl(accountingDb, syncQueue: syncQueue);
    linkPort = AccountingCustomerAccountLinkAdapter(accounts);
    await accounts.ensureDefaultChartSeeded();
  });

  tearDown(() async {
    await accountingDb.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('applyRemotePayload remounts via code prefix when parentAccountCode absent',
      () async {
    final localParent = await linkPort.findSystemCustomersParent();
    expect(localParent, isNotNull);

    const remoteAccountUuid = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01';
    await accounts.applyRemotePayload({
      'uuid': remoteAccountUuid,
      'parentId': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      'accountCode': '12215501',
      'name': 'بدون parentAccountCode',
      'accountType': 'asset',
      'normalBalance': 'debit',
      'level': 4,
      'isGroup': false,
      'isActive': true,
      'isSystemAccount': false,
      'version': 1,
      'updatedAt': DateTime.utc(2026, 8, 15).millisecondsSinceEpoch,
    });

    final created = await accounts.getByUuid(remoteAccountUuid);
    expect(created!.parentId, localParent!.accountId);
  });

  test('applyRemotePayload remounts under local parent via parentAccountCode',
      () async {
    final localParent = await linkPort.findSystemCustomersParent();
    expect(localParent, isNotNull);

    const remoteParentUuid = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
    const remoteAccountUuid = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

    await accounts.applyRemotePayload({
      'uuid': remoteAccountUuid,
      'parentId': remoteParentUuid,
      'parentAccountCode': localParent!.code,
      'accountCode': '12219901',
      'name': 'عميل من جهاز آخر',
      'accountType': 'asset',
      'normalBalance': 'debit',
      'level': 4,
      'isGroup': false,
      'isActive': true,
      'isSystemAccount': false,
      'version': 1,
      'updatedAt': DateTime.utc(2026, 8, 15).millisecondsSinceEpoch,
    });

    final created = await accounts.getByUuid(remoteAccountUuid);
    expect(created, isNotNull);
    expect(created!.parentId, localParent.accountId);

    final forest = AccountTreeNode.buildForest(await accounts.getAll());
    var foundUnderParent = false;
    void walk(AccountTreeNode node) {
      if (node.account.uuid == localParent.accountId) {
        foundUnderParent = node.children.any(
          (c) => c.account.uuid == remoteAccountUuid,
        );
      }
      for (final child in node.children) {
        walk(child);
      }
    }

    for (final root in forest) {
      walk(root);
    }
    expect(foundUnderParent, isTrue);
  });

  test('customer remote ensure creates missing CoA account under local parent',
      () async {
    final ensure = CustomerRemoteAccountEnsure(
      accounts: accounts,
      accountLink: linkPort,
      settings: settings,
    );
    final customersDb = CustomersDatabase.memory();
    final customers = CustomerRepositoryImpl(customersDb, syncQueue: syncQueue);
    final handler = CustomerSyncHandler(
      repository: customers,
      remote: InMemoryRemoteSyncApi(),
      ensureLinkedAccount: ensure.ensureFromCustomerPayload,
    );

    const accountUuid = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
    const customerUuid = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';

    await handler.applyRemoteChange(
      SyncRemoteChange(
        entityId: customerUuid,
        version: 1,
        updatedAt: DateTime.utc(2026, 8, 15),
        deleted: false,
        payload: {
          'customerCode': '12218801',
          'name': 'عميل مزامن',
          'isActive': true,
          'accountId': accountUuid,
          'dataSource': 'local',
        },
      ),
    );

    final customer = await customers.getByUuid(customerUuid);
    expect(customer, isNotNull);
    expect(customer!.accountId, accountUuid);

    final account = await accounts.getByUuid(accountUuid);
    expect(account, isNotNull);
    final parent = await linkPort.findSystemCustomersParent();
    expect(account!.parentId, parent!.accountId);
    expect(account.accountCode, '12218801');

    await customersDb.close();
  });

  test('customer remote ensure remounts orphan account', () async {
    final ensure = CustomerRemoteAccountEnsure(
      accounts: accounts,
      accountLink: linkPort,
      settings: settings,
    );
    final parent = await linkPort.findSystemCustomersParent();

    // Code without a local group prefix → stays orphan until customer ensure.
    const accountUuid = 'ffffffff-ffff-4fff-8fff-ffffffffffff';
    await accountingDb.into(accountingDb.accounts).insert(
      AccountsCompanion.insert(
        uuid: accountUuid,
        parentId: const Value('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
        accountCode: 'ORPHAN01',
        name: 'يتيم',
        accountType: 'asset',
        normalBalance: 'debit',
        level: const Value(4),
        isGroup: const Value(false),
        isActive: const Value(true),
        isSystemAccount: const Value(false),
        createdAt: DateTime.utc(2026, 8, 15).millisecondsSinceEpoch,
        updatedAt: DateTime.utc(2026, 8, 15).millisecondsSinceEpoch,
        syncStatus: const Value('synced'),
        version: const Value(1),
      ),
    );

    var orphan = await accounts.getByUuid(accountUuid);
    expect(orphan!.parentId, isNot(parent!.accountId));
    expect(await accounts.getByUuid(orphan.parentId!), isNull);

    await ensure.ensureFromCustomerPayload({
      'customerCode': 'ORPHAN01',
      'name': 'يتيم',
      'accountId': accountUuid,
    });

    orphan = await accounts.getByUuid(accountUuid);
    expect(orphan!.parentId, parent.accountId);
  });
}
