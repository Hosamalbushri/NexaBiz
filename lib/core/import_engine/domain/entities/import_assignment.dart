/// Maps a target entity field key to a source header column or static default value.
class ImportAssignment {
  const ImportAssignment({
    required this.targetFieldKey,
    this.sourceHeader,
    this.staticValue,
    this.transformExpression,
  }) : assert(
          sourceHeader != null || staticValue != null,
          'Assignment must have either a sourceHeader or a staticValue.',
        );

  final String targetFieldKey;
  final String? sourceHeader;
  final dynamic staticValue;
  final String? transformExpression;

  bool get isStatic => staticValue != null && sourceHeader == null;
}
