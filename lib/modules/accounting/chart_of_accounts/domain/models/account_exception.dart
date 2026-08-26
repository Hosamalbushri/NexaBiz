/// Domain errors for Chart of Accounts operations.
class AccountException implements Exception {
  const AccountException(this.code, [this.message]);

  static const String duplicateAccountCode = 'duplicate_account_code';
  static const String notFound = 'not_found';
  static const String invalidAccountCode = 'invalid_account_code';
  static const String invalidName = 'invalid_name';
  static const String invalidParent = 'invalid_parent';
  static const String parentInactive = 'parent_inactive';
  static const String parentDeleted = 'parent_deleted';
  static const String typeMismatch = 'type_mismatch';
  static const String circularParent = 'circular_parent';
  static const String systemAccountProtected = 'system_account_protected';
  static const String hasChildren = 'has_children';
  static const String accountInUse = 'account_in_use';
  static const String groupRequiredForChildren = 'group_required_for_children';

  final String code;
  final String? message;

  @override
  String toString() =>
      'AccountException($code${message == null ? '' : ': $message'})';
}
