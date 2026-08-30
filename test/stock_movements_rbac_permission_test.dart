import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/inventory/permissions/inventory_permission_package.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/repositories/stock_movements_repository.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/usecases/stock_movement_usecases.dart';

class _FakeStockMovementsRepository implements StockMovementsRepository {
  bool getReceiptByIdCalled = false;
  bool getAllReceiptsCalled = false;
  bool watchAllReceiptsCalled = false;
  bool saveReceiptCalled = false;
  bool deleteReceiptCalled = false;

  bool getIssueByIdCalled = false;
  bool getAllIssuesCalled = false;
  bool watchAllIssuesCalled = false;
  bool saveIssueCalled = false;
  bool deleteIssueCalled = false;

  final Map<String, StockReceipt> receipts = {};
  final Map<String, StockIssue> issues = {};

  void reset() {
    getReceiptByIdCalled = false;
    getAllReceiptsCalled = false;
    watchAllReceiptsCalled = false;
    saveReceiptCalled = false;
    deleteReceiptCalled = false;

    getIssueByIdCalled = false;
    getAllIssuesCalled = false;
    watchAllIssuesCalled = false;
    saveIssueCalled = false;
    deleteIssueCalled = false;

    receipts.clear();
    issues.clear();
  }

  @override
  Future<StockReceipt?> getReceiptById(String id) async {
    getReceiptByIdCalled = true;
    return receipts[id];
  }

  @override
  Future<List<StockReceipt>> getAllReceipts() async {
    getAllReceiptsCalled = true;
    return receipts.values.toList();
  }

  @override
  Stream<List<StockReceipt>> watchAllReceipts() {
    watchAllReceiptsCalled = true;
    return Stream.value(receipts.values.toList());
  }

  @override
  Future<void> saveReceipt(StockReceipt receipt) async {
    saveReceiptCalled = true;
    receipts[receipt.id] = receipt;
  }

  @override
  Future<void> deleteReceipt(String id) async {
    deleteReceiptCalled = true;
    receipts.remove(id);
  }

  @override
  Future<StockIssue?> getIssueById(String id) async {
    getIssueByIdCalled = true;
    return issues[id];
  }

  @override
  Future<List<StockIssue>> getAllIssues() async {
    getAllIssuesCalled = true;
    return issues.values.toList();
  }

  @override
  Stream<List<StockIssue>> watchAllIssues() {
    watchAllIssuesCalled = true;
    return Stream.value(issues.values.toList());
  }

  @override
  Future<void> saveIssue(StockIssue issue) async {
    saveIssueCalled = true;
    issues[issue.id] = issue;
  }

  @override
  Future<void> deleteIssue(String id) async {
    deleteIssueCalled = true;
    issues.remove(id);
  }

  @override
  Future<void> saveMovementLines({
    required String movementUuid,
    required String movementType,
    required List<StockMovementLine> lines,
  }) async {}
}

void main() {
  late _FakeStockMovementsRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeStockMovementsRepository();
  });

  StockReceipt buildTestReceipt({required String id}) {
    return StockReceipt(
      id: id,
      receiptNumber: 'REC-001',
      receiptDate: DateTime.now(),
      lines: [
        StockMovementLine(
          movementUuid: 'm1',
          movementType: 'receipt',
          itemCode: 'ITEM-1',
          itemName: 'Item 1',
          mainQuantity: 10,
          subQuantity: 0,
          quantity: 10,
          unitCost: 50,
          totalCost: 500,
        ),
      ],
    );
  }

  StockIssue buildTestIssue({required String id}) {
    return StockIssue(
      id: id,
      issueNumber: 'ISS-001',
      issueDate: DateTime.now(),
      lines: [
        StockMovementLine(
          movementUuid: 'm2',
          movementType: 'issue',
          itemCode: 'ITEM-1',
          itemName: 'Item 1',
          mainQuantity: 5,
          subQuantity: 0,
          quantity: 5,
          unitCost: 50,
          totalCost: 250,
        ),
      ],
    );
  }

  group('Stock Receipts RBAC Enforcement', () {
    test('Unauthorized user is blocked from reading receipts', () async {
      final guard = CallbackPermissionGuard((codes) => false);
      final useCases = StockMovementUseCases(fakeRepo, permissionGuard: guard);

      expect(() => useCases.watchAllReceipts(), throwsA(isA<PermissionDeniedException>()));
      expect(fakeRepo.watchAllReceiptsCalled, isFalse);

      expect(() => useCases.getReceiptById('REC-001'), throwsA(isA<PermissionDeniedException>()));
      expect(fakeRepo.getReceiptByIdCalled, isFalse);
    });

    test('Unauthorized user is blocked from creating receipt', () async {
      final guard = CallbackPermissionGuard((codes) => false);
      final useCases = StockMovementUseCases(fakeRepo, permissionGuard: guard);
      final receipt = buildTestReceipt(id: 'REC-001');

      expect(() => useCases.saveReceipt(receipt), throwsA(isA<PermissionDeniedException>()));
      expect(fakeRepo.saveReceiptCalled, isFalse);
      expect(fakeRepo.receipts.containsKey('REC-001'), isFalse);
    });

    test('Unauthorized user is blocked from updating existing receipt', () async {
      final receipt = buildTestReceipt(id: 'REC-001');
      fakeRepo.receipts['REC-001'] = receipt;

      final guard = CallbackPermissionGuard((codes) => false);
      final useCases = StockMovementUseCases(fakeRepo, permissionGuard: guard);

      expect(() => useCases.saveReceipt(receipt), throwsA(isA<PermissionDeniedException>()));
      expect(fakeRepo.saveReceiptCalled, isFalse);
    });

    test('Unauthorized user is blocked from deleting receipt', () async {
      final receipt = buildTestReceipt(id: 'REC-001');
      fakeRepo.receipts['REC-001'] = receipt;

      final guard = CallbackPermissionGuard((codes) => false);
      final useCases = StockMovementUseCases(fakeRepo, permissionGuard: guard);

      expect(() => useCases.deleteReceipt('REC-001'), throwsA(isA<PermissionDeniedException>()));
      expect(fakeRepo.deleteReceiptCalled, isFalse);
      expect(fakeRepo.receipts.containsKey('REC-001'), isTrue);
    });

    test('Authorized user with receipt permissions can execute operations', () async {
      final grantedPermissions = {
        ...InventoryPermissions.receiptsView,
        ...InventoryPermissions.receiptsCreate,
        ...InventoryPermissions.receiptsUpdate,
        ...InventoryPermissions.receiptsDelete,
      };
      final guard = CallbackPermissionGuard((codes) => codes.any(grantedPermissions.contains));
      final useCases = StockMovementUseCases(fakeRepo, permissionGuard: guard);

      // Create
      final receipt = buildTestReceipt(id: 'REC-001');
      await useCases.saveReceipt(receipt);
      expect(fakeRepo.saveReceiptCalled, isTrue);
      expect(fakeRepo.receipts['REC-001'], equals(receipt));

      // Read
      fakeRepo.reset();
      fakeRepo.receipts['REC-001'] = receipt;
      final fetched = await useCases.getReceiptById('REC-001');
      expect(fakeRepo.getReceiptByIdCalled, isTrue);
      expect(fetched, equals(receipt));

      // Stream
      useCases.watchAllReceipts();
      expect(fakeRepo.watchAllReceiptsCalled, isTrue);

      // Delete
      fakeRepo.reset();
      fakeRepo.receipts['REC-001'] = receipt;
      await useCases.deleteReceipt('REC-001');
      expect(fakeRepo.deleteReceiptCalled, isTrue);
      expect(fakeRepo.receipts.containsKey('REC-001'), isFalse);
    });
  });

  group('Stock Issues RBAC Enforcement', () {
    test('Unauthorized user is blocked from reading issues', () async {
      final guard = CallbackPermissionGuard((codes) => false);
      final useCases = StockMovementUseCases(fakeRepo, permissionGuard: guard);

      expect(() => useCases.watchAllIssues(), throwsA(isA<PermissionDeniedException>()));
      expect(fakeRepo.watchAllIssuesCalled, isFalse);

      expect(() => useCases.getIssueById('ISS-001'), throwsA(isA<PermissionDeniedException>()));
      expect(fakeRepo.getIssueByIdCalled, isFalse);
    });

    test('Unauthorized user is blocked from creating issue', () async {
      final guard = CallbackPermissionGuard((codes) => false);
      final useCases = StockMovementUseCases(fakeRepo, permissionGuard: guard);
      final issue = buildTestIssue(id: 'ISS-001');

      expect(() => useCases.saveIssue(issue), throwsA(isA<PermissionDeniedException>()));
      expect(fakeRepo.saveIssueCalled, isFalse);
      expect(fakeRepo.issues.containsKey('ISS-001'), isFalse);
    });

    test('Unauthorized user is blocked from updating existing issue', () async {
      final issue = buildTestIssue(id: 'ISS-001');
      fakeRepo.issues['ISS-001'] = issue;

      final guard = CallbackPermissionGuard((codes) => false);
      final useCases = StockMovementUseCases(fakeRepo, permissionGuard: guard);

      expect(() => useCases.saveIssue(issue), throwsA(isA<PermissionDeniedException>()));
      expect(fakeRepo.saveIssueCalled, isFalse);
    });

    test('Unauthorized user is blocked from deleting issue', () async {
      final issue = buildTestIssue(id: 'ISS-001');
      fakeRepo.issues['ISS-001'] = issue;

      final guard = CallbackPermissionGuard((codes) => false);
      final useCases = StockMovementUseCases(fakeRepo, permissionGuard: guard);

      expect(() => useCases.deleteIssue('ISS-001'), throwsA(isA<PermissionDeniedException>()));
      expect(fakeRepo.deleteIssueCalled, isFalse);
      expect(fakeRepo.issues.containsKey('ISS-001'), isTrue);
    });

    test('Authorized user with issue permissions can execute operations', () async {
      final grantedPermissions = {
        ...InventoryPermissions.issuesView,
        ...InventoryPermissions.issuesCreate,
        ...InventoryPermissions.issuesUpdate,
        ...InventoryPermissions.issuesDelete,
      };
      final guard = CallbackPermissionGuard((codes) => codes.any(grantedPermissions.contains));
      final useCases = StockMovementUseCases(fakeRepo, permissionGuard: guard);

      // Create
      final issue = buildTestIssue(id: 'ISS-001');
      await useCases.saveIssue(issue);
      expect(fakeRepo.saveIssueCalled, isTrue);
      expect(fakeRepo.issues['ISS-001'], equals(issue));

      // Read
      fakeRepo.reset();
      fakeRepo.issues['ISS-001'] = issue;
      final fetched = await useCases.getIssueById('ISS-001');
      expect(fakeRepo.getIssueByIdCalled, isTrue);
      expect(fetched, equals(issue));

      // Stream
      useCases.watchAllIssues();
      expect(fakeRepo.watchAllIssuesCalled, isTrue);

      // Delete
      fakeRepo.reset();
      fakeRepo.issues['ISS-001'] = issue;
      await useCases.deleteIssue('ISS-001');
      expect(fakeRepo.deleteIssueCalled, isTrue);
      expect(fakeRepo.issues.containsKey('ISS-001'), isFalse);
    });
  });
}
