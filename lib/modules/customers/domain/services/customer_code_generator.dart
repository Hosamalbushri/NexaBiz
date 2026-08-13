import '../models/customer_exception.dart';
import '../repositories/customer_repository.dart';

/// Builds a unique customer code from the Chart of Accounts parent account.
///
/// Example: parent `1221` → `12210001`, `12210002`, …
/// Callers may still import codes from ERP or enter them manually.
class CustomerCodeGenerator {
  const CustomerCodeGenerator(this._repository);

  final CustomerRepository _repository;

  /// Digits appended after the parent account code.
  static const int sequenceWidth = 4;

  /// Sequential codes under [parentAccountCode] with collision checks.
  Future<String> generate({
    required String parentAccountCode,
    DateTime? now,
  }) async {
    final prefix = parentAccountCode.trim().toUpperCase();
    if (prefix.isEmpty) {
      throw const CustomerException(CustomerException.invalidCustomerCode);
    }

    final existing = await _repository.getAll(includeInactive: true);
    var maxSeq = 0;
    for (final customer in existing) {
      final code = customer.customerCode.trim().toUpperCase();
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
      final hit = await _repository.getByCustomerCode(candidate);
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
