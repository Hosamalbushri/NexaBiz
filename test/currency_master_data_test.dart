import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:stock_count/shared/contracts/errors/currency_exception.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/data/repositories/currency_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency.dart';

void main() {
  late AccountingDatabase db;
  late CurrencyRepositoryImpl repository;
  const companyId = 'test-company-101';

  setUp(() async {
    db = AccountingDatabase.memory();
    repository = CurrencyRepositoryImpl(
      db,
      readCompanyId: () => companyId,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('CURRENCY-01 — Currency Master Data Behavioral Tests', () {
    test('1. Duplicate currency code is rejected', () async {
      await repository.upsert(
        const CurrencyDraft(
          code: 'USD',
          nameAr: 'دولار أمريكي',
          nameEn: 'US Dollar',
          symbol: '\$',
          decimalDigits: 2,
        ),
      );

      // Attempting to create duplicate currency code with different UUID
      expect(
        () async => repository.upsert(
          const CurrencyDraft(
            uuid: 'different-uuid-12345',
            code: 'usd', // Case-insensitive duplicate check
            nameAr: 'دولار إضافي',
            nameEn: 'Extra Dollar',
            symbol: '\$',
            decimalDigits: 2,
          ),
        ),
        throwsA(isA<CurrencyValidationException>()),
      );
    });

    test('2. Invalid precision (< 0 or > 6) is rejected', () async {
      // Precision < 0
      expect(
        () async => repository.upsert(
          const CurrencyDraft(
            code: 'INV1',
            nameAr: 'غير صالحة 1',
            nameEn: 'Invalid 1',
            symbol: 'X',
            decimalDigits: -1,
          ),
        ),
        throwsA(isA<CurrencyValidationException>()),
      );

      // Precision > 6
      expect(
        () async => repository.upsert(
          const CurrencyDraft(
            code: 'INV2',
            nameAr: 'غير صالحة 2',
            nameEn: 'Invalid 2',
            symbol: 'X',
            decimalDigits: 7,
          ),
        ),
        throwsA(isA<CurrencyValidationException>()),
      );
    });

    test('3. Inactive currency cannot be selected for new transactions', () async {
      await repository.upsert(
        const CurrencyDraft(
          code: 'ACTIVE1',
          nameAr: 'عملة نشطة',
          nameEn: 'Active Currency',
          symbol: 'A1',
          isActive: true,
        ),
      );
      await repository.upsert(
        const CurrencyDraft(
          code: 'INACTIVE1',
          nameAr: 'عملة معطلة',
          nameEn: 'Inactive Currency',
          symbol: 'I1',
          isActive: false,
        ),
      );

      final activeCurrencies = await repository.getAll(includeInactive: false);
      expect(activeCurrencies.map((c) => c.code), contains('ACTIVE1'));
      expect(activeCurrencies.map((c) => c.code), isNot(contains('INACTIVE1')));
    });

    test('4. Historical inactive currency remains readable', () async {
      final created = await repository.upsert(
        const CurrencyDraft(
          code: 'HIST1',
          nameAr: 'عملة تاريخية',
          nameEn: 'Historical Currency',
          symbol: 'H1',
          isActive: true,
        ),
      );

      // Deactivate currency
      await repository.toggleActive('HIST1', false);

      final fetchedByCode = await repository.getByCode('HIST1');
      expect(fetchedByCode, isNotNull);
      expect(fetchedByCode!.code, equals('HIST1'));
      expect(fetchedByCode.isActive, isFalse);

      final fetchedByUuid = await repository.getByUuid(created.uuid);
      expect(fetchedByUuid, isNotNull);
      expect(fetchedByUuid!.uuid, equals(created.uuid));
    });

    test('5. Currency deletion behavior is safe (soft deletion preserves data)', () async {
      await repository.upsert(
        const CurrencyDraft(
          code: 'DEL1',
          nameAr: 'عملة محذوفة',
          nameEn: 'Deleted Currency',
          symbol: 'D1',
        ),
      );

      await repository.deleteByCode('DEL1');

      // Normal getByCode excludes soft-deleted records
      final fetchedByCode = await repository.getByCode('DEL1');
      expect(fetchedByCode, isNull);

      // Verify row still exists in database with deleted_at timestamp (preserving history)
      final rawRow = await db.customSelect(
        'SELECT * FROM currencies WHERE code = ? AND company_id = ?',
        variables: [Variable.withString('DEL1'), Variable.withString(companyId)],
      ).getSingle();

      expect(rawRow.read<int?>('deleted_at'), isNotNull);
    });

    test('6. Multiple currencies coexist independently', () async {
      await repository.upsert(
        const CurrencyDraft(
          code: 'USD',
          nameAr: 'دولار أمريكي',
          nameEn: 'US Dollar',
          symbol: '\$',
          decimalDigits: 2,
        ),
      );
      await repository.upsert(
        const CurrencyDraft(
          code: 'SAR',
          nameAr: 'ريال سعودي',
          nameEn: 'Saudi Riyal',
          symbol: 'ر.س',
          decimalDigits: 2,
        ),
      );
      await repository.upsert(
        const CurrencyDraft(
          code: 'KWD',
          nameAr: 'دينار كويتي',
          nameEn: 'Kuwaiti Dinar',
          symbol: 'د.ك',
          decimalDigits: 3,
        ),
      );

      final all = await repository.getAll(includeInactive: true);
      expect(all.length, equals(3));
      expect(all.map((c) => c.code), containsAll(['USD', 'SAR', 'KWD']));
    });

    test('7. Creating currency A does not affect currency B', () async {
      final curB = await repository.upsert(
        const CurrencyDraft(
          code: 'EUR',
          nameAr: 'يورو',
          nameEn: 'Euro',
          symbol: '€',
          decimalDigits: 2,
          isActive: true,
        ),
      );

      await repository.upsert(
        const CurrencyDraft(
          code: 'GBP',
          nameAr: 'جنيه إسترليني',
          nameEn: 'British Pound',
          symbol: '£',
          decimalDigits: 2,
          isActive: true,
        ),
      );

      final fetchedB = await repository.getByCode('EUR');
      expect(fetchedB!.code, equals(curB.code));
      expect(fetchedB.symbol, equals(curB.symbol));
      expect(fetchedB.decimalDigits, equals(curB.decimalDigits));
      expect(fetchedB.isActive, equals(curB.isActive));
    });

    test('8. No currency becomes an implicit default merely because it was created', () async {
      await repository.upsert(
        const CurrencyDraft(
          code: 'AED',
          nameAr: 'درهم إماراتي',
          nameEn: 'UAE Dirham',
          symbol: 'د.إ',
          isDefault: false,
        ),
      );
      await repository.upsert(
        const CurrencyDraft(
          code: 'OMR',
          nameAr: 'ريال عماني',
          nameEn: 'Omani Rial',
          symbol: 'ر.ع',
          isDefault: false,
        ),
      );

      final defaultCurrency = await repository.getDefaultCurrency();
      expect(defaultCurrency, isNull);
    });

    test('9. ensureDefaultCurrenciesSeeded with defaultCode="" assigns no implicit default', () async {
      await repository.ensureDefaultCurrenciesSeeded(defaultCode: '');

      final seeded = await repository.getAll(includeInactive: true);
      expect(seeded, isNotEmpty);

      final defaultCurrency = await repository.getDefaultCurrency();
      expect(defaultCurrency, isNull);
    });
  });
}
