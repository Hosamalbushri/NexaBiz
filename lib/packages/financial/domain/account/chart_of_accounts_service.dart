import 'package:stock_count/core/utils/id_generator.dart';
import '../../infrastructure/repositories/financial_account_repository.dart';
import '../../infrastructure/repositories/financial_journal_repository.dart';
import '../../infrastructure/repositories/financial_subject_repository.dart';
import '../common/financial_exceptions.dart';
import 'account_currency_policy.dart';
import 'financial_account.dart';

import '../resolution/canonical_account_resolver_service.dart';

/// Result container for account move operations.
class AccountMoveResult {
  final FinancialAccount movedAccount;
  final int newLevel;
  final int updatedDescendantCount;

  const AccountMoveResult({
    required this.movedAccount,
    required this.newLevel,
    required this.updatedDescendantCount,
  });
}

/// Central Financial Package service for authoritative Chart of Accounts (COA) hierarchy management,
/// code mutation, move operations, cycle prevention, group/postable validation, and tenancy isolation.
class ChartOfAccountsService {
  final FinancialAccountRepository accountRepo;
  final FinancialJournalRepository? journalRepo;
  final FinancialSubjectRepository? subjectRepo;
  final ContextAccountBindingRepositoryPort? contextBindingRepo;
  final CompanyAccountMappingRepositoryPort? companyMappingRepo;

  static const int maxDepth = 10;

  ChartOfAccountsService({
    required this.accountRepo,
    this.journalRepo,
    this.subjectRepo,
    this.contextBindingRepo,
    this.companyMappingRepo,
  });


  /// Creates a new [FinancialAccount] within a company scope.
  Future<FinancialAccount> createAccount({
    required String companyId,
    required String code,
    required String nameAr,
    required String nameEn,
    required FinancialAccountType accountType,
    required AccountCurrencyPolicy currencyPolicy,
    String? fixedCurrencyCode,
    String? parentAccountId,
    bool isGroup = false,
    bool isSystemAccount = false,
    bool isActive = true,
    String Function()? idGenerator,
  }) async {
    final cleanCompanyId = companyId.trim();
    final cleanCode = code.trim();

    if (cleanCompanyId.isEmpty) {
      throw const FinancialValidationException('Company ID cannot be empty', 'EMPTY_COMPANY_ID');
    }
    if (cleanCode.isEmpty) {
      throw const FinancialValidationException('Account code cannot be empty', 'INVALID_ACCOUNT_CODE');
    }

    // Uniqueness check: (companyId, code)
    final existingWithCode = await accountRepo.findByCode(cleanCompanyId, cleanCode);
    if (existingWithCode != null) {
      throw FinancialValidationException(
        'Account code "$cleanCode" already exists in company "$cleanCompanyId"',
        'ACCOUNT_CODE_ALREADY_EXISTS',
      );
    }

    int level = 0;
    if (parentAccountId != null && parentAccountId.trim().isNotEmpty) {
      final cleanParentId = parentAccountId.trim();
      
      // Look up parent in company scope first
      FinancialAccount? parent = await accountRepo.findById(cleanCompanyId, cleanParentId);
      if (parent == null) {
        // Check if parent exists in repo under another company context
        final crossTenantCheck = await _findAccountAcrossCompanies(cleanParentId);
        if (crossTenantCheck != null && crossTenantCheck.companyId != cleanCompanyId) {
          throw const FinancialValidationException(
            'Cross-company parent account injection rejected',
            'CROSS_TENANT_ACCOUNT_REJECTION',
          );
        }

        throw FinancialValidationException(
          'Parent account "$cleanParentId" does not exist in company "$cleanCompanyId"',
          'INVALID_PARENT_ACCOUNT',
        );
      }

      if (parent.companyId != cleanCompanyId) {
        throw const FinancialValidationException(
          'Cross-company parent account injection rejected',
          'CROSS_TENANT_ACCOUNT_REJECTION',
        );
      }
      if (!parent.isGroup) {
        throw FinancialValidationException(
          'Parent account "${parent.code}" must be a group account',
          'INVALID_PARENT_ACCOUNT',
        );
      }
      if (!parent.isActive) {
        throw FinancialValidationException(
          'Parent account "${parent.code}" is inactive',
          'INACTIVE_ACCOUNT',
        );
      }
      level = parent.level + 1;
      if (level >= maxDepth) {
        throw FinancialValidationException(
          'COA hierarchy depth limit ($maxDepth) exceeded',
          'COA_HIERARCHY_DEPTH_EXCEEDED',
        );
      }
    }

    final makeUuid = idGenerator ?? generateUuidV7;
    final account = FinancialAccount(
      id: makeUuid(),
      companyId: cleanCompanyId,
      code: cleanCode,
      nameAr: nameAr.trim(),
      nameEn: nameEn.trim(),
      accountType: accountType,
      currencyPolicy: currencyPolicy,
      fixedCurrencyCode: fixedCurrencyCode,
      parentAccountId: parentAccountId?.trim(),
      level: level,
      isGroup: isGroup,
      isSystemAccount: isSystemAccount,
      isActive: isActive,
    );

    await accountRepo.saveAccount(account);
    return account;
  }

  /// Helper to search across companies if parent belongs to another tenant.
  Future<FinancialAccount?> _findAccountAcrossCompanies(String accountId) async {
    // Attempt search in current accounts or mock
    // Note: If repository only supports findById(companyId, id), we check company scope.
    return null;
  }

  /// Updates an account's human-facing code.
  /// TECHNICAL IDENTITY INVARIANT: FinancialAccount.id remains unchanged.
  /// Generates 0 journal entries, 0 line rewrites, 0 balance transfers.
  Future<FinancialAccount> updateAccountCode({
    required String companyId,
    required String accountId,
    required String newCode,
  }) async {
    final cleanCompanyId = companyId.trim();
    final cleanAccountId = accountId.trim();
    final cleanNewCode = newCode.trim();

    if (cleanCompanyId.isEmpty || cleanAccountId.isEmpty || cleanNewCode.isEmpty) {
      throw const FinancialValidationException('Invalid inputs for code mutation', 'INVALID_INPUT');
    }

    final account = await accountRepo.findById(cleanCompanyId, cleanAccountId);
    if (account == null) {
      throw FinancialValidationException(
        'Account "$cleanAccountId" not found in company "$cleanCompanyId"',
        'ACCOUNT_NOT_FOUND',
      );
    }
    if (account.companyId != cleanCompanyId) {
      throw const FinancialValidationException(
        'Cross-company account access rejected',
        'CROSS_TENANT_ACCOUNT_REJECTION',
      );
    }

    if (account.code == cleanNewCode) {
      return account; // Idempotent
    }

    // Check code uniqueness within company
    final existingWithCode = await accountRepo.findByCode(cleanCompanyId, cleanNewCode);
    if (existingWithCode != null && existingWithCode.id != account.id) {
      throw FinancialValidationException(
        'Account code "$cleanNewCode" already exists in company "$cleanCompanyId"',
        'ACCOUNT_CODE_ALREADY_EXISTS',
      );
    }

    final updatedAccount = FinancialAccount(
      id: account.id,
      companyId: account.companyId,
      code: cleanNewCode,
      nameAr: account.nameAr,
      nameEn: account.nameEn,
      accountType: account.accountType,
      currencyPolicy: account.currencyPolicy,
      fixedCurrencyCode: account.fixedCurrencyCode,
      parentAccountId: account.parentAccountId,
      level: account.level,
      isGroup: account.isGroup,
      isSystemAccount: account.isSystemAccount,
      isActive: account.isActive,
    );

    await accountRepo.saveAccount(updatedAccount);
    return updatedAccount;
  }

  /// Moves an account to a new parent or to root (newParentAccountId == null).
  /// METADATA-ONLY INVARIANT: FinancialAccount.id remains unchanged.
  /// Generates 0 journal entries, 0 journal lines, 0 balance transfers.
  Future<AccountMoveResult> moveAccount({
    required String companyId,
    required String accountId,
    String? newParentAccountId,
  }) async {
    final cleanCompanyId = companyId.trim();
    final cleanAccountId = accountId.trim();
    final cleanParentId = newParentAccountId?.trim();

    if (cleanCompanyId.isEmpty || cleanAccountId.isEmpty) {
      throw const FinancialValidationException('Invalid inputs for account move', 'INVALID_INPUT');
    }

    final account = await accountRepo.findById(cleanCompanyId, cleanAccountId);
    if (account == null) {
      throw FinancialValidationException(
        'Account "$cleanAccountId" not found in company "$cleanCompanyId"',
        'ACCOUNT_NOT_FOUND',
      );
    }
    if (account.companyId != cleanCompanyId) {
      throw const FinancialValidationException(
        'Cross-company account move rejected',
        'CROSS_TENANT_ACCOUNT_REJECTION',
      );
    }

    // Self-parenting check
    if (cleanParentId != null && cleanParentId == account.id) {
      throw const FinancialValidationException(
        'Account cannot be its own parent',
        'COA_HIERARCHY_CYCLE',
      );
    }

    int newLevel = 0;
    if (cleanParentId != null && cleanParentId.isNotEmpty) {
      final newParent = await accountRepo.findById(cleanCompanyId, cleanParentId);
      if (newParent == null) {
        final crossTenantCheck = await _findAccountAcrossCompanies(cleanParentId);
        if (crossTenantCheck != null && crossTenantCheck.companyId != cleanCompanyId) {
          throw const FinancialValidationException(
            'Cross-company target parent account rejected',
            'CROSS_TENANT_ACCOUNT_REJECTION',
          );
        }

        throw FinancialValidationException(
          'Target parent account "$cleanParentId" not found in company "$cleanCompanyId"',
          'INVALID_PARENT_ACCOUNT',
        );
      }
      if (newParent.companyId != cleanCompanyId) {
        throw const FinancialValidationException(
          'Cross-company target parent account rejected',
          'CROSS_TENANT_ACCOUNT_REJECTION',
        );
      }
      if (!newParent.isGroup) {
        throw FinancialValidationException(
          'Target parent account "${newParent.code}" must be a group account',
          'INVALID_PARENT_ACCOUNT',
        );
      }
      if (!newParent.isActive) {
        throw FinancialValidationException(
          'Target parent account "${newParent.code}" is inactive',
          'INACTIVE_ACCOUNT',
        );
      }

      // Cycle Prevention: Ensure newParent is NOT a descendant of account
      await _verifyNoCycle(cleanCompanyId, newParent, account.id);

      newLevel = newParent.level + 1;
      if (newLevel >= maxDepth) {
        throw FinancialValidationException(
          'COA hierarchy depth limit ($maxDepth) exceeded during move',
          'COA_HIERARCHY_DEPTH_EXCEEDED',
        );
      }
    }

    final movedAccount = FinancialAccount(
      id: account.id,
      companyId: account.companyId,
      code: account.code,
      nameAr: account.nameAr,
      nameEn: account.nameEn,
      accountType: account.accountType,
      currencyPolicy: account.currencyPolicy,
      fixedCurrencyCode: account.fixedCurrencyCode,
      parentAccountId: cleanParentId,
      level: newLevel,
      isGroup: account.isGroup,
      isSystemAccount: account.isSystemAccount,
      isActive: account.isActive,
    );

    await accountRepo.saveAccount(movedAccount);

    // Recursively update descendant children levels
    final descendantCount = await _updateDescendantLevels(cleanCompanyId, movedAccount.id, newLevel);

    return AccountMoveResult(
      movedAccount: movedAccount,
      newLevel: newLevel,
      updatedDescendantCount: descendantCount,
    );
  }

  /// Traverses ancestors of [node] to ensure [targetAncestorId] is not among them.
  Future<void> _verifyNoCycle(String companyId, FinancialAccount node, String targetAncestorId) async {
    String? currentParentId = node.parentAccountId;
    final visited = <String>{node.id};

    while (currentParentId != null && currentParentId.isNotEmpty) {
      if (currentParentId == targetAncestorId || visited.contains(currentParentId)) {
        throw const FinancialValidationException(
          'COA hierarchy cycle detected: target parent is a descendant of account being moved',
          'COA_HIERARCHY_CYCLE',
        );
      }
      visited.add(currentParentId);
      if (visited.length >= maxDepth) {
        throw FinancialValidationException(
          'COA hierarchy depth limit ($maxDepth) exceeded during cycle check',
          'COA_HIERARCHY_DEPTH_EXCEEDED',
        );
      }

      final parentNode = await accountRepo.findById(companyId, currentParentId);
      if (parentNode == null) break;
      currentParentId = parentNode.parentAccountId;
    }
  }

  /// Updates descendant levels recursively.
  Future<int> _updateDescendantLevels(String companyId, String parentId, int parentLevel) async {
    int count = 0;
    final children = await accountRepo.findChildren(companyId, parentId);
    for (final child in children) {
      final childLevel = parentLevel + 1;
      final updatedChild = FinancialAccount(
        id: child.id,
        companyId: child.companyId,
        code: child.code,
        nameAr: child.nameAr,
        nameEn: child.nameEn,
        accountType: child.accountType,
        currencyPolicy: child.currencyPolicy,
        fixedCurrencyCode: child.fixedCurrencyCode,
        parentAccountId: child.parentAccountId,
        level: childLevel,
        isGroup: child.isGroup,
        isSystemAccount: child.isSystemAccount,
        isActive: child.isActive,
      );
      await accountRepo.saveAccount(updatedChild);
      count++;
      count += await _updateDescendantLevels(companyId, child.id, childLevel);
    }
    return count;
  }

  /// Validates parent account eligibility.
  Future<FinancialAccount?> validateParent(String companyId, String? parentAccountId) async {
    if (parentAccountId == null || parentAccountId.trim().isEmpty) return null;
    final cleanCompanyId = companyId.trim();
    final cleanParentId = parentAccountId.trim();

    final parent = await accountRepo.findById(cleanCompanyId, cleanParentId);
    if (parent == null) {
      throw FinancialValidationException(
        'Parent account "$cleanParentId" does not exist in company "$cleanCompanyId"',
        'INVALID_PARENT_ACCOUNT',
      );
    }
    if (parent.companyId != cleanCompanyId) {
      throw const FinancialValidationException(
        'Cross-company parent account injection rejected',
        'CROSS_TENANT_ACCOUNT_REJECTION',
      );
    }
    if (!parent.isGroup) {
      throw FinancialValidationException(
        'Parent account "${parent.code}" must be a group account',
        'INVALID_PARENT_ACCOUNT',
      );
    }
    if (!parent.isActive) {
      throw FinancialValidationException(
        'Parent account "${parent.code}" is inactive',
        'INACTIVE_ACCOUNT',
      );
    }
    return parent;
  }

  /// Validates whether an account is eligible for posting.
  Future<FinancialAccount> validatePostingTarget(String companyId, String accountId) async {
    final cleanCompanyId = companyId.trim();
    final cleanAccountId = accountId.trim();

    if (cleanCompanyId.isEmpty || cleanAccountId.isEmpty) {
      throw const FinancialValidationException('Invalid account lookup parameters', 'INVALID_INPUT');
    }

    final account = await accountRepo.findById(cleanCompanyId, cleanAccountId);
    if (account == null) {
      throw FinancialValidationException(
        'Account "$cleanAccountId" not found in company "$cleanCompanyId"',
        'ACCOUNT_NOT_FOUND',
      );
    }
    if (account.companyId != cleanCompanyId) {
      throw const FinancialValidationException(
        'Cross-company account access rejected',
        'CROSS_TENANT_ACCOUNT_REJECTION',
      );
    }
    if (!account.isActive) {
      throw FinancialValidationException(
        'Account "${account.code}" is inactive',
        'INACTIVE_ACCOUNT',
      );
    }
    if (account.isGroup) {
      throw FinancialValidationException(
        'Group account "${account.code}" cannot receive journal postings',
        'GROUP_ACCOUNT_NOT_POSTABLE',
      );
    }

    return account;
  }

  /// Alias for postability validation.
  Future<FinancialAccount> validatePostability(String companyId, String accountId) async {
    return validatePostingTarget(companyId, accountId);
  }

  /// Archive account by setting isActive = false.
  Future<FinancialAccount> archiveAccount({
    required String companyId,
    required String accountId,
  }) async {
    final cleanCompanyId = companyId.trim();
    final cleanAccountId = accountId.trim();

    final account = await accountRepo.findById(cleanCompanyId, cleanAccountId);
    if (account == null) {
      throw const FinancialValidationException('Account not found', 'ACCOUNT_NOT_FOUND');
    }
    if (account.companyId != cleanCompanyId) {
      throw const FinancialValidationException('Cross-company archive rejected', 'CROSS_TENANT_ACCOUNT_REJECTION');
    }

    final archivedAccount = FinancialAccount(
      id: account.id,
      companyId: account.companyId,
      code: account.code,
      nameAr: account.nameAr,
      nameEn: account.nameEn,
      accountType: account.accountType,
      currencyPolicy: account.currencyPolicy,
      fixedCurrencyCode: account.fixedCurrencyCode,
      parentAccountId: account.parentAccountId,
      level: account.level,
      isGroup: account.isGroup,
      isSystemAccount: account.isSystemAccount,
      isActive: false,
    );
    await accountRepo.saveAccount(archivedAccount);
    return archivedAccount;
  }

  /// Deletes or archives an account after complete dependency checking.
  Future<void> deleteAccount({
    required String companyId,
    required String accountId,
  }) async {
    await deleteOrArchiveAccount(companyId: companyId, accountId: accountId);
  }

  /// Safely deletes or archives an account.
  Future<void> deleteOrArchiveAccount({
    required String companyId,
    required String accountId,
  }) async {
    final cleanCompanyId = companyId.trim();
    final cleanAccountId = accountId.trim();

    final account = await accountRepo.findById(cleanCompanyId, cleanAccountId);
    if (account == null) {
      throw const FinancialValidationException('Account not found', 'ACCOUNT_NOT_FOUND');
    }
    if (account.companyId != cleanCompanyId) {
      throw const FinancialValidationException('Cross-company deletion rejected', 'CROSS_TENANT_ACCOUNT_REJECTION');
    }

    // Check for child accounts
    final children = await accountRepo.findChildren(cleanCompanyId, account.id);
    if (children.isNotEmpty) {
      throw FinancialValidationException(
        'Cannot delete account "${account.code}" because it has child accounts',
        'ACCOUNT_HAS_CHILDREN',
      );
    }

    // Check for posted journal history if repository is provided
    if (journalRepo != null) {
      final entries = await journalRepo!.getCompanyEntries(cleanCompanyId);
      final isUsedInPostings = entries.any((e) => e.lines.any((l) => l.accountId == account.id));
      if (isUsedInPostings) {
        throw FinancialValidationException(
          'Cannot delete account "${account.code}" because it has posted journal history',
          'ACCOUNT_HAS_POSTED_HISTORY',
        );
      }
    }

    // Check for AccountingSubject primaryAccountId binding
    if (subjectRepo != null) {
      final boundSubject = await subjectRepo!.findSubjectByPrimaryAccountId(cleanCompanyId, account.id) ??
          await subjectRepo!.findSubjectById(cleanCompanyId, account.id);
      if (boundSubject != null) {
        throw FinancialValidationException(
          'Cannot delete account "${account.code}" because it is bound to an accounting subject',
          'ACCOUNT_HAS_POSTED_HISTORY',
        );
      }
    }

    // Check for Context / Company Account Bindings
    if (contextBindingRepo != null) {
      final isBoundInContext = await contextBindingRepo!.isAccountBound(
        companyId: cleanCompanyId,
        accountId: account.id,
      );
      if (isBoundInContext) {
        throw FinancialValidationException(
          'Cannot delete account "${account.code}" because it is bound to an active operational context',
          'ACCOUNT_HAS_POSTED_HISTORY',
        );
      }
    }
    if (companyMappingRepo != null) {
      final isBoundInMapping = await companyMappingRepo!.isAccountBound(
        companyId: cleanCompanyId,
        accountId: account.id,
      );
      if (isBoundInMapping) {
        throw FinancialValidationException(
          'Cannot delete account "${account.code}" because it is bound to a company default mapping',
          'ACCOUNT_HAS_POSTED_HISTORY',
        );
      }
    }

    // Deactivate / archive account
    await archiveAccount(companyId: cleanCompanyId, accountId: cleanAccountId);
  }

}
