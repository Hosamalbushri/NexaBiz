import 'package:stock_count/shared/contracts/errors/currency_exception.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_currency_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_currency_balance_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/accounting/shared/domain/repositories/currency_repository.dart';

class AccountCurrencyStatement {
  const AccountCurrencyStatement({
    required this.accountUuid,
    required this.currencyCode,
    required this.openingBalance,
    required this.movements,
    required this.periodDebit,
    required this.periodCredit,
    required this.periodNet,
    required this.closingBalance,
  });

  final String accountUuid;
  final String currencyCode;
  final double openingBalance;
  final List<AccountLedgerMovement> movements;
  final double periodDebit;
  final double periodCredit;
  final double periodNet;
  final double closingBalance;
}

class AccountBalanceService {
  AccountBalanceService({
    required AccountCurrencyBalanceRepository balanceRepository,
    required JournalRepository journalRepository,
    required CurrencyRepository currencyRepository,
  }) : _balanceRepo = balanceRepository,
       _journalRepo = journalRepository,
       _currencyRepo = currencyRepository;

  final AccountCurrencyBalanceRepository _balanceRepo;
  final JournalRepository _journalRepo;
  final CurrencyRepository _currencyRepo;

  /// Retrieves multi-currency balances for an account.
  Future<AccountMultiCurrencyBalance> getAccountBalances(
    String accountUuid, {
    String? companyId,
  }) async {
    return _balanceRepo.getBalancesForAccount(
      accountUuid,
      companyId: companyId,
    );
  }

  /// Generates an account statement strictly for ONE currency.
  Future<AccountCurrencyStatement> getAccountStatementByCurrency({
    required String accountUuid,
    required String currencyCode,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted = true,
  }) async {
    final code = currencyCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw const CurrencyRequiredException(
        'Currency code is required for account statement.',
      );
    }

    final opening = fromDate == null
        ? 0.0
        : await _journalRepo.sumNetBefore(
            accountUuid: accountUuid,
            beforeDate: fromDate,
            currencyCode: code,
            isPosted: isPosted,
          );

    final movements = await _journalRepo.listMovementsForAccount(
      accountUuid: accountUuid,
      fromDate: fromDate,
      toDate: toDate,
      currencyCode: code,
      isPosted: isPosted,
    );

    double pDebit = 0.0;
    double pCredit = 0.0;

    for (final m in movements) {
      pDebit += m.debit;
      pCredit += m.credit;
    }

    final pNet = pDebit - pCredit;
    final closing = opening + pNet;

    return AccountCurrencyStatement(
      accountUuid: accountUuid,
      currencyCode: code,
      openingBalance: opening,
      movements: movements,
      periodDebit: pDebit,
      periodCredit: pCredit,
      periodNet: pNet,
      closingBalance: closing,
    );
  }

  /// Validates that a currency is active when selecting currency for NEW transactions,
  /// while ensuring historical transactions remain valid and queryable.
  Future<void> assertCurrencySelectableForTransaction(
    String currencyCode,
  ) async {
    final code = currencyCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw const CurrencyRequiredException(
        'Transaction currency code is required.',
      );
    }

    final currency = await _currencyRepo.getByCode(code);
    if (currency == null) {
      throw CurrencyValidationException(
        'Currency code "$code" is not registered in the system.',
      );
    }
    if (!currency.isActive) {
      throw CurrencyValidationException(
        'Currency "$code" is inactive and cannot be selected for new transactions.',
      );
    }
  }

  /// Enforces that raw summation across distinct currency codes is forbidden.
  static double sumBalancesSafely(List<AccountCurrencyBalance> balances) {
    if (balances.isEmpty) {
      return 0.0;
    }
    final firstCode = balances.first.currencyCode.trim().toUpperCase();
    for (final b in balances) {
      if (b.currencyCode.trim().toUpperCase() != firstCode) {
        throw const CurrencyMismatchException(
          'Attempted cross-currency summation across distinct currencies without explicit exchange rate conversion.',
        );
      }
    }
    return balances.fold(0.0, (acc, b) => acc + b.netBalance);
  }
}
