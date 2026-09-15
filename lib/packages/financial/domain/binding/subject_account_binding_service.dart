import '../account/financial_account.dart';
import '../common/financial_exceptions.dart';
import '../subject/accounting_subject.dart';
import '../../infrastructure/repositories/financial_account_repository.dart';
import '../../infrastructure/repositories/financial_subject_repository.dart';

/// Result object for Subject Account Binding operations.
class SubjectAccountBindingResult {
  final String subjectId;
  final String accountId;
  final String roleKey;
  final bool isAlreadyBound;

  const SubjectAccountBindingResult({
    required this.subjectId,
    required this.accountId,
    required this.roleKey,
    this.isAlreadyBound = false,
  });
}

/// Central Financial Package service for authoritative Subject -> FinancialAccount binding management.
class SubjectAccountBindingService {
  final FinancialAccountRepository accountRepo;
  final FinancialSubjectRepository subjectRepo;

  SubjectAccountBindingService({
    required this.accountRepo,
    required this.subjectRepo,
  });

  /// Binds an [AccountingSubject] to a [FinancialAccount].
  /// Enforces company tenancy, subject/account active state, and role compatibility.
  Future<SubjectAccountBindingResult> bindSubjectToAccount({
    required String companyId,
    required String subjectId,
    required String financialAccountId,
    String roleKey = 'DEFAULT',
  }) async {
    final cleanCompanyId = companyId.trim();
    final cleanSubjectId = subjectId.trim();
    final cleanAccountId = financialAccountId.trim();
    final cleanRole = roleKey.trim().toUpperCase();

    if (cleanCompanyId.isEmpty) {
      throw FinancialValidationException('Company ID cannot be empty', 'EMPTY_COMPANY_ID');
    }
    if (cleanSubjectId.isEmpty || cleanAccountId.isEmpty) {
      throw FinancialValidationException('Subject ID and Account ID cannot be empty', 'INVALID_BINDING_DATA');
    }

    // 1. Fetch & Validate Subject
    final subject = await subjectRepo.findSubjectById(cleanCompanyId, cleanSubjectId);
    if (subject == null || subject.companyId != cleanCompanyId) {
      throw FinancialValidationException(
        'Subject $cleanSubjectId does not exist in company $cleanCompanyId',
        'SUBJECT_NOT_FOUND',
      );
    }
    if (!subject.isActive) {
      throw FinancialValidationException(
        'Cannot bind inactive subject ${subject.id}',
        'INACTIVE_SUBJECT',
      );
    }

    // 2. Fetch & Validate Account
    final account = await accountRepo.findById(cleanCompanyId, cleanAccountId);
    if (account == null || account.companyId != cleanCompanyId) {
      throw FinancialValidationException(
        'FinancialAccount $cleanAccountId does not exist in company $cleanCompanyId',
        'ACCOUNT_NOT_FOUND',
      );
    }
    if (!account.isActive) {
      throw FinancialValidationException(
        'Cannot bind subject to inactive account ${account.id}',
        'INACTIVE_ACCOUNT',
      );
    }

    // 3. Validate Role Compatibility
    _validateRoleCompatibility(subject, account, cleanRole);

    // 4. Idempotency Check: Existing Binding
    if (subject.primaryAccountId == account.id) {
      return SubjectAccountBindingResult(
        subjectId: subject.id,
        accountId: account.id,
        roleKey: cleanRole,
        isAlreadyBound: true,
      );
    }

    // 5. Update Subject Primary Account Binding
    final updatedSubject = AccountingSubject(
      id: subject.id,
      companyId: subject.companyId,
      subjectType: subject.subjectType,
      name: subject.name,
      code: subject.code,
      primaryAccountId: account.id,
      isActive: subject.isActive,
    );

    await subjectRepo.saveSubject(updatedSubject);

    return SubjectAccountBindingResult(
      subjectId: subject.id,
      accountId: account.id,
      roleKey: cleanRole,
      isAlreadyBound: false,
    );
  }

  /// Resolves the authoritative technical [FinancialAccount.id] for a given subject.
  /// Strictly fail-closed without any hidden account-code fallbacks.
  Future<String> resolveSubjectAccount({
    required String companyId,
    required String subjectId,
    String? roleKey,
  }) async {
    final cleanCompanyId = companyId.trim();
    final cleanSubjectId = subjectId.trim();

    if (cleanCompanyId.isEmpty) {
      throw FinancialValidationException('Company ID cannot be empty', 'EMPTY_COMPANY_ID');
    }
    if (cleanSubjectId.isEmpty) {
      throw FinancialValidationException('Subject ID cannot be empty', 'INVALID_SUBJECT_ID');
    }

    final subject = await subjectRepo.findSubjectById(cleanCompanyId, cleanSubjectId);
    if (subject == null || subject.companyId != cleanCompanyId) {
      throw FinancialValidationException(
        'Subject $cleanSubjectId not found in company $cleanCompanyId',
        'MISSING_SUBJECT_ACCOUNT_BINDING',
      );
    }

    if (subject.primaryAccountId.trim().isEmpty) {
      throw FinancialValidationException(
        'Subject $cleanSubjectId has no primary account binding',
        'MISSING_SUBJECT_ACCOUNT_BINDING',
      );
    }

    final account = await accountRepo.findById(cleanCompanyId, subject.primaryAccountId);
    if (account == null || account.companyId != cleanCompanyId) {
      throw FinancialValidationException(
        'Bound account ${subject.primaryAccountId} not found in company $cleanCompanyId',
        'MISSING_SUBJECT_ACCOUNT_BINDING',
      );
    }

    return account.id; // Returns Technical FinancialAccount.id (UUID v7)
  }

  /// Reassigns an existing subject to a new account without mutating historical journal lines.
  Future<SubjectAccountBindingResult> reassignSubjectAccount({
    required String companyId,
    required String subjectId,
    required String newFinancialAccountId,
    String roleKey = 'DEFAULT',
  }) async {
    return bindSubjectToAccount(
      companyId: companyId,
      subjectId: subjectId,
      financialAccountId: newFinancialAccountId,
      roleKey: roleKey,
    );
  }

  void _validateRoleCompatibility(
    AccountingSubject subject,
    FinancialAccount account,
    String roleKey,
  ) {
    if (roleKey == 'CUSTOMER_RECEIVABLE') {
      if (subject.subjectType != AccountingSubjectType.customer) {
        throw FinancialValidationException(
          'Role CUSTOMER_RECEIVABLE requires subject type CUSTOMER',
          'ROLE_SUBJECT_MISMATCH',
        );
      }
      if (account.accountType != FinancialAccountType.asset) {
        throw FinancialValidationException(
          'Role CUSTOMER_RECEIVABLE requires ASSET account type',
          'ROLE_ACCOUNT_MISMATCH',
        );
      }
    } else if (roleKey == 'SUPPLIER_PAYABLE') {
      if (subject.subjectType != AccountingSubjectType.supplier) {
        throw FinancialValidationException(
          'Role SUPPLIER_PAYABLE requires subject type SUPPLIER',
          'ROLE_SUBJECT_MISMATCH',
        );
      }
      if (account.accountType != FinancialAccountType.liability) {
        throw FinancialValidationException(
          'Role SUPPLIER_PAYABLE requires LIABILITY account type',
          'ROLE_ACCOUNT_MISMATCH',
        );
      }
    }
  }
}
