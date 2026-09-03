import 'relation_definition.dart';
import 'resolution_status.dart';

/// Outcome report of resolving a raw entity relation reference.
class ResolutionResult {
  const ResolutionResult({
    required this.status,
    required this.rawReference,
    this.resolvedId,
    this.resolvedCandidate,
    this.candidates = const [],
    this.errorMessage,
  });

  /// Outcome status (existing, notFound, ambiguous, invalid).
  final ResolutionStatus status;

  /// Raw input reference value.
  final dynamic rawReference;

  /// Unique primary identifier if resolved to 1 candidate.
  final String? resolvedId;

  /// Single matching candidate if status is `existing`.
  final ResolvedCandidate? resolvedCandidate;

  /// Candidates matched during lookup.
  final List<ResolvedCandidate> candidates;

  /// Descriptive error explanation if resolution failed or was ambiguous.
  final String? errorMessage;

  bool get isResolved => status == ResolutionStatus.existing && resolvedId != null;
  bool get isAmbiguous => status == ResolutionStatus.ambiguous;
  bool get isNotFound => status == ResolutionStatus.notFound;
  bool get isInvalid => status == ResolutionStatus.invalid;
}
