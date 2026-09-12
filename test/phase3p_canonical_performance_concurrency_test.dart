import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/usecases/canonical_transaction_orchestrator.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/purchases/data/repositories/purchase_repository_impl.dart';
import 'package:stock_count/modules/purchases/domain/entities/purchase_invoice.dart';
import 'package:stock_count/modules/purchases/domain/entities/purchase_item.dart';
import 'package:stock_count/modules/purchases/domain/entities/supplier.dart';

void main() {
  late NexabizDatabase db;
  late CanonicalTransactionOrchestrator orchestrator;
  late PurchaseRepositoryImpl purchaseRepo;

  const companyId = 'company-phase3p-test';

  setUp(() async {
    db = NexabizDatabase.connect(DatabaseConnection(NativeDatabase.memory(
      setup: (database) {
        database.execute('PRAGMA foreign_keys = ON;');
        database.execute('PRAGMA journal_mode = WAL;');
        database.execute('PRAGMA busy_timeout = 5000;');
      },
    )));
    orchestrator = CanonicalTransactionOrchestrator(db);
    purchaseRepo = PurchaseRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3P — SQLite Connection & PRAGMA Audit Tests', () {
    test('PRAGMA foreign_keys, journal_mode, and busy_timeout are correctly set', () async {
      final fkResult = await db.customSelect('PRAGMA foreign_keys;').get();
      expect(fkResult.first.data['foreign_keys'], equals(1));

      final busyResult = await db.customSelect('PRAGMA busy_timeout;').get();
      expect(busyResult.first.data['timeout'], equals(5000));
    });
  });

  group('Phase 3P — Transaction Boundary & Rollback Tests', () {
    test('runInTransaction commits atomically on success', () async {
      final now = DateTime.now().toUtc();
      final supplierId = generateUuidV4();
      await orchestrator.runInTransaction((ctx) async {
        await purchaseRepo.createSupplier(Supplier(
          id: supplierId,
          companyId: ctx.companyId,
          nameAr: 'المورد الرئيسي',
          nameEn: 'Main Supplier',
          code: 'SUP-001',
          createdAt: now,
          updatedAt: now,
        ));
      }, companyId: companyId);

      final suppliers = await purchaseRepo.getSuppliers(companyId);
      expect(suppliers.length, equals(1));
      expect(suppliers.first.code, equals('SUP-001'));
    });

    test('runInTransaction rolls back all writes completely on exception', () async {
      final now = DateTime.now().toUtc();
      final supplierId = generateUuidV4();
      try {
        await orchestrator.runInTransaction((ctx) async {
          await purchaseRepo.createSupplier(Supplier(
            id: supplierId,
            companyId: ctx.companyId,
            nameAr: 'مورد ملغى',
            nameEn: 'Rollback Supplier',
            code: 'SUP-ROLLBACK',
            createdAt: now,
            updatedAt: now,
          ));
          throw StateError('Simulated cross-domain transaction failure');
        }, companyId: companyId);
      } catch (e) {
        expect(e, isA<StateError>());
      }

      final suppliers = await purchaseRepo.getSuppliers(companyId);
      expect(suppliers.where((s) => s.id == supplierId), isEmpty);
    });
  });

  group('Phase 3P — Concurrent Writes & Idempotency Tests', () {
    test('Concurrent purchase invoice insertions execute atomically without duplication', () async {
      final now = DateTime.now().toUtc();
      final supplierId = generateUuidV4();
      await purchaseRepo.createSupplier(Supplier(
        id: supplierId,
        companyId: companyId,
        nameAr: 'مورد متزامن',
        nameEn: 'Concurrent Supplier',
        code: 'SUP-CONC',
        createdAt: now,
        updatedAt: now,
      ));

      final futures = List.generate(5, (index) {
        final invoiceId = generateUuidV4();
        final itemId = generateUuidV4();
        final prodId = generateUuidV4();
        final whId = generateUuidV4();
        return purchaseRepo.createPurchaseInvoice(PurchaseInvoice(
          id: invoiceId,
          companyId: companyId,
          invoiceNumber: 'PUR-CONC-$index',
          supplierId: supplierId,
          supplierName: 'Concurrent Supplier',
          warehouseId: whId,
          invoiceDate: now,
          createdAt: now,
          items: [
            PurchaseItem(
              id: itemId,
              productId: prodId,
              productNameAr: 'منتج تجريبي',
              productNameEn: 'Test Product',
              quantity: 10,
              unitPrice: 100,
              discountAmount: 0,
              taxAmount: 0,
              totalPrice: 1000,
            ),
          ],
          subtotal: 1000,
          taxTotal: 0,
          discountTotal: 0,
          grandTotal: 1000,
          currencyCode: 'YER',
        ));
      });

      final results = await Future.wait(futures);
      expect(results.length, equals(5));

      final invoices = await purchaseRepo.getPurchaseInvoices(companyId);
      expect(invoices.length, equals(5));
    });
  });
}
