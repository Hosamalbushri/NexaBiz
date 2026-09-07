import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

void main() {
  group('Phase 20 — Universal Import Engine UI Widget Tests', () {
    late ImportProfile testProfile;

    setUp(() {
      testProfile = ImportProfile(
        profileId: 'PROF-PRODUCT-TEST',
        label: 'Product Import Profile',
        entityType: 'Product',
        fields: const [
          ImportField(
            key: 'code',
            label: 'Item Code / SKU',
            dataType: ImportDataType.text,
            isRequired: true,
          ),
          ImportField(
            key: 'name',
            label: 'Product Name',
            dataType: ImportDataType.text,
            isRequired: true,
          ),
          ImportField(
            key: 'price',
            label: 'Unit Price',
            dataType: ImportDataType.number,
            isRequired: true,
          ),
          ImportField(
            key: 'unitCost',
            label: 'Unit Cost',
            dataType: ImportDataType.number,
          ),
        ],
        relations: const [
          ImportRelation(
            relationKey: 'category',
            targetEntityType: 'Category',
            lookupFieldKey: 'code',
            isRequired: true,
          ),
          ImportRelation(
            relationKey: 'warehouse',
            targetEntityType: 'Warehouse',
            lookupFieldKey: 'code',
          ),
          ImportRelation(
            relationKey: 'inventory_account',
            targetEntityType: 'Account',
            lookupFieldKey: 'code',
          ),
        ],
      );
    });

    testWidgets(
      '1. Wizard Navigation: Renders Step 1 Source Selection and progresses',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: UniversalImportWizardPage(
                companyId: 'COMP-100',
                userId: 'USER-001',
                registeredProfiles: [testProfile],
              ),
            ),
          ),
        );

        expect(
          find.text('Universal Import Wizard (Step 1 of 11)'),
          findsOneWidget,
        );
        expect(find.text('Step 1: Select Import Source'), findsOneWidget);

        final inputField = find.byKey(const Key('source_raw_text_input'));
        expect(inputField, findsOneWidget);
        await tester.enterText(
          inputField,
          'code,name,price\nP001,Laptop,1200.00\nP002,Mouse,25.00',
        );
        await tester.pump();

        final nextBtn = find.byKey(const Key('wizard_next_button'));
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();

        expect(
          find.text('Universal Import Wizard (Step 2 of 11)'),
          findsOneWidget,
        );
        expect(
          find.text('Step 2: Select Target Import Profile'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '2. Dynamic Assignments: Generates form controls dynamically from ImportProfile',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final assignmentsMap = <String, dynamic>{};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StepDynamicAssignments(
                profile: testProfile,
                assignments: assignmentsMap,
                onAssignmentChanged: (key, val) {
                  if (val == null) {
                    assignmentsMap.remove(key);
                  } else {
                    assignmentsMap[key] = val;
                  }
                },
              ),
            ),
          ),
        );

        expect(find.text('category *'), findsOneWidget);
        expect(find.text('warehouse'), findsOneWidget);
        expect(find.text('inventory_account'), findsOneWidget);

        expect(find.text('Default Item Code / SKU (code)'), findsOneWidget);
        expect(find.text('Default Product Name (name)'), findsOneWidget);

        final categoryInput = find.byKey(
          const Key('assignment_relation_category'),
        );
        expect(categoryInput, findsOneWidget);
        await tester.enterText(categoryInput, 'Computers');
        await tester.pump();

        expect(assignmentsMap['category'], equals('Computers'));
      },
    );

    testWidgets(
      '3. Background Detachment: Start Import triggers worker and displays status',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        bool importStartedCalled = false;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: UniversalImportWizardPage(
                companyId: 'COMP-100',
                userId: 'USER-001',
                registeredProfiles: [testProfile],
                onImportStarted: () {
                  importStartedCalled = true;
                },
              ),
            ),
          ),
        );

        await tester.enterText(
          find.byKey(const Key('source_raw_text_input')),
          'code,name,price\nP001,Laptop,1200.00',
        );
        await tester.pump();

        await tester.tap(find.byKey(const Key('wizard_next_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('profile_selection_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Product Import Profile (Product)').last);
        await tester.pumpAndSettle();

        for (int i = 2; i <= 9; i++) {
          await tester.tap(find.byKey(const Key('wizard_next_button')));
          await tester.pumpAndSettle();
        }

        expect(find.text('Import Started Successfully!'), findsOneWidget);
        expect(importStartedCalled, isTrue);
      },
    );

    testWidgets(
      '4. Import Jobs List UI: Renders jobs, progress bar, and control buttons',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = InMemoryImportJobRepository();
        final job = ImportJob(
          jobId: 'JOB-TEST-999',
          companyId: 'COMP-100',
          userId: 'USER-001',
          source: 'CSV',
          profile: testProfile,
          status: ImportJobStatus.processing,
          createdAt: DateTime.now().toUtc(),
          totalRows: 100,
          processedRows: 40,
          successfulRows: 38,
          failedRows: 2,
          progress: 0.4,
        );
        await repo.save(job);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [importJobRepositoryProvider.overrideWithValue(repo)],
            child: MaterialApp(home: ImportJobsListPage(companyId: 'COMP-100')),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('JOB-TEST-999'), findsOneWidget);
        expect(find.text('PROCESSING'), findsOneWidget);
        expect(find.text('Rows: 40 / 100 (40.0%)'), findsOneWidget);
        expect(
          find.byKey(const Key('job_pause_btn_JOB-TEST-999')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('job_cancel_btn_JOB-TEST-999')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '5. Import Job Details & Report UI: Renders metrics and error details',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final job = ImportJob(
          jobId: 'JOB-TEST-100',
          companyId: 'COMP-100',
          userId: 'USER-001',
          source: 'CSV',
          profile: testProfile,
          status: ImportJobStatus.completedWithErrors,
          createdAt: DateTime.now().toUtc(),
          totalRows: 50,
          processedRows: 50,
          successfulRows: 48,
          failedRows: 2,
          errorSummary: ['2 rows failed validation'],
        );

        await tester.pumpWidget(
          MaterialApp(home: ImportJobDetailsPage(job: job)),
        );

        expect(find.text('Job Details: JOB-TEST-100'), findsOneWidget);
        expect(find.text('Total Rows'), findsOneWidget);
        expect(find.text('Error Summary'), findsOneWidget);
        expect(find.text('2 rows failed validation'), findsOneWidget);

        final report = ImportReport(
          auditRecord: ImportAuditRecord(
            auditId: 'AUD-TEST-100',
            jobId: 'JOB-TEST-100',
            companyId: 'COMP-100',
            userId: 'USER-001',
            source: 'CSV',
            entityType: 'Product',
            configuration: const {},
            mappingSummary: const {},
            startedAt: DateTime.now().toUtc(),
            completedAt: DateTime.now().toUtc(),
            totalRows: 50,
            createdRows: 48,
            updatedRows: 0,
            skippedRows: 0,
            failedRows: 2,
            warningCount: 0,
            errorCount: 2,
          ),
          errorReports: [
            ImportErrorReport(
              jobId: 'JOB-TEST-100',
              rowIndex: 13,
              fieldKey: 'price',
              errorCode: 'INVALID_NUMBER',
              message: 'Price must be a valid positive number',
              severity: 'error',
              rawValue: 'abc',
              timestamp: DateTime.now().toUtc(),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(home: ImportReportPage(report: report)),
        );

        expect(find.text('Import Report: JOB-TEST-100'), findsOneWidget);
        expect(find.text('Row 13: price (INVALID_NUMBER)'), findsOneWidget);
        expect(
          find.text('Price must be a valid positive number'),
          findsOneWidget,
        );
      },
    );
  });
}
