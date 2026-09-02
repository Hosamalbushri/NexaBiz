import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/modules/sync/sync.dart';
import '../../../modules/authentication/domain/entities/auth_user.dart';
import '../../../core/tenancy/session_company.dart';
import '../../../modules/authentication/presentation/providers/auth_providers.dart';
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
          ref: ref,
          repository: ref.watch(settingsRepositoryProvider),
          logoStore: ref.watch(companyLogoStoreProvider),
          syncQueue: ref.watch(syncQueueProvider),
          companyId: ref.watch(sessionCompanyIdProvider) ?? '',
        );
      },
    );

/// Whether the system base currency was locked during System Setup.
final systemBaseCurrencyLockedProvider = FutureProvider<bool>((ref) {
  return ref.watch(settingsRepositoryProvider).loadSystemBaseCurrencyLocked();
});

class CompanyProfileController
    extends StateNotifier<AsyncValue<CompanyProfile>> {
  CompanyProfileController({
    required this._ref,
    required this._repository,
    required this._logoStore,
    this._syncQueue,
    this._companyId = '',
  }) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;
  final SettingsRepository _repository;
  final CompanyLogoStore _logoStore;
  final SyncQueue? _syncQueue;
  final String _companyId;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      var profile = await _repository.loadCompanyProfile(_companyId);
      if (profile.name.isEmpty) {
        final authState = _ref.read(authStateProvider);
        final session = authState.session;
        final companies = session?.companies ?? [];
        final currentCompany = companies.firstWhere(
          (c) => c.id == _companyId,
          orElse: () => companies.isNotEmpty
              ? companies.first
              : const AuthCompany(id: '', name: '', code: ''),
        );
        if (currentCompany.name.isNotEmpty) {
          profile = profile.copyWith(name: currentCompany.name);
          await _repository.saveCompanyProfile(profile, _companyId);
        }
      }
      return profile;
    });
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

    final locked = await _repository.loadSystemBaseCurrencyLocked();
    final existing = await _repository.loadCompanyProfile(_companyId);
    final currencyCode = locked
        ? existing.defaultCurrencyCode
        : profile.defaultCurrency.code;

    final normalized = CompanyProfile(
      name: profile.name.trim(),
      legalName: opt(profile.legalName),
      logoPath: opt(profile.logoPath),
      defaultCurrencyCode: currencyCode,
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
    await _repository.saveCompanyProfile(normalized, _companyId);

    final queue = _syncQueue;
    if (queue != null) {
      final entityId = _companyId.isNotEmpty
          ? _companyId
          : '00000000-0000-0000-0000-000000000000';
      await queue.enqueue(
        SyncOperation.create(
          entityType: 'company_profile',
          entityId: entityId,
          type: SyncOperationType.create,
          baseVersion: 0,
          payload: normalized.toMap(),
        ),
      );
    }

    state = AsyncValue.data(normalized);
  }

  Future<CompanyProfile> setLogoFromPath(String sourcePath) async {
    final current = state.valueOrNull ?? const CompanyProfile();
    final storedPath = await _logoStore.saveFromPath(sourcePath);
    final updated = current.copyWith(logoPath: storedPath);
    await save(updated);
    return updated;
  }

  Future<CompanyProfile> clearLogo() async {
    final current = state.valueOrNull ?? const CompanyProfile();
    await _logoStore.clear();
    final updated = current.copyWith(clearLogoPath: true);
    await save(updated);
    return updated;
  }
}

