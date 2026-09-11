import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:nexabiz_ui/nexabiz_ui.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return shadcn.ShadcnApp(
      home: shadcn.DrawerOverlay(
        child: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('AppFormSheet Behavioral Tests', () {
    testWidgets('renders AppFormSheet header, form body, and footer buttons', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppFormSheet.show(
                    context: context,
                    title: 'تعديل البيانات',
                    subtitle: 'إدخال معلومات العميل',
                    icon: Icons.edit,
                    child: Column(
                      children: const [
                        shadcn.FormEntry(
                          key: shadcn.FormKey<String>('name'),
                          child: Text('اسم العميل'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Open Form Sheet'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Form Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('تعديل البيانات'), findsOneWidget);
      expect(find.text('إدخال معلومات العميل'), findsOneWidget);
      expect(find.text('اسم العميل'), findsOneWidget);
      expect(find.text('حفظ'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
    });

    testWidgets('executes onSubmit callback with form values and dismisses on success', (tester) async {
      bool submitted = false;
      shadcn.FormMapValues? capturedValues;

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppFormSheet.show(
                    context: context,
                    title: 'نموذج اختبار',
                    onSubmit: (ctx, values) {
                      submitted = true;
                      capturedValues = values;
                    },
                    child: Column(
                      children: const [
                        shadcn.FormEntry(
                          key: shadcn.FormKey<String>('test_key'),
                          child: Text('حقل تجريبي'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Open Form Sheet'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Form Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('نموذج اختبار'), findsOneWidget);

      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      expect(submitted, isTrue);
      expect(capturedValues, isNotNull);
      expect(find.text('نموذج اختبار'), findsNothing);
    });

    testWidgets('displays error banner if onSubmit throws exception', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppFormSheet.show(
                    context: context,
                    title: 'نموذج خطأ',
                    onSubmit: (ctx, values) async {
                      throw Exception('فشل في حفظ البيانات');
                    },
                    child: const Text('المحتوى'),
                  );
                },
                child: const Text('Open Form Sheet'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Form Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      expect(find.textContaining('فشل في حفظ البيانات'), findsOneWidget);
      expect(find.text('نموذج خطأ'), findsOneWidget);
    });
  });

  group('AppSwiperSheet Behavioral Tests', () {
    testWidgets('renders trigger child correctly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          AppSwiperSheet(
            overlayBuilder: (context) => const Text('محتوى السحب'),
            child: Container(
              key: const Key('swiper_trigger'),
              child: const Text('اسحب هنا'),
            ),
          ),
        ),
      );

      expect(find.text('اسحب هنا'), findsOneWidget);
      expect(find.byKey(const Key('swiper_trigger')), findsOneWidget);
    });
  });
}
