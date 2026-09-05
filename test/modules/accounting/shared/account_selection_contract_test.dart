import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_selection_contract.dart';

void main() {
  group('AccountSelectionContract Unit Tests', () {
    final now = DateTime(2026, 1, 1);
    final List<Account> sampleAccounts = [
      Account(
        id: 1,
        uuid: 'acc-1',
        accountCode: '101',
        name: 'الصندوق الرئيسي',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false, // Posting account
        isActive: true,
        isSystemAccount: false,
        createdAt: now,
        updatedAt: now,
      ),
      Account(
        id: 2,
        uuid: 'acc-2',
        accountCode: '10',
        name: 'الأصول المتداولة',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 1,
        isGroup: true, // Non-posting header
        isActive: true,
        isSystemAccount: false,
        createdAt: now,
        updatedAt: now,
      ),
      Account(
        id: 3,
        uuid: 'acc-3',
        accountCode: '401',
        name: 'إيرادات المبيعات',
        accountType: AccountType.revenue,
        normalBalance: NormalBalance.credit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        createdAt: now,
        updatedAt: now,
      ),
      Account(
        id: 4,
        uuid: 'acc-4',
        accountCode: '901',
        name: 'حساب ملغي',
        accountType: AccountType.expense,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        createdAt: now,
        updatedAt: now,
        deletedAt: now, // Deleted
      ),
      Account(
        id: 5,
        uuid: 'acc-5',
        accountCode: '902',
        name: 'حساب غير موقّف',
        accountType: AccountType.expense,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: false, // Inactive
        isSystemAccount: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    test('postingOnly=true filters out header/group non-posting accounts', () {
      const contract = AccountSelectionContract(postingOnly: true);
      final eligible = contract.filterEligibleAccounts(sampleAccounts);

      expect(eligible.map((a) => a.uuid), containsAll(['acc-1', 'acc-3']));
      expect(eligible.any((a) => a.uuid == 'acc-2'), false); // Header excluded
      expect(eligible.any((a) => a.uuid == 'acc-4'), false); // Deleted excluded
      expect(eligible.any((a) => a.uuid == 'acc-5'), false); // Inactive excluded
    });

    test('postingOnly=false includes non-posting accounts when active', () {
      const contract = AccountSelectionContract(postingOnly: false);
      final eligible = contract.filterEligibleAccounts(sampleAccounts);

      expect(eligible.any((a) => a.uuid == 'acc-2'), true);
    });

    test('initialTypeFilter filters accounts by type', () {
      const contract = AccountSelectionContract(
        postingOnly: true,
        initialTypeFilter: AccountType.revenue,
      );
      final eligible = contract.filterEligibleAccounts(sampleAccounts);

      expect(eligible.length, 1);
      expect(eligible.first.uuid, 'acc-3');
    });

    test('query filtering matches accountCode and name case-insensitively', () {
      const contract = AccountSelectionContract(postingOnly: true);

      final codeMatches = contract.filterEligibleAccounts(sampleAccounts, query: '101');
      expect(codeMatches.length, 1);
      expect(codeMatches.first.uuid, 'acc-1');

      final nameMatches = contract.filterEligibleAccounts(sampleAccounts, query: 'الصندوق');
      expect(nameMatches.length, 1);
      expect(nameMatches.first.uuid, 'acc-1');
    });

    test('customPredicate enforces domain specific eligibility', () {
      final contract = AccountSelectionContract(
        postingOnly: true,
        customPredicate: (account) => account.accountCode.startsWith('4'),
      );
      final eligible = contract.filterEligibleAccounts(sampleAccounts);

      expect(eligible.length, 1);
      expect(eligible.first.uuid, 'acc-3');
    });
  });
}
