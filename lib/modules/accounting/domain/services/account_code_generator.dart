import '../models/account_exception.dart';
import '../repositories/account_repository.dart';

/// Builds a unique Chart of Accounts code from the parent account code.
///
/// Example: parent `1221` → `12210001`, `12210002`, …
/// Root accounts (no parent) stay manual — callers skip this generator.
class AccountCodeGenerator {
  const AccountCodeGenerator(this._repository);

  final AccountRepository _repository;

  /// Digits appended after the parent account code.
  static const int sequenceWidth = 4;

  /// Next free sequential code under [parentAccountCode].
  Future<String> generate({
    required String parentAccountCode,
    DateTime? now,
  }) async {
    final prefix = parentAccountCode.trim();
    if (prefix.isEmpty) {
      throw const AccountException(AccountException.invalidAccountCode);
    }

    final existing = await _repository.getAll(includeInactive: true);
    var maxSeq = 0;
    for (final account in existing) {
      final code = account.accountCode.trim();
      if (!code.startsWith(prefix)) {
        continue;
      }
      final suffix = code.substring(prefix.length);
      if (suffix.isEmpty || !_digitsOnly.hasMatch(suffix)) {
        continue;
      }
      final value = int.tryParse(suffix);
      if (value != null && value > maxSeq) {
        maxSeq = value;
      }
    }

    var next = maxSeq + 1;
    for (var attempt = 0; attempt < 10000; attempt++) {
      final candidate = '$prefix${next.toString().padLeft(sequenceWidth, '0')}';
      final hit = await _repository.getByAccountCode(candidate);
      if (hit == null) {
        return candidate;
      }
      next++;
    }

    final stamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return '$prefix$stamp';
  }

  static final RegExp _digitsOnly = RegExp(r'^\d+$');
}
