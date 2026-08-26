import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bootstrap/app_bootstrap.dart';
import '../../core/auth/presentation/providers/auth_context_providers.dart';
import '../../core/entitlements/domain/entities/entitlement.dart';
import '../../core/entitlements/presentation/providers/entitlement_providers.dart';
import '../../core/entitlements/presentation/providers/subscription_providers.dart';
import '../../core/network/sync_api_config.dart';
import 'package:stock_count/modules/sync/sync.dart';
import '../../modules/authentication/presentation/providers/auth_providers.dart';
import '../localization/app_localizations.dart';
import '../theme/app_spacing.dart';

class PackageStoreSheet extends ConsumerStatefulWidget {
  const PackageStoreSheet({
    super.key,
    this.initialCapability,
  });

  final EntitlementCapability? initialCapability;

  static Future<void> show(
    BuildContext context, {
    EntitlementCapability? initialCapability,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.lg)),
      ),
      builder: (context) => PackageStoreSheet(initialCapability: initialCapability),
    );
  }

  @override
  ConsumerState<PackageStoreSheet> createState() => _PackageStoreSheetState();
}

class _PackageStoreSheetState extends ConsumerState<PackageStoreSheet> {
  String _selectedPlanCode = 'starter';
  final Set<String> _selectedPackageCodes = {'cloud_sync', 'multi_device'};
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialCapability == EntitlementCapability.multiBranch) {
      _selectedPackageCodes.add('multi_branch');
      _selectedPlanCode = 'business';
    }
  }

  void _togglePackage(String code) {
    setState(() {
      if (_selectedPackageCodes.contains(code)) {
        _selectedPackageCodes.remove(code);
      } else {
        _selectedPackageCodes.add(code);
      }
    });
  }

  Entitlement _buildLocalEntitlement(String companyId) {
    return _selectedPlanCode == 'free'
        ? Entitlement.freeLocal(companyId)
        : Entitlement.premiumActive(
            companyId,
            planId: 'plan_$_selectedPlanCode',
            packageCodes: _selectedPackageCodes,
            capabilities: {
              if (_selectedPackageCodes.contains('cloud_sync')) EntitlementCapability.sync,
              if (_selectedPackageCodes.contains('cloud_sync')) EntitlementCapability.cloudBackup,
              if (_selectedPackageCodes.contains('multi_device')) EntitlementCapability.multiDevice,
              if (_selectedPackageCodes.contains('multi_branch')) EntitlementCapability.multiBranch,
            },
          );
  }

  Future<void> _processActivation() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final currentCompanyId = ref.read(currentEntitlementProvider).value?.companyId ?? 'company-1';

      Entitlement activeEntitlement;

      try {
        final tokenStorage = ref.read(secureTokenStorageProvider);
        final token = await tokenStorage.readAccessToken();
        final config = ref.read(syncApiConfigProvider);
        if (token != null && token.isNotEmpty && config.baseUrl.isNotEmpty) {
          final repo = ref.read(subscriptionRepositoryProvider);
          activeEntitlement = await repo.changeSubscription(
            companyId: currentCompanyId,
            planId: _selectedPlanCode,
            packageCodes: _selectedPackageCodes.toList(),
            baseUrl: config.baseUrl,
            token: token,
          );
        } else {
          activeEntitlement = _buildLocalEntitlement(currentCompanyId);
        }
      } catch (_) {
        activeEntitlement = _buildLocalEntitlement(currentCompanyId);
      }

      final service = ref.read(entitlementServiceProvider);
      await service.setEntitlement(activeEntitlement);

      ref.invalidate(currentEntitlementProvider);
      ref.invalidate(authorizationContextProvider);
      ref.invalidate(currentPermissionsProvider);

      await AppBootstrap.bootstrapSync(ref);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.subscriptionActivatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final plansAsync = ref.watch(availablePlansProvider);
    final packagesAsync = ref.watch(availablePackagesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.packageStoreSheetTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.subscriptionAndPackagesSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            ],
            Expanded(
              child: ListView(
                children: [
                  Text(
                    l10n.selectCommercialPlanSection,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  plansAsync.when(
                    data: (plans) => Column(
                      children: plans.map((plan) {
                        final isSelected = _selectedPlanCode == plan.code;
                        return Card(
                          elevation: isSelected ? 2 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.sm),
                            side: BorderSide(
                              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: RadioListTile<String>(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    plan.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text('\$${plan.price.toStringAsFixed(2)} / ${plan.billingInterval}'),
                              ],
                            ),
                            subtitle: Text(plan.description),
                            value: plan.code,
                            groupValue: _selectedPlanCode,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedPlanCode = val;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error loading plans: $err'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.availableAddonPackagesSection,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  packagesAsync.when(
                    data: (packages) => Column(
                      children: packages.map((pkg) {
                        final isChecked = _selectedPackageCodes.contains(pkg.code);
                        return CheckboxListTile(
                          title: Text(pkg.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${pkg.description} (\$${pkg.price.toStringAsFixed(2)})'),
                          value: isChecked,
                          onChanged: (val) => _togglePackage(pkg.code),
                        );
                      }).toList(),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (err, stack) => Text('Error loading packages: $err'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _processActivation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.activateSubscriptionButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
