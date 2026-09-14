import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/app/settings/company/functional_currency_config_page.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/tenancy/session_company.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/core/widgets/app_currency_selector.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/accounting/shared/data/repositories/currency_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency.dart';
import 'package:stock_count/modules/accounting/shared/domain/repositories/currency_repository.dart';
import 'package:stock_count/modules/accounting/shared/presentation/providers/currency_providers.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

class FakeSettingsRepository extends SettingsRepository {
  CompanyProfile _profile = const CompanyProfile();

  void setProfile(CompanyProfile profile) {
    _profile = profile;
  }

  @override
  Future<CompanyProfile> loadCompanyProfile([String? companyId]) async {
    return _profile;
  }

  @override
  Future<void> saveCompanyProfile(
    CompanyProfile profile, [
    String? companyId,
  ]) async {
    _profile = profile;
  }

  @override
  Future<bool> loadSystemBaseCurrencyLocked([String? companyId]) async {
    return false;
  }

  @override
  Future<void> saveSystemBaseCurrencyLocked(
    bool locked, [
    String? companyId,
  ]) async {
    // no-op
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NexabizDatabase db;
  late CurrencyRepository currencyRepo;
  late FakeSettingsRepository fakeSettingsRepo;
  late List<Currency> allCurrencies;
  late List<Currency> activeCurrencies;

  setUp(() async {
    db = NexabizDatabase.memory();
    currencyRepo = CurrencyRepositoryImpl(
      db,
      readCompanyId: () => 'comp_1',
    );
    fakeSettingsRepo = FakeSettingsRepository();

    await currencyRepo.ensureDefaultCurrenciesSeeded();
    allCurrencies = await currencyRepo.getAll(includeInactive: true);
    activeCurrencies = await currencyRepo.getAll(includeInactive: false);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestWidget({
    required List<Override> overrides,
    Locale locale = const Locale('ar'),
  }) {
    return ProviderScope(
      overrides: [
        allCurrenciesProvider.overrideWith((ref) => Stream.value(allCurrencies)),
        activeCurrenciesProvider.overrideWith((ref) => Stream.value(activeCurrencies)),
        ...overrides,
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FunctionalCurrencyConfigPage(),
      ),
    );
  }

  AuthState createAuthState({
    required bool isSuperAdmin,
    List<String> permissions = const [],
  }) {
    return AuthState(
      status: AuthStatus.authenticated,
      session: AuthSessionSnapshot(
        user: AuthUser(
          id: 'u1',
          name: 'Admin',
          email: 'admin@nexabiz.com',
          isSuperAdmin: isSuperAdmin,
        ),
        currentCompanyId: 'comp_1',
        permissions: permissions.toSet(),
        roles: const ['admin'],
        capturedAt: DateTime.now().toUtc(),
        companies: const [
          AuthCompany(id: 'comp_1', name: 'Test Comp', code: 'TC'),
        ],
      ),
    );
  }

  testWidgets(
    '1. Unconfigured State: Displays NOT_CONFIGURED banner and NEVER infers YER',
    (tester) async {
      fakeSettingsRepo.setProfile(const CompanyProfile(defaultCurrencyCode: ''));

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            accountingDatabaseProvider.overrideWithValue(db),
            settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
            currencyRepositoryProvider.overrideWithValue(currencyRepo),
            sessionCompanyIdProvider.overrideWithValue('comp_1'),
            currentCompanyIdProvider.overrideWithValue('comp_1'),
            authStateProvider.overrideWith(
              (ref) => AuthController(
                local: ref.watch(localAuthRepositoryProvider),
                remote: ref.watch(remoteAuthRepositoryProvider),
              )..replaceStateForTest(createAuthState(isSuperAdmin: true)),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Expect Not Configured status header
      expect(find.text('غير مضبوطة'), findsOneWidget);
      expect(find.text('العملة الوظيفية غير مضبوطة'), findsOneWidget);

      // CRITICAL INVARIANT: YER is NEVER displayed as a default or inferred currency
      expect(find.text('YER'), findsNothing);
      expect(find.text('ريال يمني'), findsNothing);
    },
  );

  testWidgets(
    '2. Configured State: Displays active functional currency SAR details',
    (tester) async {
      fakeSettingsRepo.setProfile(
        const CompanyProfile(defaultCurrencyCode: 'SAR'),
      );

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            accountingDatabaseProvider.overrideWithValue(db),
            settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
            currencyRepositoryProvider.overrideWithValue(currencyRepo),
            sessionCompanyIdProvider.overrideWithValue('comp_1'),
            currentCompanyIdProvider.overrideWithValue('comp_1'),
            authStateProvider.overrideWith(
              (ref) => AuthController(
                local: ref.watch(localAuthRepositoryProvider),
                remote: ref.watch(remoteAuthRepositoryProvider),
              )..replaceStateForTest(createAuthState(isSuperAdmin: true)),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('مضبوطة ومفعلة'), findsOneWidget);
      expect(find.text('SAR'), findsWidgets);
      expect(find.text('ريال سعودي'), findsOneWidget);
      expect(find.text('نشطة'), findsOneWidget);
    },
  );

  testWidgets(
    '3. Invalid Config State: Displays warning when configured code does not exist',
    (tester) async {
      fakeSettingsRepo.setProfile(
        const CompanyProfile(defaultCurrencyCode: 'XYZ'),
      );

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            accountingDatabaseProvider.overrideWithValue(db),
            settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
            currencyRepositoryProvider.overrideWithValue(currencyRepo),
            sessionCompanyIdProvider.overrideWithValue('comp_1'),
            currentCompanyIdProvider.overrideWithValue('comp_1'),
            authStateProvider.overrideWith(
              (ref) => AuthController(
                local: ref.watch(localAuthRepositoryProvider),
                remote: ref.watch(remoteAuthRepositoryProvider),
              )..replaceStateForTest(createAuthState(isSuperAdmin: true)),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('تكوين غير صالح'), findsWidgets);
      expect(
        find.textContaining('رمز العملة "XYZ" غير موجود'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '4. Currency Inactive State: Displays warning when currency is deactivated',
    (tester) async {
      // Deactivate EUR
      await currencyRepo.toggleActive('EUR', false);
      allCurrencies = await currencyRepo.getAll(includeInactive: true);
      activeCurrencies = await currencyRepo.getAll(includeInactive: false);

      fakeSettingsRepo.setProfile(
        const CompanyProfile(defaultCurrencyCode: 'EUR'),
      );

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            accountingDatabaseProvider.overrideWithValue(db),
            settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
            currencyRepositoryProvider.overrideWithValue(currencyRepo),
            sessionCompanyIdProvider.overrideWithValue('comp_1'),
            currentCompanyIdProvider.overrideWithValue('comp_1'),
            authStateProvider.overrideWith(
              (ref) => AuthController(
                local: ref.watch(localAuthRepositoryProvider),
                remote: ref.watch(remoteAuthRepositoryProvider),
              )..replaceStateForTest(createAuthState(isSuperAdmin: true)),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('عملة غير نشطة'), findsWidgets);
      expect(
        find.text('العملة الوظيفية المحددة حالياً معطلة في دليل العملات. يرجى تفعيل العملة أو اختيار عملة نشطة أخرى.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '5. Change Restricted State: Posted accounting activity locks modification',
    (tester) async {
      fakeSettingsRepo.setProfile(
        const CompanyProfile(defaultCurrencyCode: 'SAR'),
      );

      // Insert a posted journal entry into SQLite table
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.customStatement(
        'INSERT INTO journal_entries (uuid, currency_code, voucher_number, voucher_type, entry_date, is_posted, company_id, created_at, updated_at) VALUES (\'00000000-0000-0000-0000-000000000001\', \'SAR\', \'V001\', \'journal\', $nowMs, 1, \'comp_1\', $nowMs, $nowMs)',
      );

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            accountingDatabaseProvider.overrideWithValue(db),
            settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
            currencyRepositoryProvider.overrideWithValue(currencyRepo),
            sessionCompanyIdProvider.overrideWithValue('comp_1'),
            currentCompanyIdProvider.overrideWithValue('comp_1'),
            authStateProvider.overrideWith(
              (ref) => AuthController(
                local: ref.watch(localAuthRepositoryProvider),
                remote: ref.watch(remoteAuthRepositoryProvider),
              )..replaceStateForTest(createAuthState(isSuperAdmin: true)),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('تغيير العملة الوظيفية مقيد'), findsOneWidget);
      expect(
        find.textContaining('تم تسجيل قيود دفتريّة مرحلة لهذه الشركة'),
        findsOneWidget,
      );

      // Save button must be disabled
      final saveBtn = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'حفظ العملة الوظيفية'),
      );
      expect(saveBtn.onPressed, isNull);
    },
  );

  testWidgets(
    '6. Permission Enforcement: Unauthorized user gets Read-Only access mode',
    (tester) async {
      fakeSettingsRepo.setProfile(const CompanyProfile(defaultCurrencyCode: ''));

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            accountingDatabaseProvider.overrideWithValue(db),
            settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
            currencyRepositoryProvider.overrideWithValue(currencyRepo),
            sessionCompanyIdProvider.overrideWithValue('comp_1'),
            currentCompanyIdProvider.overrideWithValue('comp_1'),
            authStateProvider.overrideWith(
              (ref) => AuthController(
                local: ref.watch(localAuthRepositoryProvider),
                remote: ref.watch(remoteAuthRepositoryProvider),
              )..replaceStateForTest(
                  createAuthState(isSuperAdmin: false, permissions: []),
                ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('وضع العرض فقط'), findsOneWidget);
      expect(
        find.text('ليس لديك صلاحية لتعديل العملة الوظيفية للشركة.'),
        findsOneWidget,
      );

      final saveBtn = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'حفظ العملة الوظيفية'),
      );
      expect(saveBtn.onPressed, isNull);
    },
  );

  testWidgets(
    '7. Save Flow: Confirmation dialog appears and updates functional currency',
    (tester) async {
      fakeSettingsRepo.setProfile(const CompanyProfile(defaultCurrencyCode: ''));

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            accountingDatabaseProvider.overrideWithValue(db),
            settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
            currencyRepositoryProvider.overrideWithValue(currencyRepo),
            sessionCompanyIdProvider.overrideWithValue('comp_1'),
            currentCompanyIdProvider.overrideWithValue('comp_1'),
            authStateProvider.overrideWith(
              (ref) => AuthController(
                local: ref.watch(localAuthRepositoryProvider),
                remote: ref.watch(remoteAuthRepositoryProvider),
              )..replaceStateForTest(createAuthState(isSuperAdmin: true)),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Open currency picker sheet by tapping InkWell inside AppCurrencySelector
      final inkWell = find.descendant(
        of: find.byType(AppCurrencySelector),
        matching: find.byType(InkWell),
      );
      expect(inkWell, findsOneWidget);
      await tester.tap(inkWell);
      await tester.pumpAndSettle();

      // Enter USD in search text field inside bottom sheet
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'USD');
      await tester.pumpAndSettle();

      // Select USD ListTile from bottom sheet
      final usdTile = find.byType(ListTile).first;
      expect(usdTile, findsOneWidget);
      await tester.tap(usdTile);
      await tester.pumpAndSettle();

      // Tap Save button
      final saveBtnFinder = find.widgetWithText(AppButton, 'حفظ العملة الوظيفية');
      expect(saveBtnFinder, findsOneWidget);
      await tester.tap(saveBtnFinder);
      await tester.pumpAndSettle();

      // Confirm confirmation dialog appears
      expect(find.text('تأكيد اعتماد العملة الوظيفية'), findsOneWidget);
      expect(
        find.textContaining('هل أنت تأكيد من اختيار "USD" كعملة وظيفية'),
        findsOneWidget,
      );

      // Tap Confirm & Save
      final confirmBtn = find.text('تأكيد وحفظ');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify repository updated and profile state reflects USD
      final loadedProfile = await fakeSettingsRepo.loadCompanyProfile('comp_1');
      expect(loadedProfile.defaultCurrencyCode, equals('USD'));
    },
  );
}
