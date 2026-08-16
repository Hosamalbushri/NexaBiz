import '../../modules/accounting/domain/entities/account.dart';
import '../../modules/accounting/domain/repositories/account_repository.dart';
import '../../modules/accounting/domain/services/account_labels.dart';
import '../../modules/accounting/domain/services/cash_box_accounts.dart';
import '../../modules/receipts_payments/domain/services/rp_treasury_account_port.dart';
import '../localization/app_localizations.dart';
import '../localization/app_localizations_ar.dart';
import '../localization/app_localizations_en.dart';

/// App adapter: R&P treasury / posting accounts → Chart of Accounts.
class AccountingRpTreasuryAdapter implements RpTreasuryAccountPort {
  const AccountingRpTreasuryAdapter(this._repository);

  final AccountRepository _repository;

  static const _systemCash = 'system:cash';

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

  Future<List<Account>> _cashLikeAccounts() async {
    await _repository.ensureDefaultChartSeeded();
    final all = await _repository.getAll();
    return CashBoxAccounts.postingUnderCashBoxes(all);
  }

  @override
  Future<List<RpAccountRef>> listCashBoxAccounts({
    String? languageCode,
  }) async {
    final l10n = _l10n(languageCode);
    final accounts = await _cashLikeAccounts();
    return accounts.map((a) => _map(a, l10n)).toList(growable: false);
  }

  @override
  Future<List<RpAccountRef>> searchPostingAccounts(
    String query, {
    int limit = 40,
    String? languageCode,
  }) async {
    await _repository.ensureDefaultChartSeeded();
    final l10n = _l10n(languageCode);
    final normalized = query.trim().toLowerCase();
    final all = await _repository.getAll();
    final posting = <Account>[
      for (final account in all)
        if (account.canPost) account,
    ];

    final matched = normalized.isEmpty
        ? posting
        : [
            for (final account in posting)
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
    final account = await _repository.getByUuid(accountId);
    if (account == null || !account.canPost) {
      return null;
    }
    return _map(account, _l10n(languageCode));
  }

  @override
  Future<RpAccountRef?> findDefaultCashBox({
    String? languageCode,
  }) async {
    final l10n = _l10n(languageCode);
    final accounts = await _cashLikeAccounts();
    for (final account in accounts) {
      if (account.description?.trim() == _systemCash) {
        return _map(account, l10n);
      }
    }
    return accounts.isEmpty ? null : _map(accounts.first, l10n);
  }
}
