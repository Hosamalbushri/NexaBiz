import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

void main() {
  group('Universal Import Engine — Architecture Foundation Unit Tests', () {
    test('1. Generic profile creation and field lookups work correctly', () {
      final codeField = const ImportField(
        key: 'code',
        label: 'Item Code',
        dataType: ImportDataType.text,
        isRequired: true,
        isUnique: true,
        aliases: ['رمز', 'كود', 'item_code'],
      );

      final nameField = const ImportField(
        key: 'name',
        label: 'Item Name',
        dataType: ImportDataType.text,
        isRequired: true,
        aliases: ['الاسم', 'اسم_العنصر', 'item_name'],
      );

      final profile = ImportProfile(
        profileId: 'generic_item_profile',
        entityType: 'generic_item',
        label: 'Generic Item Profile',
        fields: [codeField, nameField],
      );

      expect(profile.profileId, equals('generic_item_profile'));
      expect(profile.entityType, equals('generic_item'));
      expect(profile.fields.length, equals(2));

      // Test field lookup by key and aliases
      expect(profile.findField('code'), equals(codeField));
      expect(profile.findField('كود'), equals(codeField));
      expect(profile.findField('ITEM_CODE'), equals(codeField));
      expect(profile.findField('الاسم'), equals(nameField));
      expect(profile.findField('non_existent'), isNull);
    });

    test(
      '2. Configuration creation and mapping assignments resolve correctly',
      () {
        final assignment1 = const ImportAssignment(
          targetFieldKey: 'code',
          sourceHeader: 'كود المنتج',
        );
        final assignment2 = const ImportAssignment(
          targetFieldKey: 'status',
          staticValue: 'active',
        );

        final config = ImportConfiguration(
          profileId: 'generic_item_profile',
          assignments: [assignment1, assignment2],
          executionMode: ImportExecutionMode.commit,
          policy: const ImportPolicy(batchSize: 250),
        );

        expect(config.profileId, equals('generic_item_profile'));
        expect(config.hasAssignmentFor('code'), isTrue);
        expect(config.hasAssignmentFor('status'), isTrue);
        expect(config.hasAssignmentFor('price'), isFalse);

        expect(
          config.getAssignmentFor('code')?.sourceHeader,
          equals('كود المنتج'),
        );
        expect(config.getAssignmentFor('status')?.isStatic, isTrue);
        expect(
          config.getAssignmentFor('status')?.staticValue,
          equals('active'),
        );
        expect(config.policy.batchSize, equals(250));
      },
    );

    test('3. Company context requirement is enforced strictly', () {
      const validContext = ImportContext(
        companyId: 'comp_12345',
        userId: 'user_99',
        locale: 'ar',
      );

      expect(validContext.hasValidCompanyContext, isTrue);
      expect(() => validContext.requireCompanyContext(), returnsNormally);

      const emptyContext = ImportContext(companyId: '   ');
      expect(emptyContext.hasValidCompanyContext, isFalse);
      expect(
        () => emptyContext.requireCompanyContext(),
        throwsA(
          isA<ImportContextException>().having(
            (e) => e.code,
            'code',
            equals('MISSING_COMPANY_CONTEXT'),
          ),
        ),
      );

      // Verify ImportJob enforces valid company context at instantiation
      expect(
        () => ImportJob(
          jobId: 'job_001',
          companyId: '   ',
          userId: 'user_99',
          source: 'test.csv',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      '4. ImportJobStatus transitions follow valid lifecycle progression',
      () {
        var job = ImportJob(
          jobId: 'job_test_1',
          companyId: 'comp_001',
          userId: 'user_01',
          source: 'test.csv',
        );

        expect(job.status, equals(ImportJobStatus.queued));

        job = job.transitionTo(ImportJobStatus.preparing);
        expect(job.status, equals(ImportJobStatus.preparing));

        job = job.transitionTo(ImportJobStatus.processing);
        expect(job.status, equals(ImportJobStatus.processing));

        job = job.transitionTo(ImportJobStatus.completed);
        expect(job.status, equals(ImportJobStatus.completed));
        expect(job.status.isTerminal, isTrue);
      },
    );

    test('5. Invalid status transitions are rejected', () {
      final job = ImportJob(
        jobId: 'job_test_2',
        companyId: 'comp_001',
        userId: 'user_01',
        source: 'test.csv',
      );

      // Transition job to terminal completed status
      final completedJob = job
          .transitionTo(ImportJobStatus.preparing)
          .transitionTo(ImportJobStatus.processing)
          .transitionTo(ImportJobStatus.completed);

      // Terminal state cannot transition back to processing or queued
      expect(
        () => completedJob.transitionTo(ImportJobStatus.processing),
        throwsA(isA<ImportStatusTransitionException>()),
      );
    });

    test('6. Invalid profiles and duplicate field keys are rejected', () {
      expect(
        () => ImportProfile(
          profileId: '',
          entityType: 'valid_entity',
          label: 'Label',
          fields: [],
        ),
        throwsA(
          isA<ImportProfileValidationException>().having(
            (e) => e.code,
            'code',
            equals('EMPTY_PROFILE_ID'),
          ),
        ),
      );

      expect(
        () => ImportProfile(
          profileId: 'prof_1',
          entityType: '   ',
          label: 'Label',
          fields: [],
        ),
        throwsA(
          isA<ImportProfileValidationException>().having(
            (e) => e.code,
            'code',
            equals('EMPTY_ENTITY_TYPE'),
          ),
        ),
      );

      final dupField1 = const ImportField(key: 'code', label: 'Code');
      final dupField2 = const ImportField(key: 'code', label: 'Duplicate Code');

      expect(
        () => ImportProfile(
          profileId: 'prof_dup',
          entityType: 'entity_dup',
          label: 'Label',
          fields: [dupField1, dupField2],
        ),
        throwsA(
          isA<ImportProfileValidationException>().having(
            (e) => e.code,
            'code',
            equals('DUPLICATE_FIELD_KEY'),
          ),
        ),
      );
    });
  });
}
