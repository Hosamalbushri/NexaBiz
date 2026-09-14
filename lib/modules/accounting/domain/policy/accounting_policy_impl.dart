import '../../../../core/domain/ports/period_validator_port.dart';
import '../../../system_setup/domain/repositories/company_initialization_repository.dart';
import '../foundation/accounting_failure.dart';
import 'accounting_lifecycle_state.dart';
import 'accounting_policy_decision.dart';
import 'accounting_policy_port.dart';

/// Concrete implementation of [AccountingPolicyPort] providing authoritative configuration & policy decision logic.
class AccountingPolicy implements AccountingPolicyPort {
  AccountingPolicy({
    required this._initRepository,
    this._periodValidator,
    Map<String, AccountingLifecycleState>? explicitStateOverrides,
  })  : _explicitStateOverrides = explicitStateOverrides ?? {};

  final CompanyInitializationRepository _initRepository;
  final PeriodValidatorPort? _periodValidator;
  final Map<String, AccountingLifecycleState> _explicitStateOverrides;

  @override
  Future<AccountingLifecycleState> getLifecycleState(String companyId) async {
    final trimmedCompanyId = companyId.trim();
    if (trimmedCompanyId.isEmpty || _isIllegalCompanyId(trimmedCompanyId)) {
      return AccountingLifecycleState.notConfigured;
    }

    if (_explicitStateOverrides.containsKey(trimmedCompanyId)) {
      return _explicitStateOverrides[trimmedCompanyId]!;
    }

    final config = await _initRepository.getAccountingConfig();
    if (config == null || config.companyId != trimmedCompanyId) {
      return AccountingLifecycleState.notConfigured;
    }

    if (!config.isComplete) {
      return AccountingLifecycleState.configuring;
    }

    return AccountingLifecycleState.active;
  }

  @override
  Future<bool> isConfigured(String companyId) async {
    final state = await getLifecycleState(companyId);
    return state.isConfigured;
  }

  @override
  Future<bool> isActive(String companyId) async {
    final state = await getLifecycleState(companyId);
    return state.isActive;
  }

  @override
  Future<bool> areAccountMappingsConfigured(String companyId) async {
    final config = await _initRepository.getAccountingConfig();
    if (config == null || config.companyId != companyId.trim()) {
      return false;
    }
    return config.isComplete;
  }

  @override
  bool isValidTransactionDate(DateTime date) {
    return date.year >= 2000 && date.year <= 2100;
  }

  @override
  Future<bool> isValidCurrency({
    required String companyId,
    required String currencyCode,
    required String baseCurrencyCode,
  }) async {
    final cur = currencyCode.trim().toUpperCase();
    final base = baseCurrencyCode.trim().toUpperCase();
    if (cur.isEmpty || base.isEmpty) {
      return false;
    }
    if (cur == 'FALLBACK' || base == 'FALLBACK') {
      return false;
    }
    return true;
  }

  @override
  Future<bool> isPeriodOpen({
    required String companyId,
    required DateTime transactionDate,
  }) async {
    if (!isValidTransactionDate(transactionDate)) {
      return false;
    }
    final periodValidator = _periodValidator;
    if (periodValidator == null) {
      return true;
    }
    try {
      await periodValidator.assertEntryAllowed(transactionDate);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AccountingPolicyDecision> evaluatePostingPermission({
    required String companyId,
    required DateTime transactionDate,
    required String currencyCode,
    required String baseCurrencyCode,
  }) async {
    final trimmedCompanyId = companyId.trim();
    if (trimmedCompanyId.isEmpty || _isIllegalCompanyId(trimmedCompanyId)) {
      return AccountingPolicyDecision.denied(
        lifecycleState: AccountingLifecycleState.notConfigured,
        failure: const MissingCompanyScopeFailure(
          'Posting denied: invalid or missing company scope.',
        ),
      );
    }

    final state = await getLifecycleState(trimmedCompanyId);

    // Accounting optionality: if disabled / not configured, signal clean skip
    if (state == AccountingLifecycleState.notConfigured) {
      return AccountingPolicyDecision.disabledSkipped();
    }

    if (state == AccountingLifecycleState.suspended) {
      return AccountingPolicyDecision.denied(
        lifecycleState: state,
        failure: const AccountingPermissionDeniedFailure(
          'Posting denied: accounting is suspended for this company.',
        ),
      );
    }

    if (state == AccountingLifecycleState.configuring) {
      return AccountingPolicyDecision.denied(
        lifecycleState: state,
        failure: const InvalidAccountingEffectFailure(
          'Posting denied: accounting configuration is incomplete.',
        ),
      );
    }

    if (!isValidTransactionDate(transactionDate)) {
      return AccountingPolicyDecision.denied(
        lifecycleState: state,
        failure: InvalidTransactionDateFailure(
          'Posting denied: transaction date $transactionDate is outside valid operational bounds.',
        ),
      );
    }

    final validCurrency = await isValidCurrency(
      companyId: trimmedCompanyId,
      currencyCode: currencyCode,
      baseCurrencyCode: baseCurrencyCode,
    );
    if (!validCurrency) {
      return AccountingPolicyDecision.denied(
        lifecycleState: state,
        failure: const InvalidAccountingEffectFailure(
          'Posting denied: invalid or fallback currency context.',
        ),
      );
    }

    final periodOpen = await isPeriodOpen(
      companyId: trimmedCompanyId,
      transactionDate: transactionDate,
    );
    if (!periodOpen) {
      return AccountingPolicyDecision.denied(
        lifecycleState: state,
        failure: ClosedAccountingPeriodFailure(
          'Posting denied: accounting period for date $transactionDate is closed or outside fiscal year.',
        ),
      );
    }

    return AccountingPolicyDecision.allowed(lifecycleState: state);
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
