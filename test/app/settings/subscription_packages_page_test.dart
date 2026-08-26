import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/company/company_cloud_providers.dart';
import 'package:stock_count/app/settings/company/company_cloud_state.dart';
import 'package:stock_count/app/settings/subscription_packages_page.dart';

class TestCompanyCloudStateNotifier extends StateNotifier<CompanyCloudState>
    implements CompanyCloudStateNotifier {
  TestCompanyCloudStateNotifier(CompanyCloudState initialState)
      : super(initialState);

  @override
  Future<void> setStatus(
    CompanyCloudStatus status, {
    String? serverCompanyId,
    String? planId,
    String? subscriptionId,
    String? error,
  }) async {
    state = state.copyWith(
      cloudStatus: status,
      serverCompanyId: serverCompanyId ?? state.serverCompanyId,
      planId: planId ?? state.planId,
      subscriptionId: subscriptionId ?? state.subscriptionId,
      lastProvisioningError: error,
    );
  }

  @override
  Future<void> updateState(CompanyCloudState newState) async {
    state = newState;
  }
}

void main() {
  testWidgets(
      'SubscriptionPackagesPage renders Local Company Onboarding for LOCAL_ONLY status',
      (WidgetTester tester) async {
    final testState = CompanyCloudState.localDefault('local-comp-test');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          companyCloudStateProvider.overrideWith((ref) {
            return TestCompanyCloudStateNotifier(testState);
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SubscriptionPackagesPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Your company is currently local'), findsOneWidget);
    expect(find.text('Link Existing Cloud Account'), findsOneWidget);
    expect(find.text('Create New Cloud Company'), findsOneWidget);
    expect(find.text('Available Cloud Packages'), findsOneWidget);

    final syncPackageFinder = find.text('Cloud Sync Package');
    await tester.scrollUntilVisible(syncPackageFinder, 200.0);
    expect(syncPackageFinder, findsOneWidget);

    // Verify dummy "Current Premium Plan" is NOT shown for local company
    expect(find.text('Plan ID: plan_starter'), findsNothing);
  });
}
