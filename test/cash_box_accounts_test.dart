import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/domain/services/cash_box_accounts.dart';

Account _account({
  required String uuid,
  required String code,
  required String name,
  String? parentId,
  String? description,
  bool isGroup = false,
}) {
  return Account(
    id: 1,
    uuid: uuid,
    parentId: parentId,
    accountCode: code,
    name: name,
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    isGroup: isGroup,
    isActive: true,
    isSystemAccount: description?.startsWith('system:') ?? false,
    level: 0,
    description: description,
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
  );
}

void main() {
  test('includes system and user cash boxes under cash_boxes', () {
    final cashBoxes = _account(
      uuid: 'root',
      code: '1210',
      name: 'Cash Boxes',
      description: 'system:cash_boxes',
      isGroup: true,
    );
    final cash = _account(
      uuid: 'cash',
      code: '1211',
      name: 'Main Cash',
      parentId: 'root',
      description: 'system:cash',
    );
    final bank = _account(
      uuid: 'bank',
      code: '1212',
      name: 'Bank',
      parentId: 'root',
      description: 'system:bank',
    );
    final custom = _account(
      uuid: 'custom',
      code: '12100001',
      name: 'Store Cash',
      parentId: 'root',
    );
    final customer = _account(
      uuid: 'cust',
      code: '12210001',
      name: 'Customer',
      parentId: 'customers',
    );

    final result = CashBoxAccounts.postingUnderCashBoxes([
      cashBoxes,
      cash,
      bank,
      custom,
      customer,
    ]);

    expect(result.map((a) => a.uuid).toSet(), {'cash', 'bank', 'custom'});
    expect(result.any((a) => a.uuid == 'cust'), isFalse);
  });
}
