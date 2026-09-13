import 'accounting_failure.dart';
import 'accounting_transaction_context.dart';

/// Single financial movement effect on an account (debit/credit).
class AccountingEffectLine {
  AccountingEffectLine({
    required this.accountUuid,
    required this.debit,
    required this.credit,
    required this.currencyCode,
    this.exchangeRateToBase,
    this.baseDebit,
    this.baseCredit,
    this.lineDescription,
    this.sortOrder = 0,
  }) {
    if (accountUuid.trim().isEmpty) {
      throw const InvalidAccountingEffectFailure('accountUuid cannot be empty.');
    }
    if (debit < 0 || credit < 0) {
      throw InvalidAccountingEffectFailure(
        'Debit and credit amounts cannot be negative. Got debit=$debit, credit=$credit.',
      );
    }
    if (debit == 0 && credit == 0) {
      throw const InvalidAccountingEffectFailure(
        'Accounting line must have non-zero debit or credit amount.',
      );
    }
    if (debit > 0 && credit > 0) {
      throw const InvalidAccountingEffectFailure(
        'Accounting line cannot have both non-zero debit and credit amounts.',
      );
    }
  }

  final String accountUuid;
  final double debit;
  final double credit;
  final String currencyCode;
  final double? exchangeRateToBase;
  final double? baseDebit;
  final double? baseCredit;
  final String? lineDescription;
  final int sortOrder;
}

/// Operational domain representation of intended financial impact prior to journal construction.
class AccountingEffect {
  AccountingEffect({
    required this.context,
    required this.voucherNumber,
    required this.voucherType,
    required this.lines,
    this.description,
  }) {
    if (voucherNumber.trim().isEmpty) {
      throw const InvalidAccountingEffectFailure('voucherNumber cannot be empty.');
    }
    if (voucherType.trim().isEmpty) {
      throw const InvalidAccountingEffectFailure('voucherType cannot be empty.');
    }
    if (lines.isEmpty) {
      throw const InvalidAccountingEffectFailure(
        'AccountingEffect must contain at least one accounting line.',
      );
    }
  }

  final AccountingTransactionContext context;
  final String voucherNumber;
  final String voucherType;
  final String? description;
  final List<AccountingEffectLine> lines;

  /// Returns total debit amount across all lines in effect currency.
  double get totalDebit =>
      lines.fold(0.0, (sum, line) => sum + line.debit);

  /// Returns total credit amount across all lines in effect currency.
  double get totalCredit =>
      lines.fold(0.0, (sum, line) => sum + line.credit);

  /// Validates raw financial balance (total debit == total credit).
  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.0001;
}
