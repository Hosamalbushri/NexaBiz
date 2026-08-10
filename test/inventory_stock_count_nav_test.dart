import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:stock_count/app/bootstrap/module_bootstrap.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/router/app_navigator_keys.dart';
import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/app/theme/app_theme.dart';
import 'package:stock_count/modules/inventory/domain/entities/inventory_item.dart';
import 'package:stock_count/modules/inventory/domain/entities/item_status.dart';
import 'package:stock_count/modules/inventory/domain/entities/report_summary.dart';
import 'package:stock_count/modules/inventory/domain/models/paged_result.dart';
import 'package:stock_count/modules/inventory/domain/repositories/inventory_repository.dart';
import 'package:stock_count/modules/inventory/inventory_module.dart';
import 'package:stock_count/modules/inventory/presentation/pages/inventory_home_page.dart';
import 'package:stock_count/modules/inventory/presentation/pages/inventory_routes.dart';
import 'package:stock_count/modules/inventory/presentation/pages/stock_count_home_page.dart';
import 'package:stock_count/modules/inventory/presentation/providers/inventory_providers.dart';

class _FakeInventoryRepository implements InventoryRepository {
  @override
  Future<List<InventoryItem>> getAll() async => const [];

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.value(const []);

  @override
  Future<InventoryItem?> getByCode(String itemCode) async => null;

  @override
  Future<void> save(InventoryItem item) async {}

  @override
  Future<void> replaceAll(List<InventoryItem> items) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<List<InventoryItem>> search(String query) async => const [];

  @override
  Future<List<InventoryItem>> filterByStatus(ItemStatus? status) async =>
      const [];

  @override
  Future<int> countAll() async => 0;

  @override
  Future<ReportSummary> getReportSummary() async => const ReportSummary.empty();

  @override
  Future<PagedResult<InventoryItem>> getPaged({
    required int page,
    required int pageSize,
    String query = '',
    ItemStatus? status,
  }) async {
    return PagedResult<InventoryItem>(
      items: const [],
      totalCount: 0,
      page: page,
      pageSize: pageSize,
    );
  }
}

class _FakeSettingsRepository extends SettingsRepository {
  List<String>? inventoryIds = const ['stock_count'];

  @override
  Future<List<String>?> loadInventoryServiceIds() async => inventoryIds;

  @override
  Future<void> saveInventoryServiceIds(List<String> ids) async {
    inventoryIds = ids;
  }

  @override
  Future<List<String>?> loadDashboardServiceIds() async => const [];

  @override
  Future<void> saveDashboardServiceIds(List<String> ids) async {}

  @override
  Future<List<String>?> loadQuickActionIds() async => null;

  @override
  Future<void> saveQuickActionIds(List<String> ids) async {}
}

void main() {
  GoRouter buildRouter({String initialLocation = InventoryRoutes.root}) {
    const module = InventoryModule();
    return GoRouter(
      navigatorKey: appRootNavigatorKey,
      initialLocation: initialLocation,
      routes: module.routes,
    );
  }

  Widget wrap(GoRouter router) {
    return ProviderScope(
      overrides: [
        ...moduleRegistryOverrides(),
        settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
        inventoryRepositoryProvider.overrideWithValue(_FakeInventoryRepository()),
        inventoryItemsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Drain zero-duration / animation timers from CustomAppBar / TabBar.
    await tester.pump(const Duration(hours: 1));
  }

  testWidgets('inventory hub shows stock count service card', (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(wrap(router));
    await settle(tester);

    expect(find.byType(InventoryHomePage), findsOneWidget);
    expect(find.text('Stock count'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Customize'), findsOneWidget);
  });

  testWidgets('inventory customize sheet supports save', (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(wrap(router));
    await settle(tester);

    await tester.tap(find.text('Customize'));
    await settle(tester);

    expect(find.text('Pinned services'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(find.byType(InventoryHomePage), findsOneWidget);
    expect(find.text('Stock count'), findsOneWidget);
  });

  testWidgets('opening stock count shows feature grid', (tester) async {
    final router = buildRouter(initialLocation: InventoryRoutes.stockCount);
    await tester.pumpWidget(wrap(router));
    await settle(tester);

    expect(find.byType(StockCountHomePage), findsOneWidget);
    expect(router.state.uri.path, InventoryRoutes.stockCount);
    expect(find.text('Count'), findsOneWidget);
    expect(find.text('Import Inventory'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
  });

  testWidgets('legacy inventory count path redirects to stock-count count', (
    tester,
  ) async {
    final router = buildRouter(initialLocation: '/inventory/count');
    await tester.pumpWidget(wrap(router));
    await settle(tester);

    expect(router.state.uri.path, InventoryRoutes.count);
  });
}
