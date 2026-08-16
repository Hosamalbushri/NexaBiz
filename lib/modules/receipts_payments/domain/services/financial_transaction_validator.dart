import '../entities/financial_transaction.dart';
import '../entities/financial_transaction_line.dart';
import '../entities/transaction_source.dart';
import '../models/financial_transaction_exception.dart';
import '../services/rp_money.dart';

/// Centralized domain validation (not in widgets).
class FinancialTransactionValidator {
  const FinancialTransactionValidator();

  void validate(FinancialTransactionDraft draft) {
    if (draft.amount <= 0) {
      throw const FinancialTransactionException(
        FinancialTransactionException.amountMustBePositive,
      );
    }
    final currency = draft.currencyCode.trim();
    if (currency.isEmpty) {
      throw const FinancialTransactionException(
        FinancialTransactionException.currencyRequired,
      );
    }
    final cashId = draft.cashAccountId.trim();
    if (cashId.isEmpty) {
      throw const FinancialTransactionException(
        FinancialTransactionException.cashAccountRequired,
      );
    }

    final lines = draft.resolvedLines;
    if (lines.isEmpty) {
      throw const FinancialTransactionException(
        FinancialTransactionException.counterAccountRequired,
      );
    }
    for (final line in lines) {
      final accountId = line.accountId.trim();
      if (accountId.isEmpty) {
        throw const FinancialTransactionException(
          FinancialTransactionException.counterAccountRequired,
        );
      }
      if (line.amount <= 0) {
        throw const FinancialTransactionException(
          FinancialTransactionException.counterAmountMustBePositive,
        );
      }
      if (line.currencyCode.trim().isEmpty) {
        throw const FinancialTransactionException(
          FinancialTransactionException.currencyRequired,
        );
      }
      if (accountId == cashId) {
        throw const FinancialTransactionException(
          FinancialTransactionException.sameAccounts,
        );
      }
    }

    final cashRate = draft.exchangeRate <= 0 ? 1.0 : draft.exchangeRate;
    final cashBase = RpMoney.round(draft.amount * cashRate);
    var counterBase = 0.0;
    for (final line in lines) {
      final rate = line.exchangeRate <= 0 ? cashRate : line.exchangeRate;
      counterBase += line.amount * rate;
    }
    counterBase = RpMoney.round(counterBase);
    if ((cashBase - counterBase).abs() >= 0.005) {
      throw const FinancialTransactionException(
        FinancialTransactionException.unbalanced,
      );
    }

    if (draft.source.requiresCustomer) {
      final customerId = draft.customerId?.trim() ?? '';
      if (customerId.isEmpty) {
        throw const FinancialTransactionException(
          FinancialTransactionException.customerRequired,
        );
      }
    }
  }
}

/// Normalize draft lines + header rollup fields before persist.
FinancialTransactionDraft normalizeFinancialTransactionDraft(
  FinancialTransactionDraft draft,
) {
  final cashCurrency = draft.currencyCode.trim().toUpperCase();
  final cashRate = draft.exchangeRate <= 0 ? 1.0 : draft.exchangeRate;
  final rawLines = draft.resolvedLines;
  final lines = <FinancialTransactionLine>[];
  for (var i = 0; i < rawLines.length; i++) {
    final line = rawLines[i];
    final accountId = line.accountId.trim();
    if (accountId.isEmpty) continue;
    lines.add(
      FinancialTransactionLine(
        accountId: accountId,
        accountCode: line.accountCode?.trim(),
        accountName: line.accountName?.trim(),
        amount: RpMoney.round(line.amount),
        currencyCode: line.currencyCode.trim().isEmpty
            ? cashCurrency
            : line.currencyCode.trim().toUpperCase(),
        exchangeRate: line.exchangeRate <= 0 ? cashRate : line.exchangeRate,
        description: line.description?.trim(),
        lineOrder: i,
      ),
    );
  }
  final first = lines.isNotEmpty ? lines.first : null;
  final rollupAmount = lines.isEmpty
      ? RpMoney.round(draft.counterAmount > 0 ? draft.counterAmount : draft.amount)
      : RpMoney.round(lines.fold<double>(0, (sum, line) => sum + line.amount));

  return FinancialTransactionDraft(
    transactionType: draft.transactionType,
    source: draft.source,
    transactionDate: draft.transactionDate,
    amount: RpMoney.round(draft.amount),
    currencyCode: cashCurrency,
    baseCurrencyCode: draft.baseCurrencyCode.trim().toUpperCase(),
    exchangeRate: cashRate,
    counterAmount: rollupAmount,
    counterCurrencyCode:
        (first?.currencyCode ?? draft.counterCurrencyCode).trim().toUpperCase(),
    counterExchangeRate: first?.exchangeRate ??
        (draft.counterExchangeRate <= 0 ? cashRate : draft.counterExchangeRate),
    voucherBookId: draft.voucherBookId,
    cashAccountId: draft.cashAccountId.trim(),
    cashAccountCode: draft.cashAccountCode?.trim(),
    cashAccountName: draft.cashAccountName?.trim(),
    counterAccountId: first?.accountId ?? draft.counterAccountId.trim(),
    counterAccountCode: first?.accountCode ?? draft.counterAccountCode?.trim(),
    counterAccountName: first?.accountName ?? draft.counterAccountName?.trim(),
    customerId: draft.customerId?.trim(),
    customerCode: draft.customerCode?.trim(),
    customerName: draft.customerName?.trim(),
    partyName: draft.partyName?.trim(),
    reference: draft.reference?.trim(),
    description: draft.description?.trim(),
    paymentMethod: draft.paymentMethod,
    relatedDocumentId: draft.relatedDocumentId?.trim(),
    relatedDocumentType: draft.relatedDocumentType?.trim(),
    documentStatus: draft.documentStatus,
    externalId: draft.externalId,
    lines: lines,
  );
}
