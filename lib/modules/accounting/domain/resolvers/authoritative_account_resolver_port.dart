import '../../../../core/domain/entities/account_role.dart';
import '../../chart_of_accounts/domain/entities/account.dart';

/// Authoritative Account Resolver Port.
///
/// Pipeline: Accounting -> Account Role -> Configured Account UUID -> Validate Account -> Return Account.
abstract class AuthoritativeAccountResolverPort {
  /// Resolves and validates an authoritative [Account] for a given [role] and [companyId].
  Future<Account> resolveAccount({
    required String companyId,
    required AccountRole role,
    String? currencyCode,
    String? overrideAccountUuid,
  });
}
