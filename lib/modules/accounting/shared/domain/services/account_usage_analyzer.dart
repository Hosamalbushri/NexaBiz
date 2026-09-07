/// Enum representing the usage state of an account in system transactions.
enum AccountUsageStatus {
  /// Account has never been referenced in any document or transaction.
  neverUsed,

  /// Account has only been referenced in unposted/draft documents.
  usedInDraftsOnly,

  /// Account has been referenced in one or more posted financial transactions.
  /// (Changing configuration bindings for accounts with this status is strictly BLOCKED).
  usedInPostedTransactions,
}

/// Detailed usage record for an account.
class AccountUsageRecord {
  const AccountUsageRecord({
    required this.accountUuid,
    required this.status,
    required this.postedTransactionCount,
    required this.draftTransactionCount,
    required this.currentBalance,
    required this.referencedDocumentTypes,
  });

  final String accountUuid;
  final AccountUsageStatus status;
  final int postedTransactionCount;
  final int draftTransactionCount;
  final double currentBalance;
  final List<String> referencedDocumentTypes;

  bool get isChangeAllowed =>
      status != AccountUsageStatus.usedInPostedTransactions;
}

/// Interface for analyzing account historical usage across all business modules.
abstract class AccountUsageAnalyzer {
  /// Analyzes historical transaction references for [accountUuid] within [companyId].
  Future<AccountUsageRecord> analyzeAccountUsage({
    required String companyId,
    required String accountUuid,
  });
}

/// In-memory / Default implementation of [AccountUsageAnalyzer].
class AccountUsageAnalyzerImpl implements AccountUsageAnalyzer {
  AccountUsageAnalyzerImpl({this.postedJournalLinesPort});

  final dynamic postedJournalLinesPort;
  final Map<String, List<Map<String, dynamic>>> _recordedTransactions = {};

  /// Registers a transaction for testing / local tracking.
  void recordTransaction({
    required String accountUuid,
    required bool isPosted,
    required String documentType,
    required double amount,
  }) {
    final list = _recordedTransactions.putIfAbsent(accountUuid, () => []);
    list.add({
      'isPosted': isPosted,
      'documentType': documentType,
      'amount': amount,
    });
  }

  @override
  Future<AccountUsageRecord> analyzeAccountUsage({
    required String companyId,
    required String accountUuid,
  }) async {
    final records = _recordedTransactions[accountUuid] ?? [];

    int postedCount = 0;
    int draftCount = 0;
    double netBalance = 0.0;
    final Set<String> docTypes = {};

    for (final rec in records) {
      final isPosted = rec['isPosted'] as bool? ?? false;
      final docType = rec['documentType'] as String? ?? 'unknown';
      final amount = (rec['amount'] as num?)?.toDouble() ?? 0.0;

      docTypes.add(docType);
      if (isPosted) {
        postedCount++;
        netBalance += amount;
      } else {
        draftCount++;
      }
    }

    AccountUsageStatus status;
    if (postedCount > 0) {
      status = AccountUsageStatus.usedInPostedTransactions;
    } else if (draftCount > 0) {
      status = AccountUsageStatus.usedInDraftsOnly;
    } else {
      status = AccountUsageStatus.neverUsed;
    }

    return AccountUsageRecord(
      accountUuid: accountUuid,
      status: status,
      postedTransactionCount: postedCount,
      draftTransactionCount: draftCount,
      currentBalance: netBalance,
      referencedDocumentTypes: docTypes.toList(),
    );
  }
}
