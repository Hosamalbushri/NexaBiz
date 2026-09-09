import 'package:drift/drift.dart';
import 'package:stock_count/shared/contracts/errors/currency_exception.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';

class AccountCurrencyMigrationReport {
  const AccountCurrencyMigrationReport({
    required this.totalJournalLines,
    required this.linesWithMissingCurrency,
    required this.distinctCurrenciesUsed,
  });

  final int totalJournalLines;
  final int linesWithMissingCurrency;
  final List<String> distinctCurrenciesUsed;

  bool get isMigrationClean => linesWithMissingCurrency == 0;
}

class AccountCurrencyMigration {
  AccountCurrencyMigration(this._db);

  final AccountingDatabase _db;

  /// Audits all historical journal lines for missing or unassigned currency codes.
  /// Rule: Unknown historical currency must NEVER be guessed or silently defaulted.
  Future<AccountCurrencyMigrationReport> auditHistoricalJournalLines({
    String? companyId,
  }) async {
    final sqlAll =
        '''
      SELECT jl.id, jl.currency_code
      FROM journal_lines jl
      INNER JOIN journal_entries je ON je.uuid = jl.entry_uuid
      ${companyId != null && companyId.trim().isNotEmpty ? "WHERE je.company_id = '$companyId'" : ""}
    ''';

    final rows = await _db
        .customSelect(sqlAll, readsFrom: {_db.journalLines, _db.journalEntries})
        .get();

    int total = rows.length;
    int missing = 0;
    final currencies = <String>{};

    for (final row in rows) {
      final code = row.read<String>('currency_code').trim().toUpperCase();
      if (code.isEmpty) {
        missing++;
      } else {
        currencies.add(code);
      }
    }

    return AccountCurrencyMigrationReport(
      totalJournalLines: total,
      linesWithMissingCurrency: missing,
      distinctCurrenciesUsed: currencies.toList()..sort(),
    );
  }

  /// Migrates lines with missing currency ONLY when an explicit target currency is provided.
  Future<int> migrateMissingCurrencyLines({
    required String explicitTargetCurrencyCode,
    String? companyId,
  }) async {
    final targetCode = explicitTargetCurrencyCode.trim().toUpperCase();
    if (targetCode.isEmpty) {
      throw const CurrencyRequiredException(
        'Migration failed: An explicit target currency code is required. Historical currency cannot be guessed.',
      );
    }

    final sqlSelect =
        '''
      SELECT jl.id
      FROM journal_lines jl
      INNER JOIN journal_entries je ON je.uuid = jl.entry_uuid
      WHERE (jl.currency_code IS NULL OR jl.currency_code = '' OR TRIM(jl.currency_code) = '')
      ${companyId != null && companyId.trim().isNotEmpty ? "AND je.company_id = '$companyId'" : ""}
    ''';

    final unassignedRows = await _db
        .customSelect(
          sqlSelect,
          readsFrom: {_db.journalLines, _db.journalEntries},
        )
        .get();
    if (unassignedRows.isEmpty) {
      return 0;
    }

    final idsToUpdate = unassignedRows.map((r) => r.read<int>('id')).toList();

    await _db.transaction(() async {
      await customUpdate(
        'UPDATE journal_lines SET currency_code = ? WHERE id IN (${idsToUpdate.join(",")})',
        variables: [targetCode],
      );
    });

    return idsToUpdate.length;
  }

  Future<void> customUpdate(
    String sql, {
    List<Object?> variables = const [],
  }) async {
    await _db.customUpdate(
      sql,
      variables: variables
          .map((v) => Variable.withString(v.toString()))
          .toList(),
      updates: {_db.journalLines},
    );
  }
}
