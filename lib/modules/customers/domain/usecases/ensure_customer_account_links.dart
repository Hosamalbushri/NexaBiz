import '../entities/customer.dart';
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
    final linked = await _linkPort.ensurePostingUnderParent(
      parentId: parentId,
      accountCode: draft.customerCode,
      name: draft.name,
    );
    if (linked == null) {
      return draft;
    }
    return draft.copyWith(accountId: linked.accountId);
  }

  Future<List<CustomerDraft>> applyAll(
    List<CustomerDraft> drafts, {
    required String parentId,
  }) async {
    final out = <CustomerDraft>[];
    for (final draft in drafts) {
      out.add(await apply(draft, parentId: parentId));
    }
    return out;
  }
}
