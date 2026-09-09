import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/tenancy/session_company.dart';
import 'package:stock_count/core/auth/presentation/providers/auth_state_core.dart';
import '../../domain/entities/currency.dart';
import 'currency_providers.dart';

/// All 5 explicit configuration states required by CURRENCY-UI-03.
enum FunctionalCurrencyConfigState {
  /// Functional currency is set, valid, and active.
  configured,

  /// Functional currency code is empty (not configured).
  /// CRITICAL: No currency is assumed or defaulted (never defaults to YER).
  notConfigured,

  /// Configured functional currency code does not exist in master data.
  invalidConfig,

  /// Configured functional currency exists but is inactive in master data.
  currencyInactive,

  /// Posted accounting activity exists; changing functional currency is locked.
  changeRestricted,
}

class FunctionalCurrencyStateInfo {
  const FunctionalCurrencyStateInfo({
    required this.configState,
    this.currency,
    required this.currencyCode,
    required this.hasPostedActivity,
    this.errorMessage,
    required this.canModify,
  });

  final FunctionalCurrencyConfigState configState;
  final Currency? currency;
  final String currencyCode;
  final bool hasPostedActivity;
  final String? errorMessage;
  final bool canModify;

  bool get isLocked =>
      hasPostedActivity ||
      configState == FunctionalCurrencyConfigState.changeRestricted;
}

final functionalCurrencyStateInfoProvider =
    FutureProvider.autoDispose<FunctionalCurrencyStateInfo>((ref) async {
      final companyId = ref.watch(sessionCompanyIdProvider) ?? '';
      final currencyRepo = ref.watch(currencyRepositoryProvider);
      final service = ref.watch(functionalCurrencyServiceProvider);

      // Check RBAC permissions / user role
      final authState = ref.watch(authStateProvider);
      final isSuperAdmin = authState.session?.user.isSuperAdmin ?? false;
      final hasPerm =
          authState.hasPermission('platform.company.manage') ||
          authState.hasPermission('accounting.fiscal_years.configure_fx') ||
          authState.hasPermission('currency.functional.configure');
      final canModify = isSuperAdmin || hasPerm;

      final hasPosted = await service.hasPostedAccountingActivity(companyId);
      final currency = await currencyRepo.getDefaultCurrency();

      // State 2: Not Configured (no default currency in Currency Master)
      if (currency == null) {
        return FunctionalCurrencyStateInfo(
          configState: FunctionalCurrencyConfigState.notConfigured,
          currencyCode: '',
          hasPostedActivity: hasPosted,
          canModify: canModify,
        );
      }

      final code = currency.code;

      // State 4: Currency Inactive (currency is deactivated)
      if (!currency.isActive) {
        return FunctionalCurrencyStateInfo(
          configState: FunctionalCurrencyConfigState.currencyInactive,
          currency: currency,
          currencyCode: code,
          hasPostedActivity: hasPosted,
          errorMessage: 'العملة المعرفة "$code" غير نشطة حالياً.',
          canModify: canModify,
        );
      }

      // State 5: Change Restricted (has posted accounting activity)
      if (hasPosted) {
        return FunctionalCurrencyStateInfo(
          configState: FunctionalCurrencyConfigState.changeRestricted,
          currency: currency,
          currencyCode: code,
          hasPostedActivity: true,
          canModify: false, // Modification restricted due to posted activity
        );
      }

      // State 1: Configured (valid & active, no restriction)
      return FunctionalCurrencyStateInfo(
        configState: FunctionalCurrencyConfigState.configured,
        currency: currency,
        currencyCode: code,
        hasPostedActivity: false,
        canModify: canModify,
      );
    });
