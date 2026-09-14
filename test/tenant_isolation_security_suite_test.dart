import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2C-4 Security & Tenant Isolation Suite', () {
    late NexabizDatabase db;

    setUp(() async {
      db = NexabizDatabase.connect(NativeDatabase.memory());
      // Enable physical foreign key enforcement
      await db.customStatement('PRAGMA foreign_keys = ON;');
    });

    tearDown(() async {
      await db.close();
    });

    test('Physical Composite FK rejects cross-tenant foreign key reference attack', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Seed two isolated companies (Company A and Company B)
      await db.customStatement('''
        INSERT INTO companies (id, code, name, base_currency_code, inventory_currency_code, status, created_at, updated_at)
        VALUES 
          ('COMP-A', 'CA', 'Company A', 'YER', 'SAR', 'active', $now, $now),
          ('COMP-B', 'CB', 'Company B', 'YER', 'SAR', 'active', $now, $now);
      ''');

      // 2. Seed Customer for Company A
      await db.customStatement('''
        INSERT INTO customers (id, company_id, customer_code, name, status, created_at, updated_at)
        VALUES ('CUST-A-1', 'COMP-A', 'CUST-001', 'Company A Customer', 'active', $now, $now);
      ''');

      // 3. Seed Customer for Company B
      await db.customStatement('''
        INSERT INTO customers (id, company_id, customer_code, name, status, created_at, updated_at)
        VALUES ('CUST-B-1', 'COMP-B', 'CUST-001', 'Company B Customer', 'active', $now, $now);
      ''');

      // 4. CROSS-TENANT ATTACK: Company B tries to insert a Sale referencing Company A's Customer ('CUST-A-1')
      // Expect SQLite C engine to physically reject with FOREIGN KEY constraint failed!
      expect(
        () async {
          await db.customStatement('''
            INSERT INTO sales (id, company_id, sale_number, customer_id, currency_code, base_currency_code, exchange_rate, subtotal, item_discount_total, total, created_at, updated_at)
            VALUES ('SALE-ATTACK-1', 'COMP-B', 'SALE-B-001', 'CUST-A-1', 'SAR', 'YER', 140.0, 100.0, 0.0, 100.0, $now, $now);
          ''');
        },
        throwsA(anything),
        reason: 'SQLite physical composite FK must prevent Company B from referencing Company A customer!',
      );

      // 5. VALID TENANT INVOCATION: Company A inserts Sale referencing Company A's Customer ('CUST-A-1')
      await db.customStatement('''
        INSERT INTO sales (id, company_id, sale_number, customer_id, currency_code, base_currency_code, exchange_rate, subtotal, item_discount_total, total, created_at, updated_at)
        VALUES ('SALE-VALID-1', 'COMP-A', 'SALE-A-001', 'CUST-A-1', 'SAR', 'YER', 140.0, 100.0, 0.0, 100.0, $now, $now);
      ''');

      final saleRow = await db.customSelect("SELECT * FROM sales WHERE id = 'SALE-VALID-1'").getSingle();
      expect(saleRow.read<String>('company_id'), equals('COMP-A'));
      expect(saleRow.read<String>('customer_id'), equals('CUST-A-1'));

      // 6. PRAGMA foreign_key_check must confirm 0 violations!
      final fkViolations = await db.customSelect('PRAGMA foreign_key_check;').get();
      expect(fkViolations.isEmpty, isTrue);
    });

    test('Physical Composite FK enforces child cascading/restriction within company boundary', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.customStatement('''
        INSERT INTO companies (id, code, name, base_currency_code, inventory_currency_code, status, created_at, updated_at)
        VALUES ('COMP-X', 'CX', 'Company X', 'YER', 'SAR', 'active', $now, $now);
      ''');

      await db.customStatement('''
        INSERT INTO products (id, company_id, item_code, name, pack_size, price, avg_cost, unit_cost, is_active, created_at, updated_at)
        VALUES ('PROD-X-1', 'COMP-X', 'ITEM-X1', 'Product X1', 1, 50.0, 30.0, 30.0, 1, $now, $now);
      ''');

      await db.customStatement('''
        INSERT INTO sales (id, company_id, sale_number, currency_code, base_currency_code, exchange_rate, subtotal, item_discount_total, total, created_at, updated_at)
        VALUES ('SALE-X-1', 'COMP-X', 'SX-1', 'SAR', 'YER', 140.0, 50.0, 0.0, 50.0, $now, $now);
      ''');

      // SaleItem referencing Product X1 of Company X
      await db.customStatement('''
        INSERT INTO sale_items (id, company_id, sale_id, product_id, product_name, product_code, quantity, unit_price, subtotal, total)
        VALUES ('SITEM-X-1', 'COMP-X', 'SALE-X-1', 'PROD-X-1', 'Product X1', 'ITEM-X1', 1.0, 50.0, 50.0, 50.0);
      ''');

      // Deleting product referenced by sale_items should throw RESTRICT violation
      expect(
        () async {
          await db.customStatement("DELETE FROM products WHERE id = 'PROD-X-1';");
        },
        throwsA(anything),
      );

      final fkViolations = await db.customSelect('PRAGMA foreign_key_check;').get();
      expect(fkViolations.isEmpty, isTrue);
    });
  });
}
