import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/customers/accounts/domain/services/customer_account_link_port.dart';
import '../settings/settings_repository.dart';

/// After a remote customer is applied, ensure its CoA posting account exists
/// under this device's customers parent (system chart UUIDs differ per install).
class CustomerRemoteAccountEnsure {
  CustomerRemoteAccountEnsure({
    required this._accounts,
    required this._accountLink,
    required this._settings,
  });

  final AccountRepositoryImpl _accounts;
  final CustomerAccountLinkPort _accountLink;
  final SettingsRepository _settings;

  Future<void> ensureFromCustomerPayload(Map<String, dynamic> payload) async {
    if (payload['deletedAt'] != null) {
      return;
    }
    final accountId = payload['accountId']?.toString().trim();
    if (accountId == null || accountId.isEmpty) {
      return;
    }

    final parent = await _resolveCustomersParent();
    if (parent == null) {
      return;
    }

    final existing = await _accounts.getByUuid(accountId);
    if (existing != null && !existing.isDeleted) {
      await _accounts.remountUnderParent(
        accountUuid: accountId,
        parentUuid: parent.accountId,
      );
      return;
    }

    final code =
        (payload['customerCode']?.toString() ?? accountId).trim().toUpperCase();
    final name = (payload['name']?.toString() ?? code).trim();
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    await _accounts.applyRemotePayload({
      'uuid': accountId,
      'parentId': parent.accountId,
      'parentAccountCode': parent.code,
      'accountCode': code,
      'name': name.isEmpty ? code : name,
      'accountType': AccountType.asset.storageValue,
      'normalBalance': AccountType.asset.normalBalance.storageValue,
      'level': 0,
      'isGroup': false,
      'isActive': true,
      'isSystemAccount': false,
      'version': 1,
      'updatedAt': nowMs,
      'createdAt': nowMs,
    });
  }

  Future<LinkedAccountRef?> _resolveCustomersParent() async {
    final configured = await _settings.loadCustomersParentAccountId();
    if (configured != null && configured.isNotEmpty) {
      final linked = await _accountLink.findById(configured);
      if (linked != null && linked.isGroup) {
        return linked;
      }
    }
    return _accountLink.findSystemCustomersParent();
  }
}
