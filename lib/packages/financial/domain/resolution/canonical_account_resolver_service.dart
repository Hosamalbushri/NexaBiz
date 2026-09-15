import '../account/financial_account.dart';
import '../common/financial_exceptions.dart';
import '../../infrastructure/repositories/financial_account_repository.dart';
import '../../infrastructure/repositories/financial_subject_repository.dart';

/// The layer source that resolved the account.
enum ResolutionSource {
  context,
  subject,
  companyMapping,
}

/// Strongly-typed resolution result containing technical account ID and resolution trace.
class AccountResolutionResult {
  final String accountId;
  final ResolutionSource source;
  final String roleKey;

  const AccountResolutionResult({
    required this.accountId,
    required this.source,
    required this.roleKey,
  });
}

/// Representation of an operational context node in the hierarchy chain.
class ContextHierarchyNode {
  final String contextId;
  final String companyId;
  final String? parentContextId;
  final bool isActive;
  final bool isDeleted;

  const ContextHierarchyNode({
    required this.contextId,
    required this.companyId,
    this.parentContextId,
    this.isActive = true,
    this.isDeleted = false,
  });
}

/// Abstract port interface for resolving operational context parent relationships.
abstract class ContextHierarchyProviderPort {
  Future<ContextHierarchyNode?> getContextNode(String contextId);
}

/// Abstract port interface for resolving Context-level account bindings.
abstract class ContextAccountBindingRepositoryPort {
  Future<String?> findAccountId({
    required String companyId,
    required String contextId,
    required String roleKey,
  });

  Future<bool> isAccountBound({
    required String companyId,
    required String accountId,
  }) async => false;
}

/// Abstract port interface for resolving Company-level default role account mappings.
abstract class CompanyAccountMappingRepositoryPort {
  Future<String?> findAccountId({
    required String companyId,
    required String roleKey,
  });

  Future<bool> isAccountBound({
    required String companyId,
    required String accountId,
  }) async => false;
}


/// Central Financial Package service for authoritative Account Resolution Precedence.
///
/// GATE-05 & GATE-06 HARDENED APPLICABILITY & FAIL-CLOSED SEMANTICS:
/// 1. ROLE APPLICABILITY MATRIX: Checks if requested role allows Context, Subject, or Company resolution.
/// 2. HIERARCHICAL CONTEXT RESOLUTION: Nearest context wins. UNCONFIGURED context level traverses to parent context.
/// 3. CYCLE & TENANCY PROTECTION: Cycle detection (CONTEXT_HIERARCHY_CYCLE) and cross-company rejection (CROSS_TENANT_CONTEXT_REJECTION).
/// 4. UNCONFIGURED vs CONFIGURED_INVALID:
///    - UNCONFIGURED source -> Permits fallback to parent context or next applicable layer.
///    - CONFIGURED BUT INVALID source -> FAILS CLOSED IMMEDIATELY (No silent fallback to parent context or lower layers).
class CanonicalAccountResolverService {
  final FinancialAccountRepository accountRepo;
  final FinancialSubjectRepository subjectRepo;
  final ContextAccountBindingRepositoryPort? contextBindingRepo;
  final CompanyAccountMappingRepositoryPort? companyMappingRepo;
  final ContextHierarchyProviderPort? contextHierarchyProvider;

  CanonicalAccountResolverService({
    required this.accountRepo,
    required this.subjectRepo,
    this.contextBindingRepo,
    this.companyMappingRepo,
    this.contextHierarchyProvider,
  });

  /// Role Applicability Matrix definitions.
  static bool isContextApplicable(String roleKey) {
    switch (roleKey.toUpperCase()) {
      case 'SALES_REVENUE':
      case 'PURCHASE_EXPENSE':
      case 'COGS':
      case 'INVENTORY':
      case 'CASH':
      case 'BANK':
        return true;
      case 'CUSTOMER_RECEIVABLE':
      case 'SUPPLIER_PAYABLE':
      case 'TAX':
      case 'FX_GAIN_LOSS':
      default:
        return false;
    }
  }

  static bool isSubjectApplicable(String roleKey) {
    switch (roleKey.toUpperCase()) {
      case 'CUSTOMER_RECEIVABLE':
      case 'SUPPLIER_PAYABLE':
        return true;
      default:
        return false;
    }
  }

  static bool isCompanyMappingApplicable(String roleKey) {
    return true; // Company default mapping is applicable to all roles as ultimate fallback
  }

  /// Resolves the canonical [FinancialAccount.id] (UUID v7) using strict resolution precedence & fail-closed validation.
  Future<AccountResolutionResult> resolveAccount({
    required String companyId,
    required String roleKey,
    String? subjectId,
    String? contextId,
    String? requiredCurrencyCode,
  }) async {
    final cleanCompanyId = companyId.trim();
    final cleanRole = roleKey.trim().toUpperCase();

    if (cleanCompanyId.isEmpty || _isIllegalCompanyId(cleanCompanyId)) {
      throw FinancialValidationException(
        'Account resolution denied: missing or illegal company scope',
        'MISSING_COMPANY_SCOPE',
      );
    }

    if (cleanRole.isEmpty) {
      throw FinancialValidationException('Role key cannot be empty', 'INVALID_ROLE_KEY');
    }

    // ------------------------------------------------------------------------
    // LAYER A: Context Account Binding Hierarchy Traversal
    // ------------------------------------------------------------------------
    if (isContextApplicable(cleanRole) &&
        contextId != null &&
        contextId.trim().isNotEmpty &&
        contextBindingRepo != null) {
      String? currentContextId = contextId.trim();
      final visitedContextIds = <String>{};

      while (currentContextId != null && currentContextId.isNotEmpty) {
        // Cycle & Bounded Traversal Check (Max depth 10)
        if (visitedContextIds.contains(currentContextId)) {
          throw FinancialValidationException(
            'Context hierarchy cycle detected for context "$currentContextId"',
            'CONTEXT_HIERARCHY_CYCLE',
          );
        }
        if (visitedContextIds.length >= 10) {
          throw FinancialValidationException(
            'Context hierarchy depth limit (10) exceeded for context "$currentContextId"',
            'CONTEXT_HIERARCHY_DEPTH_EXCEEDED',
          );
        }
        visitedContextIds.add(currentContextId);

        // Fetch & Validate Context Hierarchy Node (if provider is configured)
        ContextHierarchyNode? contextNode;
        if (contextHierarchyProvider != null) {
          contextNode = await contextHierarchyProvider!.getContextNode(currentContextId);

          if (contextNode != null) {
            // Tenancy Enforcement: Parent/Context company scope MUST match request companyId
            if (contextNode.companyId.trim() != cleanCompanyId) {
              throw FinancialValidationException(
                'Context "$currentContextId" belongs to company "${contextNode.companyId}", expected "$cleanCompanyId"',
                'CROSS_TENANT_CONTEXT_REJECTION',
              );
            }

            // Active/Deleted Check on Context Node
            if (!contextNode.isActive || contextNode.isDeleted) {
              throw FinancialValidationException(
                'Context "$currentContextId" is inactive or deleted',
                'INACTIVE_CONTEXT',
              );
            }
          }
        }

        // Query binding at current context level
        final contextAccountId = await contextBindingRepo!.findAccountId(
          companyId: cleanCompanyId,
          contextId: currentContextId,
          roleKey: cleanRole,
        );

        // If Context Binding IS CONFIGURED at this level: validate target account.
        // IF INVALID: FAIL CLOSED IMMEDIATELY (No silent fallback to parent context or company mapping)!
        if (contextAccountId != null && contextAccountId.trim().isNotEmpty) {
          final account = await _fetchAndValidateAccount(
            companyId: cleanCompanyId,
            accountId: contextAccountId.trim(),
            roleKey: cleanRole,
          );
          return AccountResolutionResult(
            accountId: account.id,
            source: ResolutionSource.context,
            roleKey: cleanRole,
          );
        }

        // UNCONFIGURED at current context level: traverse to parent context node (if any)
        if (contextNode != null &&
            contextNode.parentContextId != null &&
            contextNode.parentContextId!.trim().isNotEmpty) {
          currentContextId = contextNode.parentContextId!.trim();
        } else {
          // No parent context; exit hierarchy loop and proceed to lower layers
          break;
        }
      }
    }

    // ------------------------------------------------------------------------
    // LAYER B: Subject Account Binding (AccountingSubject.primaryAccountId)
    // ------------------------------------------------------------------------
    if (isSubjectApplicable(cleanRole) && subjectId != null && subjectId.trim().isNotEmpty) {
      final cleanSubjectId = subjectId.trim();
      final subject = await subjectRepo.findSubjectById(cleanCompanyId, cleanSubjectId);
      if (subject == null || subject.companyId != cleanCompanyId) {
        throw FinancialValidationException(
          'Subject $cleanSubjectId not found in company $cleanCompanyId',
          'CROSS_TENANT_SUBJECT_REJECTION',
        );
      }

      if (!subject.isActive) {
        throw FinancialValidationException(
          'Cannot resolve account for inactive subject ${subject.id}',
          'INACTIVE_SUBJECT',
        );
      }

      // If Subject HAS a primary account binding: validate account.
      // IF INVALID: FAIL CLOSED IMMEDIATELY (No silent fallback to Company Mapping)!
      if (subject.primaryAccountId.trim().isNotEmpty) {
        final account = await _fetchAndValidateAccount(
          companyId: cleanCompanyId,
          accountId: subject.primaryAccountId.trim(),
          roleKey: cleanRole,
        );

        return AccountResolutionResult(
          accountId: account.id,
          source: ResolutionSource.subject,
          roleKey: cleanRole,
        );
      }
    }

    // ------------------------------------------------------------------------
    // LAYER C: Company Account Mapping
    // ------------------------------------------------------------------------
    if (isCompanyMappingApplicable(cleanRole) && companyMappingRepo != null) {
      final companyAccountId = await companyMappingRepo!.findAccountId(
        companyId: cleanCompanyId,
        roleKey: cleanRole,
      );

      // If Company Mapping IS CONFIGURED: validate account.
      // IF INVALID: FAIL CLOSED IMMEDIATELY!
      if (companyAccountId != null && companyAccountId.trim().isNotEmpty) {
        final account = await _fetchAndValidateAccount(
          companyId: cleanCompanyId,
          accountId: companyAccountId.trim(),
          roleKey: cleanRole,
        );
        return AccountResolutionResult(
          accountId: account.id,
          source: ResolutionSource.companyMapping,
          roleKey: cleanRole,
        );
      }
    }

    // ------------------------------------------------------------------------
    // FAIL CLOSED: No hardcoded fallback account codes permitted!
    // ------------------------------------------------------------------------
    throw FinancialValidationException(
      'No account mapping configured for role "$cleanRole" in company $cleanCompanyId',
      'MISSING_ACCOUNT_MAPPING',
    );
  }

  Future<FinancialAccount> _fetchAndValidateAccount({
    required String companyId,
    required String accountId,
    required String roleKey,
  }) async {
    // Reject hardcoded numeric codes being passed as UUIDs
    if (int.tryParse(accountId) != null && int.parse(accountId) > 0) {
      throw FinancialValidationException(
        'Account resolution rejected: target "$accountId" is a numeric integer code. Must use UUID v7.',
        'ILLEGAL_ACCOUNT_CODE_AS_IDENTITY',
      );
    }

    final account = await accountRepo.findById(companyId, accountId);
    if (account == null) {
      throw FinancialValidationException(
        'Account $accountId not found in company $companyId or belongs to another company',
        'CROSS_TENANT_ACCOUNT_REJECTION',
      );
    }

    if (account.companyId != companyId) {
      throw FinancialValidationException(
        'Account ${account.id} belongs to company ${account.companyId}, expected $companyId',
        'CROSS_TENANT_ACCOUNT_REJECTION',
      );
    }

    if (!account.isActive) {
      throw FinancialValidationException(
        'Account ${account.id} is inactive',
        'INACTIVE_ACCOUNT',
      );
    }

    if (account.isGroup) {
      throw FinancialValidationException(
        'Account ${account.id} is a group account and cannot receive journal postings',
        'GROUP_ACCOUNT_NOT_POSTABLE',
      );
    }

    return account;
  }

  bool _isIllegalCompanyId(String id) {
    final lower = id.toLowerCase();
    return lower == 'fallback' ||
        lower == 'default' ||
        lower == 'legacy_company' ||
        lower == 'global' ||
        lower == 'legacycompanyid';
  }
}
