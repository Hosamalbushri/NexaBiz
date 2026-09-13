import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_scope_resolver.dart';
import 'package:stock_count/modules/cash_registers/domain/entities/cash_register.dart';
import 'package:stock_count/modules/cash_registers/domain/repositories/cash_register_repository.dart';
import 'package:stock_count/modules/cash_registers/domain/services/default_cash_register_resolver.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_treasury_account_port.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';
import '../localization/app_localizations.dart';
import '../localization/app_localizations_ar.dart';
import '../localization/app_localizations_en.dart';

/// App adapter: R&P treasury / posting accounts → Chart of Accounts with strict Cash Register readiness gating.
class AccountingRpTreasuryAdapter implements RpTreasuryAccountPort {
  const AccountingRpTreasuryAdapter(
    this._repository, {
    this.cashRegisterRepository,
    this.initRepository,
  });

  final AccountRepository _repository;
  final CashRegisterRepository? cashRegisterRepository;
  final CompanyInitializationRepository? initRepository;

  AppLocalizations _l10n(String? languageCode) {
    final code = (languageCode ?? 'ar').trim().toLowerCase();
    if (code.startsWith('ar')) {
      return AppLocalizationsAr();
    }
    return AppLocalizationsEn();
  }

  RpAccountRef _map(
    CashRegister register,
    Account account,
    AppLocalizations l10n,
  ) {
    return RpAccountRef(
      accountId: account.id,
      code: account.accountCode,
      name: '${register.name} (${AccountLabels.displayName(l10n, account)})',
      systemKey: AccountLabels.systemKeyOf(account),
    );
  }

  Future<List<Account>> _scopedCashAccounts(String companyId) async {
    final resolver = AccountingScopeResolver(
      accountRepository: _repository,
      initRepository: initRepository,
    );
    final scope = await resolver.resolveScope(
      companyId: companyId,
      role: AccountRole.cash,
    );
    if (!scope.isReady) {
      return const [];
    }
    return scope.accounts;
  }

  Future<List<MapEntry<CashRegister, Account>>>
  _getReadyRegistersWithAccounts() async {
    final state = await initRepository?.getState();
    final companyId = state?.companyId ?? '';

    if (cashRegisterRepository != null) {
      final readyRegisters = await cashRegisterRepository!
          .getAccountingReadyCashRegisters(companyId);
      final results = <MapEntry<CashRegister, Account>>[];
      for (final reg in readyRegisters) {
        final accId = reg.accountingAccountId;
        if (accId != null) {
          final account =
              await _repository.getByUuid(accId) ??
              await _repository.getByAccountCode(accId);
          if (account != null &&
              (companyId.isEmpty ||
                  account.companyId == companyId ||
                  account.companyId == reg.companyId) &&
              account.canPost &&
              !account.isDeleted) {
            results.add(MapEntry(reg, account));
          }
        }
      }
      return results;
    }

    // Fallback if cashRegisterRepository is not provided: query scoped accounts
    final scopedAccounts = await _scopedCashAccounts(companyId);
    return scopedAccounts
        .map(
          (a) => MapEntry(
            CashRegister(
              id: 'cr-${a.id}',
              companyId: companyId.isNotEmpty
                  ? companyId
                  : (a.companyId ?? 'default'),
              name: a.name,
              code: a.accountCode,
              isActive: true,
              accountingAccountId: a.id,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            a,
          ),
        )
        .toList();
  }

  @override
  Future<List<RpAccountRef>> listCashBoxAccounts({String? languageCode}) async {
    final l10n = _l10n(languageCode);
    final entries = await _getReadyRegistersWithAccounts();
    return entries
        .map((e) => _map(e.key, e.value, l10n))
        .toList(growable: false);
  }

  @override
  Future<List<RpAccountRef>> searchPostingAccounts(
    String query, {
    int limit = 40,
    String? languageCode,
  }) async {
    final l10n = _l10n(languageCode);
    final entries = await _getReadyRegistersWithAccounts();
    if (entries.isEmpty) {
      return const [];
    }

    final normalized = query.trim().toLowerCase();
    final matched = <MapEntry<CashRegister, Account>>[];

    for (final entry in entries) {
      final regNameMatch =
          entry.key.name.toLowerCase().contains(normalized) ||
          entry.key.code.toLowerCase().contains(normalized);
      final accMatch = AccountLabels.matchesQuery(
        l10n,
        entry.value,
        normalized,
      );

      if (normalized.isEmpty || regNameMatch || accMatch) {
        matched.add(entry);
      }
    }

    final safeLimit = limit <= 0 ? 40 : limit;
    return matched
        .take(safeLimit)
        .map((e) => _map(e.key, e.value, l10n))
        .toList(growable: false);
  }

  @override
  Future<RpAccountRef?> findById(
    String accountId, {
    String? languageCode,
  }) async {
    final entries = await _getReadyRegistersWithAccounts();
    for (final entry in entries) {
      if (entry.value.id == accountId || entry.key.id == accountId) {
        return _map(entry.key, entry.value, _l10n(languageCode));
      }
    }
    return null;
  }

  @override
  Future<RpAccountRef?> findDefaultCashBox({String? languageCode}) async {
    final l10n = _l10n(languageCode);
    final state = await initRepository?.getState();
    final companyId = state?.companyId ?? 'default';

    if (cashRegisterRepository != null) {
      final resolver = DefaultCashRegisterResolver(
        cashRegisterRepository: cashRegisterRepository!,
        accountRepository: _repository,
      );
      final result = await resolver.resolveDefaultCashRegister(companyId);
      final reg = result.register;
      final linkedAccount = result.linkedAccount;
      if (result.isValid && reg != null && linkedAccount != null) {
        return _map(reg, linkedAccount, l10n);
      }
      return null;
    }

    // Fallback only if cashRegisterRepository is completely unavailable
    final entries = await _getReadyRegistersWithAccounts();
    return entries.isEmpty
        ? null
        : _map(entries.first.key, entries.first.value, l10n);
  }
}
