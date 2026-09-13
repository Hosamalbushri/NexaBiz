import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/ports/period_validator_port.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/shared/contracts/errors/journal_exception.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_failure.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_lifecycle_state.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_policy_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

class FakeCompanyInitRepository implements CompanyInitializationRepository {
  CompanyAccountingConfig? config;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<CompanyAccountingConfig?> getAccountingConfig() async => config;

  @override
  Future<void> saveAccountingConfig(CompanyAccountingConfig config) async {
    this.config = config;
  }

  @override
  Future<bool> isCompanyInitialized() async => config != null;
}


class FakePeriodValidator implements PeriodValidatorPort {
  bool allowPosting = true;

  @override
  Future<void> assertEntryAllowed(DateTime entryDate) async {
    if (!allowPosting) {
      throw JournalException(
        JournalException.periodClosed,
        'Period is closed for date $entryDate',
      );
    }
  }

  @override
  Future<void> assertMutationAllowed({
    required DateTime entryDate,
    DateTime? originalDate,
  }) async {
    await assertEntryAllowed(entryDate);
  }
}

void main() {
  late FakeCompanyInitRepository fakeInitRepo;
  late FakePeriodValidator fakePeriodValidator;
  late AccountingPolicy policy;

  final validCompanyId = 'comp-uuid-100';
  final validDate = DateTime.utc(2026, 9, 12);

  final completeConfig = CompanyAccountingConfig(
    companyId: validCompanyId,
    accountMappings: const {
      AccountRole.inventory: 'acc-inv-01',
      AccountRole.cogs: 'acc-cogs-01',
      AccountRole.revenue: 'acc-rev-01',
      AccountRole.receivable: 'acc-ar-01',
      AccountRole.payable: 'acc-ap-01',
      AccountRole.cash: 'acc-cash-01',
      AccountRole.adjustment: 'acc-adj-01',
      AccountRole.fxGainLoss: 'acc-fx-01',
    },
  );

  final incompleteConfig = CompanyAccountingConfig(
    companyId: validCompanyId,
    accountMappings: const {
      AccountRole.inventory: 'acc-inv-01',
    },
  );

  setUp(() {
    fakeInitRepo = FakeCompanyInitRepository();
    fakePeriodValidator = FakePeriodValidator();
    policy = AccountingPolicy(
      initRepository: fakeInitRepo,
      periodValidator: fakePeriodValidator,
    );
  });

  group('Accounting Lifecycle State Tests', () {
    test('returns notConfigured when company has no configuration', () async {
      final state = await policy.getLifecycleState(validCompanyId);
      expect(state, AccountingLifecycleState.notConfigured);
      expect(await policy.isConfigured(validCompanyId), isFalse);
      expect(await policy.isActive(validCompanyId), isFalse);
    });

    test('returns configuring when account mappings are incomplete', () async {
      fakeInitRepo.config = incompleteConfig;
      final state = await policy.getLifecycleState(validCompanyId);
      expect(state, AccountingLifecycleState.configuring);
      expect(await policy.isConfigured(validCompanyId), isFalse);
      expect(await policy.isActive(validCompanyId), isFalse);
    });


    test('returns active when account mappings are complete', () async {
      fakeInitRepo.config = completeConfig;
      final state = await policy.getLifecycleState(validCompanyId);
      expect(state, AccountingLifecycleState.active);
      expect(await policy.isConfigured(validCompanyId), isTrue);
      expect(await policy.isActive(validCompanyId), isTrue);
    });

    test('supports explicit suspended state override', () async {
      final suspendedPolicy = AccountingPolicy(
        initRepository: fakeInitRepo,
        explicitStateOverrides: {
          validCompanyId: AccountingLifecycleState.suspended,
        },
      );
      final state = await suspendedPolicy.getLifecycleState(validCompanyId);
      expect(state, AccountingLifecycleState.suspended);
      expect(state.isSuspended, isTrue);
      expect(await suspendedPolicy.isActive(validCompanyId), isFalse);
    });
  });

  group('Accounting Optionality Tests', () {
    test('returns clean skipped decision when accounting is not configured', () async {
      final decision = await policy.evaluatePostingPermission(
        companyId: validCompanyId,
        transactionDate: validDate,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.isSkippedBecauseDisabled, isTrue);
      expect(decision.lifecycleState, AccountingLifecycleState.notConfigured);
    });
  });

  group('Posting Permission & Policy Checks', () {
    test('permits posting when accounting is active and period open', () async {
      fakeInitRepo.config = completeConfig;
      fakePeriodValidator.allowPosting = true;

      final decision = await policy.evaluatePostingPermission(
        companyId: validCompanyId,
        transactionDate: validDate,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      expect(decision.isAllowed, isTrue);
      expect(decision.isSkippedBecauseDisabled, isFalse);
      expect(decision.lifecycleState, AccountingLifecycleState.active);
    });

    test('denies posting when accounting is incomplete (configuring)', () async {
      fakeInitRepo.config = incompleteConfig;

      final decision = await policy.evaluatePostingPermission(
        companyId: validCompanyId,
        transactionDate: validDate,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.failure, isA<InvalidAccountingEffectFailure>());
    });

    test('denies posting when period is closed', () async {
      fakeInitRepo.config = completeConfig;
      fakePeriodValidator.allowPosting = false;

      final decision = await policy.evaluatePostingPermission(
        companyId: validCompanyId,
        transactionDate: validDate,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.failure, isA<ClosedAccountingPeriodFailure>());
    });

    test('denies posting when transaction date is out of bounds', () async {
      fakeInitRepo.config = completeConfig;

      final decision = await policy.evaluatePostingPermission(
        companyId: validCompanyId,
        transactionDate: DateTime.utc(1998, 1, 1),
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.failure, isA<InvalidTransactionDateFailure>());
    });

    test('denies posting on illegal fallback company ID', () async {
      fakeInitRepo.config = completeConfig;

      final decision = await policy.evaluatePostingPermission(
        companyId: 'legacy_company',
        transactionDate: validDate,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.failure, isA<MissingCompanyScopeFailure>());
    });

    test('denies posting when currency is fallback or invalid', () async {
      fakeInitRepo.config = completeConfig;

      final decision = await policy.evaluatePostingPermission(
        companyId: validCompanyId,
        transactionDate: validDate,
        currencyCode: 'FALLBACK',
        baseCurrencyCode: 'USD',
      );

      expect(decision.isAllowed, isFalse);
      expect(decision.failure, isA<InvalidAccountingEffectFailure>());
    });
  });
}
