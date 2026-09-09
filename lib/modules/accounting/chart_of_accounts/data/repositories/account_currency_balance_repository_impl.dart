import 'package:drift/drift.dart';
import 'package:stock_count/core/tenancy/company_context_resolver.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_currency_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_currency_balance_repository.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';

class AccountCurrencyBalanceRepositoryImpl
    implements AccountCurrencyBalanceRepository {
  AccountCurrencyBalanceRepositoryImpl(
    this._db, {
    String Function()? readCompanyId,
  }) : _readCompanyId = readCompanyId;

  final AccountingDatabase _db;
  final String Function()? _readCompanyId;

  String _currentCompanyId(String? overrideCompanyId) {
    final explicit = overrideCompanyId?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }
    final read = _readCompanyId?.call().trim();
    if (read != null && read.isNotEmpty) {
      return read;
    }
    throw const MissingCompanyContextException(
      'AccountCurrencyBalanceRepository operation failed: missing company context.',
    );
  }

  @override
  Future<AccountMultiCurrencyBalance> getBalancesForAccount(
    String accountUuid, {
    String? companyId,
  }) async {
    final cid = _currentCompanyId(companyId);
    final uuid = accountUuid.trim();
    if (uuid.isEmpty) {
      return AccountMultiCurrencyBalance(
        accountUuid: uuid,
        balances: const {},
        companyId: cid,
      );
    }

    final sql = '''
      SELECT 
        jl.currency_code AS currency_code,
        COALESCE(SUM(jl.debit), 0.0) AS total_debit,
        COALESCE(SUM(jl.credit), 0.0) AS total_credit,
        COALESCE(SUM(jl.debit - jl.credit), 0.0) AS net_balance
      FROM journal_lines jl
      INNER JOIN journal_entries je ON je.uuid = jl.entry_uuid
      WHERE jl.account_uuid = ?
        AND je.company_id = ?
        AND je.deleted_at IS NULL
        AND je.is_posted = 1
      GROUP BY jl.currency_code
      ORDER BY jl.currency_code COLLATE NOCASE
    ''';

    final rows = await _db
        .customSelect(
          sql,
          variables: [Variable.withString(uuid), Variable.withString(cid)],
          readsFrom: {_db.journalLines, _db.journalEntries},
        )
        .get();

    final balances = <String, AccountCurrencyBalance>{};
    final now = DateTime.now().toUtc();

    for (final row in rows) {
      final code = row.read<String>('currency_code').trim().toUpperCase();
      if (code.isEmpty) continue;

      final debit = row.read<double>('total_debit');
      final credit = row.read<double>('total_credit');
      final net = row.read<double>('net_balance');

      balances[code] = AccountCurrencyBalance(
        accountUuid: uuid,
        currencyCode: code,
        totalDebit: debit,
        totalCredit: credit,
        netBalance: net,
        companyId: cid,
        updatedAt: now,
      );
    }

    return AccountMultiCurrencyBalance(
      accountUuid: uuid,
      balances: balances,
      companyId: cid,
    );
  }

  @override
  Future<AccountCurrencyBalance?> getBalanceForCurrency({
    required String accountUuid,
    required String currencyCode,
    String? companyId,
  }) async {
    final multi = await getBalancesForAccount(
      accountUuid,
      companyId: companyId,
    );
    return multi.getBalance(currencyCode);
  }

  @override
  Future<List<AccountCurrencyBalance>> getAllAccountCurrencyBalances({
    String? companyId,
    bool includeZeroBalances = false,
  }) async {
    final cid = _currentCompanyId(companyId);
    final sql = '''
      SELECT 
        jl.account_uuid AS account_uuid,
        jl.currency_code AS currency_code,
        COALESCE(SUM(jl.debit), 0.0) AS total_debit,
        COALESCE(SUM(jl.credit), 0.0) AS total_credit,
        COALESCE(SUM(jl.debit - jl.credit), 0.0) AS net_balance
      FROM journal_lines jl
      INNER JOIN journal_entries je ON je.uuid = jl.entry_uuid
      WHERE je.company_id = ?
        AND je.deleted_at IS NULL
        AND je.is_posted = 1
      GROUP BY jl.account_uuid, jl.currency_code
      ORDER BY jl.account_uuid, jl.currency_code COLLATE NOCASE
    ''';

    final rows = await _db
        .customSelect(
          sql,
          variables: [Variable.withString(cid)],
          readsFrom: {_db.journalLines, _db.journalEntries},
        )
        .get();

    final result = <AccountCurrencyBalance>[];
    final now = DateTime.now().toUtc();

    for (final row in rows) {
      final accountUuid = row.read<String>('account_uuid').trim();
      final code = row.read<String>('currency_code').trim().toUpperCase();
      final debit = row.read<double>('total_debit');
      final credit = row.read<double>('total_credit');
      final net = row.read<double>('net_balance');

      if (!includeZeroBalances &&
          debit.abs() < 0.0000001 &&
          credit.abs() < 0.0000001 &&
          net.abs() < 0.0000001) {
        continue;
      }

      result.add(
        AccountCurrencyBalance(
          accountUuid: accountUuid,
          currencyCode: code,
          totalDebit: debit,
          totalCredit: credit,
          netBalance: net,
          companyId: cid,
          updatedAt: now,
        ),
      );
    }

    return result;
  }

  @override
  Future<AccountMultiCurrencyBalance> recalculateAccountBalances(
    String accountUuid, {
    String? companyId,
  }) async {
    final cid = _currentCompanyId(companyId);
    final uuid = accountUuid.trim();
    return getBalancesForAccount(uuid, companyId: cid);
  }

  @override
  Future<List<String>> listAccountCurrencies(
    String accountUuid, {
    String? companyId,
  }) async {
    final multi = await getBalancesForAccount(
      accountUuid,
      companyId: companyId,
    );
    return multi.balances.keys.toList();
  }
}
