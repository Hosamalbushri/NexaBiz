import 'package:flutter/foundation.dart';
import '../../../domain/ports/setup_account_lookup_port.dart';
import 'account_binding_status.dart';
import 'account_requirement.dart';

/// Resolution state of an [AccountRequirement] for a given tenant context.
@immutable
class AccountResolutionResult {
  const AccountResolutionResult({
    required this.requirement,
    required this.status,
    this.account,
    this.descendants = const [],
    this.message,
  });

  final AccountRequirement requirement;
  final AccountBindingStatus status;
  final SetupAccountData? account;
  final List<SetupAccountData> descendants;
  final String? message;

  bool get isBound => status == AccountBindingStatus.bound && account != null;
  bool get isUnbound => status == AccountBindingStatus.unbound;
  bool get isInvalidStale => status == AccountBindingStatus.invalidStale;
  bool get isConfiguredButEmpty => isBound && descendants.isEmpty;

  factory AccountResolutionResult.unbound(AccountRequirement requirement) {
    return AccountResolutionResult(
      requirement: requirement,
      status: AccountBindingStatus.unbound,
      message: 'لم يتم ربط حساب لهذا المتطلب بعد',
    );
  }

  factory AccountResolutionResult.bound({
    required AccountRequirement requirement,
    required SetupAccountData account,
    List<SetupAccountData> descendants = const [],
  }) {
    return AccountResolutionResult(
      requirement: requirement.withBoundAccountUuid(account.uuid),
      status: AccountBindingStatus.bound,
      account: account,
      descendants: descendants,
      message: descendants.isEmpty && requirement.bindingMode.name == 'parent'
          ? 'الحساب الرئيسي مرتبط ولكنه لا يحتوي على حسابات فرعية حالياً'
          : 'الحساب مرتبط ومستقر',
    );
  }

  factory AccountResolutionResult.invalidStale({
    required AccountRequirement requirement,
    required String message,
  }) {
    return AccountResolutionResult(
      requirement: requirement,
      status: AccountBindingStatus.invalidStale,
      message: message,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountResolutionResult &&
          runtimeType == other.runtimeType &&
          requirement == other.requirement &&
          status == other.status &&
          account == other.account &&
          listEquals(descendants, other.descendants) &&
          message == other.message;

  @override
  int get hashCode =>
      requirement.hashCode ^
      status.hashCode ^
      account.hashCode ^
      Object.hashAll(descendants) ^
      message.hashCode;
}

