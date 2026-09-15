import '../../domain/account/financial_account.dart';

/// Repository port interface for Financial Accounts.
abstract class FinancialAccountRepository {
  Future<void> saveAccount(FinancialAccount account);
  Future<FinancialAccount?> findById(String companyId, String id);
  Future<FinancialAccount?> findByCode(String companyId, String code);
  Future<List<FinancialAccount>> findChildren(String companyId, String parentAccountId);
  Future<List<FinancialAccount>> getCompanyAccounts(String companyId);
}
