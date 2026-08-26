import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/settings/company/company_profile_providers.dart';
import '../../../../core/auth/presentation/providers/auth_context_providers.dart';
import '../../../../core/entitlements/presentation/providers/entitlement_providers.dart';
import '../../../../core/sync/sync_providers.dart';
import '../providers/auth_providers.dart';

class CompanySelectionPage extends ConsumerWidget {
  const CompanySelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authStateProvider).session;
    final companies = session?.companies ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authSelectCompanyTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: companies.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final company = companies[index];
          return ListTile(
            title: Text(company.name),
            subtitle: Text(company.code),
            trailing: company.role != null ? Text(company.role!) : null,
            onTap: () async {
              await ref
                  .read(authStateProvider.notifier)
                  .switchCompany(company.id);

              ref.invalidate(currentEntitlementProvider);
              ref.invalidate(currentPermissionsProvider);
              ref.invalidate(authorizationContextProvider);
              ref.invalidate(companyProfileProvider);
              ref.invalidate(dashboardServicesProvider);
              ref.invalidate(syncOverviewProvider);
            },
          );
        },
      ),
    );
  }
}
