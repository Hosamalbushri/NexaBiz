
enum SetupAccountType { asset, liability, equity, revenue, expense, other }

class SetupAccountData {
  const SetupAccountData({
    required this.uuid,
    required this.accountCode,
    required this.accountType,
    this.companyId,
    required this.isActive,
    required this.isDeleted,
    required this.isGroup,
    required this.canPost,
  });

  final String uuid;
  final String accountCode;
  final SetupAccountType accountType;
  final String? companyId;
  final bool isActive;
  final bool isDeleted;
  final bool isGroup;
  final bool canPost;
}

abstract class SetupAccountLookupPort {
  Future<SetupAccountData?> findAccount(String codeOrUuidOrId);
  Future<List<SetupAccountData>> getChildren(String parentUuid, {String? companyId});
  Future<List<SetupAccountData>> getDescendants(String parentUuid, {String? companyId});
}

class NoOpSetupAccountLookupPort implements SetupAccountLookupPort {
  const NoOpSetupAccountLookupPort();

  @override
  Future<SetupAccountData?> findAccount(String codeOrUuidOrId) async => null;

  @override
  Future<List<SetupAccountData>> getChildren(String parentUuid, {String? companyId}) async => const [];

  @override
  Future<List<SetupAccountData>> getDescendants(String parentUuid, {String? companyId}) async => const [];
}

