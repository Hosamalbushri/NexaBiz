import '../domain/exceptions/tenant_isolation_exception.dart';
import 'relation_definition.dart';
import 'resolution_result.dart';
import 'resolution_status.dart';
import 'resolution_strategy.dart';

/// Generic Relation Resolver evaluating raw entity references against candidate lookup providers.
/// Enforces strict ambiguity safety and multi-company tenant isolation.
class RelationResolver {
  const RelationResolver();

  /// Resolves a [rawReference] using the provided [definition] for a specific [companyId].
  /// Optional [overrideStrategy] allows overriding default resolution strategy.
  Future<ResolutionResult> resolve({
    required dynamic rawReference,
    required RelationDefinition definition,
    String? companyId,
    ResolutionStrategy? overrideStrategy,
  }) async {
    // 1. Invalid Reference Check
    if (rawReference == null) {
      return ResolutionResult(
        status: ResolutionStatus.invalid,
        rawReference: rawReference,
        errorMessage: 'Relation reference is null',
      );
    }

    final strRef = rawReference.toString().trim();
    if (strRef.isEmpty) {
      return ResolutionResult(
        status: ResolutionStatus.invalid,
        rawReference: rawReference,
        errorMessage: 'Relation reference string is empty',
      );
    }

    final effectiveStrategy = overrideStrategy ?? definition.strategy;

    try {
      // 2. Execute Async Candidate Lookup with companyId context
      final candidates = await definition.lookupFn(
        rawReference,
        effectiveStrategy,
        companyId,
      );

      // 3. Multi-Company Tenant Isolation Check
      if (companyId != null && companyId.trim().isNotEmpty) {
        final crossTenantCandidates = candidates
            .where((c) => c.companyId != null && c.companyId != companyId)
            .toList();

        if (crossTenantCandidates.isNotEmpty) {
          throw TenantIsolationException(
            'Cross-company relation resolution security violation: candidate entity belongs to company "${crossTenantCandidates.first.companyId}" instead of expected tenant "$companyId"',
            expectedCompanyId: companyId,
            attemptedCompanyId: crossTenantCandidates.first.companyId,
          );
        }
      }

      // 4. Not Found
      if (candidates.isEmpty) {
        return ResolutionResult(
          status: ResolutionStatus.notFound,
          rawReference: rawReference,
          errorMessage:
              'No ${definition.targetEntityKey} found matching reference "$strRef" via strategy ${effectiveStrategy.name}',
        );
      }

      // 5. Existing — Single Unique Match
      if (candidates.length == 1) {
        final candidate = candidates.first;
        return ResolutionResult(
          status: ResolutionStatus.existing,
          rawReference: rawReference,
          resolvedId: candidate.id,
          resolvedCandidate: candidate,
          candidates: candidates,
        );
      }

      // 6. Ambiguous — Multiple Candidates Matched (NEVER SILENTLY SELECT)
      final candidateNames = candidates
          .map((c) => '${c.displayName} (${c.id})')
          .join(', ');
      return ResolutionResult(
        status: ResolutionStatus.ambiguous,
        rawReference: rawReference,
        candidates: candidates,
        errorMessage:
            'Ambiguous reference "$strRef" matched ${candidates.length} candidates: [$candidateNames]',
      );
    } catch (e) {
      if (e is TenantIsolationException) {
        rethrow;
      }
      return ResolutionResult(
        status: ResolutionStatus.invalid,
        rawReference: rawReference,
        errorMessage: 'Error during relation resolution: $e',
      );
    }
  }
}
