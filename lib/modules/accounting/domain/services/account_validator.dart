import '../entities/account.dart';
import '../entities/account_type.dart';
import '../models/account_exception.dart';

/// Domain validation for Chart of Accounts mutations.
class AccountValidator {
  const AccountValidator();

  static final RegExp _codePattern = RegExp(r'^[A-Za-z0-9.\-]{1,32}$');

  void validateDraft(AccountDraft draft) {
    final code = draft.accountCode.trim();
    final name = draft.name.trim();
    if (code.isEmpty || !_codePattern.hasMatch(code)) {
      throw const AccountException(AccountException.invalidAccountCode);
    }
    if (name.isEmpty) {
      throw const AccountException(AccountException.invalidName);
    }
  }

  /// Ensures parent/child type consistency and hierarchy integrity.
  void validateHierarchy({
    required AccountDraft draft,
    required Account? parent,
    required Account? existing,
    required Iterable<Account> allAccounts,
  }) {
    validateDraft(draft);

    if (draft.parentId == null) {
      return;
    }

    if (parent == null || parent.isDeleted) {
      throw const AccountException(AccountException.parentDeleted);
    }
    if (!parent.isActive) {
      throw const AccountException(AccountException.parentInactive);
    }
    if (!parent.isGroup) {
      throw const AccountException(AccountException.groupRequiredForChildren);
    }
    if (parent.accountType != draft.accountType) {
      throw const AccountException(AccountException.typeMismatch);
    }

    if (existing != null) {
      if (draft.parentId == existing.uuid) {
        throw const AccountException(AccountException.circularParent);
      }
      if (_isDescendant(
        ancestorUuid: existing.uuid,
        candidateUuid: draft.parentId!,
        allAccounts: allAccounts,
      )) {
        throw const AccountException(AccountException.circularParent);
      }
    }
  }

  /// System accounts cannot change type, code, or be hard-removed.
  void assertSystemAccountEditable({
    required Account existing,
    required AccountDraft draft,
    required bool isDeactivating,
  }) {
    if (!existing.isSystemAccount) {
      return;
    }
    if (draft.accountCode.trim() != existing.accountCode) {
      throw const AccountException(AccountException.systemAccountProtected);
    }
    if (draft.accountType != existing.accountType) {
      throw const AccountException(AccountException.systemAccountProtected);
    }
    if (isDeactivating || !draft.isActive) {
      throw const AccountException(AccountException.systemAccountProtected);
    }
  }

  bool _isDescendant({
    required String ancestorUuid,
    required String candidateUuid,
    required Iterable<Account> allAccounts,
  }) {
    final byUuid = {for (final a in allAccounts) a.uuid: a};
    var current = byUuid[candidateUuid];
    while (current != null) {
      if (current.uuid == ancestorUuid) {
        return true;
      }
      final parentId = current.parentId;
      if (parentId == null) {
        return false;
      }
      current = byUuid[parentId];
    }
    return false;
  }

  /// Infers [AccountType] from parent when creating under a group.
  AccountType? inferTypeFromParent(Account? parent) => parent?.accountType;
}
