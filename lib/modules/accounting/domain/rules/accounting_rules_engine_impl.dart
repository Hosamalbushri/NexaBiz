import '../../../../core/domain/entities/account_role.dart';
import '../foundation/accounting_effect.dart';
import '../foundation/accounting_transaction_context.dart';
import '../policy/accounting_policy_port.dart';
import '../resolvers/authoritative_account_resolver_port.dart';
import 'accounting_rules_engine_port.dart';
import 'accounting_transaction_intent.dart';

/// Concrete implementation of [AccountingRulesEnginePort].
class AccountingRulesEngine implements AccountingRulesEnginePort {
  AccountingRulesEngine({
    required this._accountResolver,
    required this._policyPort,
  });

  final AuthoritativeAccountResolverPort _accountResolver;
  final AccountingPolicyPort _policyPort;

  @override
  Future<AccountingEffect?> deriveAccountingEffect(
    AccountingBusinessTransaction transaction,
  ) async {
    // Check accounting policy & optionality
    final decision = await _policyPort.evaluatePostingPermission(
      companyId: transaction.companyId,
      transactionDate: transaction.transactionDate,
      currencyCode: transaction.currencyCode,
      baseCurrencyCode: transaction.baseCurrencyCode,
    );

    // Optional accounting: if disabled / not configured, signal clean skip (no fake journals)
    if (decision.isSkippedBecauseDisabled || !decision.isAllowed) {
      return null;
    }

    final context = AccountingTransactionContext(
      companyId: transaction.companyId,
      sourceReference: transaction.sourceReference,
      transactionDate: transaction.transactionDate,
      currencyCode: transaction.currencyCode,
      baseCurrencyCode: transaction.baseCurrencyCode,
      exchangeRate: transaction.exchangeRate,
    );

    final lines = <AccountingEffectLine>[];
    final voucherType = transaction.voucherType ?? _defaultVoucherType(transaction.transactionType);
    final voucherNumber = transaction.voucherNumber ?? transaction.sourceReference.sourceId;
    final description = transaction.description ?? voucherType;

    switch (transaction.transactionType) {
      case AccountingTransactionType.saleCash:
        final cashAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.cash,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final revAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.revenue,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: cashAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: revAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.saleCredit:
        final arAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.receivable,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final revAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.revenue,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: arAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: revAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.saleReturn:
        final revAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.revenue,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final arAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.receivable,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: revAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: 'مردود $description',
        ));
        lines.add(AccountingEffectLine(
          accountUuid: arAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: 'مردود $description',
        ));
        break;

      case AccountingTransactionType.purchaseCash:
        final invAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.inventory,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final cashAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.cash,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: invAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: cashAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.purchaseCredit:
        final invAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.inventory,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final apAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.payable,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: invAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: apAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.purchaseReturn:
        final apAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.payable,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final invAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.inventory,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: apAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: 'مردود مشتريات $description',
        ));
        lines.add(AccountingEffectLine(
          accountUuid: invAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: 'مردود مشتريات $description',
        ));
        break;

      case AccountingTransactionType.stockReceipt:
        final invAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.inventory,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final equityAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.openingEquity,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: invAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: equityAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.stockIssue:
        final cogsAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.cogs,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final invAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.inventory,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: cogsAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: invAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.stockTransfer:
        final toAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.inventoryTo,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final fromAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.inventoryFrom,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: toAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: fromAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.stockAdjustment:
        final adjAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.adjustment,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final invAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.inventory,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: adjAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: invAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.customerReceipt:
        final cashAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.cash,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final arAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.receivable,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: cashAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: arAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.customerPayment:
        final arAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.receivable,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final cashAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.cash,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: arAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: cashAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.supplierPayment:
        final apAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.payable,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final cashAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.cash,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: apAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: cashAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.cashTransfer:
        final toAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.cash,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final fromAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.cash,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: toAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: fromAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.bankTransfer:
        final toAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.bank,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final fromAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.bank,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: toAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: fromAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.expense:
        final expAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.cogs,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final cashAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.cash,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: expAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: cashAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.income:
        final cashAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.cash,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final revAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.revenue,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: cashAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: revAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.tax:
        final taxInput = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.taxInput,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final taxOutput = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.tax,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: taxInput.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: taxOutput.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.fxGain:
        final cashAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.cash,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final fxAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.fxGainLoss,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: cashAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: fxAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.fxLoss:
        final fxAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.fxGainLoss,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final cashAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.cash,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: fxAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: cashAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;

      case AccountingTransactionType.openingBalance:
        final assetAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.inventory,
          overrideAccountUuid: transaction.customDebitAccountUuid,
        );
        final equityAcc = await _accountResolver.resolveAccount(
          companyId: transaction.companyId,
          role: AccountRole.openingEquity,
          overrideAccountUuid: transaction.customCreditAccountUuid,
        );

        lines.add(AccountingEffectLine(
          accountUuid: assetAcc.id,
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        lines.add(AccountingEffectLine(
          accountUuid: equityAcc.id,
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
          lineDescription: description,
        ));
        break;
    }

    return AccountingEffect(
      context: context,
      voucherNumber: voucherNumber,
      voucherType: voucherType,
      lines: lines,
    );
  }

  String _defaultVoucherType(AccountingTransactionType type) {
    switch (type) {
      case AccountingTransactionType.saleCash:
        return 'بيع نقدي';
      case AccountingTransactionType.saleCredit:
        return 'بيع آجل';
      case AccountingTransactionType.saleReturn:
        return 'مردود مبيعات';
      case AccountingTransactionType.purchaseCash:
        return 'شراء نقدي';
      case AccountingTransactionType.purchaseCredit:
        return 'شراء آجل';
      case AccountingTransactionType.purchaseReturn:
        return 'مردود مشتريات';
      case AccountingTransactionType.stockReceipt:
        return 'سند استلام مخزني';
      case AccountingTransactionType.stockIssue:
        return 'سند صرف مخزني';
      case AccountingTransactionType.stockTransfer:
        return 'تحويل مخزني';
      case AccountingTransactionType.stockAdjustment:
        return 'تسوية مخزنية';
      case AccountingTransactionType.customerReceipt:
        return 'سند قبض عميل';
      case AccountingTransactionType.customerPayment:
        return 'سند صرف عميل';
      case AccountingTransactionType.supplierPayment:
        return 'سند صرف مورد';
      case AccountingTransactionType.cashTransfer:
        return 'تحويل صندوق';
      case AccountingTransactionType.bankTransfer:
        return 'تحويل بنكي';
      case AccountingTransactionType.expense:
        return 'سند مصروفات';
      case AccountingTransactionType.income:
        return 'سند إيرادات';
      case AccountingTransactionType.tax:
        return 'تسوية ضريبية';
      case AccountingTransactionType.fxGain:
        return 'أرباح فروق عملة';
      case AccountingTransactionType.fxLoss:
        return 'خسائر فروق عملة';
      case AccountingTransactionType.openingBalance:
        return 'رصيد افتتاحي';
    }
  }
}
