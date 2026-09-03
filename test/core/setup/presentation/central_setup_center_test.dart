import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/setup/presentation/widgets/central_setup_center_widget.dart';
import 'package:stock_count/core/setup/presentation/widgets/package_setup_view.dart';
import 'package:stock_count/core/setup/presentation/widgets/setup_field_renderer.dart';
import 'package:stock_count/core/setup/presentation/widgets/setup_section_card.dart';
import 'package:stock_count/core/setup/setup.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';

import 'package:stock_count/modules/sales/sales_module_setup.dart';
import 'package:stock_count/modules/customers/customers_module_setup.dart';
import 'package:stock_count/modules/receipts_payments/receipts_payments_module_setup.dart';

void main() {
  group('Phase 7 — Central Setup Center UI Tests', () {
    late CentralSetupRegistry registry;

    setUp(() {
      registry = CentralSetupRegistry();
      registerSalesSetup(registry);
      registerCustomersSetup(registry);
      registerReceiptsPaymentsSetup(registry);
    });

    Widget createTestableWidget(Widget child, {Locale locale = const Locale('ar'), CentralSetupRegistry? customRegistry}) {
      return ProviderScope(
        overrides: [
          centralSetupRegistryProvider.overrideWithValue(customRegistry ?? registry),
          accountsProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    testWidgets('1. CentralSetupCenterWidget renders registered packages dynamically', (tester) async {
      await tester.pumpWidget(createTestableWidget(const CentralSetupCenterWidget()));
      await tester.pumpAndSettle();

      // Verify registered packages are displayed
      expect(find.text('إعدادات المبيعات'), findsWidgets);
      expect(find.text('sales'), findsWidgets);
    });

    testWidgets('2. Displays NOT CONFIGURED status badge for unbound required account fields', (tester) async {
      const field = SetupField(
        id: 'sales_account',
        sectionId: 'account_requirements',
        key: 'sales_account',
        labelAr: 'حساب مبيعات البضائع (إيرادات)',
        labelEn: 'Sales Revenue Account',
        fieldType: SetupFieldType.reference,
        isRequired: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SetupFieldRenderer(
              field: field,
              currentValue: null,
              onChanged: (_) {},
              isArabic: true,
              availableAccounts: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('غير مهيأ'), findsOneWidget);
      expect(find.text('NOT CONFIGURED'), findsNothing);
    });

    testWidgets('3. Renders CONFIGURED badge when account reference is bound', (tester) async {
      const field = SetupField(
        id: 'sales_account',
        sectionId: 'account_requirements',
        key: 'sales_account',
        labelAr: 'حساب مبيعات البضائع (إيرادات)',
        labelEn: 'Sales Revenue Account',
        fieldType: SetupFieldType.reference,
        isRequired: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SetupFieldRenderer(
              field: field,
              currentValue: 'uuid_account_123',
              onChanged: (_) {},
              isArabic: true,
              availableAccounts: const [
                SetupAccountOption(uuid: 'uuid_account_123', code: '4101', name: 'مبيعات عامة'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مربوط'), findsOneWidget);
      expect(find.text('4101 - مبيعات عامة'), findsOneWidget);
    });

    testWidgets('4. SetupSectionCard renders section fields cleanly', (tester) async {
      const section = SetupSection(
        id: 'policies',
        packageId: 'sales',
        titleAr: 'سياسات فواتير المبيعات',
        titleEn: 'Sales Invoice Policies',
        descriptionAr: 'وصف السياسات',
        descriptionEn: 'Policies Description',
        fields: [
          SetupField(
            id: 'allowPriceOverride',
            sectionId: 'policies',
            key: 'allowPriceOverride',
            labelAr: 'السماح بتعديل أسعار البيع للفاتورة',
            labelEn: 'Allow Price Modification on Invoice',
            fieldType: SetupFieldType.boolean,
            defaultValue: true,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SetupSectionCard(
              section: section,
              fieldValues: const {'allowPriceOverride': true},
              onFieldValueChanged: (_, __) {},
              isArabic: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('سياسات فواتير المبيعات'), findsOneWidget);
      expect(find.text('السماح بتعديل أسعار البيع للفاتورة'), findsOneWidget);
    });

    testWidgets('5. PackageSetupView displays status badge and section cards', (tester) async {
      final setupDef = salesPackageSetupDefinition;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: PackageSetupView(
              definition: setupDef,
              fieldValues: const {},
              onFieldValueChanged: (_, __) {},
              isArabic: true,
              status: SetupStatus.notConfigured,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إعدادات المبيعات'), findsOneWidget);
      expect(find.text('غير مهيأ'), findsWidgets);
      expect(find.text('سياسات فواتير المبيعات'), findsOneWidget);
      expect(find.text('ربط حسابات المبيعات'), findsOneWidget);
    });

    testWidgets('6. Empty registry shows clean empty state without crash', (tester) async {
      final emptyRegistry = CentralSetupRegistry();

      await tester.pumpWidget(
        createTestableWidget(
          const CentralSetupCenterWidget(),
          customRegistry: emptyRegistry,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('لا توجد حزم مسجلة في مركز الإعدادات المركزي'), findsOneWidget);
    });
  });
}
