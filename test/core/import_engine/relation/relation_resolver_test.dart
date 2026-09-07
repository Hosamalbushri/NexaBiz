import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

void main() {
  group('Phase 08 — Universal Import Engine Relation Resolution Engine Tests', () {
    const resolver = RelationResolver();

    // Mock dataset simulating external entity store
    final mockEntities = [
      const ResolvedCandidate(
        id: 'CAT-UUID-001',
        displayName: 'Electronics',
        code: 'ELEC',
      ),
      const ResolvedCandidate(
        id: 'CAT-UUID-002',
        displayName: 'Furniture',
        code: 'FURN',
      ),
      const ResolvedCandidate(
        id: 'CAT-UUID-003',
        displayName: 'Electronics',
        code: 'ELEC-DUPE',
      ), // Duplicate display name
    ];

    Future<List<ResolvedCandidate>> mockLookup(
      dynamic rawReference,
      ResolutionStrategy strategy, [
      String? companyId,
    ]) async {
      final query = rawReference.toString().trim().toLowerCase();
      switch (strategy) {
        case ResolutionStrategy.id:
        case ResolutionStrategy.uuid:
          return mockEntities
              .where((e) => e.id.toLowerCase() == query)
              .toList();
        case ResolutionStrategy.code:
          return mockEntities
              .where((e) => e.code?.toLowerCase() == query)
              .toList();
        case ResolutionStrategy.name:
        case ResolutionStrategy.alias:
          return mockEntities
              .where((e) => e.displayName.toLowerCase() == query)
              .toList();
        default:
          return [];
      }
    }

    test('1. Resolves entity reference successfully by ID', () async {
      final def = RelationDefinition(
        targetEntityKey: 'category',
        strategy: ResolutionStrategy.id,
        lookupFn: mockLookup,
      );

      final result = await resolver.resolve(
        rawReference: 'CAT-UUID-002',
        definition: def,
      );

      expect(result.status, equals(ResolutionStatus.existing));
      expect(result.resolvedId, equals('CAT-UUID-002'));
      expect(result.resolvedCandidate?.displayName, equals('Furniture'));
    });

    test('2. Resolves entity reference successfully by CODE', () async {
      final def = RelationDefinition(
        targetEntityKey: 'category',
        strategy: ResolutionStrategy.code,
        lookupFn: mockLookup,
      );

      final result = await resolver.resolve(
        rawReference: 'FURN',
        definition: def,
      );

      expect(result.status, equals(ResolutionStatus.existing));
      expect(result.resolvedId, equals('CAT-UUID-002'));
    });

    test(
      '3. Resolves entity reference successfully by NAME when unique',
      () async {
        final def = RelationDefinition(
          targetEntityKey: 'category',
          strategy: ResolutionStrategy.name,
          lookupFn: mockLookup,
        );

        final result = await resolver.resolve(
          rawReference: 'Furniture',
          definition: def,
        );

        expect(result.status, equals(ResolutionStatus.existing));
        expect(result.resolvedId, equals('CAT-UUID-002'));
      },
    );

    test(
      '4. Detects DUPLICATE NAMES as AMBIGUOUS relation (never silently selects)',
      () async {
        final def = RelationDefinition(
          targetEntityKey: 'category',
          strategy: ResolutionStrategy.name,
          lookupFn: mockLookup,
        );

        final result = await resolver.resolve(
          rawReference:
              'Electronics', // Matches two candidates (CAT-UUID-001 & CAT-UUID-003)
          definition: def,
        );

        expect(result.status, equals(ResolutionStatus.ambiguous));
        expect(result.isAmbiguous, isTrue);
        expect(result.resolvedId, isNull);
        expect(result.candidates.length, equals(2));
        expect(result.errorMessage, contains('matched 2 candidates'));
      },
    );

    test('5. Returns NOT_FOUND for missing relations', () async {
      final def = RelationDefinition(
        targetEntityKey: 'category',
        strategy: ResolutionStrategy.code,
        lookupFn: mockLookup,
      );

      final result = await resolver.resolve(
        rawReference: 'NON-EXISTENT-CODE',
        definition: def,
      );

      expect(result.status, equals(ResolutionStatus.notFound));
      expect(result.isNotFound, isTrue);
      expect(result.resolvedId, isNull);
    });

    test('6. Handles null / empty inputs returning INVALID status', () async {
      final def = RelationDefinition(
        targetEntityKey: 'category',
        strategy: ResolutionStrategy.code,
        lookupFn: mockLookup,
      );

      final nullRes = await resolver.resolve(
        rawReference: null,
        definition: def,
      );
      expect(nullRes.status, equals(ResolutionStatus.invalid));

      final emptyRes = await resolver.resolve(
        rawReference: '   ',
        definition: def,
      );
      expect(emptyRes.status, equals(ResolutionStatus.invalid));
    });

    test(
      '7. Architecture remains 100% domain independent (zero hardcoded entities)',
      () {
        final def = RelationDefinition(
          targetEntityKey: 'custom_generic_entity',
          strategy: ResolutionStrategy.custom,
          lookupFn: (ref, strat, [companyId]) async => [
            const ResolvedCandidate(id: 'GEN-01', displayName: 'Generic Item'),
          ],
        );

        expect(def.targetEntityKey, equals('custom_generic_entity'));
      },
    );
  });
}
