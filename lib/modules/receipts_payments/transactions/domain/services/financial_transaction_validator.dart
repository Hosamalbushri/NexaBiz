import 'package:stock_count/core/errors/invalid_exchange_rate_exception.dart';
import '../entities/financial_transaction.dart';
import '../entities/financial_transaction_line.dart';
import '../entities/transaction_source.dart';
import '../entities/transaction_type.dart';
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
    final currency = draft.currencyCode.trim().toUpperCase();
    final baseCurrency = draft.baseCurrencyCode.trim().toUpperCase();
    if (currency.isEmpty) {
      throw const FinancialTransactionException(
        FinancialTransactionException.currencyRequired,
      );
    }

    // Validate header exchange rate
    if (currency != baseCurrency && baseCurrency.isNotEmpty) {
      if (draft.exchangeRate <= 0 ||
          draft.exchangeRate.isNaN ||
          draft.exchangeRate.isInfinite) {
        throw const FinancialTransactionException(
          FinancialTransactionException.currencyRequired,
        );
      }
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

    if (draft.transactionType.isTransfer) {
      if (lines.length != 1) {
        throw const FinancialTransactionException(
          FinancialTransactionException.counterAccountRequired,
        );
      }
      final toId = lines.first.accountId.trim();
      if (toId.isEmpty) {
        throw const FinancialTransactionException(
          FinancialTransactionException.counterAccountRequired,
        );
      }
      if (toId == cashId) {
        throw const FinancialTransactionException(
          FinancialTransactionException.sameAccounts,
        );
      }
      if (lines.first.amount <= 0) {
        throw const FinancialTransactionException(
          FinancialTransactionException.counterAmountMustBePositive,
        );
      }
      final lineCurrency = lines.first.currencyCode.trim().toUpperCase();
      if (lineCurrency.isEmpty) {
        throw const FinancialTransactionException(
          FinancialTransactionException.currencyRequired,
        );
      }
      if (lineCurrency != currency) {
        throw const FinancialTransactionException(
          FinancialTransactionException.unbalanced,
        );
      }
      if ((RpMoney.round(draft.amount) - RpMoney.round(lines.first.amount))
              .abs() >=
          0.005) {
        throw const FinancialTransactionException(
          FinancialTransactionException.unbalanced,
        );
      }
      return;
    }

    if (draft.transactionType.isCurrencyExchange) {
      if (lines.length != 1) {
        throw const FinancialTransactionException(
          FinancialTransactionException.counterAccountRequired,
        );
      }
      final toId = lines.first.accountId.trim();
      if (toId.isEmpty || toId != cashId) {
        throw const FinancialTransactionException(
          FinancialTransactionException.cashAccountRequired,
        );
      }
      final toCurrency = lines.first.currencyCode.trim().toUpperCase();
      if (toCurrency.isEmpty) {
        throw const FinancialTransactionException(
          FinancialTransactionException.currencyRequired,
        );
      }
      if (toCurrency == currency) {
        throw const FinancialTransactionException(
          FinancialTransactionException.currenciesMustDiffer,
        );
      }
      if (lines.first.amount <= 0) {
        throw const FinancialTransactionException(
          FinancialTransactionException.counterAmountMustBePositive,
        );
      }
      final fromRate = currency == baseCurrency
          ? 1.0
          : ExchangeRateValidator.validate(
              currencyCode: currency,
              baseCurrencyCode: baseCurrency,
              exchangeRate: draft.exchangeRate,
            );
      final toRate = toCurrency == baseCurrency
          ? 1.0
          : ExchangeRateValidator.validate(
              currencyCode: toCurrency,
              baseCurrencyCode: baseCurrency,
              exchangeRate: lines.first.exchangeRate,
            );
      if (fromRate <= 0 || toRate <= 0) {
        throw const FinancialTransactionException(
          FinancialTransactionException.unbalanced,
        );
      }
      return;
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
      final lineCurrency = line.currencyCode.trim().toUpperCase();
      if (lineCurrency.isEmpty) {
        throw const FinancialTransactionException(
          FinancialTransactionException.currencyRequired,
        );
      }
      if (lineCurrency != baseCurrency && baseCurrency.isNotEmpty) {
        if (line.exchangeRate <= 0 ||
            line.exchangeRate.isNaN ||
            line.exchangeRate.isInfinite) {
          throw const FinancialTransactionException(
            FinancialTransactionException.currencyRequired,
          );
        }
      }
      if (accountId == cashId) {
        throw const FinancialTransactionException(
          FinancialTransactionException.sameAccounts,
        );
      }
    }

    final cashRate = currency == baseCurrency
        ? 1.0
        : ExchangeRateValidator.validate(
            currencyCode: currency,
            baseCurrencyCode: baseCurrency,
            exchangeRate: draft.exchangeRate,
          );
    final cashBase = RpMoney.round(draft.amount * cashRate);
    var counterBase = 0.0;
    for (final line in lines) {
      final lineCurrency = line.currencyCode.trim().toUpperCase();
      final rate = lineCurrency == baseCurrency
          ? 1.0
          : ExchangeRateValidator.validate(
              currencyCode: lineCurrency,
              baseCurrencyCode: baseCurrency,
              exchangeRate: line.exchangeRate > 0 ? line.exchangeRate : cashRate,
            );
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
  final baseCurrency = draft.baseCurrencyCode.trim().toUpperCase();
  final cashRate = cashCurrency == baseCurrency || baseCurrency.isEmpty
      ? 1.0
      : (draft.exchangeRate > 0 &&
              !draft.exchangeRate.isNaN &&
              !draft.exchangeRate.isInfinite
          ? draft.exchangeRate
          : 1.0);
  final rawLines = draft.resolvedLines;
  final lines = <FinancialTransactionLine>[];
  for (var i = 0; i < rawLines.length; i++) {
    final line = rawLines[i];
    final accountId = line.accountId.trim();
    if (accountId.isEmpty) continue;
    final lineCurrency = line.currencyCode.trim().isEmpty
        ? cashCurrency
        : line.currencyCode.trim().toUpperCase();
    final lineRate = lineCurrency == baseCurrency || baseCurrency.isEmpty
        ? 1.0
        : (line.exchangeRate > 0 &&
                !line.exchangeRate.isNaN &&
                !line.exchangeRate.isInfinite
            ? line.exchangeRate
            : cashRate);
    lines.add(
      FinancialTransactionLine(
        accountId: accountId,
        accountCode: line.accountCode?.trim(),
        accountName: line.accountName?.trim(),
        amount: RpMoney.round(line.amount),
        currencyCode: lineCurrency,
        exchangeRate: lineRate,
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
    baseCurrencyCode: baseCurrency,
    exchangeRate: cashRate,
    counterAmount: rollupAmount,
    counterCurrencyCode:
        (first?.currencyCode ?? draft.counterCurrencyCode).trim().toUpperCase(),
    counterExchangeRate: first?.exchangeRate ?? cashRate,
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
