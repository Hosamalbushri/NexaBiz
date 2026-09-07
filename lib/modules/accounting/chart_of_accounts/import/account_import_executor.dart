import '../../../../../core/import_engine/import_engine.dart';
import '../domain/entities/account.dart';
import '../domain/entities/account_type.dart';
import '../domain/repositories/account_repository.dart';
import 'account_hierarchy_sorter.dart';

/// Domain exception for Chart of Accounts import failures.
class AccountImportException extends ImportEngineException {
  const AccountImportException(
    super.message, [
    super.code = 'ACCOUNT_IMPORT_ERROR',
  ]);
}

/// Execution result payload for a single imported account row.
class AccountImportRowResult {
  const AccountImportRowResult({
    required this.account,
    this.debitOpening = 0.0,
    this.creditOpening = 0.0,
    this.currencyCode,
  });

  final Account account;
  final double debitOpening;
  final double creditOpening;
  final String? currencyCode;
}

/// Domain import executor for Chart of Accounts (COA) enforcing multi-company tenant isolation.
class AccountImportExecutor {
  AccountImportExecutor({required this.accountRepository});

  final AccountRepository accountRepository;

  /// Executes batch import of account rows with topological parent-before-child ordering.
  Future<List<AccountImportRowResult>> executeAccountBatch({
    required List<Map<String, dynamic>> rows,
    required String companyId,
    ImportPolicy policy = const ImportPolicy(),
    Map<String, String> resolvedRelations = const {},
  }) async {
    final cleanCompanyId = companyId.trim();
    if (cleanCompanyId.isEmpty) {
      throw const AccountImportException(
        'Company ID cannot be empty.',
        'EMPTY_COMPANY',
      );
    }

    // Topological sorting ensuring parent accounts precede dependent child accounts
    final sortedRows = AccountHierarchySorter.sortRows(
      rows: rows,
      parentFieldKey: 'parentAccount',
      codeFieldKey: 'accountCode',
      nameFieldKey: 'name',
    );

    final results = <AccountImportRowResult>[];

    for (final rowData in sortedRows) {
      final res = await executeAccountRow(
        rowData: rowData,
        companyId: cleanCompanyId,
        policy: policy,
        resolvedRelations: resolvedRelations,
      );
      if (res != null) {
        results.add(res);
      }
    }

    return results;
  }

  /// Executes import for a single account row.
  Future<AccountImportRowResult?> executeAccountRow({
    required Map<String, dynamic> rowData,
    required String companyId,
    ImportPolicy policy = const ImportPolicy(),
    Map<String, String> resolvedRelations = const {},
  }) async {
    final code = rowData['accountCode']?.toString().trim() ?? '';
    if (code.isEmpty) {
      throw const AccountImportException(
        'Account Code cannot be empty.',
        'EMPTY_ACCOUNT_CODE',
      );
    }

    final name = rowData['name']?.toString().trim() ?? '';
    if (name.isEmpty) {
      throw const AccountImportException(
        'Account Name cannot be empty.',
        'EMPTY_ACCOUNT_NAME',
      );
    }

    // 1. Parse & Validate AccountType
    final rawType = rowData['accountType']?.toString().trim() ?? '';
    final accountType = parseAccountType(rawType);

    // 2. Parse Group flag
    final isGroup = parseBoolean(rowData['isGroup']) ?? false;

    // 3. Parse & Validate Opening Balances
    final debitOpening =
        double.tryParse(rowData['debitOpening']?.toString() ?? '') ?? 0.0;
    final creditOpening =
        double.tryParse(rowData['creditOpening']?.toString() ?? '') ?? 0.0;
    final currencyCode = rowData['currency']?.toString().trim();
    final description = rowData['description']?.toString().trim();
    final isActive = parseBoolean(rowData['isActive']) ?? true;

    if (debitOpening < 0 || creditOpening < 0) {
      throw const AccountImportException(
        'Opening balance amounts cannot be negative.',
        'NEGATIVE_OPENING_BALANCE',
      );
    }

    if (debitOpening > 0 && creditOpening > 0) {
      throw const AccountImportException(
        'Account cannot have both debit and credit opening balances on the same row.',
        'BOTH_OPENING_SIDES',
      );
    }

    if (isGroup && (debitOpening > 0 || creditOpening > 0)) {
      throw const AccountImportException(
        'Group (header) accounts cannot have opening balances.',
        'GROUP_OPENING_BALANCE',
      );
    }

    // 4. Resolve Parent Account with Multi-Company Tenant Isolation
    final parentTerm =
        rowData['parentAccount']?.toString().trim() ??
        resolvedRelations['parentAccount'];
    Account? parentAccount;

    if (parentTerm != null && parentTerm.isNotEmpty) {
      parentAccount = await _resolveParentAccount(parentTerm, companyId);
      if (parentAccount == null) {
        if (!policy.createMissingRelations) {
          throw AccountImportException(
            'Parent account "$parentTerm" not found for account "$code - $name".',
            'PARENT_NOT_FOUND',
          );
        }
      }
    }

    // 5. Check Duplicate Code & Ambiguity Protection
    final existing = await accountRepository.getByAccountCode(code);

    if (existing != null) {
      if (policy.duplicateResolution == DuplicateResolutionStrategy.error) {
        throw AccountImportException(
          'Account code "$code" already exists.',
          'DUPLICATE_CODE',
        );
      } else if (policy.duplicateResolution ==
          DuplicateResolutionStrategy.skip) {
        return AccountImportRowResult(
          account: existing,
          debitOpening: debitOpening,
          creditOpening: creditOpening,
          currencyCode: currencyCode,
        );
      }
    }

    // Ambiguity Check: Ensure name isn't conflicting with an existing account of different code
    final allAccounts = await accountRepository.getAll(includeInactive: true);
    for (final acc in allAccounts) {
      if (acc.name.toLowerCase().trim() == name.toLowerCase() &&
          acc.accountCode != code) {
        if (policy.duplicateResolution == DuplicateResolutionStrategy.error) {
          throw AccountImportException(
            'Account name "$name" already exists under code "${acc.accountCode}". Silent merge is prohibited.',
            'AMBIGUOUS_NAME',
          );
        }
      }
    }

    // 6. Build Draft & Insert / Update
    final draft = AccountDraft(
      accountCode: code,
      name: name,
      accountType: accountType,
      isGroup: isGroup,
      parentId: parentAccount?.uuid,
      description: description,
      isActive: isActive,
    );

    final Account account;
    if (existing != null &&
        policy.duplicateResolution == DuplicateResolutionStrategy.overwrite) {
      account = await accountRepository.update(existing.id, draft);
    } else {
      account = await accountRepository.insert(draft);
    }

    return AccountImportRowResult(
      account: account,
      debitOpening: debitOpening,
      creditOpening: creditOpening,
      currencyCode: currencyCode,
    );
  }

  /// Resolves parent account by code, name, or UUID strictly scoped to tenant [companyId].
  Future<Account?> _resolveParentAccount(String term, String companyId) async {
    final clean = term.trim();
    if (clean.isEmpty) return null;

    // By exact code
    final byCode = await accountRepository.getByAccountCode(clean);
    if (byCode != null) {
      if (byCode.companyId != null && byCode.companyId != companyId) {
        throw TenantIsolationException(
          'Cross-company parent account resolution violation: Parent account "${byCode.accountCode}" belongs to company "${byCode.companyId}", attempted by company "$companyId"',
          expectedCompanyId: companyId,
          attemptedCompanyId: byCode.companyId,
        );
      }
      return byCode;
    }

    // By UUID
    final byUuid = await accountRepository.getByUuid(clean);
    if (byUuid != null) {
      if (byUuid.companyId != null && byUuid.companyId != companyId) {
        throw TenantIsolationException(
          'Cross-company parent account resolution violation: Parent account "${byUuid.uuid}" belongs to company "${byUuid.companyId}", attempted by company "$companyId"',
          expectedCompanyId: companyId,
          attemptedCompanyId: byUuid.companyId,
        );
      }
      return byUuid;
    }

    // By search / name match
    final search = await accountRepository.search(clean, includeInactive: true);
    for (final acc in search) {
      if (acc.accountCode == clean ||
          acc.name.toLowerCase().trim() == clean.toLowerCase()) {
        if (acc.companyId != null && acc.companyId != companyId) {
          throw TenantIsolationException(
            'Cross-company parent account resolution violation: Parent account "${acc.name}" belongs to company "${acc.companyId}", attempted by company "$companyId"',
            expectedCompanyId: companyId,
            attemptedCompanyId: acc.companyId,
          );
        }
        return acc;
      }
    }

    return null;
  }

  /// Parses [AccountType] from English or Arabic input strings.
  AccountType parseAccountType(String raw) {
    final clean = raw.trim().toLowerCase();
    switch (clean) {
      case 'asset':
      case 'assets':
      case 'أصل':
      case 'أصول':
      case 'الأصول':
        return AccountType.asset;

      case 'liability':
      case 'liabilities':
      case 'التزام':
      case 'التزامات':
      case 'خصوم':
      case 'الخصوم':
        return AccountType.liability;

      case 'equity':
      case 'equities':
      case 'حقوق ملكية':
      case 'حقوق الملكية':
      case 'رأس المال':
        return AccountType.equity;

      case 'revenue':
      case 'income':
      case 'إيراد':
      case 'إيرادات':
      case 'الإيرادات':
        return AccountType.revenue;

      case 'expense':
      case 'expenses':
      case 'مصروف':
      case 'مصروفات':
      case 'المصروفات':
      case 'مصاريف':
        return AccountType.expense;

      default:
        throw AccountImportException(
          'Invalid account type "$raw". Supported types are Asset, Liability, Equity, Revenue, Expense.',
          'INVALID_ACCOUNT_TYPE',
        );
    }
  }

  /// Helper parser for boolean values (handles true/false, 1/0, yes/no, نعم/لا).
  bool? parseBoolean(dynamic input) {
    if (input == null) return null;
    if (input is bool) return input;
    final str = input.toString().trim().toLowerCase();
    if (str == 'true' ||
        str == '1' ||
        str == 'yes' ||
        str == 'y' ||
        str == 'نعم' ||
        str == 'صحيح') {
      return true;
    }
    if (str == 'false' ||
        str == '0' ||
        str == 'no' ||
        str == 'n' ||
        str == 'لا' ||
        str == 'خطأ') {
      return false;
    }
    return null;
  }
}
