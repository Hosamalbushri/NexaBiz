import '../entities/account.dart';
import 'account_labels.dart';

/// Posting accounts under the Chart of Accounts **Cash Boxes** group.
///
/// Includes system cash/bank/petty cash and any user-created children
/// (e.g. codes like `12100001` under parent `1210`).
class CashBoxAccounts {
  const CashBoxAccounts._();

  static const systemKey = 'cash_boxes';

  /// Returns posting accounts whose parent chain reaches the cash-boxes group.

  static List<Account> postingUnderCashBoxes(List<Account> all) {
    final root = _findCashBoxesRoot(all);
    if (root == null) {
      return const [];
    }

    final byId = <String, Account>{
      for (final account in all) account.id: account,
    };
    final rootId = root.id;

    final matches = all.where((account) {
      if (!account.canPost) {
        return false;
      }
      return _isDescendantOf(account, rootId: rootId, byId: byId);
    }).toList();

    matches.sort((a, b) => a.accountCode.compareTo(b.accountCode));
    return matches;
  }

  static bool isCashBoxPosting(Account account, List<Account> all) {
    if (!account.canPost) {
      return false;
    }
    final root = _findCashBoxesRoot(all);
    if (root == null) {
      return false;
    }
    final byId = <String, Account>{for (final item in all) item.id: item};
    return _isDescendantOf(account, rootId: root.id, byId: byId);
  }

  static Account? _findCashBoxesRoot(List<Account> all) {
    for (final account in all) {
      if (AccountLabels.systemKeyOf(account) == systemKey) {
        return account;
      }
    }
    return null;
  }

  static bool _isDescendantOf(
    Account account, {
    required String rootId,
    required Map<String, Account> byId,
  }) {
    var parentId = account.parentId;
    var guard = 0;
    while (parentId != null && guard++ < 64) {
      if (parentId == rootId) {
        return true;
      }
      parentId = byId[parentId]?.parentId;
    }
    return false;
  }
}
