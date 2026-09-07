import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import '../../domain/services/account_selection_contract.dart';

/// Parameter family provider that filters accounts based on an [AccountSelectionContract],
/// current search query, active account type, and posting-only toggle.
final filteredAccountsProvider =
    Provider.family<
      AsyncValue<List<Account>>,
      ({
        AccountSelectionContract contract,
        String query,
        AccountType? activeTypeFilter,
        bool? activePostingOnly,
      })
    >((ref, args) {
      final accountsAsync = ref.watch(allAccountsProvider);

      return accountsAsync.whenData((allAccounts) {
        return args.contract.filterEligibleAccounts(
          allAccounts,
          query: args.query,
          activeTypeFilter: args.activeTypeFilter,
          activePostingOnly: args.activePostingOnly,
        );
      });
    });
