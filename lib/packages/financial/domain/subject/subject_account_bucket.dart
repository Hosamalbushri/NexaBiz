import '../money/decimal_money.dart';

/// Sub-ledger multi-currency bucket for an AccountingSubject under a control account.
class SubjectAccountBucket {
  final String id;
  final String companyId;
  final String subjectId;
  final String accountId;
  final String currencyCode;
  final DecimalMoney balance;

  const SubjectAccountBucket({
    required this.id,
    required this.companyId,
    required this.subjectId,
    required this.accountId,
    required this.currencyCode,
    required this.balance,
  });

  SubjectAccountBucket applyTransaction(DecimalMoney delta) {
    if (delta.currencyCode != currencyCode) {
      throw ArgumentError(
        'Bucket currency $currencyCode does not match transaction currency ${delta.currencyCode}',
      );
    }
    return SubjectAccountBucket(
      id: id,
      companyId: companyId,
      subjectId: subjectId,
      accountId: accountId,
      currencyCode: currencyCode,
      balance: balance.add(delta),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SubjectAccountBucket &&
            id == other.id &&
            companyId == other.companyId &&
            subjectId == other.subjectId &&
            accountId == other.accountId &&
            currencyCode == other.currencyCode);
  }

  @override
  int get hashCode => Object.hash(id, companyId, subjectId, accountId, currencyCode);

  @override
  String toString() => '$subjectId @ $accountId [$currencyCode]: $balance';
}
