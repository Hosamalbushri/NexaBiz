import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/auth/domain/services/local_authorization_guard.dart';
import 'package:stock_count/core/data/multi_tenant_repository_guard.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  group('Phase 2C-2 — Comprehensive Tenant Isolation Security Suite', () {
    late NexabizDatabase db;
    final companyA = generateUuidV7();
    final companyB = generateUuidV7();

    final accIdA = generateUuidV7();
    final accIdB = generateUuidV7();

    final prodIdA = generateUuidV7();
    final prodIdB = generateUuidV7();

    setUp(() async {
      db = NexabizDatabase.memory();

      // Seed Account for Company A
      await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          id: Value(accIdA),
          accountCode: '1001',
          name: 'Cash Box A',
          accountType: 'asset',
          normalBalance: 'debit',
          companyId: companyA,
        ),
      );

      // Seed Account for Company B
      await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          id: Value(accIdB),
          accountCode: '1001',
          name: 'Cash Box B',
          accountType: 'asset',
          normalBalance: 'debit',
          companyId: companyB,
        ),
      );

      // Seed Product for Company A
      await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: Value(prodIdA),
          itemCode: 'ITEM-A',
          name: 'Product A',
          companyId: companyA,
        ),
      );

      // Seed Product for Company B
      await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: Value(prodIdB),
          itemCode: 'ITEM-B',
          name: 'Product B',
          companyId: companyB,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Read Isolation — Company A query by ID enforces company scope', () async {
      // Query with company A scope for Company A's account MUST succeed
      final queryA = db.select(db.accounts)
        ..where((tbl) => tbl.id.equals(accIdA) & tbl.companyId.equals(companyA));
      final accountA = await queryA.getSingleOrNull();
      expect(accountA, isNotNull);
      expect(accountA?.name, equals('Cash Box A'));

      // Query with company A scope for Company B's account MUST return NULL
      final queryCross = db.select(db.accounts)
        ..where((tbl) => tbl.id.equals(accIdB) & tbl.companyId.equals(companyA));
      final accountCross = await queryCross.getSingleOrNull();
      expect(accountCross, isNull, reason: 'Company A MUST NOT read Company B record by UUID');
    });

    test('2. Direct UUID Cross-Tenant Access — Knowing Company B UUID yields zero results', () async {
      final query = db.select(db.products)
        ..where((tbl) => tbl.id.equals(prodIdB) & tbl.companyId.equals(companyA));
      final prod = await query.getSingleOrNull();
      expect(prod, isNull, reason: 'Knowing Company B product UUID MUST NOT grant access to Company A');
    });

    test('3. Update Isolation — Company A cannot mutate Company B record', () async {
      final updatedRows = await (db.update(db.accounts)
            ..where((tbl) => tbl.id.equals(accIdB) & tbl.companyId.equals(companyA)))
          .write(const AccountsCompanion(name: Value('Hacked Cash Box B')));

      expect(updatedRows, equals(0), reason: 'Cross-tenant update MUST affect 0 rows');

      // Verify Company B data remains intact
      final checkB = await (db.select(db.accounts)..where((tbl) => tbl.id.equals(accIdB))).getSingle();
      expect(checkB.name, equals('Cash Box B'));
    });

    test('4. Delete Isolation — Company A cannot delete Company B record', () async {
      final deletedRows = await (db.delete(db.accounts)
            ..where((tbl) => tbl.id.equals(accIdB) & tbl.companyId.equals(companyA)))
          .go();

      expect(deletedRows, equals(0), reason: 'Cross-tenant delete MUST affect 0 rows');

      final checkB = await (db.select(db.accounts)..where((tbl) => tbl.id.equals(accIdB))).getSingleOrNull();
      expect(checkB, isNotNull);
    });

    test('5. Search Isolation — Search query under Company A scope excludes Company B records', () async {
      final results = await (db.select(db.products)
            ..where((tbl) => tbl.companyId.equals(companyA)))
          .get();

      expect(results.length, equals(1));
      expect(results.first.id, equals(prodIdA));
      expect(results.any((p) => p.companyId == companyB), isFalse);
    });

    test('6. MultiTenantRepositoryGuard — Rejects company context mismatch', () {
      expect(
        () => MultiTenantRepositoryGuard.enforceCompanyContext(
          companyId: companyA,
          activeCompanyId: companyB,
        ),
        throwsA(isA<CompanyContextMismatchException>()),
      );
    });
  });
}
