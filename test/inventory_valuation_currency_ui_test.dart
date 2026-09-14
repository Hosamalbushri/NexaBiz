import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/accounting/shared/data/repositories/currency_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency.dart';
import 'package:stock_count/modules/accounting/shared/domain/repositories/currency_repository.dart';
import 'package:stock_count/modules/accounting/shared/presentation/providers/currency_providers.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/inventory/cost_valuation/presentation/pages/cost_valuation_settings_page.dart';
import 'package:stock_count/modules/inventory/cost_valuation/presentation/widgets/inventory_valuation_currency_card.dart';
import 'package:stock_count/modules/inventory/products/presentation/providers/product_providers.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/presentation/widgets/cost_layer_card.dart';

class FakeSettingsRepo extends SettingsRepository {
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

class FakeAuthController extends StateNotifier<AuthState> implements AuthController {
  FakeAuthController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NexabizDatabase inventoryDb;
  late NexabizDatabase accountingDb;
  late CurrencyRepository currencyRepo;
  late FakeSettingsRepo fakeSettingsRepo;
  late List<Currency> allCurrencies;
  late List<Currency> activeCurrencies;

  setUp(() async {
    inventoryDb = NexabizDatabase.memory();
    accountingDb = NexabizDatabase.memory();
    currencyRepo = CurrencyRepositoryImpl(
      accountingDb,
      readCompanyId: () => 'comp_1',
    );
    fakeSettingsRepo = FakeSettingsRepo();

    await currencyRepo.ensureDefaultCurrenciesSeeded();
    await currencyRepo.setDefaultCurrency('SAR');
    allCurrencies = await currencyRepo.getAll(includeInactive: true);
    activeCurrencies = await currencyRepo.getAll(includeInactive: false);
  });

  tearDown(() async {
    await inventoryDb.close();
    await accountingDb.close();
  });

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
          AuthCompany(id: 'comp_1', name: 'NexaBiz Test Enterprise', code: 'TC'),
        ],
      ),
    );
  }

  Widget createWidgetUnderTest(Widget widget, {required bool canModify, String defaultCurrency = 'SAR'}) {
    fakeSettingsRepo.setProfile(const CompanyProfile());

    final authState = createAuthState(
      isSuperAdmin: canModify,
      permissions: canModify
          ? const ['platform.company.manage', 'accounting.fiscal_years.configure_fx']
          : const [],
    );

    return ProviderScope(
      overrides: [
        allCurrenciesProvider.overrideWith((ref) => Stream.value(allCurrencies)),
        activeCurrenciesProvider.overrideWith((ref) => Stream.value(activeCurrencies)),
        inventoryDatabaseProvider.overrideWithValue(inventoryDb),
        accountingDatabaseProvider.overrideWithValue(accountingDb),
        settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
        currentCompanyIdProvider.overrideWithValue('comp_1'),
        authStateProvider.overrideWith(
          (ref) => FakeAuthController(authState),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        home: Scaffold(body: widget),
      ),
    );
  }

  group('CURRENCY-UI-04 — Inventory Valuation Currency UI Tests', () {
    testWidgets('1. Displays Configured Inventory Valuation Currency card with scope label', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const InventoryValuationCurrencyCard(),
          canModify: true,
          defaultCurrency: 'SAR',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('عملة تقييم المخزون'), findsOneWidget);
      expect(find.textContaining('Company Inventory Book'), findsOneWidget);
      expect(find.textContaining('SAR'), findsWidgets);
      expect(find.text('محددة (Configured)'), findsOneWidget);
    });

    testWidgets('2. Displays warning banner when inventory valuation currency is not configured', (tester) async {
      await currencyRepo.setDefaultCurrency('');
      await tester.pumpWidget(
        createWidgetUnderTest(
          const InventoryValuationCurrencyCard(),
          canModify: true,
          defaultCurrency: '', // Not configured
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('غير محددة'), findsOneWidget);
      expect(find.textContaining('لم يتم تحديد عملة تقييم المخزون'), findsOneWidget);
    });

    testWidgets('3. Displays lock banner when cost layers exist in SQLite database', (tester) async {
      // Ensure Drift memory database schema is generated
      await inventoryDb.select(inventoryDb.inventoryCostLayers).get();
      await inventoryDb.customStatement('''
        INSERT INTO inventory_cost_layers (
          uuid, company_id, item_code, movement_uuid, movement_type, received_date,
          received_qty, remaining_qty, unit_cost, total_cost,
          inventory_currency_id, unit_cost_inventory_currency, total_cost_inventory_currency,
          document_currency_id, unit_cost_document_currency, total_cost_document_currency,
          exchange_rate, closed, created_at, updated_at, sync_status, version
        ) VALUES (
          'layer_10000000-0000-0000-0000-000000000000', 'comp_1', 'ITEM-100', 'mov_100000000-0000-0000-0000-000000000000', 'receipt', 1788800000000,
          50.0, 50.0, 100.0, 5000.0,
          'SAR', 100.0, 5000.0,
          'SAR', 100.0, 5000.0,
          1.0, 0, 1788800000000, 1788800000000, 'synced', 1
        );
      ''');

      await tester.pumpWidget(
        createWidgetUnderTest(
          const InventoryValuationCurrencyCard(),
          canModify: true,
          defaultCurrency: 'SAR',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مقفلة (Locked)'), findsOneWidget);
      expect(find.textContaining('تغيير عملة التقييم مقفل لوجود حركات مخزنية'), findsOneWidget);
    });

    testWidgets('4. Verifies CostLayerCard displays valuation currency and source currency breakdown', (tester) async {
      final now = DateTime.now();

      // Dual-currency cost layer (Foreign purchase: Document USD = $100, Exchange Rate = 3.75, Inventory Valuation SAR = 375 SAR)
      final layer = CostLayer(
        id: 'layer_foreign',
        companyId: 'comp_1',
        itemCode: 'LAPTOP-PRO',
        movementType: 'receipt',
        movementId: 'rcpt_1001',
        receivedDate: now,
        receivedQty: 10.0,
        remainingQty: 10.0,
        unitCost: 375.0,
        unitCostInventoryCurrency: 375.0,
        totalCostInventoryCurrency: 3750.0,
        inventoryCurrencyId: 'SAR',
        unitCostDocumentCurrency: 100.0,
        totalCostDocumentCurrency: 1000.0,
        documentCurrencyId: 'USD',
        exchangeRate: 3.75,
        closed: false,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CostLayerCard(layer: layer),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check item code & status
      expect(find.text('طبقة تكلفة: LAPTOP-PRO'), findsOneWidget);
      expect(find.text('نشطة (Active)'), findsOneWidget);

      // Check Valuation Currency Breakdown (SAR)
      expect(find.text('375.00 ر.س'), findsOneWidget);
      expect(find.text('3750.00 ر.س'), findsOneWidget);
      expect(find.text('عملة التقييم: SAR'), findsOneWidget);

      // Check Source Amount & Exchange Rate Breakdown (USD @ 3.75)
      expect(find.textContaining('المبلغ المصدر (Source Amount): 1000.00 \$ (USD)'), findsOneWidget);
      expect(find.textContaining('سعر الصرف: 3.7500'), findsOneWidget);
    });

    testWidgets('5. CostValuationSettingsPage integrates valuation currency card with valuation methods', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          const CostValuationSettingsPage(),
          canModify: true,
          defaultCurrency: 'SAR',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تقييم تكلفة المخزون'), findsOneWidget);
      expect(find.text('عملة تقييم المخزون'), findsOneWidget);
      expect(find.textContaining('FIFO - الوارد أولاً يصرف أولاً'), findsOneWidget);
    });
  });
}
