import 'resolution_strategy.dart';

/// Single candidate returned by an external relation lookup callback.
class ResolvedCandidate {
  const ResolvedCandidate({
    required this.id,
    required this.displayName,
    this.code,
    this.companyId,
    this.metadata = const {},
  });

  /// Unique primary identifier of the resolved entity.
  final String id;

  /// User-visible candidate display name.
  final String displayName;

  /// Optional code / SKU of candidate.
  final String? code;

  /// Optional companyId / tenant context of candidate.
  final String? companyId;

  /// Optional metadata attributes.
  final Map<String, dynamic> metadata;
}

/// Generic contract defining relation target entity resolution logic.
class RelationDefinition {
  const RelationDefinition({
    required this.targetEntityKey,
    this.strategy = ResolutionStrategy.code,
    required this.lookupFn,
    this.allowCreationIfMissing = false,
  });

  /// Target domain entity key (e.g. 'category', 'supplier', 'account').
  final String targetEntityKey;

  /// Strategy used for lookup matching.
  final ResolutionStrategy strategy;

  /// Asynchronous candidate lookup function provided by domain feature module.
  final Future<List<ResolvedCandidate>> Function(
    dynamic rawReference,
    ResolutionStrategy strategy, [
    String? companyId,
  ])
  lookupFn;

  /// Whether missing relations may be auto-created during persistence phase.
  final bool allowCreationIfMissing;
}
