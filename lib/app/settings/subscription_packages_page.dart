import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/entitlements/domain/entities/entitlement.dart';
import '../../core/entitlements/presentation/providers/entitlement_providers.dart';
import '../localization/app_localizations.dart';
import '../theme/app_spacing.dart';
import 'company/company_cloud_providers.dart';
import 'company/company_cloud_state.dart';
import 'package:stock_count/app/settings/package_store_sheet.dart';
import 'widgets/cloud_provisioning_flow_dialog.dart';

class SubscriptionPackagesPage extends ConsumerWidget {
  const SubscriptionPackagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final cloudState = ref.watch(companyCloudStateProvider);
    final entitlementAsync = ref.watch(currentEntitlementProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subscriptionAndPackagesTitle),
      ),
      body: cloudState.isLocalOnly
          ? _buildLocalCompanyOnboardingView(context, ref, cloudState)
          : cloudState.cloudStatus == CompanyCloudStatus.provisioningFailed
              ? _buildProvisioningFailedView(context, ref, cloudState)
              : cloudState.cloudStatus == CompanyCloudStatus.provisioning ||
                      cloudState.cloudStatus == CompanyCloudStatus.initialSyncing
                  ? _buildMigrationProgressView(context, ref, cloudState)
                  : entitlementAsync.when(
                      data: (entitlement) =>
                          _buildCloudReadySubscriptionView(context, ref, cloudState, entitlement),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) =>
                          Center(child: Text('Error loading subscription: $err')),
                    ),
    );
  }

  /// Onboarding view for LOCAL_ONLY company.
  Widget _buildLocalCompanyOnboardingView(
      BuildContext context, WidgetRef ref, CompanyCloudState cloudState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            side: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.offline_pin, color: colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Your company is currently local',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Your business data is stored securely on this local device. Upgrade your company to Cloud to unlock:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildBenefitItem(context, Icons.cloud_sync, 'Cloud Synchronization', 'Sync sales and accounting seamlessly across devices.'),
                _buildBenefitItem(context, Icons.devices, 'Multi-device Access', 'Connect multiple POS registers and worker devices.'),
                _buildBenefitItem(context, Icons.cloud_done, 'Cloud Backup & Restore', 'Never lose your business records.'),
                _buildBenefitItem(context, Icons.add_shopping_cart, 'Premium Add-on Packages', 'Multi-branch management and team roles.'),
                const SizedBox(height: AppSpacing.lg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => CloudProvisioningFlowDialog.show(
                        context,
                        initialMode: ProvisioningMode.linkExisting,
                      ),
                      icon: const Icon(Icons.link),
                      label: const Text('Link Existing Cloud Account'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => CloudProvisioningFlowDialog.show(
                        context,
                        initialMode: ProvisioningMode.createNew,
                      ),
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Create New Cloud Company'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Available Cloud Packages',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_sync, color: Colors.grey),
                title: const Text('Cloud Sync Package'),
                subtitle: const Text('Real-time database synchronization'),
                trailing: const Text('Included in Starter', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.devices, color: Colors.grey),
                title: const Text('Multi-Device Access'),
                subtitle: const Text('Support up to 10 registers'),
                trailing: const Text('Included in Starter', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.store, color: Colors.grey),
                title: const Text('Multi-Branch Management'),
                subtitle: const Text('Consolidated reports for multi-store setup'),
                trailing: const Text('Requires Business Plan', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(BuildContext context, IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Provisioning / migration progress view.
  Widget _buildMigrationProgressView(
      BuildContext context, WidgetRef ref, CompanyCloudState cloudState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provisioningState = ref.watch(companyProvisioningControllerProvider).value;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(strokeWidth: 3.5),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Preparing your cloud workspace',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  provisioningState?.stepMessage ?? 'Setting up server environment...',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                _buildProgressCheck('Company setup', true),
                _buildProgressCheck('Cloud admin linked', cloudState.cloudStatus.index >= CompanyCloudStatus.cloudAdminLinked.index),
                _buildProgressCheck('Subscription active', cloudState.cloudStatus.index >= CompanyCloudStatus.subscriptionActive.index),
                _buildProgressCheck('Uploading local data', cloudState.cloudStatus == CompanyCloudStatus.initialSyncing),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCheck(String title, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? Colors.green : Colors.grey,
            size: 18,
          ),
        ],
      ),
    );
  }

  /// Provisioning failed view with Retry and Continue Offline options.
  Widget _buildProvisioningFailedView(
      BuildContext context, WidgetRef ref, CompanyCloudState cloudState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 56, color: colorScheme.error),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Cloud setup could not be completed',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  cloudState.lastProvisioningError ?? 'Network or connection error during provisioning.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        ref.read(companyCloudStateProvider.notifier).setStatus(CompanyCloudStatus.localOnly);
                      },
                      child: const Text('Continue Offline'),
                    ),
                    ElevatedButton(
                      onPressed: () => CloudProvisioningFlowDialog.show(context),
                      child: const Text('Retry Setup'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Active Cloud Ready subscription dashboard view.
  Widget _buildCloudReadySubscriptionView(
    BuildContext context,
    WidgetRef ref,
    CompanyCloudState cloudState,
    Entitlement entitlement,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            side: BorderSide(color: colorScheme.primary, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.star, size: 18, color: Colors.amber),
                      label: Text(
                        entitlement.tier.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'CLOUD READY',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Plan ID: ${entitlement.planId}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (cloudState.serverCompanyId != null)
                  Text(
                    'Server Company ID: ${cloudState.serverCompanyId}',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                Text(
                  'Verified: ${entitlement.lastVerifiedAt.toLocal().toString().split('.').first}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: () => PackageStoreSheet.show(context),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(l10n.manageSubscriptionButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.activePackagesHeader,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_sync, color: Colors.green),
                title: Text(l10n.cloudSyncCapabilityTitle),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.devices, color: Colors.green),
                title: Text(l10n.multiDeviceCapabilityTitle),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.store,
                  color: entitlement.hasCapability(EntitlementCapability.multiBranch)
                      ? Colors.green
                      : colorScheme.onSurfaceVariant,
                ),
                title: Text(l10n.multiBranchCapabilityTitle),
                trailing: entitlement.hasCapability(EntitlementCapability.multiBranch)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : Text(l10n.capabilityLockedLabel, style: const TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.resourceUsageHeader,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _buildUsageRow(
                  context,
                  title: l10n.registeredDevicesLabel,
                  used: entitlement.usage['active_devices'] ?? 1,
                  limit: entitlement.limits['max_devices'] ?? 5,
                ),
                const Divider(),
                _buildUsageRow(
                  context,
                  title: l10n.teamUsersLabel,
                  used: entitlement.usage['active_users'] ?? 1,
                  limit: entitlement.limits['max_users'] ?? 5,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsageRow(
    BuildContext context, {
    required String title,
    required int used,
    required int limit,
  }) {
    final theme = Theme.of(context);
    final ratio = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('$used / $limit', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          color: ratio >= 1.0 ? Colors.red : theme.colorScheme.primary,
        ),
      ],
    );
  }
}
