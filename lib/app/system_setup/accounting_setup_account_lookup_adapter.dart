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
      default:
        mappedType = SetupAccountType.other;
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
}
