import '../models/customer_exception.dart';
import '../repositories/customer_repository.dart';
import 'customer_account_link_port.dart';

/// Builds a unique customer code from the Chart of Accounts parent account.
///
/// Example: parent `1221` → `12210001`, `12210002`, …
/// Callers may still import codes from ERP or enter them manually.
///
/// When [linkPort] + [parentAccountId] are provided, existing CoA children
/// under that parent also reserve sequence numbers (keeps customer codes and
/// manual CoA leaves in sync).
class CustomerCodeGenerator {
  const CustomerCodeGenerator(
    this._repository, {
    CustomerAccountLinkPort? linkPort,
  }) : _linkPort = linkPort;

  final CustomerRepository _repository;
  final CustomerAccountLinkPort? _linkPort;

  /// Digits appended after the parent account code.
  static const int sequenceWidth = 4;

  /// Sequential codes under [parentAccountCode] with collision checks.
  Future<String> generate({
    required String parentAccountCode,
    String? parentAccountId,
    DateTime? now,
  }) async {
    final prefix = parentAccountCode.trim().toUpperCase();
    if (prefix.isEmpty) {
      throw const CustomerException(CustomerException.invalidCustomerCode);
    }

    var maxSeq = 0;

    final existing = await _repository.getAll(includeInactive: true);
    for (final customer in existing) {
      maxSeq = _maxSeqFor(prefix, customer.customerCode, maxSeq);
    }

    final linkPort = _linkPort;
    final parentId = parentAccountId?.trim();
    if (linkPort != null && parentId != null && parentId.isNotEmpty) {
      final children = await linkPort.listUnderParent(parentId);
      for (final child in children) {
        maxSeq = _maxSeqFor(prefix, child.code, maxSeq);
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

  int _maxSeqFor(String prefix, String rawCode, int currentMax) {
    final code = rawCode.trim().toUpperCase();
    if (!code.startsWith(prefix)) {
      return currentMax;
    }
    final suffix = code.substring(prefix.length);
    if (suffix.isEmpty || !_digitsOnly.hasMatch(suffix)) {
      return currentMax;
    }
    final value = int.tryParse(suffix);
    if (value != null && value > currentMax) {
      return value;
    }
    return currentMax;
  }

  static final RegExp _digitsOnly = RegExp(r'^\d+$');
}
