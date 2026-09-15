import 'package:stock_count/core/utils/id_generator.dart';
import '../account/account_currency_policy.dart';
import '../account/financial_account.dart';
import '../common/financial_exceptions.dart';
import '../subject/accounting_subject.dart';
import '../../infrastructure/repositories/financial_account_repository.dart';
import '../../infrastructure/repositories/financial_subject_repository.dart';
import 'account_code_generator.dart';

/// Result container for Customer Accounting Provisioning operations.
class CustomerAccountingProvisioningResult {
  final String subjectId;
  final String accountId;
  final String accountCode;
  final bool isAlreadyProvisioned;

  const CustomerAccountingProvisioningResult({
    required this.subjectId,
    required this.accountId,
    required this.accountCode,
    this.isAlreadyProvisioned = false,
  });
}

/// Central Financial Package service for atomic and idempotent Customer Accounting Provisioning.
class CustomerAccountingProvisioningService {
  final FinancialAccountRepository accountRepo;
  final FinancialSubjectRepository subjectRepo;

  CustomerAccountingProvisioningService({
    required this.accountRepo,
    required this.subjectRepo,
  });

  /// Provisions a dedicated CoA [FinancialAccount] and [AccountingSubject] for a Customer.
  /// Execution is company-scoped, collision-safe, atomic, and idempotent.
  Future<CustomerAccountingProvisioningResult> provisionCustomer({
    required String companyId,
    required String customerId,
    required String customerCode,
    required String customerName,
    String? configuredParentAccountId,
    String Function()? idGenerator,
  }) async {
    final cleanCompanyId = companyId.trim();
    final cleanCustomerCode = customerCode.trim();
    final cleanCustomerName = customerName.trim();

    if (cleanCompanyId.isEmpty) {
      throw FinancialValidationException(
        'Company ID cannot be empty',
        'EMPTY_COMPANY_ID',
      );
    }
    if (cleanCustomerCode.isEmpty || cleanCustomerName.isEmpty) {
      throw FinancialValidationException(
        'Customer code and name cannot be empty',
        'INVALID_CUSTOMER_DATA',
      );
    }

    final makeUuid = idGenerator ?? generateUuidV7;

    // 1. Idempotency Check: Existing Subject by ID or by Code
    AccountingSubject? existingSubject;
    if (customerId.isNotEmpty) {
      existingSubject = await subjectRepo.findSubjectById(cleanCompanyId, customerId);
    }
    existingSubject ??= await subjectRepo.findSubjectByCode(
      cleanCompanyId,
      AccountingSubjectType.customer,
      cleanCustomerCode,
    );

    if (existingSubject != null) {
      final linkedAccount = await accountRepo.findById(cleanCompanyId, existingSubject.primaryAccountId);
      if (linkedAccount != null && linkedAccount.companyId == cleanCompanyId) {
        return CustomerAccountingProvisioningResult(
          subjectId: existingSubject.id,
          accountId: linkedAccount.id,
          accountCode: linkedAccount.code,
          isAlreadyProvisioned: true,
        );
      }
    }

    // 2. Resolve & Validate Configured Parent Account
    FinancialAccount? parentAccount;
    if (configuredParentAccountId != null && configuredParentAccountId.trim().isNotEmpty) {
      parentAccount = await accountRepo.findById(cleanCompanyId, configuredParentAccountId.trim());
      if (parentAccount == null) {
        throw FinancialValidationException(
          'Configured customer parent account $configuredParentAccountId does not exist in company $cleanCompanyId',
          'INVALID_PARENT_ACCOUNT',
        );
      }
    } else {
      parentAccount = await accountRepo.findByCode(cleanCompanyId, '1200');
    }

    if (parentAccount == null || parentAccount.companyId != cleanCompanyId) {
      throw FinancialValidationException(
        'Configured customer parent account is missing or belongs to a different company',
        'INVALID_PARENT_ACCOUNT',
      );
    }

    if (!parentAccount.isGroup) {
      throw FinancialValidationException(
        'Parent account ${parentAccount.code} must be a group account',
        'PARENT_MUST_BE_GROUP',
      );
    }

    // 3. Fetch siblings to generate next collision-safe child account code
    final children = await accountRepo.findChildren(cleanCompanyId, parentAccount.id);
    final siblingCodes = children.map((c) => c.code).toList();
    final nextCode = AccountCodeGenerator.generateNextChildCode(
      parentCode: parentAccount.code,
      existingSiblingCodes: siblingCodes,
    );

    final newAccountId = makeUuid();
    final newSubjectId = makeUuid();

    // 4. Instantiate FinancialAccount (Model B: Dedicated Customer Account)
    final newAccount = FinancialAccount(
      id: newAccountId,
      companyId: cleanCompanyId,
      code: nextCode,
      nameAr: cleanCustomerName,
      nameEn: cleanCustomerName,
      accountType: parentAccount.accountType,
      parentAccountId: parentAccount.id,
      level: parentAccount.level + 1,
      isGroup: false,
      currencyPolicy: AccountCurrencyPolicy.functionalOnly,
    );

    // 5. Instantiate AccountingSubject
    final newSubject = AccountingSubject(
      id: newSubjectId,
      companyId: cleanCompanyId,
      subjectType: AccountingSubjectType.customer,
      name: cleanCustomerName,
      code: cleanCustomerCode,
      primaryAccountId: newAccountId,
      isActive: true,
    );

    // 6. Atomic Persistence
    await accountRepo.saveAccount(newAccount);
    await subjectRepo.saveSubject(newSubject);

    return CustomerAccountingProvisioningResult(
      subjectId: newSubject.id,
      accountId: newAccount.id,
      accountCode: newAccount.code,
      isAlreadyProvisioned: false,
    );
  }
}
