import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/di/app_providers.dart';

void main() {
  Widget buildTestApp({
    Locale? locale,
    Widget? child,
    List<LocalizationsDelegate<dynamic>>? extraDelegates,
  }) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        NexaBizShadcnLocalizationsDelegate.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        ...?extraDelegates,
      ],
      home: Scaffold(
        body: child ?? const SizedBox.shrink(),
      ),
    );
  }

  group('NexaBiz Localization & Internationalization Behavioral Tests', () {
    test('Test 1 — Supported Locales: AppLocalizations contains ar and en', () {
      expect(AppLocalizations.supportedLocales, contains(const Locale('ar')));
      expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
      expect(AppLocalizations.supportedLocales.length, equals(2));
    });

    testWidgets('Test 2 — AppLocalizations Loading: Loads in en and ar', (tester) async {
      AppLocalizations? enL10n;
      AppLocalizations? arL10n;

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('en'),
          child: Builder(
            builder: (context) {
              enL10n = AppLocalizations.of(context);
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('ar'),
          child: Builder(
            builder: (context) {
              arL10n = AppLocalizations.of(context);
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(enL10n, isNotNull);
      expect(arL10n, isNotNull);
      expect(enL10n!.appTitle, equals('NexaBiz'));
      expect(arL10n!.appTitle, equals('NexaBiz'));
    });

    testWidgets('Test 3 — ShadcnLocalizations (English): Returns valid instance in en', (tester) async {
      shadcn.ShadcnLocalizations? shadcnL10n;

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('en'),
          child: Builder(
            builder: (context) {
              shadcnL10n = shadcn.ShadcnLocalizations.of(context);
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(shadcnL10n, isNotNull);
      expect(shadcnL10n!.buttonCancel, equals('Cancel'));
      expect(shadcnL10n!.buttonSave, equals('Save'));
    });

    testWidgets('Test 4 — ShadcnLocalizations Fallback (Arabic): Safely loads fallback without throwing', (tester) async {
      shadcn.ShadcnLocalizations? shadcnL10n;

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('ar'),
          child: Builder(
            builder: (context) {
              shadcnL10n = shadcn.ShadcnLocalizations.of(context);
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(shadcnL10n, isNotNull);
      expect(shadcnL10n!.buttonCancel, isNotEmpty);
    });

    testWidgets('Test 5 — Co-existence: ShadcnLocalizations and AppLocalizations co-exist in tree', (tester) async {
      AppLocalizations? appL10n;
      shadcn.ShadcnLocalizations? shadcnL10n;

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('en'),
          child: Builder(
            builder: (context) {
              appL10n = AppLocalizations.of(context);
              shadcnL10n = shadcn.ShadcnLocalizations.of(context);
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(appL10n, isNotNull);
      expect(shadcnL10n, isNotNull);
      expect(appL10n!.servicesTitle, equals('Services'));
      expect(shadcnL10n!.buttonSave, equals('Save'));
    });

    testWidgets('Test 6 — Locale Switching: Mode updates localized string output', (tester) async {
      String? titleEn;
      String? titleAr;

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('en'),
          child: Builder(
            builder: (context) {
              titleEn = AppLocalizations.of(context).moduleInventory;
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('ar'),
          child: Builder(
            builder: (context) {
              titleAr = AppLocalizations.of(context).moduleInventory;
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(titleEn, equals('Inventory'));
      expect(titleAr, equals('المخزون'));
    });

    testWidgets('Test 7 — RTL Directionality: TextDirection is RTL for Arabic', (tester) async {
      TextDirection? direction;

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('ar'),
          child: Builder(
            builder: (context) {
              direction = Directionality.of(context);
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(direction, equals(TextDirection.rtl));
    });

    testWidgets('Test 8 — LTR Directionality: TextDirection is LTR for English', (tester) async {
      TextDirection? direction;

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('en'),
          child: Builder(
            builder: (context) {
              direction = Directionality.of(context);
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(direction, equals(TextDirection.ltr));
    });

    testWidgets('Test 9 — Riverpod Provider Integration: localeProvider triggers rebuild', (tester) async {
      final container = ProviderContainer(
        overrides: [
          localeProvider.overrideWith((ref) => const Locale('en')),
        ],
      );

      TextDirection? capturedDirection;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, child) {
              final activeLocale = ref.watch(localeProvider);
              return buildTestApp(
                locale: activeLocale,
                child: Builder(
                  builder: (context) {
                    capturedDirection = Directionality.of(context);
                    return Container();
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedDirection, equals(TextDirection.ltr));

      // Switch to Arabic
      container.read(localeProvider.notifier).state = const Locale('ar');
      await tester.pumpAndSettle();

      expect(capturedDirection, equals(TextDirection.rtl));
    });

    testWidgets('Test 10 — Fallback Locale: Unsupported locale falls back to supported locale', (tester) async {
      AppLocalizations? l10n;

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('fr'),
          child: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(l10n, isNotNull);
    });

    testWidgets('Test 11 — Design System Decoupling: AppDialog accepts localized strings', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('en'),
          child: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              final shadcnL10n = shadcn.ShadcnLocalizations.of(context);
              return AppDialog(
                title: l10n.servicesTitle,
                confirmLabel: shadcnL10n.buttonSave,
                cancelLabel: shadcnL10n.buttonCancel,
                onConfirm: () {},
                onCancel: () {},
                child: Text(l10n.servicesSubtitle),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
