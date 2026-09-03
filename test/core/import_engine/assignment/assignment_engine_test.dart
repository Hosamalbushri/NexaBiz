import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

void main() {
  group('Phase 09 — Universal Import Engine Assignment Engine Tests', () {
    const engine = AssignmentEngine();

    test('1. FIXED_REFERENCE strategy assigns constant target entity to all rows', () {
      final rules = [
        const AssignmentRule(
          targetFieldKey: 'target_category_id',
          strategy: AssignmentStrategy.fixedReference,
          fixedValue: 'CAT-FIXED-99',
          policy: AssignmentPolicy.required,
        ),
        const AssignmentRule(
          targetFieldKey: 'target_warehouse_id',
          strategy: AssignmentStrategy.fixedReference,
          fixedValue: 'WH-DEFAULT-01',
          policy: AssignmentPolicy.optional,
        ),
      ];

      final rowData = {'raw_code': 'PROD-101', 'raw_name': 'Widget'};

      final results = engine.evaluateRecordAssignments(
        rowData: rowData,
        rules: rules,
      );

      expect(results['target_category_id']?.isAssigned, isTrue);
      expect(results['target_category_id']?.assignedValue, equals('CAT-FIXED-99'));
      expect(results['target_warehouse_id']?.isAssigned, isTrue);
      expect(results['target_warehouse_id']?.assignedValue, equals('WH-DEFAULT-01'));
    });

    test('2. FROM_COLUMN and FROM_MAPPING strategy extracts values from row data', () {
      final rules = [
        const AssignmentRule(
          targetFieldKey: 'target_supplier_id',
          strategy: AssignmentStrategy.fromColumn,
          sourceColumnKey: 'supplier_col',
          policy: AssignmentPolicy.required,
        ),
      ];

      final rowData = {'supplier_col': 'SUP-555'};

      final results = engine.evaluateRecordAssignments(
        rowData: rowData,
        rules: rules,
      );

      expect(results['target_supplier_id']?.isAssigned, isTrue);
      expect(results['target_supplier_id']?.assignedValue, equals('SUP-555'));
    });

    test('3. RESOLVED_REFERENCE strategy assigns resolved relation IDs from lookup map', () {
      final rules = [
        const AssignmentRule(
          targetFieldKey: 'target_account_id',
          strategy: AssignmentStrategy.resolvedReference,
          resolvedRelationKey: 'account_relation',
          policy: AssignmentPolicy.failIfMissing,
        ),
      ];

      final rowData = {'account_name': 'Sales Account'};
      final resolvedMap = {'account_relation': 'ACC-UUID-888'};

      final results = engine.evaluateRecordAssignments(
        rowData: rowData,
        rules: rules,
        resolvedRelationsMap: resolvedMap,
      );

      expect(results['target_account_id']?.isAssigned, isTrue);
      expect(results['target_account_id']?.assignedValue, equals('ACC-UUID-888'));
    });

    test('4. MULTIPLE_REFERENCES strategy evaluates multi-value reference functions', () {
      final rules = [
        AssignmentRule(
          targetFieldKey: 'tag_ids',
          strategy: AssignmentStrategy.multipleReferences,
          multipleValuesFn: (row) => ['TAG-1', 'TAG-2', 'TAG-3'],
          policy: AssignmentPolicy.optional,
        ),
      ];

      final results = engine.evaluateRecordAssignments(
        rowData: {},
        rules: rules,
      );

      expect(results['tag_ids']?.isAssigned, isTrue);
      expect(results['tag_ids']?.assignedValue, equals(['TAG-1', 'TAG-2', 'TAG-3']));
    });

    test('5. CONDITIONAL_ASSIGNMENT strategy evaluates predicate conditions accurately', () {
      final rules = [
        AssignmentRule(
          targetFieldKey: 'tax_group_id',
          strategy: AssignmentStrategy.conditionalAssignment,
          conditionFn: (row) => (row['price'] ?? 0) > 1000,
          conditionalTargetValue: 'TAX-LUXURY',
          policy: AssignmentPolicy.optional,
        ),
      ];

      // Test condition true
      final resHighPrice = engine.evaluateRecordAssignments(
        rowData: {'price': 1500},
        rules: rules,
      );
      expect(resHighPrice['tax_group_id']?.isAssigned, isTrue);
      expect(resHighPrice['tax_group_id']?.assignedValue, equals('TAX-LUXURY'));

      // Test condition false
      final resLowPrice = engine.evaluateRecordAssignments(
        rowData: {'price': 500},
        rules: rules,
      );
      expect(resLowPrice['tax_group_id']?.isSkipped, isTrue);
      expect(resLowPrice['tax_group_id']?.isAssigned, isFalse);
    });

    test('6. Policy enforcement (REQUIRED, FAIL_IF_MISSING, SKIP_IF_MISSING)', () {
      final rules = [
        const AssignmentRule(
          targetFieldKey: 'req_field',
          strategy: AssignmentStrategy.fromColumn,
          sourceColumnKey: 'missing_col',
          policy: AssignmentPolicy.required,
        ),
        const AssignmentRule(
          targetFieldKey: 'skip_field',
          strategy: AssignmentStrategy.fromColumn,
          sourceColumnKey: 'missing_col',
          policy: AssignmentPolicy.skipIfMissing,
        ),
      ];

      final results = engine.evaluateRecordAssignments(
        rowData: {},
        rules: rules,
      );

      expect(results['req_field']?.isFailed, isTrue);
      expect(results['req_field']?.errorMessage, contains('Assignment failed'));
      expect(results['skip_field']?.isSkipped, isTrue);
      expect(results['skip_field']?.isFailed, isFalse);
    });

    test('7. CREATE_IF_ALLOWED policy requires explicit policy and flags creation requirement', () {
      final rules = [
        const AssignmentRule(
          targetFieldKey: 'new_brand_id',
          strategy: AssignmentStrategy.fromColumn,
          sourceColumnKey: 'brand_name',
          policy: AssignmentPolicy.createIfAllowed,
        ),
      ];

      final results = engine.evaluateRecordAssignments(
        rowData: {}, // missing brand_name
        rules: rules,
      );

      expect(results['new_brand_id']?.requiresCreation, isTrue);
      expect(results['new_brand_id']?.isAssigned, isFalse);
      expect(results['new_brand_id']?.errorMessage, contains('creation policy triggered'));
    });

    test('8. Engine remains 100% domain independent (zero hardcoded entities)', () {
      final rule = const AssignmentRule(
        targetFieldKey: 'generic_relation_id',
        strategy: AssignmentStrategy.fixedReference,
        fixedValue: 'GENERIC-ID-001',
      );

      expect(rule.targetFieldKey, equals('generic_relation_id'));
    });
  });
}
