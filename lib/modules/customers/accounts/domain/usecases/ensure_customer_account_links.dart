import 'package:stock_count/modules/customers/directory/domain/entities/customer.dart';
import '../services/customer_account_link_port.dart';

/// Fills missing [CustomerDraft.accountId] via [CustomerAccountLinkPort].
class EnsureCustomerAccountLinks {
  const EnsureCustomerAccountLinks(this._linkPort);

  final CustomerAccountLinkPort _linkPort;

  Future<CustomerDraft> apply(
    CustomerDraft draft, {
    required String parentId,
  }) async {
    final existing = draft.accountId?.trim();
    if (existing != null && existing.isNotEmpty) {
      return draft;
    }
    try {
      final linked = await _linkPort.ensurePostingUnderParent(
        parentId: parentId,
        accountCode: draft.customerCode,
        name: draft.name,
      );
      if (linked == null) {
        return draft;
      }
      return draft.copyWith(accountId: linked.accountId);
    } catch (_) {
      // Import must not fail when a single CoA link cannot be created
      // (e.g. code already used under another parent).
      return draft;
    }
  }

  Future<List<CustomerDraft>> applyAll(
    List<CustomerDraft> drafts, {
    required String parentId,
    void Function(int processed, int total)? onProgress,
  }) async {
    final out = <CustomerDraft>[];
    final total = drafts.length;
    for (var i = 0; i < drafts.length; i++) {
      out.add(await apply(drafts[i], parentId: parentId));
      onProgress?.call(i + 1, total);
      if ((i + 1) % 8 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
    return out;
  }
}
