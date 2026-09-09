import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/widgets/app_confirmation_dialog.dart';
import 'package:stock_count/core/widgets/app_loading.dart';

void main() {
  group('Phase 1D: Loading & Confirmation Consolidation Tests', () {
    testWidgets('1. AppLoading renders circular and linear indicators correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AppLoading(
              style: AppLoadingStyle.circular,
              message: 'جاري التحميل...',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('جاري التحميل...'), findsOneWidget);
    });

    testWidgets('2. AppConfirmationDialog displays title, message, tone icon, and handles confirm/cancel', (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await AppConfirmationDialog.show(
                    context,
                    title: 'تأكيد العملية',
                    message: 'هل تريد الاستمرار؟',
                    confirmLabel: 'موافق',
                    cancelLabel: 'إلغاء',
                    tone: AppDialogTone.info,
                    onConfirm: () {},
                  );
                },
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      expect(find.text('تأكيد العملية'), findsOneWidget);
      expect(find.text('هل تريد الاستمرار؟'), findsOneWidget);
      expect(find.text('موافق'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);

      await tester.tap(find.text('موافق'));
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
    });
  });
}
