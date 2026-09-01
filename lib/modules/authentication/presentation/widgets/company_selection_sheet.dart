import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/bootstrap/app_bootstrap.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/settings/company/company_profile_providers.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/auth/presentation/providers/auth_context_providers.dart';
import '../../../../core/entitlements/presentation/providers/entitlement_providers.dart';
import 'package:stock_count/modules/sync/sync.dart';
import '../providers/auth_providers.dart';

/// Interactive modal sheet to switch active company context.
class CompanySelectionSheet extends ConsumerWidget {
  const CompanySelectionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CompanySelectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final session = ref.watch(authStateProvider).session;
    final activeCompanyId = session?.currentCompanyId;
    final companies = session?.companies ?? const [];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.business_rounded, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.authSelectCompanyTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.xs),
          if (companies.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(
                  'No companies available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: companies.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final company = companies[index];
                  final isSelected = company.id == activeCompanyId;

                  return Material(
                    color: isSelected
                        ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () async {
                        if (isSelected) {
                          Navigator.of(context).pop();
                          return;
                        }

                        // Stop active sync for current tenant before switching
                        await AppBootstrap.stopSync(ref);

                        // Perform company switch
                        await ref
                            .read(authStateProvider.notifier)
                            .switchCompany(company.id);

                        // Invalidate tenant, authorization, and dashboard providers
                        ref.invalidate(currentEntitlementProvider);
                        ref.invalidate(currentPermissionsProvider);
                        ref.invalidate(authorizationContextProvider);
                        ref.invalidate(companyProfileProvider);
                        ref.invalidate(dashboardServicesProvider);
                        ref.invalidate(syncOverviewProvider);

                        // Re-evaluate entitlement capability & sync manager wiring for new company
                        await AppBootstrap.bootstrapSync(ref);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + 2,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                company.name.isNotEmpty
                                    ? company.name.substring(0, 1).toUpperCase()
                                    : 'C',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isSelected
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    company.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  if (company.code.isNotEmpty ||
                                      company.role != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        if (company.code.isNotEmpty) company.code,
                                        if (company.role != null) company.role!,
                                      ].join(' • '),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            icon: const Icon(Icons.add_business_rounded),
            label: const Text(
              'إضافة شركة جديدة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => _showAddCompanyDialog(context, ref),
          ),
        ],
      ),
    );
  }

  static Future<void> _showAddCompanyDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nameController = TextEditingController();
    final codeController = TextEditingController(
      text:
          'CMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Row(
          children: [
            Icon(Icons.add_business_rounded, color: colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            const Text('إضافة شركة جديدة'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الشركة *',
                  hintText: 'مثال: شركة التجارة المتقدمة',
                  prefixIcon: Icon(Icons.business_rounded),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty
                        ? 'يرجى إدخال اسم الشركة'
                        : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'كود الشركة *',
                  hintText: 'مثال: CMP-02',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty
                        ? 'يرجى إدخال كود الشركة'
                        : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final name = nameController.text.trim();
              final code = codeController.text.trim();
              Navigator.of(dialogContext).pop();

              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }

              await AppBootstrap.stopSync(ref);
              await ref
                  .read(authStateProvider.notifier)
                  .createCompany(name: name, code: code);

              ref.invalidate(currentEntitlementProvider);
              ref.invalidate(currentPermissionsProvider);
              ref.invalidate(authorizationContextProvider);
              ref.invalidate(companyProfileProvider);
              ref.invalidate(dashboardServicesProvider);
              ref.invalidate(syncOverviewProvider);

              await AppBootstrap.bootstrapSync(ref);
            },
            child: const Text('إضافة وتأكيد'),
          ),
        ],
      ),
    );
  }
}
