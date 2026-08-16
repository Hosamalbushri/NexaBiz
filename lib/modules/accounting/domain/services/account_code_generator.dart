import '../models/account_exception.dart';
import '../repositories/account_repository.dart';

/// Builds the next sequential Chart of Accounts code under a parent.
///
/// Looks at existing **sibling** accounts (same parent), takes the highest
/// numeric code, and returns that value + 1.
///
/// Examples:
/// - Parent `1210` with children `1211`, `1212`, `1213` → `1214`
/// - Parent `1221` with children `12210001`, `12210002` → `12210003`
/// - Parent with no children yet → `12210001` (parent code + 4-digit sequence)
///
/// Root accounts (no parent) stay manual — callers skip this generator.
class AccountCodeGenerator {
  const AccountCodeGenerator(this._repository);

  final AccountRepository _repository;

  /// Digits appended after the parent account code when it has no children.
  static const int sequenceWidth = 4;

  /// Next free sequential code under [parentAccountCode] / [parentAccountId].
  Future<String> generate({
    required String parentAccountCode,
    String? parentAccountId,
    DateTime? now,
  }) async {
    final prefix = parentAccountCode.trim();
    if (prefix.isEmpty) {
      throw const AccountException(AccountException.invalidAccountCode);
    }

    final existing = await _repository.getAll(includeInactive: true);
    final parentId = parentAccountId?.trim();
    var maxCode = 0;

    for (final account in existing) {
      if (!_isSibling(account.parentId, account.accountCode, prefix, parentId)) {
        continue;
      }
      final value = int.tryParse(account.accountCode.trim());
      if (value != null && value > maxCode) {
        maxCode = value;
      }
    }

    var next = maxCode == 0
        ? int.tryParse('$prefix${1.toString().padLeft(sequenceWidth, '0')}') ?? 1
        : maxCode + 1;

    for (var attempt = 0; attempt < 10000; attempt++) {
      final candidate = next.toString();
      final hit = await _repository.getByAccountCode(candidate);
      if (hit == null) {
        return candidate;
      }
      next++;
    }

    final stamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return '$prefix$stamp';
  }

  /// Prefer same [parentId]; fall back to code-prefix siblings when id is absent.
  static bool _isSibling(
    String? accountParentId,
    String accountCode,
    String parentCode,
    String? parentId,
  ) {
    final code = accountCode.trim();
    if (code.isEmpty || code == parentCode) {
      return false;
    }
    if (parentId != null && parentId.isNotEmpty) {
      return accountParentId == parentId;
    }
    // Prefix fallback: only codes that look like parent + numeric suffix.
    if (!code.startsWith(parentCode)) {
      return false;
    }
    final suffix = code.substring(parentCode.length);
    return suffix.isNotEmpty && _digitsOnly.hasMatch(suffix);
  }

  static final RegExp _digitsOnly = RegExp(r'^\d+$');
}
