import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/bootstrap/app_bootstrap.dart';
import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/settings/company/company_profile_providers.dart';
import '../../../../core/auth/presentation/providers/auth_context_providers.dart';
import '../../../../core/entitlements/presentation/providers/entitlement_providers.dart';
import 'package:stock_count/modules/sync/sync.dart';
import '../providers/auth_providers.dart';
import '../widgets/company_details_sheet.dart';

class CompanySelectionScreen extends ConsumerWidget {
  const CompanySelectionScreen({super.key});

  static const routeName = 'company-selection';
  static const routePath = '/company-selection';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final session = authState.session;

    if (session == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('جلسة غير صالحة'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        ),
      );
    }

    final companies = session.companies;

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر الشركة (Select Company)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'مرحباً ${session.user.name}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'اختر الشركة التي ترغب بالعمل عليها:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: companies.isEmpty
                    ? const Center(child: Text('لا توجد شركات متاحة للحساب.'))
                    : ListView.separated(
                        itemCount: companies.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final company = companies[index];
                          final isSelected = company.id == session.currentCompanyId;
                          return Card(
                            elevation: isSelected ? 4 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isSelected
                                  ? BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    )
                                  : BorderSide.none,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(company.code.isNotEmpty
                                    ? company.code.substring(0, 1)
                                    : 'C'),
                              ),
                              title: Text(
                                company.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('الكود: ${company.code} | الدور: ${company.role}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.info_outline_rounded),
                                    tooltip: 'بيانات الشركة',
                                    onPressed: () => CompanyDetailsSheet.show(
                                      context,
                                      company,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (isSelected) {
                                        context.go('/dashboard');
                                        return;
                                      }
                                      final router = GoRouter.of(context);
                                      await AppBootstrap.stopSync(ref);

                                      final switchedSession = await ref
                                          .read(authStateProvider.notifier)
                                          .switchCompany(company.id);

                                      ref.invalidate(currentEntitlementProvider);
                                      ref.invalidate(currentPermissionsProvider);
                                      ref.invalidate(authorizationContextProvider);
                                      ref.invalidate(companyProfileProvider);
                                      ref.invalidate(dashboardServicesProvider);
                                      ref.invalidate(syncOverviewProvider);

                                      await AppBootstrap.bootstrapSync(ref);

                                      if (switchedSession != null) {
                                        router.go('/dashboard');
                                      } else {
                                        await ref
                                            .read(authStateProvider.notifier)
                                            .logout();
                                        router.go('/login');
                                      }
                                    },
                                    child: Text(isSelected ? 'دخول' : 'تغيير وتأكيد'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
