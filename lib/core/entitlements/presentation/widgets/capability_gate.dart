import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/settings/package_store_sheet.dart';
import '../../domain/entities/entitlement.dart';
import '../providers/entitlement_providers.dart';

/// UI widget for capability gating and Premium upgrade prompts.
///
/// NOTE: [CapabilityGate] is for UX presentation only and is NOT a security boundary.
/// Domain use cases and backend endpoints MUST enforce entitlement security guards independently.
class CapabilityGate extends ConsumerWidget {
  const CapabilityGate({
    super.key,
    required this.capability,
    required this.child,
    this.fallback,
    this.hideIfDenied = false,
    this.onUpgradeRequested,
  });

  final EntitlementCapability capability;
  final Widget child;
  final Widget? fallback;
  final bool hideIfDenied;
  final VoidCallback? onUpgradeRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlementAsync = ref.watch(currentEntitlementProvider);
    final service = ref.watch(entitlementServiceProvider);

    final current = entitlementAsync.valueOrNull ?? service.currentEntitlement;
    final granted = current.hasCapability(capability);

    if (granted) {
      return child;
    }

    if (hideIfDenied) {
      return fallback ?? const SizedBox.shrink();
    }

    return fallback ??
        _DefaultUpgradePrompt(
          capability: capability,
          onUpgradeRequested: onUpgradeRequested,
        );
  }
}

class _DefaultUpgradePrompt extends StatelessWidget {
  const _DefaultUpgradePrompt({
    required this.capability,
    this.onUpgradeRequested,
  });

  final EntitlementCapability capability;
  final VoidCallback? onUpgradeRequested;

  String _capabilityTitle(EntitlementCapability cap) {
    return switch (cap) {
      EntitlementCapability.sync => 'Cloud Data Synchronization',
      EntitlementCapability.cloudBackup => 'Automated Cloud Backup',
      EntitlementCapability.multiDevice => 'Multi-Device Synchronization',
      EntitlementCapability.advancedReports => 'Advanced Business Analytics',
      EntitlementCapability.multiBranch => 'Multi-Branch Management',
      EntitlementCapability.teamUsers => 'Team Access & Collaboration',
      EntitlementCapability.cloudStorage => 'Cloud Storage & Documents',
    };
  }

  String _capabilityDescription(EntitlementCapability cap) {
    return switch (cap) {
      EntitlementCapability.sync =>
        'Sync your business data automatically across devices and locations with secure cloud backup.',
      EntitlementCapability.cloudBackup =>
        'Keep your accounting and sales records safely backed up in the cloud with automated snapshots.',
      EntitlementCapability.multiDevice =>
        'Access and update your store data simultaneously from multiple phones, tablets, or computers.',
      EntitlementCapability.advancedReports =>
        'Unlock deep financial metrics, profit trends, and customizable executive reports.',
      EntitlementCapability.multiBranch =>
        'Manage inventory, transfers, and sales across multiple retail branches or warehouses.',
      EntitlementCapability.teamUsers =>
        'Add team members with role-based access control and live audit trails.',
      EntitlementCapability.cloudStorage =>
        'Store invoice PDFs, customer attachments, and receipt photos in cloud storage.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.6 : 0.4),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PREMIUM CAPABILITY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Premium Feature Required',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _capabilityTitle(capability),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _capabilityDescription(capability),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onUpgradeRequested ??
                () => PackageStoreSheet.show(
                      context,
                      initialCapability: capability,
                    ),
            icon: const Icon(Icons.star_rounded, size: 18),
            label: const Text('Upgrade Company to Premium'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
