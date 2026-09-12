import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/usecases/canonical_transaction_orchestrator.dart';
import 'package:stock_count/modules/purchases/data/repositories/purchase_repository_impl.dart';
import 'package:stock_count/modules/purchases/domain/entities/purchase_invoice.dart';
import 'package:stock_count/modules/purchases/domain/entities/purchase_item.dart';
import 'package:stock_count/modules/purchases/domain/entities/supplier.dart';

void main() {
  late NexabizDatabase db;
  late PurchaseRepositoryImpl purchaseRepo;
  late CanonicalTransactionOrchestrator orchestrator;

  const testCompanyId = '00000000-0000-4000-8000-000000000001';
  const supUuid1 = '00000000-0000-4000-8000-000000000101';
  const invUuid1 = '00000000-0000-4000-8000-000000000201';
  const itemUuid1 = '00000000-0000-4000-8000-000000000301';
  const prodUuid1 = '00000000-0000-4000-8000-000000000401';
  const whUuid1 = '00000000-0000-4000-8000-000000000501';

  setUp(() async {
    db = NexabizDatabase.connect(NativeDatabase.memory());
    purchaseRepo = PurchaseRepositoryImpl(db);
    orchestrator = CanonicalTransactionOrchestrator(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3N — Purchase Repository Drift Persistence', () {
    test('createSupplier persists to Drift table suppliers and filters by companyId', () async {
      final supplier = Supplier(
        id: supUuid1,
        companyId: testCompanyId,
        nameAr: 'مورد الاختبار',
        nameEn: 'Test Supplier',
        code: 'SUP-101',
        phone: '0501234567',
        taxNumber: '300000000000003',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      final created = await purchaseRepo.createSupplier(supplier);
      expect(created.id, equals(supUuid1));
      expect(created.companyId, equals(testCompanyId));

      final suppliers = await purchaseRepo.getSuppliers(testCompanyId);
      expect(suppliers.length, equals(1));
      expect(suppliers.first.nameAr, equals('مورد الاختبار'));

      final otherSuppliers = await purchaseRepo.getSuppliers('00000000-0000-4000-8000-000000000999');
      expect(otherSuppliers, isEmpty);
    });

    test('createPurchaseInvoice persists header and line items atomically to Drift tables', () async {
      final invoice = PurchaseInvoice(
        id: invUuid1,
        companyId: testCompanyId,
        invoiceNumber: 'PUR-2026-001',
        supplierId: supUuid1,
        supplierName: 'مورد الاختبار',
        warehouseId: whUuid1,
        invoiceDate: DateTime.now().toUtc(),
        items: const [
          PurchaseItem(
            id: itemUuid1,
            productId: prodUuid1,
            productNameAr: 'منتج أ',
            productNameEn: 'Product A',
            quantity: 10.0,
            unitPrice: 50.0,
            totalPrice: 500.0,
          ),
        ],
        subtotal: 500.0,
        taxTotal: 75.0,
        grandTotal: 575.0,
        currencyCode: 'SAR',
        createdAt: DateTime.now().toUtc(),
      );

      final created = await purchaseRepo.createPurchaseInvoice(invoice);
      expect(created.id, equals(invUuid1));
      expect(created.invoiceNumber, equals('PUR-2026-001'));
      expect(created.items.length, equals(1));
      expect(created.items.first.productNameAr, equals('منتج أ'));

      final invoices = await purchaseRepo.getPurchaseInvoices(testCompanyId);
      expect(invoices.length, equals(1));
      expect(invoices.first.status, equals(PurchaseInvoiceStatus.draft));
    });
  });

  group('Phase 3N — Canonical Transaction Orchestrator & Single-Transaction Boundaries', () {
    test('runInTransaction commits all writes on success', () async {
      const txnSupUuid = '00000000-0000-4000-8000-000000000601';
      final result = await orchestrator.runInTransaction(
        (context) async {
          await purchaseRepo.createSupplier(Supplier(
            id: txnSupUuid,
            companyId: testCompanyId,
            nameAr: 'مورد معاملة 1',
            nameEn: 'Txn Supplier 1',
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ));
          return 'SUCCESS';
        },
        companyId: testCompanyId,
      );

      expect(result, equals('SUCCESS'));

      final suppliers = await purchaseRepo.getSuppliers(testCompanyId);
      expect(suppliers.length, equals(1));
    });

    test('runInTransaction rolls back all writes on exception', () async {
      const failSupUuid = '00000000-0000-4000-8000-000000000701';
      try {
        await orchestrator.runInTransaction(
          (context) async {
            await purchaseRepo.createSupplier(Supplier(
              id: failSupUuid,
              companyId: testCompanyId,
              nameAr: 'مورد فاشل',
              nameEn: 'Failing Supplier',
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
            ));
            throw Exception('SIMULATED_TRANSACTION_FAILURE');
          },
          companyId: testCompanyId,
        );
      } catch (e) {
        expect(e.toString(), contains('SIMULATED_TRANSACTION_FAILURE'));
      }

      // Verify that supplier was rolled back and does not exist in DB
      final suppliers = await purchaseRepo.getSuppliers(testCompanyId);
      expect(suppliers, isEmpty);
    });
  });
}
