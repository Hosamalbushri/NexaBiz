import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_button.dart';
import '../../modules/system_setup/presentation/pages/system_setup_routes.dart';
import '../bootstrap/app_initialization.dart';
import '../bootstrap/app_initialization_state.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../router/app_routes.dart';
import '../theme/app_spacing.dart';

/// Progress and recovery UI for server-based initialization setup.
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

    // React to completed ready state
    ref.listen<InitializationState>(appInitializationControllerProvider, (_, next) {
      if (next.isReady) {
        context.go(AppRoutes.dashboard);
      }
    });

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
                  const SizedBox(height: AppSpacing.xl),
                  Icon(
                    state.isFailed
                        ? Icons.error_outline
                        : state.isServerNoData
                            ? Icons.info_outline
                            : Icons.cloud_download_outlined,
                    size: 64,
                    color: state.isFailed
                        ? colorScheme.error
                        : state.isServerNoData
                            ? colorScheme.tertiary
                            : colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    state.isFailed
                        ? 'Initialization Failed'
                        : state.isServerNoData
                            ? 'No Server Data Found'
                            : 'Initializing Application',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    state.stageDetails.isNotEmpty
                        ? state.stageDetails
                        : 'Setting up device configuration...',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Active progress bar
                  if (!state.isFailed && !state.isServerNoData) ...[
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

                  // Server has no initialization data
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

                  // Failure State with Recovery Options
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
                      child: Text(
                        state.error?.message ?? 'An unexpected error occurred during initialization.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    const Spacer(),
                    AppButton(
                      label: 'Retry Initialization',
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
                        context.go(AppRoutes.login);
                      },
                      child: const Text('Use Local Offline Setup'),
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
        ? Icon(Icons.check_circle, color: colorScheme.primary)
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
