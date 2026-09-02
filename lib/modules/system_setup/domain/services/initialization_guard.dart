import '../entities/company_initialization_state.dart';
import '../repositories/company_initialization_repository.dart';
import 'initialization_validator.dart';

/// Exception thrown when operational inventory/financial domain services are invoked
/// prior to completing mandatory company initialization.
class UninitializedCompanyException implements Exception {
  const UninitializedCompanyException({
    required this.companyId,
    required this.missingRequirements,
  });

  final String companyId;
  final List<String> missingRequirements;

  @override
  String toString() =>
      'UninitializedCompanyException: Operational action blocked for company ($companyId) — Missing setup: ${missingRequirements.join(', ')}';
}

/// Domain boundary guard operating below UI to enforce company setup completion.
class InitializationGuard {
  InitializationGuard({
    required this._initRepository,
    this._validator = const InitializationValidator(),
  });

  final CompanyInitializationRepository _initRepository;
  final InitializationValidator _validator;

  /// Asserts that the active company context has completed all mandatory initialization gates.
  /// Throws [UninitializedCompanyException] if initialization is incomplete.
  Future<CompanyInitializationState> assertInitialized() async {
    final state = await _initRepository.getState();
    final invConfig = await _initRepository.getInventoryConfig();
    final accConfig = await _initRepository.getAccountingConfig();
    final whConfig = await _initRepository.getWarehouseConfig();

    final result = _validator.validate(
      state: state,
      inventoryConfig: invConfig,
      accountingConfig: accConfig,
      warehouseConfig: whConfig,
    );

    if (!result.isReady) {
      throw UninitializedCompanyException(
        companyId: state.companyId,
        missingRequirements: result.missingRequirements,
      );
    }

    return state;
  }

  /// Evaluates whether the active company initialization is complete.
  Future<bool> isInitialized() async {
    try {
      await assertInitialized();
      return true;
    } catch (_) {
      return false;
    }
  }
}
