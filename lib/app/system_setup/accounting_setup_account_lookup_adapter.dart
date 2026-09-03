import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';

class AccountingSetupAccountLookupAdapter implements SetupAccountLookupPort {
  AccountingSetupAccountLookupAdapter(this._accountRepository);

  final AccountRepository _accountRepository;

  @override
  Future<SetupAccountData?> findAccount(String codeOrUuidOrId) async {
    final account = await _accountRepository.getByUuid(codeOrUuidOrId) ??
        await _accountRepository.getByAccountCode(codeOrUuidOrId) ??
        (int.tryParse(codeOrUuidOrId) != null
            ? await _accountRepository.getById(int.parse(codeOrUuidOrId))
            : null);

    if (account == null) return null;

    SetupAccountType mappedType;
    switch (account.accountType) {
      case AccountType.asset:
        mappedType = SetupAccountType.asset;
        break;
      case AccountType.liability:
        mappedType = SetupAccountType.liability;
        break;
      case AccountType.equity:
        mappedType = SetupAccountType.equity;
        break;
      case AccountType.revenue:
        mappedType = SetupAccountType.revenue;
        break;
      case AccountType.expense:
        mappedType = SetupAccountType.expense;
        break;
    }

    return SetupAccountData(
      uuid: account.uuid,
      accountCode: account.accountCode,
      accountType: mappedType,
      companyId: account.companyId,
      isActive: account.isActive,
      isDeleted: account.isDeleted,
      isGroup: account.isGroup,
      canPost: account.canPost,
    );
  }

  @override
  Future<List<SetupAccountData>> getChildren(
    String parentUuid, {
    String? companyId,
  }) async {
    final children = await _accountRepository.getChildren(parentUuid);
    return children
        .where((a) => companyId == null || companyId.isEmpty || a.companyId == companyId)
        .map(_mapToSetupAccountData)
        .toList(growable: false);
  }

  @override
  Future<List<SetupAccountData>> getDescendants(
    String parentUuid, {
    String? companyId,
  }) async {
    final all = await _accountRepository.getAll(includeInactive: true);
    final tenantAccounts = all
        .where((a) => companyId == null || companyId.isEmpty || a.companyId == companyId)
        .toList();

    final map = <String, List<dynamic>>{};
    for (final a in tenantAccounts) {
      if (a.parentId != null && a.parentId!.isNotEmpty) {
        map.putIfAbsent(a.parentId!, () => []).add(a);
      }
    }

    final descendants = <SetupAccountData>[];
    final visited = <String>{parentUuid};

    void walk(String pid) {
      final children = map[pid] ?? const [];
      for (final child in children) {
        if (visited.add(child.uuid as String)) {
          descendants.add(_mapToSetupAccountData(child));
          walk(child.uuid as String);
        }
      }
    }

    walk(parentUuid);
    return descendants;
  }

  SetupAccountData _mapToSetupAccountData(dynamic account) {
    SetupAccountType mappedType;
    switch (account.accountType) {
      case AccountType.asset:
        mappedType = SetupAccountType.asset;
        break;
      case AccountType.liability:
        mappedType = SetupAccountType.liability;
        break;
      case AccountType.equity:
        mappedType = SetupAccountType.equity;
        break;
      case AccountType.revenue:
        mappedType = SetupAccountType.revenue;
        break;
      case AccountType.expense:
        mappedType = SetupAccountType.expense;
        break;
      default:
        mappedType = SetupAccountType.other;
    }
    return SetupAccountData(
      uuid: account.uuid as String,
      accountCode: account.accountCode as String,
      accountType: mappedType,
      companyId: account.companyId as String?,
      isActive: account.isActive as bool,
      isDeleted: account.isDeleted as bool,
      isGroup: account.isGroup as bool,
      canPost: account.canPost as bool,
    );
  }
}

