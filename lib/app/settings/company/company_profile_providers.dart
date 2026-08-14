import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/dashboard_services_provider.dart';
import '../settings_repository.dart';
import 'company_logo_store.dart';
import 'company_profile.dart';

final companyLogoStoreProvider = Provider<CompanyLogoStore>((ref) {
  return const CompanyLogoStore();
});

final companyProfileProvider =
    StateNotifierProvider<CompanyProfileController, AsyncValue<CompanyProfile>>(
      (ref) {
        return CompanyProfileController(
          repository: ref.watch(settingsRepositoryProvider),
          logoStore: ref.watch(companyLogoStoreProvider),
        );
      },
    );

class CompanyProfileController
    extends StateNotifier<AsyncValue<CompanyProfile>> {
  CompanyProfileController({
    required SettingsRepository repository,
    required CompanyLogoStore logoStore,
  }) : _repository = repository,
       _logoStore = logoStore,
       super(const AsyncValue.loading()) {
    _load();
  }

  final SettingsRepository _repository;
  final CompanyLogoStore _logoStore;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.loadCompanyProfile);
  }

  Future<void> refresh() => _load();

  Future<void> save(CompanyProfile profile) async {
    String? opt(String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) {
        return null;
      }
      return trimmed;
    }

    final normalized = CompanyProfile(
      name: profile.name.trim(),
      legalName: opt(profile.legalName),
      logoPath: opt(profile.logoPath),
      defaultCurrencyCode: profile.defaultCurrency.code,
      taxNumber: opt(profile.taxNumber),
      commercialRegister: opt(profile.commercialRegister),
      phone: opt(profile.phone),
      email: opt(profile.email),
      address: opt(profile.address),
      city: opt(profile.city),
      country: opt(profile.country),
      website: opt(profile.website),
      fiscalYearStartMonth: profile.fiscalYearStartMonth.clamp(1, 12),
      invoiceHeaderRight: opt(profile.invoiceHeaderRight),
      invoiceHeaderLeft: opt(profile.invoiceHeaderLeft),
    );
    await _repository.saveCompanyProfile(normalized);
    state = AsyncValue.data(normalized);
  }

  Future<CompanyProfile> setLogoFromPath(String sourcePath) async {
    final current = state.valueOrNull ?? const CompanyProfile();
    final storedPath = await _logoStore.saveFromPath(sourcePath);
    final updated = current.copyWith(logoPath: storedPath);
    await _repository.saveCompanyProfile(updated);
    state = AsyncValue.data(updated);
    return updated;
  }

  Future<CompanyProfile> clearLogo() async {
    final current = state.valueOrNull ?? const CompanyProfile();
    await _logoStore.clear();
    final updated = current.copyWith(clearLogoPath: true);
    await _repository.saveCompanyProfile(updated);
    state = AsyncValue.data(updated);
    return updated;
  }
}
