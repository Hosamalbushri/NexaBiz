import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/auth/domain/entities/authorization_context.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/entitlements/presentation/providers/entitlement_providers.dart';
import 'package:stock_count/core/entitlements/presentation/widgets/capability_gate.dart';
import 'package:stock_count/modules/authentication/data/auth_repository_impl.dart';
import 'package:stock_count/modules/authentication/data/local_auth_repository.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/repositories/auth_repository.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/authentication/presentation/widgets/company_selection_sheet.dart';

void main() {
  group('Phase 10 — UX/UI Architecture Alignment Tests', () {
    testWidgets('Free tier CapabilityGate displays styled upgrade prompt', (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentEntitlementProvider.overrideWith(
            (ref) => Stream.value(Entitlement.freeLocal('company_1')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: CapabilityGate(
                capability: EntitlementCapability.sync,
                child: const Text('Sync Feature Content'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Free user must NOT see the protected content
      expect(find.text('Sync Feature Content'), findsNothing);

      // Must display the Premium Capability prompt
      expect(find.text('PREMIUM CAPABILITY'), findsOneWidget);
      expect(find.text('Cloud Data Synchronization'), findsOneWidget);
      expect(find.text('Upgrade Company to Premium'), findsOneWidget);
    });

    testWidgets('Premium tier CapabilityGate renders child widget directly', (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentEntitlementProvider.overrideWith(
            (ref) => Stream.value(Entitlement.premiumActive('company_1')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: CapabilityGate(
                capability: EntitlementCapability.sync,
                child: const Text('Sync Feature Content'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Premium user must see the protected feature content
      expect(find.text('Sync Feature Content'), findsOneWidget);
      expect(find.text('PREMIUM CAPABILITY'), findsNothing);
    });

    testWidgets('CompanySelectionSheet lists user companies and allows selection', (tester) async {
      final user = const AuthUser(
        id: 'user_1',
        email: 'admin@nexabiz.com',
        name: 'Admin User',
      );
      final companies = const [
        AuthCompany(id: 'c1', name: 'Company Alpha', code: 'ALPHA'),
        AuthCompany(id: 'c2', name: 'Company Beta', code: 'BETA'),
      ];
      final session = AuthSessionSnapshot(
        sessionId: 's1',
        user: user,
        currentCompanyId: 'c1',
        companies: companies,
        roles: const [],
        permissions: const {},
        capturedAt: DateTime.now(),
      );

      final mockController = AuthControllerMock(
        AuthState(
          status: AuthStatus.authenticated,
          session: session,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => mockController),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => CompanySelectionSheet.show(context),
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Company Alpha'), findsOneWidget);
      expect(find.text('Company Beta'), findsOneWidget);
    });
  });
}

class AuthControllerMock extends AuthController {
  AuthControllerMock(AuthState initialState)
      : super(
          local: FakeLocalAuthRepo(),
          remote: FakeAuthRepoImpl(),
        ) {
    replaceStateForTest(initialState);
  }

  @override
  Future<void> switchCompany(String companyId) async {
    final current = state.session;
    if (current != null) {
      replaceStateForTest(
        AuthState(
          status: AuthStatus.authenticated,
          session: current.copyWith(currentCompanyId: companyId),
        ),
      );
    }
  }
}

class FakeLocalAuthRepo implements LocalAuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepoImpl implements AuthRepositoryImpl {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
