import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/shared/contracts/errors/currency_exception.dart';
import 'package:stock_count/app/sales/accounting_sale_currency_adapter.dart';
import 'package:stock_count/app/receipts_payments/accounting_rp_currency_adapter.dart';
import 'package:stock_count/app/settings/company/app_currency.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/core/domain/entities/document_status.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/accounting/shared/domain/repositories/currency_rate_repository.dart';

class _FakeCurrencyRateRepository implements CurrencyRateRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final fakeRates = _FakeCurrencyRateRepository();

  group('CURRENCY-00 Forensic Currency Eradication Tests', () {
    test('1. AccountingSaleCurrencyAdapter throws CurrencyRequiredException when base currency is empty', () async {
      final adapter = AccountingSaleCurrencyAdapter(
        baseCurrencyReader: () async => '',
        rates: fakeRates,
      );

      expect(
        () async => adapter.baseCurrencyCode,
        throwsA(isA<CurrencyRequiredException>()),
      );
    });

    test('2. AccountingRpCurrencyAdapter throws CurrencyRequiredException when base currency is empty', () async {
      final adapter = AccountingRpCurrencyAdapter(
        baseCurrencyReader: () async => '   ',
        rates: fakeRates,
      );

      expect(
        () async => adapter.baseCurrencyCode,
        throwsA(isA<CurrencyRequiredException>()),
      );
    });

    test('3. AppCurrencies.byCode throws CurrencyRequiredException when currency code is null or empty', () {
      expect(
        () => AppCurrencies.byCode(null),
        throwsA(isA<CurrencyRequiredException>()),
      );
      expect(
        () => AppCurrencies.byCode(''),
        throwsA(isA<CurrencyRequiredException>()),
      );
      expect(
        () => AppCurrencies.byCode('   '),
        throwsA(isA<CurrencyRequiredException>()),
      );
    });

    test('4. AppCurrencies.byCode returns matching or custom AppCurrency for valid codes', () {
      final sar = AppCurrencies.byCode('SAR');
      expect(sar.code, equals('SAR'));

      final custom = AppCurrencies.byCode('USD');
      expect(custom.code, equals('USD'));
    });

    test('5. CompanyProfile contains no currency fields', () {
      const profile = CompanyProfile(name: 'Test Corp');
      expect(profile.name, equals('Test Corp'));
    });

    test('6. DocumentRef defaults currencyCode to empty string when not passed', () {
      final doc = DocumentRef(
        documentId: 'doc1',
        documentNumber: 'DOC-001',
        documentType: DocumentType.stockReceipt,
        documentDate: DateTime.now(),
      );
      expect(doc.currencyCode, equals(''));
    });

    test('7. StockDocumentPostingData defaults currencyCode to empty string when not passed', () {
      final postingData = StockDocumentPostingData(
        id: 'p1',
        documentNumber: 'DOC-001',
        documentType: DocumentType.stockIssue,
        documentDate: DateTime.now(),
        warehouseId: 'wh1',
        status: DocumentStatus.draft,
        totalAmount: 100.0,
      );
      expect(postingData.currencyCode, equals(''));
    });

    test('8. SaleInvoicePostingData defaults currencyCode and baseCurrencyCode to empty string', () {
      final saleData = SaleInvoicePostingData(
        uuid: 'u1',
        saleNumber: 'INV-001',
        saleDate: DateTime.now(),
        total: 500.0,
        itemDiscountTotal: 0.0,
        discountAmount: 0.0,
        settlementType: PostingSettlementType.cash,
      );
      expect(saleData.currencyCode, equals(''));
      expect(saleData.baseCurrencyCode, equals(''));
    });

    test('9. StockIssue and StockReceipt domain entities default currencyCode to empty string', () {
      final issue = StockIssue(
        issueNumber: 'ISS-001',
        issueDate: DateTime.now(),
      );
      expect(issue.currencyCode, equals(''));

      final receipt = StockReceipt(
        receiptNumber: 'REC-001',
        receiptDate: DateTime.now(),
      );
      expect(receipt.currencyCode, equals(''));
    });
  });
}
