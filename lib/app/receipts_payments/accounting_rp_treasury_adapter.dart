import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_scope_resolver.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_treasury_account_port.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';
import '../localization/app_localizations.dart';
import '../localization/app_localizations_ar.dart';
import '../localization/app_localizations_en.dart';

/// App adapter: R&P treasury / posting accounts → Chart of Accounts with strict scope gating.
class AccountingRpTreasuryAdapter implements RpTreasuryAccountPort {
  const AccountingRpTreasuryAdapter(
    this._repository, {
    this.initRepository,
  });

  final AccountRepository _repository;
  final CompanyInitializationRepository? initRepository;

  AppLocalizations _l10n(String? languageCode) {
    final code = (languageCode ?? 'ar').trim().toLowerCase();
    if (code.startsWith('ar')) {
      return AppLocalizationsAr();
    }
    return AppLocalizationsEn();
  }

  RpAccountRef _map(Account account, AppLocalizations l10n) {
    return RpAccountRef(
      accountId: account.uuid,
      code: account.accountCode,
      name: AccountLabels.displayName(l10n, account),
      systemKey: AccountLabels.systemKeyOf(account),
    );
  }

  Future<List<Account>> _scopedCashAccounts() async {
    final state = await initRepository?.getState();
    final companyId = state?.companyId ?? '';
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

  @override
  Future<List<RpAccountRef>> listCashBoxAccounts({
    String? languageCode,
  }) async {
    final l10n = _l10n(languageCode);
    final accounts = await _scopedCashAccounts();
    return accounts.map((a) => _map(a, l10n)).toList(growable: false);
  }

  @override
  Future<List<RpAccountRef>> searchPostingAccounts(
    String query, {
    int limit = 40,
    String? languageCode,
  }) async {
    final l10n = _l10n(languageCode);
    final scopedAccounts = await _scopedCashAccounts();
    if (scopedAccounts.isEmpty) {
      return const [];
    }

    final normalized = query.trim().toLowerCase();
    final matched = normalized.isEmpty
        ? scopedAccounts
        : [
            for (final account in scopedAccounts)
              if (AccountLabels.matchesQuery(l10n, account, normalized))
                account,
          ];

    matched.sort((a, b) {
      if (normalized.isNotEmpty) {
        final aCode = a.accountCode.toLowerCase();
        final bCode = b.accountCode.toLowerCase();
        final aExact = aCode == normalized ? 0 : 1;
        final bExact = bCode == normalized ? 0 : 1;
        if (aExact != bExact) {
          return aExact - bExact;
        }
        final aPrefix = aCode.startsWith(normalized) ? 0 : 1;
        final bPrefix = bCode.startsWith(normalized) ? 0 : 1;
        if (aPrefix != bPrefix) {
          return aPrefix - bPrefix;
        }
      }
      return a.accountCode.compareTo(b.accountCode);
    });

    final safeLimit = limit <= 0 ? 40 : limit;
    return matched
        .take(safeLimit)
        .map((a) => _map(a, l10n))
        .toList(growable: false);
  }

  @override
  Future<RpAccountRef?> findById(
    String accountId, {
    String? languageCode,
  }) async {
    final accounts = await _scopedCashAccounts();
    for (final acc in accounts) {
      if (acc.uuid == accountId) {
        return _map(acc, _l10n(languageCode));
      }
    }
    return null;
  }

  @override
  Future<RpAccountRef?> findDefaultCashBox({
    String? languageCode,
  }) async {
    final l10n = _l10n(languageCode);
    final accounts = await _scopedCashAccounts();
    return accounts.isEmpty ? null : _map(accounts.first, l10n);
  }
}
