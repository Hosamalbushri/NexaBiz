/// Stable canonical reference identifying the operational source of an accounting entry.
///
/// Disallows empty strings and local integer identity as cross-domain identity.
class AccountingSourceReference {
  AccountingSourceReference({
    required this.sourceType,
    required this.sourceId,
  }) {
    if (sourceType.trim().isEmpty) {
      throw ArgumentError('AccountingSourceReference: sourceType cannot be empty.');
    }
    if (sourceId.trim().isEmpty) {
      throw ArgumentError('AccountingSourceReference: sourceId cannot be empty.');
    }
    // Reject pure integer local identifiers as cross-domain identities
    if (int.tryParse(sourceId.trim()) != null && int.parse(sourceId.trim()) > 0) {
      throw ArgumentError(
        'AccountingSourceReference: sourceId "$sourceId" is a local integer ID. '
        'Cross-domain accounting references MUST use stable canonical UUID identifiers.',
      );
    }
  }

  final String sourceType;
  final String sourceId;

  String get canonicalKey => '${sourceType.trim()}:${sourceId.trim()}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountingSourceReference &&
          runtimeType == other.runtimeType &&
          sourceType.trim() == other.sourceType.trim() &&
          sourceId.trim() == other.sourceId.trim();

  @override
  int get hashCode => sourceType.trim().hashCode ^ sourceId.trim().hashCode;

  @override
  String toString() => 'AccountingSourceReference($canonicalKey)';
}
