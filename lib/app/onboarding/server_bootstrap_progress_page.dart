import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/network_status_indicator.dart';
import '../bootstrap/app_initialization.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../router/app_routes.dart';
import '../theme/app_spacing.dart';

/// Dedicated initialization and completion screen for server-based device onboarding.
class ServerBootstrapProgressPage extends ConsumerWidget {
  const ServerBootstrapProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appInitializationControllerProvider);
    final coordinator = ref.read(appInitializationControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: AppConstants.pageInsets(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // Header Icon
                  Icon(
                    state.isFailed
                        ? Icons.error_outline_rounded
                        : state.isServerNoData
                            ? Icons.info_outline_rounded
                            : state.isBootstrapCompleted
                                ? Icons.task_alt_rounded
                                : Icons.cloud_download_rounded,
                    size: 68,
                    color: state.isFailed
                        ? colorScheme.error
                        : state.isServerNoData
                            ? colorScheme.tertiary
                            : state.isBootstrapCompleted
                                ? Colors.green
                                : colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Title
                  Text(
                    state.isFailed
                        ? 'Initialization Failed'
                        : state.isServerNoData
                            ? 'No Server Data Found'
                            : state.isBootstrapCompleted
                                ? 'Setup Complete'
                                : 'Preparing Your Workspace',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Subtitle
                  Text(
                    state.isBootstrapCompleted
                        ? 'Your company data has been successfully downloaded and committed to this device.'
                        : (state.stageDetails.isNotEmpty
                            ? state.stageDetails
                            : 'Downloading company data and setting up your workspace...'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // STATE 1: COMPLETION SCREEN WITH CHECKMARKS
                  if (state.isBootstrapCompleted) ...[
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: const [
                                  _CompletionCheckTile(
                                    label: 'Company Profile & Settings',
                                  ),
                                  _CompletionCheckTile(
                                    label: 'Products & Master Catalog',
                                  ),
                                  _CompletionCheckTile(
                                    label: 'Customers & Debtors Records',
                                  ),
                                  _CompletionCheckTile(
                                    label: 'Suppliers & Creditors Records',
                                  ),
                                  _CompletionCheckTile(
                                    label: 'Accounting Ledger & Currencies',
                                  ),
                                  _CompletionCheckTile(
                                    label: 'Inventory Balances & Sequence Cursor',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Center(
                              child: NetworkStatusIndicator(showLabel: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Continue to Dashboard',
                      icon: Icons.arrow_forward_rounded,
                      expand: true,
                      variant: AppButtonVariant.filled,
                      onPressed: () {
                        coordinator.completeBootstrapAndProceedToDashboard();
                        context.go(AppRoutes.dashboard);
                      },
                    ),
                  ],

                  // STATE 2: ACTIVE PROGRESS & DOWNLOAD STAGES
                  if (!state.isFailed &&
                      !state.isServerNoData &&
                      !state.isBootstrapCompleted) ...[
                    // Download progress stats (e.g. 80%, 1,250 / 1,560)
                    if (state.isDownloading && state.totalToDownload > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            state.currentEntityType.isNotEmpty
                                ? state.currentEntityType.toUpperCase()
                                : 'MASTER DATA',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            '${(state.progressPercentage * 100).toInt()}%  (${state.downloadedCount} / ${state.totalToDownload})',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],

                    LinearProgressIndicator(
                      value: state.progressPercentage > 0
                          ? state.progressPercentage
                          : null,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Expanded(
                      child: ListView(
                        children: [
                          _ProgressStageTile(
                            title: 'Server Reachability & Health',
                            subtitle: 'Connected to server health probe',
                            isCompleted: state.currentStep > 1 || state.isReady,
                            isActive: state.isValidatingServer,
                          ),
                          _ProgressStageTile(
                            title: 'Server Authentication',
                            subtitle: 'Session token & company context established',
                            isCompleted: state.currentStep > 2 || state.isReady,
                            isActive: state.isAuthenticating,
                          ),
                          _ProgressStageTile(
                            title: 'Remote Bootstrap Verification',
                            subtitle: 'Checking existing server initialization snapshot',
                            isCompleted: state.currentStep > 3 || state.isReady,
                            isActive: state.isCheckingRemote,
                          ),
                          _ProgressStageTile(
                            title: 'Downloading Master Data',
                            subtitle: state.isDownloading
                                ? 'Downloading ${state.currentEntityType} (${state.downloadedCount}/${state.totalToDownload})'
                                : 'Accounts, inventory, currencies, settings',
                            isCompleted: state.currentStep > 4 || state.isReady,
                            isActive: state.isDownloading,
                          ),
                          _ProgressStageTile(
                            title: 'Local Database Snapshot',
                            subtitle: 'Transactional write to local storage',
                            isCompleted: state.currentStep > 5 || state.isReady,
                            isActive: state.isWritingDatabase,
                          ),
                          _ProgressStageTile(
                            title: 'Initial Synchronization',
                            subtitle: 'Establishing sync cursor and initial pass',
                            isCompleted: state.currentStep > 6 || state.isReady,
                            isActive: state.isSynchronizing,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // STATE 3: SERVER NO DATA
                  if (state.isServerNoData) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.tertiary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'No initialization data was found on the server for your company.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'You can set up this device locally to configure your company, accounts, and settings.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    AppButton(
                      label: 'Initialize Device Locally',
                      icon: Icons.phone_android_outlined,
                      expand: true,
                      onPressed: () {
                        context.go(AppRoutes.login);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.serverSetup),
                      child: Text(l10n.serverSetupBackToChoice),
                    ),
                  ],

                  // STATE 4: FAILURE RECOVERY STATE
                  if (state.isFailed) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Unable to prepare your workspace',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            state.error?.message ??
                                'We couldn\'t download your company data.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    AppButton(
                      label: 'Retry Download',
                      icon: Icons.refresh,
                      expand: true,
                      onPressed: () => coordinator.retry(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () => context.go(AppRoutes.serverSetup),
                      child: const Text('Change Server URL'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () {
                        coordinator.continueOffline();
                        context.go(AppRoutes.dashboard);
                      },
                      child: const Text('Continue Offline'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionCheckTile extends StatelessWidget {
  const _CompletionCheckTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStageTile extends StatelessWidget {
  const _ProgressStageTile({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isActive,
  });

  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final leadingIcon = isCompleted
        ? const Icon(Icons.check_circle, color: Colors.green)
        : isActive
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.primary,
                ),
              )
            : Icon(Icons.radio_button_unchecked, color: colorScheme.outline);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      leading: leadingIcon,
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: isActive || isCompleted ? FontWeight.w700 : FontWeight.w500,
          color: isActive || isCompleted
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
