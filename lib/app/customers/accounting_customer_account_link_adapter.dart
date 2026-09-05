import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/models/account_exception.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_scope_resolver.dart';
import 'package:stock_count/modules/customers/accounts/domain/services/customer_account_link_port.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

/// App-layer bridge: Customers → Accounting accounts with strict scope gating.
class AccountingCustomerAccountLinkAdapter implements CustomerAccountLinkPort {
  const AccountingCustomerAccountLinkAdapter(
    this._accounts, {
    this.initRepository,
  });

  final AccountRepository _accounts;
  final CompanyInitializationRepository? initRepository;

  LinkedAccountRef? _map(
    Account? account, {
    required bool requirePosting,
    required bool requireGroup,
  }) {
    if (account == null || account.isDeleted || !account.isActive) {
      return null;
    }
    if (requirePosting && !account.canPost) {
      return null;
    }
    if (requireGroup && !account.isGroup) {
      return null;
    }
    return LinkedAccountRef(
      accountId: account.uuid,
      code: account.accountCode,
      name: account.name,
      isPosting: account.isPostingAccount,
      isGroup: account.isGroup,
    );
  }

  Future<AccountingScopeResult> _resolveReceivableScope() async {
    final state = await initRepository?.getState();
    final companyId = state?.companyId ?? '';
    final resolver = AccountingScopeResolver(
      accountRepository: _accounts,
      initRepository: initRepository,
    );
    return resolver.resolveScope(
      companyId: companyId,
      role: AccountRole.receivable,
    );
  }

  @override
  Future<LinkedAccountRef?> findById(String accountId) async {
    final trimmed = accountId.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final scope = await _resolveReceivableScope();
    if (!scope.isReady) {
      return null;
    }
    final account = await _accounts.getByUuid(trimmed);
    if (account == null) return null;

    final parentAccount = scope.parentAccount;
    final isScoped = scope.accounts.any((a) => a.uuid == account.uuid) ||
        (parentAccount != null && parentAccount.uuid == account.uuid);
    if (!isScoped) {
      return null;
    }
    return _map(account, requirePosting: false, requireGroup: false);
  }

  @override
  Future<LinkedAccountRef?> resolve(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final scope = await _resolveReceivableScope();
    if (!scope.isReady) {
      return null;
    }

    var account = await _accounts.getByUuid(trimmed);
    account ??= await _accounts.getByAccountCode(trimmed);
    if (account == null) return null;
    final nonNullAccount = account;
    final isScoped = scope.accounts.any((a) => a.uuid == nonNullAccount.uuid);
    if (!isScoped) {
      return null;
    }
    return _map(account, requirePosting: true, requireGroup: false);
  }

  @override
  Future<List<LinkedAccountRef>> search(String query, {int limit = 20}) async {
    final scope = await _resolveReceivableScope();
    if (!scope.isReady) {
      return const [];
    }

    final normalized = query.trim().toLowerCase();
    final scopedAccounts = scope.accounts;
    final matched = normalized.isEmpty
        ? scopedAccounts
        : scopedAccounts
            .where(
              (a) =>
                  a.accountCode.toLowerCase().contains(normalized) ||
                  a.name.toLowerCase().contains(normalized),
            )
            .toList();

    return matched
        .take(limit)
        .map(
          (a) => LinkedAccountRef(
            accountId: a.uuid,
            code: a.accountCode,
            name: a.name,
            isPosting: true,
            isGroup: false,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<LinkedAccountRef?> findSystemCustomersParent() async {
    final scope = await _resolveReceivableScope();
    if (!scope.isReady || scope.parentAccount == null) {
      return null;
    }
    return _map(scope.parentAccount, requirePosting: false, requireGroup: true);
  }

  @override
  Future<LinkedAccountRef?> resolveParent(String input) async {
    final scope = await _resolveReceivableScope();
    final parentAccount = scope.parentAccount;
    if (!scope.isReady || parentAccount == null) {
      return null;
    }
    final trimmed = input.trim();
    if (trimmed == parentAccount.uuid || trimmed == parentAccount.accountCode) {
      return _map(parentAccount, requirePosting: false, requireGroup: true);
    }
    return null;
  }

  @override
  Future<List<LinkedAccountRef>> searchParentCandidates(
    String query, {
    int limit = 20,
  }) async {
    final parentRef = await findSystemCustomersParent();
    if (parentRef == null) {
      return const [];
    }
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty ||
        parentRef.code.toLowerCase().contains(normalized) ||
        parentRef.name.toLowerCase().contains(normalized)) {
      return [parentRef];
    }
    return const [];
  }

  @override
  Future<bool> isUnderParent({
    required String accountId,
    required String parentId,
  }) async {
    if (accountId == parentId) {
      return true;
    }
    var current = await _accounts.getByUuid(accountId);
    var guard = 0;
    while (current != null && guard < 64) {
      final parent = current.parentId;
      if (parent == null) {
        return false;
      }
      if (parent == parentId) {
        return true;
      }
      current = await _accounts.getByUuid(parent);
      guard++;
    }
    return false;
  }

  @override
  Future<LinkedAccountRef?> ensurePostingUnderParent({
    required String parentId,
    required String accountCode,
    required String name,
  }) async {
    final scope = await _resolveReceivableScope();
    final parentAccount = scope.parentAccount;
    if (!scope.isReady || parentAccount == null) {
      return null;
    }
    if (parentId.trim() != parentAccount.uuid) {
      return null;
    }

    final code = accountCode.trim();
    final displayName = name.trim();
    final parentUuid = parentId.trim();
    if (code.isEmpty || displayName.isEmpty || parentUuid.isEmpty) {
      return null;
    }

    final parent = await _accounts.getByUuid(parentUuid);
    final parentRef = _map(parent, requirePosting: false, requireGroup: true);
    if (parentRef == null || parent == null) {
      return null;
    }

    final existing = await _accounts.getByAccountCode(code);
    if (existing != null && !existing.isDeleted) {
      final underParent = await isUnderParent(
        accountId: existing.uuid,
        parentId: parentUuid,
      );
      if (underParent && existing.canPost) {
        if (existing.name != displayName) {
          await _accounts.update(
            existing.id,
            AccountDraft(
              parentId: existing.parentId,
              accountCode: existing.accountCode,
              name: displayName,
              accountType: existing.accountType,
              isGroup: false,
              isActive: existing.isActive,
              isSystemAccount: existing.isSystemAccount,
              description: existing.description,
            ),
          );
          final refreshed = await _accounts.getByUuid(existing.uuid);
          return _map(refreshed, requirePosting: true, requireGroup: false);
        }
        return _map(existing, requirePosting: true, requireGroup: false);
      }
      throw const AccountException(AccountException.duplicateAccountCode);
    }

    final created = await _accounts.insert(
      AccountDraft(
        parentId: parentUuid,
        accountCode: code,
        name: displayName,
        accountType: parent.accountType,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
      ),
    );
    return _map(created, requirePosting: true, requireGroup: false);
  }

  @override
  Future<List<LinkedAccountRef>> listUnderParent(String parentId) async {
    final scope = await _resolveReceivableScope();
    final parentAccount = scope.parentAccount;
    if (!scope.isReady || parentAccount == null) {
      return const [];
    }
    if (parentId.trim() != parentAccount.uuid) {
      return const [];
    }

    final children = await _accounts.getChildren(parentId.trim());
    final refs = <LinkedAccountRef>[];
    for (final account in children) {
      if (account.isDeleted || !account.isActive) {
        continue;
      }
      refs.add(
        LinkedAccountRef(
          accountId: account.uuid,
          code: account.accountCode,
          name: account.name,
          isPosting: account.isPostingAccount,
          isGroup: account.isGroup,
        ),
      );
    }
    refs.sort((a, b) => a.code.compareTo(b.code));
    return refs;
  }
}
