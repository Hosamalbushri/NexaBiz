import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import 'package:stock_count/core/utils/digit_normalization.dart';

/// Pure domain contract for account selection rules, filtering, and query matching.
///
/// Ensures all presentation surfaces (Bottom Sheet, Inline Search, Dropdown)
/// enforce identical business rules without duplicating filtering code or boolean flags.
class AccountSelectionContract {
  const AccountSelectionContract({
    this.postingOnly = true,
    this.initialTypeFilter,
    this.selectedUuid,
    this.customPredicate,
  });

  /// When true, non-posting (header/group) accounts are filtered out.
  final bool postingOnly;

  /// Optional account type filter (e.g. Asset, Liability, Revenue, Expense, Equity).
  final AccountType? initialTypeFilter;

  /// Currently selected account UUID, if any.
  final String? selectedUuid;

  /// Optional custom predicate for domain-specific constraints (e.g. cash box accounts).
  final bool Function(Account account)? customPredicate;

  /// Pure filtering method that returns eligible accounts matching the given [query].
  List<Account> filterEligibleAccounts(
    List<Account> allAccounts, {
    String query = '',
    AccountType? activeTypeFilter,
    bool? activePostingOnly,
    AppLocalizations? l10n,
  }) {
    final effectivePostingOnly = activePostingOnly ?? postingOnly;
    final effectiveTypeFilter = activeTypeFilter ?? initialTypeFilter;
    final normalizedQuery = normalizeDigitsToWestern(query).trim().toLowerCase();

    return allAccounts.where((account) {
      if (account.isDeleted) return false;
      if (!account.isActive) return false;
      if (effectivePostingOnly && !account.isPostingAccount) return false;
      if (effectiveTypeFilter != null && account.accountType != effectiveTypeFilter) {
        return false;
      }
      if (customPredicate != null && !customPredicate!(account)) {
        return false;
      }

      if (normalizedQuery.isNotEmpty) {
        final codeMatch = account.accountCode.toLowerCase().contains(normalizedQuery);
        final nameMatch = l10n != null
            ? AccountLabels.matchesQuery(l10n, account, normalizedQuery)
            : account.name.toLowerCase().contains(normalizedQuery);
        final descMatch = account.description != null &&
            account.description!.toLowerCase().contains(normalizedQuery);

        if (!codeMatch && !nameMatch && !descMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
