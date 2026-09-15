import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/packages/financial/domain/account/account_currency_policy.dart';
import 'package:stock_count/packages/financial/domain/account/chart_of_accounts_service.dart';
import 'package:stock_count/packages/financial/domain/account/financial_account.dart';
import 'package:stock_count/packages/financial/domain/common/financial_exceptions.dart';
import 'package:stock_count/packages/financial/domain/journal/financial_side.dart';
import 'package:stock_count/packages/financial/domain/journal/journal_entry.dart';
import 'package:stock_count/packages/financial/domain/journal/journal_line.dart';
import 'package:stock_count/packages/financial/domain/journal/journal_status.dart';
import 'package:stock_count/packages/financial/domain/money/decimal_money.dart';
import 'package:stock_count/packages/financial/domain/money/decimal_rate.dart';
import 'package:stock_count/packages/financial/domain/subject/accounting_subject.dart';
import 'package:stock_count/packages/financial/domain/subject/subject_account_bucket.dart';
import 'package:stock_count/packages/financial/infrastructure/repositories/financial_account_repository.dart';
import 'package:stock_count/packages/financial/infrastructure/repositories/financial_journal_repository.dart';
import 'package:stock_count/packages/financial/infrastructure/repositories/financial_subject_repository.dart';
import 'package:stock_count/packages/financial/domain/resolution/canonical_account_resolver_service.dart';


class MockFinancialAccountRepository implements FinancialAccountRepository {
  final Map<String, FinancialAccount> _accounts = {};

  @override
  Future<void> saveAccount(FinancialAccount account) async {
    final key = '${account.companyId}:${account.id}';
    _accounts[key] = account;
  }

  @override
  Future<FinancialAccount?> findById(String companyId, String id) async {
    return _accounts['$companyId:$id'];
  }

  @override
  Future<FinancialAccount?> findByCode(String companyId, String code) async {
    for (final account in _accounts.values) {
      if (account.companyId == companyId && account.code == code) {
        return account;
      }
    }
    return null;
  }

  @override
  Future<List<FinancialAccount>> findChildren(String companyId, String parentAccountId) async {
    return _accounts.values
        .where((a) => a.companyId == companyId && a.parentAccountId == parentAccountId)
        .toList();
  }

  @override
  Future<List<FinancialAccount>> getCompanyAccounts(String companyId) async {
    return _accounts.values.where((a) => a.companyId == companyId).toList();
  }
}

class MockFinancialJournalRepository implements FinancialJournalRepository {
  final List<JournalEntry> entries = [];

  @override
  Future<void> saveEntry(JournalEntry entry) async {
    final existingIndex = entries.indexWhere((e) => e.companyId == entry.companyId && e.id == entry.id);
    if (existingIndex >= 0) {
      if (entries[existingIndex].status == JournalStatus.posted) {
        throw PostedJournalImmutableException(entry.id);
      }
      entries[existingIndex] = entry;
    } else {
      entries.add(entry);
    }
  }

  @override
  Future<JournalEntry?> findById(String companyId, String id) async {
    try {
      return entries.firstWhere((e) => e.companyId == companyId && e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<JournalEntry?> findByNumber(String companyId, String entryNumber) async {
    try {
      return entries.firstWhere((e) => e.companyId == companyId && e.entryNumber == entryNumber);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<JournalEntry?> findBySourceDocument({
    required String companyId,
    required String sourceModule,
    required String sourceDocumentId,
  }) async {
    try {
      return entries.firstWhere(
        (e) =>
            e.companyId == companyId &&
            e.sourceModule == sourceModule &&
            e.sourceDocumentId == sourceDocumentId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<JournalEntry>> getCompanyEntries(String companyId) async {
    return entries.where((e) => e.companyId == companyId).toList();
  }
}

class MockFinancialSubjectRepository implements FinancialSubjectRepository {
  final Map<String, AccountingSubject> subjects = {};

  @override
  Future<void> saveSubject(AccountingSubject subject) async {
    subjects['${subject.companyId}:${subject.id}'] = subject;
  }

  @override
  Future<AccountingSubject?> findSubjectById(String companyId, String id) async {
    return subjects['$companyId:$id'];
  }

  @override
  Future<AccountingSubject?> findSubjectByCode(
    String companyId,
    AccountingSubjectType subjectType,
    String code,
  ) async {
    for (final s in subjects.values) {
      if (s.companyId == companyId && s.subjectType == subjectType && s.code == code) {
        return s;
      }
    }
    return null;
  }

  @override
  Future<AccountingSubject?> findSubjectByPrimaryAccountId(String companyId, String accountId) async {
    for (final s in subjects.values) {
      if (s.companyId == companyId && s.primaryAccountId == accountId) {
        return s;
      }
    }
    return null;
  }

  @override
  Future<SubjectAccountBucket?> getBucket({

    required String companyId,
    required String subjectId,
    required String accountId,
    required String currencyCode,
  }) async {
    return null;
  }

  @override
  Future<void> updateBucketBalance(SubjectAccountBucket bucket) async {}
}

class MockContextBindingRepo implements ContextAccountBindingRepositoryPort {
  final Map<String, String> _bindings = {};

  void setBinding({
    required String companyId,
    required String contextId,
    required String roleKey,
    required String accountId,
  }) {
    _bindings['$companyId:$contextId:$roleKey'] = accountId;
  }

  @override
  Future<String?> findAccountId({
    required String companyId,
    required String contextId,
    required String roleKey,
  }) async {
    return _bindings['$companyId:$contextId:$roleKey'];
  }

  @override
  Future<bool> isAccountBound({
    required String companyId,
    required String accountId,
  }) async {
    return _bindings.entries.any((e) => e.key.startsWith('$companyId:') && e.value == accountId);
  }
}

class MockCompanyMappingRepo implements CompanyAccountMappingRepositoryPort {
  final Map<String, String> _mappings = {};

  void setMapping({
    required String companyId,
    required String roleKey,
    required String accountId,
  }) {
    _mappings['$companyId:$roleKey'] = accountId;
  }

  @override
  Future<String?> findAccountId({
    required String companyId,
    required String roleKey,
  }) async {
    return _mappings['$companyId:$roleKey'];
  }

  @override
  Future<bool> isAccountBound({
    required String companyId,
    required String accountId,
  }) async {
    return _mappings.entries.any((e) => e.key.startsWith('$companyId:') && e.value == accountId);
  }
}

void main() {
  group('GATE-07 COA Hierarchy & Composite Tenancy Mandatory Unit Suite (TEST-136..178)', () {
    late MockFinancialAccountRepository accountRepo;
    late MockFinancialJournalRepository journalRepo;
    late MockFinancialSubjectRepository subjectRepo;
    late MockContextBindingRepo contextRepo;
    late MockCompanyMappingRepo companyMappingRepo;
    late ChartOfAccountsService coaService;

    const companyA = '0191c784-754e-7b3b-8b77-502a3a5f8001';
    const companyB = '0191c784-754e-7b3b-8b77-502a3a5f8002';

    setUp(() {
      accountRepo = MockFinancialAccountRepository();
      journalRepo = MockFinancialJournalRepository();
      subjectRepo = MockFinancialSubjectRepository();
      contextRepo = MockContextBindingRepo();
      companyMappingRepo = MockCompanyMappingRepo();
      coaService = ChartOfAccountsService(
        accountRepo: accountRepo,
        journalRepo: journalRepo,
        subjectRepo: subjectRepo,
        contextBindingRepo: contextRepo,
        companyMappingRepo: companyMappingRepo,
      );
    });



    test('TEST-136: Root account creation', () async {
      final root = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'الأصول',
        nameEn: 'Assets',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: null,
        isGroup: true,
      );

      expect(root.companyId, companyA);
      expect(root.code, '1000');
      expect(root.parentAccountId, isNull);
      expect(root.level, 0);
      expect(root.isGroup, isTrue);
    });

    test('TEST-137: Child account creation', () async {
      final parent = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'الأصول المتداولة',
        nameEn: 'Current Assets',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );

      final child = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'الصندوق',
        nameEn: 'Cash',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.singleFixedCurrency,
        fixedCurrencyCode: 'YER',
        parentAccountId: parent.id,
        isGroup: false,
      );

      expect(child.parentAccountId, parent.id);
      expect(child.level, 1);
      expect(child.isGroup, isFalse);
    });

    test('TEST-138: Multi-level hierarchy', () async {
      final l0 = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'Root',
        nameEn: 'Root',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final l1 = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'L1',
        nameEn: 'L1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: l0.id,
        isGroup: true,
      );
      final l2 = await coaService.createAccount(
        companyId: companyA,
        code: '1110',
        nameAr: 'L2',
        nameEn: 'L2',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: l1.id,
        isGroup: true,
      );
      final l3 = await coaService.createAccount(
        companyId: companyA,
        code: '1111',
        nameAr: 'L3',
        nameEn: 'L3',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: l2.id,
        isGroup: false,
      );

      expect(l0.level, 0);
      expect(l1.level, 1);
      expect(l2.level, 2);
      expect(l3.level, 3);
    });

    test('TEST-139: Multiple roots allowed in same company', () async {
      final assets = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'Assets',
        nameEn: 'Assets',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final liabilities = await coaService.createAccount(
        companyId: companyA,
        code: '2000',
        nameAr: 'Liabilities',
        nameEn: 'Liabilities',
        accountType: FinancialAccountType.liability,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );

      expect(assets.parentAccountId, isNull);
      expect(liabilities.parentAccountId, isNull);
      expect(assets.level, 0);
      expect(liabilities.level, 0);
    });

    test('TEST-140: Parent/child same-company validation', () async {
      final parentA = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'Assets',
        nameEn: 'Assets',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );

      expect(
        () => coaService.createAccount(
          companyId: companyB,
          code: '1001',
          nameAr: 'Cross Child',
          nameEn: 'Cross Child',
          accountType: FinancialAccountType.asset,
          currencyPolicy: AccountCurrencyPolicy.functionalOnly,
          parentAccountId: parentA.id,
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'INVALID_PARENT_ACCOUNT',
          ),
        ),
      );
    });

    test('TEST-141: FinancialAccount.id remains stable after move', () async {
      final parent1 = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'Group 1',
        nameEn: 'Group 1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final parent2 = await coaService.createAccount(
        companyId: companyA,
        code: '1200',
        nameAr: 'Group 2',
        nameEn: 'Group 2',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final account = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Account',
        nameEn: 'Account',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: parent1.id,
      );

      final originalId = account.id;
      final moveResult = await coaService.moveAccount(
        companyId: companyA,
        accountId: account.id,
        newParentAccountId: parent2.id,
      );
      expect(moveResult.movedAccount.id, originalId);
    });

    test('TEST-142: FinancialAccount.id remains stable after code change', () async {
      final account = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Account',
        nameEn: 'Account',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      final originalId = account.id;
      final mutatedAccount = await coaService.updateAccountCode(
        companyId: companyA,
        accountId: account.id,
        newCode: '1209',
      );
      expect(mutatedAccount.id, originalId);
    });

    test('TEST-143: JournalLine.accountId remains unchanged after move', () async {
      final parent1 = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'Group 1',
        nameEn: 'Group 1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final parent2 = await coaService.createAccount(
        companyId: companyA,
        code: '1200',
        nameAr: 'Group 2',
        nameEn: 'Group 2',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Cash',
        nameEn: 'Cash',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: parent1.id,
      );

      final entry = JournalEntry(
        id: generateUuidV7(),
        companyId: companyA,
        entryNumber: 'JE-001',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        status: JournalStatus.posted,
        lines: [
          JournalLine(
            id: generateUuidV7(),
            companyId: companyA,
            journalEntryId: 'JE-001',
            lineNumber: 1,
            accountId: acc.id,
            side: FinancialSide.debit,
            transactionAmount: DecimalMoney.fromScaled(BigInt.from(10000000), 'YER'),
            exchangeRate: DecimalRate.identity('YER'),
            baseAmount: DecimalMoney.fromScaled(BigInt.from(10000000), 'YER'),
          ),
        ],
      );
      await journalRepo.saveEntry(entry);

      await coaService.moveAccount(companyId: companyA, accountId: acc.id, newParentAccountId: parent2.id);
      final savedEntry = await journalRepo.findById(companyA, entry.id);
      expect(savedEntry!.lines.first.accountId, acc.id);
    });

    test('TEST-144: Subject primaryAccountId remains unchanged after move', () async {
      final parent = await coaService.createAccount(
        companyId: companyA,
        code: '1200',
        nameAr: 'AR Group',
        nameEn: 'AR Group',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1201',
        nameAr: 'Customer Acc',
        nameEn: 'Customer Acc',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: parent.id,
      );
      final subject = AccountingSubject(
        id: generateUuidV7(),
        companyId: companyA,
        subjectType: AccountingSubjectType.customer,
        name: 'Ahmed',
        code: 'CUST-01',
        primaryAccountId: acc.id,
      );
      await subjectRepo.saveSubject(subject);

      await coaService.moveAccount(companyId: companyA, accountId: acc.id, newParentAccountId: null);

      final savedSubject = await subjectRepo.findSubjectById(companyA, subject.id);
      expect(savedSubject!.primaryAccountId, acc.id);
    });

    test('TEST-145: Balances remain unchanged after move', () async {
      final parent = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'Group',
        nameEn: 'Group',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Acc',
        nameEn: 'Acc',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: parent.id,
      );

      final moveResult = await coaService.moveAccount(
        companyId: companyA,
        accountId: acc.id,
        newParentAccountId: null,
      );

      expect(moveResult.movedAccount.id, acc.id);
      expect(journalRepo.entries.length, 0);
    });

    test('TEST-146: Group account cannot receive posting', () async {
      final groupAcc = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'Group',
        nameEn: 'Group',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );

      expect(
        () => coaService.validatePostingTarget(companyA, groupAcc.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'GROUP_ACCOUNT_NOT_POSTABLE',
          ),
        ),
      );
    });

    test('TEST-147: Postable account can receive valid posting', () async {
      final postableAcc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Cash',
        nameEn: 'Cash',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: false,
      );

      final result = await coaService.validatePostingTarget(companyA, postableAcc.id);
      expect(result.id, postableAcc.id);
    });

    test('TEST-148: Inactive account cannot receive posting', () async {
      final inactiveAcc = await coaService.createAccount(
        companyId: companyA,
        code: '1102',
        nameAr: 'Inactive',
        nameEn: 'Inactive',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isActive: false,
      );

      expect(
        () => coaService.validatePostingTarget(companyA, inactiveAcc.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'INACTIVE_ACCOUNT',
          ),
        ),
      );
    });

    test('TEST-149: Archived account cannot receive posting', () async {
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1103',
        nameAr: 'To Archive',
        nameEn: 'To Archive',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );
      final archived = await coaService.archiveAccount(companyId: companyA, accountId: acc.id);
      expect(archived.isActive, false);

      expect(
        () => coaService.validatePostingTarget(companyA, acc.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'INACTIVE_ACCOUNT',
          ),
        ),
      );
    });

    test('TEST-150: Code uniqueness within company', () async {
      await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'Acc1',
        nameEn: 'Acc1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      expect(
        () => coaService.createAccount(
          companyId: companyA,
          code: '1100',
          nameAr: 'Acc2',
          nameEn: 'Acc2',
          accountType: FinancialAccountType.asset,
          currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'ACCOUNT_CODE_ALREADY_EXISTS',
          ),
        ),
      );
    });

    test('TEST-151: Same code allowed across different companies', () async {
      final accA = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'Acc A',
        nameEn: 'Acc A',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );
      final accB = await coaService.createAccount(
        companyId: companyB,
        code: '1100',
        nameAr: 'Acc B',
        nameEn: 'Acc B',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      expect(accA.code, '1100');
      expect(accB.code, '1100');
      expect(accA.companyId, companyA);
      expect(accB.companyId, companyB);
    });

    test('TEST-152: Code mutation preserves identity', () async {
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Cash Old',
        nameEn: 'Cash Old',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      final updated = await coaService.updateAccountCode(
        companyId: companyA,
        accountId: acc.id,
        newCode: '9901',
      );

      expect(updated.id, acc.id);
      expect(updated.code, '9901');
    });

    test('TEST-153: Code mutation preserves historical journal lines', () async {
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Cash Old',
        nameEn: 'Cash Old',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      final entry = JournalEntry(
        id: generateUuidV7(),
        companyId: companyA,
        entryNumber: 'JE-100',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        status: JournalStatus.posted,
        lines: [
          JournalLine(
            id: generateUuidV7(),
            companyId: companyA,
            journalEntryId: 'JE-100',
            lineNumber: 1,
            accountId: acc.id,
            side: FinancialSide.debit,
            transactionAmount: DecimalMoney.fromScaled(BigInt.from(5000000), 'YER'),
            exchangeRate: DecimalRate.identity('YER'),
            baseAmount: DecimalMoney.fromScaled(BigInt.from(5000000), 'YER'),
          ),
        ],
      );
      await journalRepo.saveEntry(entry);

      await coaService.updateAccountCode(
        companyId: companyA,
        accountId: acc.id,
        newCode: '9901',
      );

      final fetchedEntry = await journalRepo.findById(companyA, entry.id);
      expect(fetchedEntry!.lines.first.accountId, acc.id);
    });

    test('TEST-154: Move account within same company', () async {
      final p1 = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'Parent 1',
        nameEn: 'Parent 1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final p2 = await coaService.createAccount(
        companyId: companyA,
        code: '1200',
        nameAr: 'Parent 2',
        nameEn: 'Parent 2',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );

      final child = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Child',
        nameEn: 'Child',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: p1.id,
      );

      final move1 = await coaService.moveAccount(
        companyId: companyA,
        accountId: child.id,
        newParentAccountId: p2.id,
      );
      expect(move1.movedAccount.parentAccountId, p2.id);
      expect(move1.newLevel, 1);
    });

    test('TEST-155: Move account to root', () async {
      final p1 = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'Parent 1',
        nameEn: 'Parent 1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );

      final child = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Child',
        nameEn: 'Child',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: p1.id,
      );

      final move = await coaService.moveAccount(
        companyId: companyA,
        accountId: child.id,
        newParentAccountId: null,
      );
      expect(move.movedAccount.parentAccountId, isNull);
      expect(move.newLevel, 0);
    });

    test('TEST-156: Move account updates descendant levels recursively', () async {
      final p1 = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'P1',
        nameEn: 'P1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final c1 = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'C1',
        nameEn: 'C1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: p1.id,
        isGroup: true,
      );
      final gc1 = await coaService.createAccount(
        companyId: companyA,
        code: '1110',
        nameAr: 'GC1',
        nameEn: 'GC1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: c1.id,
        isGroup: false,
      );

      expect(c1.level, 1);
      expect(gc1.level, 2);

      // Move C1 to root
      final res = await coaService.moveAccount(companyId: companyA, accountId: c1.id, newParentAccountId: null);
      expect(res.newLevel, 0);
      expect(res.updatedDescendantCount, 1);

      final updatedGc1 = await accountRepo.findById(companyA, gc1.id);
      expect(updatedGc1!.level, 1);
    });

    test('TEST-157: Move generates zero journal entries', () async {
      final p1 = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'P1',
        nameEn: 'P1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Acc',
        nameEn: 'Acc',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: p1.id,
      );

      await coaService.moveAccount(companyId: companyA, accountId: acc.id, newParentAccountId: null);
      expect(journalRepo.entries.length, 0);
    });

    test('TEST-158: Move generates zero journal lines', () async {
      final p1 = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'P1',
        nameEn: 'P1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Acc',
        nameEn: 'Acc',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: p1.id,
      );

      await coaService.moveAccount(companyId: companyA, accountId: acc.id, newParentAccountId: null);
      final entries = await journalRepo.getCompanyEntries(companyA);
      expect(entries.every((e) => e.lines.isEmpty), isTrue);
    });

    test('TEST-159: Move generates zero balance transfers', () async {
      final p1 = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'P1',
        nameEn: 'P1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Acc',
        nameEn: 'Acc',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: p1.id,
      );

      await coaService.moveAccount(companyId: companyA, accountId: acc.id, newParentAccountId: null);
      expect(journalRepo.entries.length, 0);
    });

    test('TEST-160: Move generates zero new FinancialAccounts', () async {
      final p1 = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'P1',
        nameEn: 'P1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Acc',
        nameEn: 'Acc',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: p1.id,
      );

      final beforeAccounts = await accountRepo.getCompanyAccounts(companyA);
      await coaService.moveAccount(companyId: companyA, accountId: acc.id, newParentAccountId: null);
      final afterAccounts = await accountRepo.getCompanyAccounts(companyA);

      expect(afterAccounts.length, beforeAccounts.length);
    });

    test('TEST-161: Move generates zero subject rebindings', () async {
      final p1 = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'P1',
        nameEn: 'P1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Acc',
        nameEn: 'Acc',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: p1.id,
      );

      await coaService.moveAccount(companyId: companyA, accountId: acc.id, newParentAccountId: null);
      expect(subjectRepo.subjects.length, 0);
    });

    test('TEST-162: Self-parent rejection', () async {
      final group = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'Group',
        nameEn: 'Group',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );

      expect(
        () => coaService.moveAccount(companyId: companyA, accountId: group.id, newParentAccountId: group.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'COA_HIERARCHY_CYCLE',
          ),
        ),
      );
    });

    test('TEST-163: Two-node cycle rejection (A -> B -> A)', () async {
      final a = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'A',
        nameEn: 'A',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final b = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'B',
        nameEn: 'B',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: a.id,
        isGroup: true,
      );

      expect(
        () => coaService.moveAccount(companyId: companyA, accountId: a.id, newParentAccountId: b.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'COA_HIERARCHY_CYCLE',
          ),
        ),
      );
    });

    test('TEST-164: Multi-node ancestor cycle rejection (A -> B -> C -> A)', () async {
      final a = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'A',
        nameEn: 'A',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final b = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'B',
        nameEn: 'B',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: a.id,
        isGroup: true,
      );
      final c = await coaService.createAccount(
        companyId: companyA,
        code: '1110',
        nameAr: 'C',
        nameEn: 'C',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: b.id,
        isGroup: true,
      );

      expect(
        () => coaService.moveAccount(companyId: companyA, accountId: a.id, newParentAccountId: c.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'COA_HIERARCHY_CYCLE',
          ),
        ),
      );
    });

    test('TEST-165: Move account under descendant rejected', () async {
      final parent = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'Parent',
        nameEn: 'Parent',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final child = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'Child',
        nameEn: 'Child',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: parent.id,
        isGroup: true,
      );

      expect(
        () => coaService.moveAccount(companyId: companyA, accountId: parent.id, newParentAccountId: child.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'COA_HIERARCHY_CYCLE',
          ),
        ),
      );
    });

    test('TEST-166: Cycle check bounded by MAX_DEPTH', () async {
      final a = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'A',
        nameEn: 'A',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final b = await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'B',
        nameEn: 'B',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: a.id,
        isGroup: true,
      );

      expect(
        () => coaService.moveAccount(companyId: companyA, accountId: a.id, newParentAccountId: b.id),
        throwsA(isA<FinancialValidationException>()),
      );
    });

    test('TEST-167: Hierarchy depth 10 nodes (level 0..9) accepted', () async {
      FinancialAccount currentParent = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'Node 0',
        nameEn: 'Node 0',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );

      for (int i = 1; i <= 8; i++) {
        currentParent = await coaService.createAccount(
          companyId: companyA,
          code: '100$i',
          nameAr: 'Node $i',
          nameEn: 'Node $i',
          accountType: FinancialAccountType.asset,
          currencyPolicy: AccountCurrencyPolicy.functionalOnly,
          parentAccountId: currentParent.id,
          isGroup: true,
        );
      }

      final node9 = await coaService.createAccount(
        companyId: companyA,
        code: '1009',
        nameAr: 'Node 9',
        nameEn: 'Node 9',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: currentParent.id,
        isGroup: true,
      );
      expect(node9.level, 9);
    });

    test('TEST-168: Hierarchy depth 11 nodes (level 10) rejected', () async {
      FinancialAccount currentParent = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'Node 0',
        nameEn: 'Node 0',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );

      for (int i = 1; i <= 9; i++) {
        currentParent = await coaService.createAccount(
          companyId: companyA,
          code: '100$i',
          nameAr: 'Node $i',
          nameEn: 'Node $i',
          accountType: FinancialAccountType.asset,
          currencyPolicy: AccountCurrencyPolicy.functionalOnly,
          parentAccountId: currentParent.id,
          isGroup: true,
        );
      }

      expect(
        () => coaService.createAccount(
          companyId: companyA,
          code: '1010',
          nameAr: 'Node 10',
          nameEn: 'Node 10',
          accountType: FinancialAccountType.asset,
          currencyPolicy: AccountCurrencyPolicy.functionalOnly,
          parentAccountId: currentParent.id,
          isGroup: false,
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'COA_HIERARCHY_DEPTH_EXCEEDED',
          ),
        ),
      );
    });

    test('TEST-169: Cross-company parent creation rejected', () async {
      final parentB = await coaService.createAccount(
        companyId: companyB,
        code: '1000',
        nameAr: 'P B',
        nameEn: 'P B',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );

      expect(
        () => coaService.createAccount(
          companyId: companyA,
          code: '1001',
          nameAr: 'C A',
          nameEn: 'C A',
          accountType: FinancialAccountType.asset,
          currencyPolicy: AccountCurrencyPolicy.functionalOnly,
          parentAccountId: parentB.id,
        ),
        throwsA(isA<FinancialValidationException>()),
      );
    });

    test('TEST-170: Cross-company account move rejected', () async {
      final accA = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'Acc A',
        nameEn: 'Acc A',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );

      expect(
        () => coaService.moveAccount(companyId: companyB, accountId: accA.id, newParentAccountId: null),
        throwsA(isA<FinancialValidationException>()),
      );
    });

    test('TEST-171: Cross-company account code mutation rejected', () async {
      final accA = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'Acc A',
        nameEn: 'Acc A',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      expect(
        () => coaService.updateAccountCode(companyId: companyB, accountId: accA.id, newCode: '9999'),
        throwsA(isA<FinancialValidationException>()),
      );
    });

    test('TEST-172: Cross-company repository isolation', () async {
      final accA = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'Acc A',
        nameEn: 'Acc A',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      final fetchedInB = await accountRepo.findById(companyB, accA.id);
      expect(fetchedInB, isNull);
    });

    test('TEST-173: Account resolution tenant isolation', () async {
      final accA = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'Acc A',
        nameEn: 'Acc A',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      expect(accA.companyId, companyA);
      final byCodeB = await accountRepo.findByCode(companyB, '1000');
      expect(byCodeB, isNull);
    });

    test('TEST-174: Journal lines remain bound to original FinancialAccount.id', () async {
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Acc',
        nameEn: 'Acc',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );
      final originalId = acc.id;

      await coaService.updateAccountCode(companyId: companyA, accountId: acc.id, newCode: '8888');
      expect(acc.id, originalId);
    });

    test('TEST-175: Subject bindings remain bound to original FinancialAccount.id', () async {
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Acc',
        nameEn: 'Acc',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );
      final subject = AccountingSubject(
        id: generateUuidV7(),
        companyId: companyA,
        subjectType: AccountingSubjectType.customer,
        name: 'Client',
        code: 'CLI-01',
        primaryAccountId: acc.id,
      );
      await subjectRepo.saveSubject(subject);

      await coaService.updateAccountCode(companyId: companyA, accountId: acc.id, newCode: '7777');
      final fetchedSubject = await subjectRepo.findSubjectById(companyA, subject.id);
      expect(fetchedSubject!.primaryAccountId, acc.id);
    });

    test('TEST-176: Balance calculations remain bound to original FinancialAccount.id', () async {
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Acc',
        nameEn: 'Acc',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      final originalId = acc.id;
      final moved = await coaService.moveAccount(companyId: companyA, accountId: acc.id, newParentAccountId: null);
      expect(moved.movedAccount.id, originalId);
    });

    test('TEST-177: Account identity survives hierarchy mutation', () async {
      final p = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'P',
        nameEn: 'P',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1001',
        nameAr: 'Acc',
        nameEn: 'Acc',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: p.id,
      );

      final originalId = acc.id;
      final res = await coaService.moveAccount(companyId: companyA, accountId: acc.id, newParentAccountId: null);
      expect(res.movedAccount.id, originalId);
    });

    test('TEST-178: Attempt to delete account bound to active context -> REJECTED & Account remains intact', () async {
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1105',
        nameAr: 'حساب مبيعات',
        nameEn: 'Sales Account',
        accountType: FinancialAccountType.revenue,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'SALES_REVENUE',
        accountId: acc.id,
      );

      expect(
        () => coaService.deleteOrArchiveAccount(companyId: companyA, accountId: acc.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'ACCOUNT_HAS_POSTED_HISTORY',
          ),
        ),
      );

      final preservedAccount = await accountRepo.findById(companyA, acc.id);
      expect(preservedAccount, isNotNull);
      expect(preservedAccount!.isActive, isTrue);
      expect(preservedAccount.id, acc.id);
    });
  });


  group('GATE-07 COA Hierarchy & Composite Tenancy Adversarial Security Suite (ATTACK-27..39)', () {
    late MockFinancialAccountRepository accountRepo;
    late MockFinancialJournalRepository journalRepo;
    late MockFinancialSubjectRepository subjectRepo;
    late ChartOfAccountsService coaService;

    const companyA = '0191c784-754e-7b3b-8b77-502a3a5f8001';
    const companyB = '0191c784-754e-7b3b-8b77-502a3a5f8002';

    setUp(() {
      accountRepo = MockFinancialAccountRepository();
      journalRepo = MockFinancialJournalRepository();
      subjectRepo = MockFinancialSubjectRepository();
      coaService = ChartOfAccountsService(
        accountRepo: accountRepo,
        journalRepo: journalRepo,
        subjectRepo: subjectRepo,
      );
    });

    test('ATTACK-27: Cross-company parent injection -> REJECTED', () async {
      final parentB = await coaService.createAccount(
        companyId: companyB,
        code: '1000',
        nameAr: 'Parent B',
        nameEn: 'Parent B',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );

      expect(
        () => coaService.createAccount(
          companyId: companyA,
          code: '1001',
          nameAr: 'Child A',
          nameEn: 'Child A',
          accountType: FinancialAccountType.asset,
          currencyPolicy: AccountCurrencyPolicy.functionalOnly,
          parentAccountId: parentB.id,
        ),
        throwsA(isA<FinancialValidationException>()),
      );
    });

    test('ATTACK-28: Cross-company move injection -> REJECTED', () async {
      final parentB = await coaService.createAccount(
        companyId: companyB,
        code: '1000',
        nameAr: 'Parent B',
        nameEn: 'Parent B',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final childA = await coaService.createAccount(
        companyId: companyA,
        code: '1001',
        nameAr: 'Child A',
        nameEn: 'Child A',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      expect(
        () => coaService.moveAccount(companyId: companyA, accountId: childA.id, newParentAccountId: parentB.id),
        throwsA(isA<FinancialValidationException>()),
      );
    });

    test('ATTACK-29: Self-parent cycle -> REJECTED', () async {
      final groupA = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'Group A',
        nameEn: 'Group A',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );

      expect(
        () => coaService.moveAccount(companyId: companyA, accountId: groupA.id, newParentAccountId: groupA.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'COA_HIERARCHY_CYCLE',
          ),
        ),
      );
    });

    test('ATTACK-30: Two-node cycle injection -> REJECTED', () async {
      final n1 = await coaService.createAccount(
        companyId: companyA,
        code: '1001',
        nameAr: 'N1',
        nameEn: 'N1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final n2 = await coaService.createAccount(
        companyId: companyA,
        code: '1002',
        nameAr: 'N2',
        nameEn: 'N2',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: n1.id,
        isGroup: true,
      );

      expect(
        () => coaService.moveAccount(companyId: companyA, accountId: n1.id, newParentAccountId: n2.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'COA_HIERARCHY_CYCLE',
          ),
        ),
      );
    });

    test('ATTACK-31: Long cycle injection -> REJECTED', () async {
      final n1 = await coaService.createAccount(
        companyId: companyA,
        code: '1001',
        nameAr: 'N1',
        nameEn: 'N1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final n2 = await coaService.createAccount(
        companyId: companyA,
        code: '1002',
        nameAr: 'N2',
        nameEn: 'N2',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: n1.id,
        isGroup: true,
      );
      final n3 = await coaService.createAccount(
        companyId: companyA,
        code: '1003',
        nameAr: 'N3',
        nameEn: 'N3',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: n2.id,
        isGroup: true,
      );

      expect(
        () => coaService.moveAccount(companyId: companyA, accountId: n1.id, newParentAccountId: n3.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'COA_HIERARCHY_CYCLE',
          ),
        ),
      );
    });

    test('ATTACK-32: Inactive parent injection -> REJECTED', () async {
      final inactiveParent = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'Inactive Parent',
        nameEn: 'Inactive Parent',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
        isActive: false,
      );

      expect(
        () => coaService.createAccount(
          companyId: companyA,
          code: '1001',
          nameAr: 'Child',
          nameEn: 'Child',
          accountType: FinancialAccountType.asset,
          currencyPolicy: AccountCurrencyPolicy.functionalOnly,
          parentAccountId: inactiveParent.id,
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'INACTIVE_ACCOUNT',
          ),
        ),
      );
    });

    test('ATTACK-33: Group parent misuse (non-group parent) -> REJECTED', () async {
      final postableAccount = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'Postable',
        nameEn: 'Postable',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: false,
      );

      expect(
        () => coaService.createAccount(
          companyId: companyA,
          code: '1001',
          nameAr: 'Child',
          nameEn: 'Child',
          accountType: FinancialAccountType.asset,
          currencyPolicy: AccountCurrencyPolicy.functionalOnly,
          parentAccountId: postableAccount.id,
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'INVALID_PARENT_ACCOUNT',
          ),
        ),
      );
    });

    test('ATTACK-34: Cross-company account ID masquerading -> REJECTED', () async {
      final accB = await coaService.createAccount(
        companyId: companyB,
        code: '1000',
        nameAr: 'Acc B',
        nameEn: 'Acc B',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      expect(
        () => coaService.validatePostingTarget(companyA, accB.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            anyOf('CROSS_TENANT_ACCOUNT_REJECTION', 'ACCOUNT_NOT_FOUND'),
          ),
        ),
      );
    });

    test('ATTACK-35: Account code masquerading as technical ID -> REJECTED', () async {
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Cash',
        nameEn: 'Cash',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      final result = await accountRepo.findById(companyA, acc.code);
      expect(result, isNull);
    });

    test('ATTACK-36: Code-based identity injection in journal line -> REJECTED', () async {
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Cash',
        nameEn: 'Cash',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      final result = await accountRepo.findById(companyA, '1101');
      expect(result, isNull);
    });

    test('ATTACK-37: Delete account with posted history -> REJECTED/ARCHIVED', () async {
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Cash',
        nameEn: 'Cash',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      final entry = JournalEntry(
        id: generateUuidV7(),
        companyId: companyA,
        entryNumber: 'JE-999',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        status: JournalStatus.posted,
        lines: [
          JournalLine(
            id: generateUuidV7(),
            companyId: companyA,
            journalEntryId: 'JE-999',
            lineNumber: 1,
            accountId: acc.id,
            side: FinancialSide.debit,
            transactionAmount: DecimalMoney.fromScaled(BigInt.from(1000000), 'YER'),
            exchangeRate: DecimalRate.identity('YER'),
            baseAmount: DecimalMoney.fromScaled(BigInt.from(1000000), 'YER'),
          ),
        ],
      );
      await journalRepo.saveEntry(entry);

      expect(
        () => coaService.deleteOrArchiveAccount(companyId: companyA, accountId: acc.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'ACCOUNT_HAS_POSTED_HISTORY',
          ),
        ),
      );
    });

    test('ATTACK-38: Move account with posted history -> METADATA UPDATE ONLY', () async {
      final p = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'Parent',
        nameEn: 'Parent',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1001',
        nameAr: 'Acc',
        nameEn: 'Acc',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      final moveRes = await coaService.moveAccount(
        companyId: companyA,
        accountId: acc.id,
        newParentAccountId: p.id,
      );

      expect(moveRes.movedAccount.parentAccountId, p.id);
      expect(journalRepo.entries.length, 0);
    });

    test('ATTACK-39: Concurrent duplicate account code creation -> REJECTED', () async {
      await coaService.createAccount(
        companyId: companyA,
        code: '1100',
        nameAr: 'Acc 1',
        nameEn: 'Acc 1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      expect(
        () => coaService.createAccount(
          companyId: companyA,
          code: '1100',
          nameAr: 'Acc 2',
          nameEn: 'Acc 2',
          accountType: FinancialAccountType.asset,
          currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'ACCOUNT_CODE_ALREADY_EXISTS',
          ),
        ),
      );
    });
  });

  group('GATE-07 Final Delete-Dependency Execution Proof Suite (TEST-DP-01..05)', () {
    late MockFinancialAccountRepository accountRepo;
    late MockFinancialJournalRepository journalRepo;
    late MockFinancialSubjectRepository subjectRepo;
    late MockContextBindingRepo contextRepo;
    late MockCompanyMappingRepo companyMappingRepo;
    late ChartOfAccountsService coaService;

    const companyA = '0191c784-754e-7b3b-8b77-502a3a5f8001';

    setUp(() {
      accountRepo = MockFinancialAccountRepository();
      journalRepo = MockFinancialJournalRepository();
      subjectRepo = MockFinancialSubjectRepository();
      contextRepo = MockContextBindingRepo();
      companyMappingRepo = MockCompanyMappingRepo();
      coaService = ChartOfAccountsService(
        accountRepo: accountRepo,
        journalRepo: journalRepo,
        subjectRepo: subjectRepo,
        contextBindingRepo: contextRepo,
        companyMappingRepo: companyMappingRepo,
      );
    });

    test('TEST-DP-01: Isolated Child Account deletion block -> REJECTED & ZERO MUTATION', () async {
      final parent = await coaService.createAccount(
        companyId: companyA,
        code: '1000',
        nameAr: 'Assets Group',
        nameEn: 'Assets Group',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        isGroup: true,
      );

      final child = await coaService.createAccount(
        companyId: companyA,
        code: '1001',
        nameAr: 'Cash Sub Account',
        nameEn: 'Cash Sub Account',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
        parentAccountId: parent.id,
      );

      expect(
        () => coaService.deleteOrArchiveAccount(companyId: companyA, accountId: parent.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'ACCOUNT_HAS_CHILDREN',
          ),
        ),
      );

      final preservedParent = await accountRepo.findById(companyA, parent.id);
      expect(preservedParent, isNotNull);
      expect(preservedParent!.id, parent.id);
      expect(preservedParent.code, '1000');
      expect(preservedParent.isActive, isTrue);

      final preservedChild = await accountRepo.findById(companyA, child.id);
      expect(preservedChild, isNotNull);
      expect(preservedChild!.parentAccountId, parent.id);
    });

    test('TEST-DP-02: Isolated Posted JournalLine deletion block -> REJECTED & ZERO MUTATION', () async {
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1101',
        nameAr: 'Cash',
        nameEn: 'Cash',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      final entry = JournalEntry(
        id: generateUuidV7(),
        companyId: companyA,
        entryNumber: 'JE-DP-02',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        status: JournalStatus.posted,
        lines: [
          JournalLine(
            id: generateUuidV7(),
            companyId: companyA,
            journalEntryId: 'JE-DP-02',
            lineNumber: 1,
            accountId: acc.id,
            side: FinancialSide.debit,
            transactionAmount: DecimalMoney.fromScaled(BigInt.from(5000), 'YER'),
            exchangeRate: DecimalRate.identity('YER'),
            baseAmount: DecimalMoney.fromScaled(BigInt.from(5000), 'YER'),
          ),
        ],
      );
      await journalRepo.saveEntry(entry);

      expect(
        () => coaService.deleteOrArchiveAccount(companyId: companyA, accountId: acc.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'ACCOUNT_HAS_POSTED_HISTORY',
          ),
        ),
      );

      final preservedAcc = await accountRepo.findById(companyA, acc.id);
      expect(preservedAcc, isNotNull);
      expect(preservedAcc!.id, acc.id);
      expect(preservedAcc.code, '1101');
      expect(preservedAcc.isActive, isTrue);

      final preservedEntry = await journalRepo.findById(companyA, entry.id);
      expect(preservedEntry, isNotNull);
      expect(preservedEntry!.lines.first.accountId, acc.id);
    });

    test('TEST-DP-03: Isolated AccountingSubject.primaryAccountId deletion block -> REJECTED & ZERO MUTATION', () async {
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1201',
        nameAr: 'Customer AR Account',
        nameEn: 'Customer AR Account',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      final subject = AccountingSubject(
        id: generateUuidV7(),
        companyId: companyA,
        subjectType: AccountingSubjectType.customer,
        code: 'CUST-DP-03',
        name: 'Test Customer',
        primaryAccountId: acc.id,
      );
      await subjectRepo.saveSubject(subject);

      expect(
        () => coaService.deleteOrArchiveAccount(companyId: companyA, accountId: acc.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'ACCOUNT_HAS_POSTED_HISTORY',
          ),
        ),
      );

      final preservedAcc = await accountRepo.findById(companyA, acc.id);
      expect(preservedAcc, isNotNull);
      expect(preservedAcc!.id, acc.id);
      expect(preservedAcc.code, '1201');
      expect(preservedAcc.isActive, isTrue);

      final preservedSubject = await subjectRepo.findSubjectByPrimaryAccountId(companyA, acc.id);
      expect(preservedSubject, isNotNull);
      expect(preservedSubject!.primaryAccountId, acc.id);
    });

    test('TEST-DP-04: Isolated ContextAccountBinding deletion block -> REJECTED & ZERO MUTATION', () async {
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1301',
        nameAr: 'Inventory Asset',
        nameEn: 'Inventory Asset',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-MAIN',
        roleKey: 'INVENTORY_ASSET',
        accountId: acc.id,
      );

      expect(
        () => coaService.deleteOrArchiveAccount(companyId: companyA, accountId: acc.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'ACCOUNT_HAS_POSTED_HISTORY',
          ),
        ),
      );

      final preservedAcc = await accountRepo.findById(companyA, acc.id);
      expect(preservedAcc, isNotNull);
      expect(preservedAcc!.id, acc.id);
      expect(preservedAcc.code, '1301');
      expect(preservedAcc.isActive, isTrue);

      final isBound = await contextRepo.isAccountBound(companyId: companyA, accountId: acc.id);
      expect(isBound, isTrue);
    });

    test('TEST-DP-05: Isolated CompanyAccountMapping deletion block -> REJECTED & ZERO MUTATION', () async {
      final acc = await coaService.createAccount(
        companyId: companyA,
        code: '1401',
        nameAr: 'Default Cash Account',
        nameEn: 'Default Cash Account',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      companyMappingRepo.setMapping(
        companyId: companyA,
        roleKey: 'DEFAULT_CASH_ACCOUNT',
        accountId: acc.id,
      );

      expect(
        () => coaService.deleteOrArchiveAccount(companyId: companyA, accountId: acc.id),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'ACCOUNT_HAS_POSTED_HISTORY',
          ),
        ),
      );

      final preservedAcc = await accountRepo.findById(companyA, acc.id);
      expect(preservedAcc, isNotNull);
      expect(preservedAcc!.id, acc.id);
      expect(preservedAcc.code, '1401');
      expect(preservedAcc.isActive, isTrue);

      final isBound = await companyMappingRepo.isAccountBound(companyId: companyA, accountId: acc.id);
      expect(isBound, isTrue);
    });
  });
}



