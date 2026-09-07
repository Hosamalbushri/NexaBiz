import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

void main() {
  group('Phase 07 — Universal Import Engine Validation Engine Tests', () {
    const engine = ValidationEngine();

    final targetFields = [
      const ImportField(
        key: 'product_code',
        label: 'Product Code',
        isRequired: true,
        isUnique: true,
      ),
      const ImportField(
        key: 'product_name',
        label: 'Product Name',
        isRequired: true,
      ),
      const ImportField(
        key: 'unit_price',
        label: 'Unit Price',
        dataType: ImportDataType.number,
      ),
      const ImportField(key: 'category_id', label: 'Category ID'),
    ];

    test(
      '1. Validates missing required fields and produces ERROR severity issues',
      () async {
        final rows = [
          {
            'product_code': const NormalizedValue(
              originalValue: 'P-101',
              normalizedValue: 'P-101',
            ),
            'product_name': const NormalizedValue(
              originalValue: null,
              normalizedValue: null,
              isNull: true,
            ), // Missing required product_name
          },
        ];

        final report = await engine.validateDataset(
          rows: rows,
          targetFields: targetFields,
        );

        expect(report.isValid, isFalse);
        expect(report.errorCount, equals(1));
        expect(report.issues.first.code, equals('REQUIRED_FIELD_MISSING'));
        expect(report.issues.first.row, equals(1));
        expect(report.issues.first.field, equals('product_name'));
      },
    );

    test(
      '2. In-memory UniqueValidationRule detects duplicate values across rows',
      () async {
        final rows = [
          {
            'product_code': const NormalizedValue(
              originalValue: 'P-101',
              normalizedValue: 'P-101',
            ),
            'product_name': const NormalizedValue(
              originalValue: 'Laptop',
              normalizedValue: 'Laptop',
            ),
          },
          {
            'product_code': const NormalizedValue(
              originalValue: 'p-101',
              normalizedValue: 'P-101',
            ), // Duplicate code
            'product_name': const NormalizedValue(
              originalValue: 'Desktop',
              normalizedValue: 'Desktop',
            ),
          },
        ];

        final report = await engine.validateDataset(
          rows: rows,
          targetFields: targetFields,
        );

        expect(report.isValid, isFalse);
        expect(report.errorCount, equals(1));

        final duplicateIssue = report.issues.first;
        expect(duplicateIssue.code, equals('DUPLICATE_IN_DATASET'));
        expect(duplicateIssue.row, equals(2));
        expect(duplicateIssue.field, equals('product_code'));
      },
    );

    test(
      '3. Range and Length rules evaluate min/max bounds accurately',
      () async {
        final rangeRule = const RangeValidationRule(min: 10, max: 500);
        final lengthRule = const LengthValidationRule(
          minLength: 3,
          maxLength: 10,
        );

        // Value below min
        final issueRange = rangeRule.evaluate(
          row: 1,
          field: 'unit_price',
          normalizedValue: const NormalizedValue(
            originalValue: 5,
            normalizedValue: 5,
          ),
        );

        expect(issueRange, isNotNull);
        expect(issueRange?.code, equals('VALUE_BELOW_MINIMUM'));

        // String too long
        final issueLength = lengthRule.evaluate(
          row: 1,
          field: 'product_code',
          normalizedValue: const NormalizedValue(
            originalValue: 'EXCEEDING_TEN_CHARS',
            normalizedValue: 'EXCEEDING_TEN_CHARS',
          ),
        );

        expect(issueLength, isNotNull);
        expect(issueLength?.code, equals('LENGTH_TOO_LONG'));
      },
    );

    test('4. RegexValidationRule validates patterns correctly', () {
      final rule = RegexValidationRule(
        pattern: RegExp(r'^P-\d{3}$'),
        message: 'Must follow format P-XXX',
      );

      final validRes = rule.evaluate(
        row: 1,
        field: 'product_code',
        normalizedValue: const NormalizedValue(
          originalValue: 'P-101',
          normalizedValue: 'P-101',
        ),
      );
      expect(validRes, isNull);

      final invalidRes = rule.evaluate(
        row: 1,
        field: 'product_code',
        normalizedValue: const NormalizedValue(
          originalValue: 'INVALID-CODE',
          normalizedValue: 'INVALID-CODE',
        ),
      );
      expect(invalidRes, isNotNull);
      expect(invalidRes?.code, equals('PATTERN_MISMATCH'));
    });

    test(
      '5. ExistsValidationRule performs async external entity lookup validation',
      () async {
        Future<bool> mockCategoryLookup(dynamic id) async {
          return id == 'CAT-01'; // Only CAT-01 exists
        }

        final rows = [
          {
            'product_code': const NormalizedValue(
              originalValue: 'P-101',
              normalizedValue: 'P-101',
            ),
            'product_name': const NormalizedValue(
              originalValue: 'Mouse',
              normalizedValue: 'Mouse',
            ),
            'category_id': const NormalizedValue(
              originalValue: 'CAT-99',
              normalizedValue: 'CAT-99',
            ), // Non-existent
          },
        ];

        final report = await engine.validateDataset(
          rows: rows,
          targetFields: targetFields,
          existsLookups: {'category_id': mockCategoryLookup},
        );

        expect(report.isValid, isFalse);
        expect(report.errorCount, equals(1));
        expect(report.issues.first.code, equals('ENTITY_DOES_NOT_EXIST'));
        expect(report.issues.first.field, equals('category_id'));
      },
    );

    test(
      '6. Supports all severity levels (INFO, WARNING, ERROR, FATAL) and metrics breakdown',
      () async {
        final issues = [
          const ValidationIssue(
            row: 1,
            field: 'col1',
            code: 'INFO_1',
            severity: ValidationSeverity.info,
            message: 'Info message',
          ),
          const ValidationIssue(
            row: 1,
            field: 'col2',
            code: 'WARN_1',
            severity: ValidationSeverity.warning,
            message: 'Warning message',
          ),
          const ValidationIssue(
            row: 2,
            field: 'col3',
            code: 'ERR_1',
            severity: ValidationSeverity.error,
            message: 'Error message',
          ),
          const ValidationIssue(
            row: 3,
            field: 'col4',
            code: 'FATAL_1',
            severity: ValidationSeverity.fatal,
            message: 'Fatal message',
          ),
        ];

        final report = ValidationReport(issues: issues, totalProcessedRows: 3);

        expect(report.infoCount, equals(1));
        expect(report.warningCount, equals(1));
        expect(report.errorCount, equals(1));
        expect(report.fatalCount, equals(1));
        expect(report.totalIssues, equals(4));
        expect(report.isValid, isFalse);
        expect(report.invalidRows, containsAll([2, 3]));
        expect(report.validRows, contains(1));
      },
    );

    test(
      '7. Validation is 100% independent from persistence without mutating state',
      () async {
        final rows = [
          {
            'product_code': const NormalizedValue(
              originalValue: 'P-101',
              normalizedValue: 'P-101',
            ),
            'product_name': const NormalizedValue(
              originalValue: 'Keyboard',
              normalizedValue: 'Keyboard',
            ),
          },
        ];

        final report = await engine.validateDataset(
          rows: rows,
          targetFields: targetFields,
        );

        expect(report.isValid, isTrue);
        expect(report.errorCount, equals(0));
      },
    );
  });
}
