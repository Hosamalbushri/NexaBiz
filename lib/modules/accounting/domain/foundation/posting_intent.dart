import 'package:equatable/equatable.dart';
import 'package:stock_count/modules/accounting/domain/rules/determination_context.dart';
import 'posting_template.dart';

sealed class PostingIntent extends Equatable {
  const PostingIntent({
    required this.companyId,
    required this.sourceType,
    required this.sourceId,
    required this.transactionDate,
    required this.currencyCode,
  });

  final String companyId;
  final String sourceType;
  final String sourceId;
  final DateTime transactionDate;
  final String currencyCode;
}

class DeterminedAccountPostingIntent extends PostingIntent {
  const DeterminedAccountPostingIntent({
    required super.companyId,
    required super.sourceType,
    required super.sourceId,
    required super.transactionDate,
    required super.currencyCode,
    required this.context,
    required this.template,
    required this.amountsByRoleKey,
    this.baseCurrencyCode,
    this.exchangeRate,
    this.description,
  });

  final DeterminationContext context;
  final PostingTemplate template;
  final Map<String, double> amountsByRoleKey;
  final String? baseCurrencyCode;
  final double? exchangeRate;
  final String? description;

  @override
  List<Object?> get props => [
        companyId,
        sourceType,
        sourceId,
        transactionDate,
        currencyCode,
        context,
        template,
        amountsByRoleKey,
        baseCurrencyCode,
        exchangeRate,
        description,
      ];
}

class ExplicitAccountLineDraft extends Equatable {
  const ExplicitAccountLineDraft({
    required this.accountUuid,
    required this.debit,
    required this.credit,
    this.lineDescription,
    this.sortOrder = 0,
  });

  final String accountUuid;
  final double debit;
  final double credit;
  final String? lineDescription;
  final int sortOrder;

  @override
  List<Object?> get props => [
        accountUuid,
        debit,
        credit,
        lineDescription,
        sortOrder,
      ];
}

class ExplicitAccountPostingIntent extends PostingIntent {
  const ExplicitAccountPostingIntent({
    required super.companyId,
    required super.sourceType,
    required super.sourceId,
    required super.transactionDate,
    required super.currencyCode,
    required this.lines,
    required this.voucherNumber,
    required this.voucherType,
    this.baseCurrencyCode,
    this.exchangeRate,
    this.description,
  });

  final List<ExplicitAccountLineDraft> lines;
  final String voucherNumber;
  final String voucherType;
  final String? baseCurrencyCode;
  final double? exchangeRate;
  final String? description;

  @override
  List<Object?> get props => [
        companyId,
        sourceType,
        sourceId,
        transactionDate,
        currencyCode,
        lines,
        voucherNumber,
        voucherType,
        baseCurrencyCode,
        exchangeRate,
        description,
      ];
}
