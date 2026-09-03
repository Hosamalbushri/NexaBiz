import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

void main() {
  group('Phase 14 — Universal Import Engine Preview Engine Tests', () {
    late ImportPreviewEngine previewEngine;
    late Map<String, dynamic> mockDatabase;

    setUp(() {
      previewEngine = const ImportPreviewEngine();
      mockDatabase = {
        'PROD-101': {'label': 'Existing Product A', 'price': 100.0},
        'PROD-102': {'label': 'Existing Product B', 'price': 200.0},
      };
    });

    List<ImportField> createSchema() {
      return const [
        ImportField(key: 'code', label: 'Product Code', isRequired: true, isUnique: true, dataType: ImportDataType.text),
        ImportField(key: 'name', label: 'Product Name', isRequired: true, dataType: ImportDataType.text),
        ImportField(key: 'price', label: 'Price', isRequired: false, dataType: ImportDataType.number),
        ImportField(key: 'category_code', label: 'Category Code', isRequired: false, dataType: ImportDataType.text),
      ];
    }

    List<FieldMappingResult> createMappings(List<ImportField> fields) {
      final codeField = fields.firstWhere((f) => f.key == 'code');
      final nameField = fields.firstWhere((f) => f.key == 'name');
      final priceField = fields.firstWhere((f) => f.key == 'price');
      final catField = fields.firstWhere((f) => f.key == 'category_code');

      return [
        FieldMappingResult(sourceColumnIndex: 0, sourceColumnHeader: 'Code', normalizedSourceHeader: 'code', targetField: codeField),
        FieldMappingResult(sourceColumnIndex: 1, sourceColumnHeader: 'Name', normalizedSourceHeader: 'name', targetField: nameField),
        FieldMappingResult(sourceColumnIndex: 2, sourceColumnHeader: 'Price', normalizedSourceHeader: 'price', targetField: priceField),
        FieldMappingResult(sourceColumnIndex: 3, sourceColumnHeader: 'Category', normalizedSourceHeader: 'category', targetField: catField),
      ];
    }

    test('1. Summary metrics calculation: totalRows, validRows, warnings, errors, creates, updates, skips, relationProblems, assignments', () async {
      final targetFields = createSchema();
      final mappings = createMappings(targetFields);

      final rawRows = [
        const ParsedRow(rowIndex: 0, cells: [
          ParsedCell(headerName: 'Code', rawValue: 'PROD-101', columnIndex: 0),
          ParsedCell(headerName: 'Name', rawValue: 'Updated Prod A', columnIndex: 1),
          ParsedCell(headerName: 'Price', rawValue: '150.0', columnIndex: 2),
        ]),
        const ParsedRow(rowIndex: 1, cells: [
          ParsedCell(headerName: 'Code', rawValue: 'PROD-103', columnIndex: 0),
          ParsedCell(headerName: 'Name', rawValue: 'Brand New Prod C', columnIndex: 1),
          ParsedCell(headerName: 'Price', rawValue: '300.0', columnIndex: 2),
        ]),
        const ParsedRow(rowIndex: 2, cells: [
          ParsedCell(headerName: 'Code', rawValue: 'PROD-104', columnIndex: 0),
          // Missing required name!
          ParsedCell(headerName: 'Price', rawValue: '400.0', columnIndex: 2),
        ]),
        const ParsedRow(rowIndex: 3, cells: [
          ParsedCell(headerName: 'Code', rawValue: 'PROD-105', columnIndex: 0),
          ParsedCell(headerName: 'Name', rawValue: 'Skipped Product', columnIndex: 1),
        ]),
      ];

      final summary = await previewEngine.generatePreview(
        rawRows: rawRows,
        targetFields: targetFields,
        mappings: mappings,
        existenceChecker: (row, normMap) async {
          final code = normMap['code'];
          return mockDatabase.containsKey(code);
        },
        skipChecker: (row, normMap) {
          final code = normMap['code'];
          return code == 'PROD-105';
        },
        fixedAssignments: const {'warehouse_id': 'WH-MAIN'},
      );

      expect(summary.totalRows, equals(4));

      expect(summary.validRows, equals(3)); // 101 (update), 103 (create), 105 (skip)
      expect(summary.errors, equals(1)); // 104 missing required name
      expect(summary.creates, equals(1)); // 103
      expect(summary.updates, equals(1)); // 101
      expect(summary.skips, equals(1)); // 105
      expect(summary.assignments, equals(4)); // 1 assignment per row
    });

    test('2. Proof of ZERO business data mutation: Database state before and after preview remains identical', () async {
      final targetFields = createSchema();
      final mappings = createMappings(targetFields);

      final dbSnapshotBefore = Map<String, dynamic>.from(mockDatabase);

      final rawRows = [
        const ParsedRow(rowIndex: 0, cells: [
          ParsedCell(headerName: 'Code', rawValue: 'PROD-101', columnIndex: 0),
          ParsedCell(headerName: 'Name', rawValue: 'MUTATION ATTEMPT 1', columnIndex: 1),
        ]),
        const ParsedRow(rowIndex: 1, cells: [
          ParsedCell(headerName: 'Code', rawValue: 'NEW-999', columnIndex: 0),
          ParsedCell(headerName: 'Name', rawValue: 'MUTATION ATTEMPT 2', columnIndex: 1),
        ]),
      ];

      // Run preview engine dry run
      await previewEngine.generatePreview(
        rawRows: rawRows,
        targetFields: targetFields,
        mappings: mappings,
        existenceChecker: (row, normMap) async => mockDatabase.containsKey(normMap['code']),
      );

      // Verify ZERO database mutation
      expect(mockDatabase, equals(dbSnapshotBefore));
      expect(mockDatabase.containsKey('NEW-999'), isFalse);
      expect(mockDatabase['PROD-101']['label'], equals('Existing Product A'));
    });

    test('3. Action classification (CREATE, UPDATE, SKIP, ERROR) and human-readable explanations', () async {
      final targetFields = createSchema();
      final mappings = createMappings(targetFields);

      final rawRows = [
        const ParsedRow(rowIndex: 0, cells: [
          ParsedCell(headerName: 'Code', rawValue: 'PROD-101', columnIndex: 0),
          ParsedCell(headerName: 'Name', rawValue: 'Prod A', columnIndex: 1),
        ]),
        const ParsedRow(rowIndex: 1, cells: [
          ParsedCell(headerName: 'Code', rawValue: 'PROD-200', columnIndex: 0),
          ParsedCell(headerName: 'Name', rawValue: 'Prod B', columnIndex: 1),
        ]),
        const ParsedRow(rowIndex: 2, cells: [
          ParsedCell(headerName: 'Code', rawValue: 'PROD-300', columnIndex: 0),
          ParsedCell(headerName: 'Name', rawValue: 'Prod C', columnIndex: 1),
        ]),
        const ParsedRow(rowIndex: 3, cells: [
          ParsedCell(headerName: 'Code', rawValue: 'PROD-400', columnIndex: 0),
          // Missing required 'name' -> ERROR
        ]),
      ];

      final summary = await previewEngine.generatePreview(
        rawRows: rawRows,
        targetFields: targetFields,
        mappings: mappings,
        existenceChecker: (row, normMap) async => normMap['code'] == 'PROD-101',
        skipChecker: (row, normMap) => normMap['code'] == 'PROD-300',
      );

      final row101 = summary.rows[0];
      expect(row101.action, equals(ImportRowAction.update));
      expect(row101.isSuccess, isTrue);
      expect(row101.explanation, contains('UPDATE'));

      final row200 = summary.rows[1];
      expect(row200.action, equals(ImportRowAction.create));
      expect(row200.isSuccess, isTrue);
      expect(row200.explanation, contains('CREATE'));

      final row300 = summary.rows[2];
      expect(row300.action, equals(ImportRowAction.skip));
      expect(row300.isSuccess, isTrue);
      expect(row300.explanation, contains('skip'));

      final row400 = summary.rows[3];
      expect(row400.action, equals(ImportRowAction.error));
      expect(row400.isSuccess, isFalse);
      expect(row400.explanation, contains('Validation failed'));
    });

    test('4. Relation problem identification & post-import assignment simulation', () async {
      final targetFields = createSchema();
      final mappings = createMappings(targetFields);

      final rawRows = [
        const ParsedRow(rowIndex: 0, cells: [
          ParsedCell(headerName: 'Code', rawValue: 'PROD-901', columnIndex: 0),
          ParsedCell(headerName: 'Name', rawValue: 'Item With Bad Category', columnIndex: 1),
          ParsedCell(headerName: 'Category', rawValue: 'INVALID-CAT', columnIndex: 3),
        ]),
      ];

      final relDefs = [
        RelationDefinition(
          targetEntityKey: 'category_code',
          lookupFn: (rawRef, strat, [companyId]) async {
            if (rawRef == 'CAT-01') {
              return const [ResolvedCandidate(id: 'UUID-CAT-01', displayName: 'Category 1')];
            }
            return [];
          },
        ),
      ];

      final summary = await previewEngine.generatePreview(
        rawRows: rawRows,
        targetFields: targetFields,
        mappings: mappings,
        relationDefinitions: relDefs,
        fixedAssignments: const {'company_id': 'COMP-99'},
      );

      expect(summary.relationProblems, equals(1));
      expect(summary.rows.first.action, equals(ImportRowAction.error));
      expect(summary.rows.first.assignedFields['company_id'], equals('COMP-99'));
      expect(summary.rows.first.hasRelationProblems, isTrue);
    });
  });
}
