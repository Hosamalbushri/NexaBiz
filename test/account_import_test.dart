import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/data/datasources/account_excel_import_datasource.dart';
import 'package:stock_count/modules/accounting/data/datasources/opening_balance_excel_datasource.dart';
import 'package:stock_count/modules/accounting/domain/models/account_import_row.dart';
import 'package:stock_count/modules/accounting/domain/models/opening_balance_line.dart';
import 'package:stock_count/modules/accounting/domain/services/account_import_opening_journal.dart';

Uint8List _workbookBytes({
  required List<List<String>> rows,
}) {
  final excel = Excel.createExcel();
  final sheet = excel[excel.getDefaultSheet()!];
  for (var r = 0; r < rows.length; r++) {
    for (var c = 0; c < rows[r].length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
          .value = TextCellValue(rows[r][c]);
    }
  }
  final encoded = excel.encode();
  return Uint8List.fromList(encoded!);
}

void main() {
  group('AccountExcelImportDatasource', () {
    const datasource = AccountExcelImportDatasource();

    test('parses header aliases for code and name only', () {
      final bytes = _workbookBytes(
        rows: const [
          ['Code', 'Name', 'Opening Debit', 'Opening Credit'],
          ['1214', 'Store Cash', '1500', ''],
          ['1215', 'Petty', '', '200'],
        ],
      );
      final result = datasource.parseBytes(bytes);
      expect(result.rows, hasLength(2));
      expect(result.rows[0].code, '1214');
      expect(result.rows[0].name, 'Store Cash');
      expect(result.rows[1].code, '1215');
      expect(result.rows[1].name, 'Petty');
    });

    test('parses positional columns without headers', () {
      final bytes = _workbookBytes(
        rows: const [
          ['1301', 'Warehouse'],
        ],
      );
      final result = datasource.parseBytes(bytes);
      expect(result.rows, hasLength(1));
      expect(result.rows.first.code, '1301');
      expect(result.rows.first.name, 'Warehouse');
    });

    test('keeps code empty when only name header is present', () {
      final bytes = _workbookBytes(
        rows: const [
          ['Name'],
          ['Store Cash'],
        ],
      );
      final result = datasource.parseBytes(bytes);
      expect(result.rows, hasLength(1));
      expect(result.rows.first.code, isEmpty);
      expect(result.rows.first.name, 'Store Cash');
    });
  });

  group('OpeningBalanceExcelDatasource', () {
    const datasource = OpeningBalanceExcelDatasource();

    test('parses multi-currency rows for same account code', () {
      final bytes = _workbookBytes(
        rows: const [
          ['Code', 'Currency', 'Debit', 'Credit'],
          ['1214', 'SAR', '1000', ''],
          ['1214', 'YER', '500', ''],
        ],
      );
      final result = datasource.parseBytes(bytes);
      expect(result.rows, hasLength(2));
      expect(result.rows[0].accountCode, '1214');
      expect(result.rows[0].currencyCode, 'SAR');
      expect(result.rows[0].debit, 1000);
      expect(result.rows[1].currencyCode, 'YER');
      expect(result.rows[1].debit, 500);

      final lines = datasource.resolveRows(
        rawRows: result.rows,
        byCode: {
          '1214': (id: 'cash', code: '1214', name: 'Store'),
        },
        byId: const {},
      );
      expect(lines, hasLength(2));
      expect(lines[0].accountId, 'cash');
      expect(lines[1].currencyCode, 'YER');
    });
  });

  group('AccountImportOpeningJournal', () {
    test('balances net debit against capital credit', () {
      final draft = AccountImportOpeningJournal.buildFromBalanceLines(
        balances: [
          const OpeningBalanceLine(
            id: '1',
            accountId: 'cash',
            accountCode: '1214',
            accountName: 'Store',
            debit: 1000,
          ),
        ],
        capitalAccountUuid: 'capital',
        defaultCurrencyCode: 'SAR',
        entryDate: DateTime.utc(2024, 1, 1),
        voucherNumber: 'OI-1',
        voucherType: 'Opening',
        description: 'Import OB',
      );

      expect(draft, isNotNull);
      expect(draft!.lines, hasLength(2));
      expect(draft.lines[0].accountUuid, 'cash');
      expect(draft.lines[0].debit, 1000);
      expect(draft.lines[1].accountUuid, 'capital');
      expect(draft.lines[1].credit, 1000);
    });

    test('balances net credit against capital debit', () {
      final draft = AccountImportOpeningJournal.buildFromBalanceLines(
        balances: [
          const OpeningBalanceLine(
            id: '1',
            accountId: 'loan',
            accountCode: '2121',
            accountName: 'Loan',
            credit: 500,
          ),
        ],
        capitalAccountUuid: 'capital',
        defaultCurrencyCode: 'SAR',
        entryDate: DateTime.utc(2024, 1, 1),
        voucherNumber: 'OI-2',
        voucherType: 'Opening',
      );

      expect(draft, isNotNull);
      expect(draft!.lines[0].credit, 500);
      expect(draft.lines[1].accountUuid, 'capital');
      expect(draft.lines[1].debit, 500);
    });

    test('one account with SAR and YER debit creates two capital lines', () {
      final draft = AccountImportOpeningJournal.buildFromBalanceLines(
        balances: [
          const OpeningBalanceLine(
            id: '1',
            accountId: 'cash',
            accountCode: '1214',
            accountName: 'Store',
            currencyCode: 'SAR',
            debit: 100,
          ),
          const OpeningBalanceLine(
            id: '2',
            accountId: 'cash',
            accountCode: '1214',
            accountName: 'Store',
            currencyCode: 'YER',
            debit: 200,
          ),
        ],
        capitalAccountUuid: 'capital',
        defaultCurrencyCode: 'SAR',
        entryDate: DateTime.utc(2024, 1, 1),
        voucherNumber: 'OI-FX',
        voucherType: 'Opening',
      );

      expect(draft, isNotNull);
      expect(draft!.allowUnbalancedMultiCurrency, isTrue);
      expect(draft.lines.where((l) => l.accountUuid == 'capital'), hasLength(2));
      expect(
        draft.lines.where((l) => l.currencyCode == 'SAR' && l.credit == 100),
        hasLength(1),
      );
      expect(
        draft.lines.where((l) => l.currencyCode == 'YER' && l.credit == 200),
        hasLength(1),
      );
    });

    test('rejects debit and credit on the same currency line', () {
      expect(
        () => AccountImportOpeningJournal.buildFromBalanceLines(
          balances: [
            const OpeningBalanceLine(
              id: '1',
              accountId: 'cash',
              accountCode: '1214',
              accountName: 'Store',
              debit: 10,
              credit: 5,
            ),
          ],
          capitalAccountUuid: 'capital',
          defaultCurrencyCode: 'SAR',
          entryDate: DateTime.utc(2024, 1, 1),
          voucherNumber: 'OI-bad',
          voucherType: 'Opening',
        ),
        throwsA(
          isA<AccountImportException>().having(
            (e) => e.code,
            'code',
            AccountImportException.bothOpeningSides,
          ),
        ),
      );
    });

    test('rejects duplicate currency for the same account', () {
      expect(
        () => AccountImportOpeningJournal.buildFromBalanceLines(
          balances: [
            const OpeningBalanceLine(
              id: '1',
              accountId: 'cash',
              accountCode: '1214',
              accountName: 'Store',
              currencyCode: 'SAR',
              debit: 10,
            ),
            const OpeningBalanceLine(
              id: '2',
              accountId: 'cash',
              accountCode: '1214',
              accountName: 'Store',
              currencyCode: 'SAR',
              debit: 20,
            ),
          ],
          capitalAccountUuid: 'capital',
          defaultCurrencyCode: 'SAR',
          entryDate: DateTime.utc(2024, 1, 1),
          voucherNumber: 'OI-dup',
          voucherType: 'Opening',
        ),
        throwsA(
          isA<AccountImportException>().having(
            (e) => e.code,
            'code',
            AccountImportException.duplicateCurrency,
          ),
        ),
      );
    });

    test('returns null when no opening amounts', () {
      final draft = AccountImportOpeningJournal.buildFromBalanceLines(
        balances: [
          const OpeningBalanceLine(
            id: '1',
            accountId: 'cash',
            accountCode: '1214',
            accountName: 'Store',
          ),
        ],
        capitalAccountUuid: 'capital',
        defaultCurrencyCode: 'SAR',
        entryDate: DateTime.utc(2024, 1, 1),
        voucherNumber: 'OI-3',
        voucherType: 'Opening',
      );
      expect(draft, isNull);
    });

    test('summarize groups totals by currency', () {
      final summaries = AccountImportOpeningJournal.summarize(
        [
          const OpeningBalanceLine(
            id: '1',
            accountId: 'a',
            accountCode: '1',
            accountName: 'A',
            currencyCode: 'SAR',
            debit: 100,
          ),
          const OpeningBalanceLine(
            id: '2',
            accountId: 'b',
            accountCode: '2',
            accountName: 'B',
            currencyCode: 'SAR',
            credit: 40,
          ),
          const OpeningBalanceLine(
            id: '3',
            accountId: 'c',
            accountCode: '3',
            accountName: 'C',
            currencyCode: 'YER',
            debit: 10,
          ),
        ],
        defaultCurrencyCode: 'SAR',
      );
      expect(summaries, hasLength(2));
      expect(summaries.first.currencyCode, 'SAR');
      expect(summaries.first.totalDebit, 100);
      expect(summaries.first.totalCredit, 40);
      expect(summaries.last.currencyCode, 'YER');
      expect(summaries.last.totalDebit, 10);
    });
  });
}
