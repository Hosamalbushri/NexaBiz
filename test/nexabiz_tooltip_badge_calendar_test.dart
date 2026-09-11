import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:nexabiz_ui/nexabiz_ui.dart';

Widget buildTestApp(Widget child) {
  return shadcn.ShadcnApp(
    home: shadcn.DrawerOverlay(
      child: Scaffold(
        body: Center(child: child),
      ),
    ),
  );
}

void main() {
  group('Tooltip Level 0 Direct Behavioral Tests', () {
    testWidgets('renders Tooltip trigger and TooltipContainer content', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          shadcn.Tooltip(
            tooltip: (context) => const shadcn.TooltipContainer(
              child: Text('معلومات إضافية'),
            ),
            child: const IconButton(
              icon: Icon(Icons.info),
              onPressed: null,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.info), findsOneWidget);
    });
  });

  group('AppStatusBadge Behavioral Tests', () {
    testWidgets('renders AppStatusBadge across all AppStatusTone variants with shadcn badge primitives', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Column(
            children: const [
              AppStatusBadge(label: 'مكتمل', tone: AppStatusTone.success, animate: false),
              AppStatusBadge(label: 'قيد الانتظار', tone: AppStatusTone.warning, animate: false),
              AppStatusBadge(label: 'ملغي', tone: AppStatusTone.error, animate: false),
              AppStatusBadge(label: 'مسودة', tone: AppStatusTone.info, animate: false),
              AppStatusBadge(label: 'عادي', tone: AppStatusTone.neutral, animate: false),
            ],
          ),
        ),
      );

      expect(find.text('مكتمل'), findsOneWidget);
      expect(find.text('قيد الانتظار'), findsOneWidget);
      expect(find.text('ملغي'), findsOneWidget);
      expect(find.text('مسودة'), findsOneWidget);
      expect(find.text('عادي'), findsOneWidget);

      expect(find.byType(shadcn.PrimaryBadge), findsOneWidget);
      expect(find.byType(shadcn.SecondaryBadge), findsOneWidget);
      expect(find.byType(shadcn.DestructiveBadge), findsOneWidget);
      expect(find.byType(shadcn.OutlineBadge), findsNWidgets(2));
    });
  });

  group('Calendar & Date Field Behavioral Tests', () {
    testWidgets('shadcn Calendar single and range selection state independence', (tester) async {
      final singleVal = shadcn.CalendarValue.single(DateTime(2026, 9, 11));
      final view = singleVal.view;

      expect(singleVal.lookup(2026, 9, 11), equals(shadcn.CalendarValueLookup.selected));

      final nextView = view.next;
      expect(nextView.month, equals(10));
      expect(singleVal.lookup(2026, 9, 11), equals(shadcn.CalendarValueLookup.selected));

      final rangeVal = shadcn.CalendarValue.range(DateTime(2026, 9, 1), DateTime(2026, 9, 15));
      expect(rangeVal.lookup(2026, 9, 1), equals(shadcn.CalendarValueLookup.start));
      expect(rangeVal.lookup(2026, 9, 15), equals(shadcn.CalendarValueLookup.end));
      expect(rangeVal.lookup(2026, 9, 10), equals(shadcn.CalendarValueLookup.inRange));
    });

    testWidgets('AppDateField and AppDateRangeField render label and placeholder', (tester) async {
      DateTime? selectedDate;
      shadcn.DateTimeRange? selectedRange;

      await tester.pumpWidget(
        buildTestApp(
          Column(
            children: [
              AppDateField(
                label: 'تاريخ الفاتورة',
                value: selectedDate,
                onChanged: (val) => selectedDate = val,
              ),
              AppDateRangeField(
                label: 'الفترة المالية',
                value: selectedRange,
                onChanged: (val) => selectedRange = val,
              ),
            ],
          ),
        ),
      );

      expect(find.text('تاريخ الفاتورة'), findsOneWidget);
      expect(find.text('الفترة المالية'), findsOneWidget);
      expect(find.byType(AppDateField), findsOneWidget);
      expect(find.byType(AppDateRangeField), findsOneWidget);
    });
  });
}
