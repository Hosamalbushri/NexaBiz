import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/presentation/scaffolds/module_form_scaffold.dart';
import 'package:stock_count/core/presentation/scaffolds/module_list_scaffold.dart';
import 'package:stock_count/core/presentation/widgets/app_form_fields.dart';
import 'package:stock_count/core/presentation/widgets/app_state_feedback.dart';
import 'package:stock_count/core/presentation/widgets/search_filter_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feedback State Widgets Test Suite', () {
    testWidgets('AppLoadingState renders message and indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingState(message: 'جاري تحميل البيانات...'),
          ),
        ),
      );

      expect(find.text('جاري تحميل البيانات...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppErrorState renders title, error, and triggers retry', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorState(
              title: 'خطأ الاتصال',
              message: 'تعذر الاتصال بالسيرفر',
              onRetry: () {
                retried = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('خطأ الاتصال'), findsOneWidget);
      expect(find.text('تعذر الاتصال بالسيرفر'), findsOneWidget);

      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('AppEmptyState renders empty title, message, and triggers action button', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              title: 'لا يوجد مخزون',
              message: 'اضغط إضافة لإنشاء عنصر جديد',
              actionLabel: 'إضافة عنصر',
              onAction: () {
                actionTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('لا يوجد مخزون'), findsOneWidget);
      expect(find.text('اضغط إضافة لإنشاء عنصر جديد'), findsOneWidget);

      await tester.tap(find.text('إضافة عنصر'));
      await tester.pump();

      expect(actionTriggered, isTrue);
    });
  });

  group('SearchFilterBar Widget Test Suite', () {
    testWidgets('SearchFilterBar handles input, clear, and filter button tap', (tester) async {
      String searchResult = '';
      bool filterTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterBar(
              searchHint: 'ابحث عن منتج...',
              debounceMs: 50,
              onSearchChanged: (val) {
                searchResult = val;
              },
              onFilterTap: () {
                filterTapped = true;
              },
              activeFilterCount: 2,
            ),
          ),
        ),
      );

      // Enter search text
      await tester.enterText(find.byType(TextField), 'حليب');
      await tester.pump(const Duration(milliseconds: 100));

      expect(searchResult, equals('حليب'));
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);

      // Tap filter icon
      await tester.tap(find.byIcon(Icons.filter_list_rounded));
      await tester.pump();
      expect(filterTapped, isTrue);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      expect(searchResult, equals(''));
    });
  });

  group('AppFormFields Widget Test Suite', () {
    testWidgets('AppTextField enforces 48dp minimum touch target and validation', (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: AppTextField(
                label: 'اسم المستخدم',
                validator: (val) => val == null || val.isEmpty ? 'حقل مطلوب' : null,
              ),
            ),
          ),
        ),
      );

      final textFieldBox = tester.getRect(find.byType(TextFormField));
      expect(textFieldBox.height, greaterThanOrEqualTo(48.0));

      // Trigger validation
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('حقل مطلوب'), findsOneWidget);
    });

    testWidgets('AppFormSection renders title, icon, and children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppFormSection(
              title: 'البيانات الأساسية',
              icon: Icons.info_outline,
              children: [
                Text('عنصر التابع الأول'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('البيانات الأساسية'), findsOneWidget);
      expect(find.text('عنصر التابع الأول'), findsOneWidget);
    });
  });

  group('ModuleListScaffold Widget Test Suite', () {
    testWidgets('ModuleListScaffold renders loading, empty, and populated items', (tester) async {
      // 1. Loading State
      await tester.pumpWidget(
        MaterialApp(
          home: ModuleListScaffold<String>(
            title: 'قائمة المنتجات',
            items: const [],
            isLoading: true,
            itemBuilder: (ctx, item) => Text(item),
          ),
        ),
      );
      expect(find.byType(AppLoadingState), findsOneWidget);

      // 2. Empty State
      await tester.pumpWidget(
        MaterialApp(
          home: ModuleListScaffold<String>(
            title: 'قائمة المنتجات',
            items: const [],
            isLoading: false,
            emptyTitle: 'لا توجد منتجات',
            itemBuilder: (ctx, item) => Text(item),
          ),
        ),
      );
      expect(find.text('لا توجد منتجات'), findsOneWidget);

      // 3. Populated Items List
      await tester.pumpWidget(
        MaterialApp(
          home: ModuleListScaffold<String>(
            title: 'قائمة المنتجات',
            items: const ['منتج A', 'منتج B'],
            isLoading: false,
            itemBuilder: (ctx, item) => Text(item),
          ),
        ),
      );
      expect(find.text('منتج A'), findsOneWidget);
      expect(find.text('منتج B'), findsOneWidget);
    });

    testWidgets('ModuleListScaffold renders grid delegate layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ModuleListScaffold<String>(
            title: 'شبكة المنتجات',
            items: const ['منتج 1', 'منتج 2'],
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemBuilder: (ctx, item) => Card(child: Text(item)),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('منتج 1'), findsOneWidget);
      expect(find.text('منتج 2'), findsOneWidget);
    });
  });

  group('ModuleFormScaffold Widget Test Suite', () {
    testWidgets('ModuleFormScaffold validates form and triggers onSave', (tester) async {
      final formKey = GlobalKey<FormState>();
      bool saved = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ModuleFormScaffold(
            title: 'إضافة منتج',
            formKey: formKey,
            onSave: () async {
              saved = true;
            },
            body: AppTextField(
              label: 'رمز المنتج',
              validator: (val) => val == null || val.isEmpty ? 'الرمز مطلوب' : null,
            ),
          ),
        ),
      );

      // Tap save without filling field -> validation fails
      await tester.tap(find.text('حفظ'));
      await tester.pump();

      expect(find.text('الرمز مطلوب'), findsOneWidget);
      expect(saved, isFalse);

      // Fill field -> validation succeeds
      await tester.enterText(find.byType(TextFormField), 'PRD-001');
      await tester.tap(find.text('حفظ'));
      await tester.pump();

      expect(saved, isTrue);
    });
  });
}
