import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/settings/company/app_currency.dart';
import '../../../../app/settings/company/company_profile.dart';
import '../../../../app/settings/company/company_profile_providers.dart';
import '../../../../app/sync/sync_enabled_provider.dart';
import '../../../../app/sync/sync_session_state.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/system_setup_state.dart';
import '../../domain/ports/system_setup_seed_exception.dart';
import '../providers/system_setup_providers.dart';
import '../widgets/system_settings_hub.dart';
import '../widgets/system_setup_labels.dart';
import '../widgets/system_setup_progress.dart';

/// First-launch / resume wizard for System Setup.
class SystemSetupWizardPage extends ConsumerStatefulWidget {
  const SystemSetupWizardPage({super.key});

  @override
  ConsumerState<SystemSetupWizardPage> createState() =>
      _SystemSetupWizardPageState();
}

class _SystemSetupWizardPageState extends ConsumerState<SystemSetupWizardPage> {
  SetupStepId? _selected;
  var _busy = false;
  var _reviewSetup = false;

  Future<void> _refresh() async {
    ref.invalidate(systemSetupProgressProvider);
    ref.invalidate(systemSetupReadyProvider);
  }

  Future<void> _run(
    Future<SetupProgress> Function() action, {
    String? successMessage,
  }) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      final progress = await action();
      await _refresh();
      if (!mounted) {
        return;
      }
      setState(() {
        _selected = progress.currentStep ?? _selected;
      });
      if (successMessage != null) {
        showAppSnackBar(context, message: successMessage, isSuccess: true);
      }
    } catch (error) {
      await _refresh();
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: _seedErrorMessage(l10n, error),
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _seedErrorMessage(AppLocalizations l10n, Object error) {
    if (error is SystemSetupSeedException) {
      return switch (error.code) {
        SystemSetupSeedError.syncRequired => l10n.systemSetupSeedErrorSyncRequired,
        SystemSetupSeedError.authRequired => l10n.systemSetupSeedErrorAuth,
        SystemSetupSeedError.offline => l10n.systemSetupSeedErrorOffline,
        SystemSetupSeedError.emptyRemote => l10n.systemSetupSeedErrorEmpty,
        SystemSetupSeedError.pullFailed => l10n.systemSetupSeedErrorPull,
      };
    }
    return l10n.systemSetupErrorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final asyncProgress = ref.watch(systemSetupProgressProvider);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: CustomAppBar(
          title: l10n.moduleSystemSetup,
          showBackButton: true,
        ),
        body: asyncProgress.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AppErrorState(
            title: l10n.moduleSystemSetup,
            message: l10n.systemSetupErrorGeneric,
            onRetry: _refresh,
          ),
          data: (progress) {
            if (progress.isReady && !_reviewSetup) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go(AppRoutes.dashboard);
                }
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return _buildWizard(context, l10n, theme, progress);
          },
        ),
      ),
    );
  }

  Widget _buildWizard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    SetupProgress progress,
  ) {
    final selected = _selected ?? progress.currentStep ?? SetupStepId.locale;
    return ListView(
      padding: AppConstants.pageInsets(context),
      children: [
        if (progress.isReady) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => setState(() => _reviewSetup = false),
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.moduleSystemSetup),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(
          l10n.systemSetupSubtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SystemSetupProgressHeader(progress: progress),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.systemSetupRequiredSection,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              for (final id in SetupStepId.requiredIds)
                SystemSetupStepTile(
                  step: progress.stateFor(id),
                  selected: selected == id,
                  onTap: () => setState(() => _selected = id),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          setupStepTitle(l10n, selected),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          setupStepHint(l10n, selected),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _StepBody(
          stepId: selected,
          progress: progress,
          busy: _busy,
          onRun: _run,
        ),
      ],
    );
  }
}

class _StepBody extends ConsumerWidget {
  const _StepBody({
    required this.stepId,
    required this.progress,
    required this.busy,
    required this.onRun,
  });

  final SetupStepId stepId;
  final SetupProgress progress;
  final bool busy;
  final Future<void> Function(
    Future<SetupProgress> Function() action, {
    String? successMessage,
  })
  onRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = progress.stateFor(stepId);
    return switch (stepId) {
      SetupStepId.locale => _LocaleStep(busy: busy, onRun: onRun),
      SetupStepId.primaryCurrency => _PrimaryCurrencyStep(
        busy: busy,
        state: state,
        onRun: onRun,
      ),
      SetupStepId.companyProfile => _CompanyProfileStep(
        busy: busy,
        onRun: onRun,
      ),
      SetupStepId.seedLocal => _SeedLocalStep(
        busy: busy,
        state: state,
        onRun: onRun,
      ),
    };
  }
}

class _CompanyProfileStep extends ConsumerStatefulWidget {
  const _CompanyProfileStep({required this.busy, required this.onRun});

  final bool busy;
  final Future<void> Function(
    Future<SetupProgress> Function() action, {
    String? successMessage,
  })
  onRun;

  @override
  ConsumerState<_CompanyProfileStep> createState() =>
      _CompanyProfileStepState();
}

class _CompanyProfileStepState extends ConsumerState<_CompanyProfileStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  var _hydrated = false;
  int _fiscalMonth = 1;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _hydrate(CompanyProfile profile) {
    if (_hydrated) {
      return;
    }
    _hydrated = true;
    _nameController.text = profile.name;
    _fiscalMonth = profile.fiscalYearStartMonth.clamp(1, 12);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(companyProfileProvider);
    profileAsync.whenData(_hydrate);

    final monthFormat = DateFormat.MMMM(
      Localizations.localeOf(context).toString(),
    );

    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.setupCompanyName,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.setupCompanyNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: _fiscalMonth,
              decoration: InputDecoration(
                labelText: l10n.setupFiscalYearStart,
                helperText: l10n.setupFiscalYearStartHelper,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (var m = 1; m <= 12; m++)
                  DropdownMenuItem(
                    value: m,
                    child: Text(monthFormat.format(DateTime(2026, m))),
                  ),
              ],
              onChanged: widget.busy
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _fiscalMonth = value);
                      }
                    },
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.systemSetupContinue,
              isLoading: widget.busy,
              expand: true,
              onPressed: widget.busy
                  ? null
                  : () async {
                      if (!(_formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      await widget.onRun(() async {
                        final coordinator = ref.read(
                          systemInitializationCoordinatorProvider,
                        );
                        return coordinator.runStep(
                          SetupStepId.companyProfile,
                          () async {
                            final existing = await ref
                                .read(settingsRepositoryProvider)
                                .loadCompanyProfile();
                            final updated = existing.copyWith(
                              name: _nameController.text.trim(),
                              fiscalYearStartMonth: _fiscalMonth,
                            );
                            await ref
                                .read(companyProfileProvider.notifier)
                                .save(updated);
                          },
                        );
                      }, successMessage: l10n.setupSavedSuccess);
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryCurrencyStep extends ConsumerStatefulWidget {
  const _PrimaryCurrencyStep({
    required this.busy,
    required this.state,
    required this.onRun,
  });

  final bool busy;
  final SetupStepState state;
  final Future<void> Function(
    Future<SetupProgress> Function() action, {
    String? successMessage,
  })
  onRun;

  @override
  ConsumerState<_PrimaryCurrencyStep> createState() =>
      _PrimaryCurrencyStepState();
}

class _PrimaryCurrencyStepState extends ConsumerState<_PrimaryCurrencyStep> {
  var _hydrated = false;
  String _currencyCode = AppCurrencies.sar.code;

  void _hydrate(CompanyProfile profile) {
    if (_hydrated) {
      return;
    }
    _hydrated = true;
    _currencyCode = profile.defaultCurrencyCode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final lockedAsync = ref.watch(systemBaseCurrencyLockedProvider);
    final locked = lockedAsync.valueOrNull ?? false;
    final alreadyDone =
        widget.state.status == SetupStepStatus.completed || locked;
    ref.watch(companyProfileProvider).whenData(_hydrate);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _currencyCode,
            decoration: InputDecoration(
              labelText: l10n.setupDefaultCurrency,
              helperText: alreadyDone
                  ? l10n.systemSetupCurrencyLocked
                  : l10n.systemSetupStepPrimaryCurrencyHint,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final currency in AppCurrencies.all)
                DropdownMenuItem(
                  value: currency.code,
                  child: Text(
                    '${currency.code} — ${currency.localizedName(isArabic)}',
                  ),
                ),
            ],
            onChanged: (widget.busy || alreadyDone)
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _currencyCode = value);
                    }
                  },
          ),
          const SizedBox(height: AppSpacing.md),
          if (!alreadyDone)
            AppButton(
              label: l10n.systemSetupContinue,
              isLoading: widget.busy,
              expand: true,
              onPressed: widget.busy
                  ? null
                  : () async {
                      await widget.onRun(() async {
                        final coordinator = ref.read(
                          systemInitializationCoordinatorProvider,
                        );
                        return coordinator.runStep(
                          SetupStepId.primaryCurrency,
                          () async {
                            final settings = ref.read(
                              settingsRepositoryProvider,
                            );
                            if (await settings.loadSystemBaseCurrencyLocked()) {
                              return;
                            }
                            final existing = await settings.loadCompanyProfile();
                            await ref
                                .read(companyProfileProvider.notifier)
                                .save(
                                  existing.copyWith(
                                    defaultCurrencyCode: _currencyCode,
                                  ),
                                );
                            await settings.saveSystemBaseCurrencyLocked(true);
                            ref.invalidate(systemBaseCurrencyLockedProvider);
                          },
                        );
                      });
                    },
            )
          else
            Text(
              l10n.systemSetupCurrencyLocked,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _LocaleStep extends ConsumerWidget {
  const _LocaleStep({required this.busy, required this.onRun});

  final bool busy;
  final Future<void> Function(
    Future<SetupProgress> Function() action, {
    String? successMessage,
  })
  onRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);

    Future<void> choose(Locale? value) async {
      await onRun(() async {
        final coordinator = ref.read(systemInitializationCoordinatorProvider);
        return coordinator.runStep(SetupStepId.locale, () async {
          ref.read(localeProvider.notifier).state = value;
          await ref.read(settingsRepositoryProvider).saveLocale(value);
        });
      });
    }

    return AppCard(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              locale == null
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: Text(l10n.systemSetupLocaleSystem),
            onTap: busy ? null : () => choose(null),
          ),
          ListTile(
            leading: Icon(
              locale == AppConstants.englishLocale
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: Text(l10n.systemSetupLocaleEnglish),
            onTap: busy ? null : () => choose(AppConstants.englishLocale),
          ),
          ListTile(
            leading: Icon(
              locale == AppConstants.arabicLocale
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: Text(l10n.systemSetupLocaleArabic),
            onTap: busy ? null : () => choose(AppConstants.arabicLocale),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l10n.systemSetupContinue,
            isLoading: busy,
            expand: true,
            onPressed: busy ? null : () => choose(locale),
          ),
        ],
      ),
    );
  }
}

class _SeedLocalStep extends ConsumerWidget {
  const _SeedLocalStep({
    required this.busy,
    required this.state,
    required this.onRun,
  });

  final bool busy;
  final SetupStepState state;
  final Future<void> Function(
    Future<SetupProgress> Function() action, {
    String? successMessage,
  })
  onRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final done = state.status == SetupStepStatus.completed;
    final syncReady = ref.watch(syncSessionStateProvider).phase ==
        SyncSessionPhase.enabledAuthenticated;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            done
                ? l10n.systemSetupSeedDone
                : (busy
                      ? l10n.systemSetupSeedRunning
                      : l10n.systemSetupStepSeedHint),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.errorMessage!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          if (!done) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l10n.systemSetupSeedCreateLocalTitle,
              icon: Icons.play_arrow_rounded,
              isLoading: busy,
              expand: true,
              onPressed: busy
                  ? null
                  : () async {
                      await onRun(
                        () => ref
                            .read(systemInitializationCoordinatorProvider)
                            .runSeedLocal(),
                        successMessage: l10n.systemSetupSeedDone,
                      );
                      if (context.mounted) {
                        final ready = await ref
                            .read(systemInitializationCoordinatorProvider)
                            .isReady();
                        if (ready && context.mounted) {
                          context.go(AppRoutes.dashboard);
                        }
                      }
                    },
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.systemSetupSeedDone,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SeedChoiceTile extends StatelessWidget {
  const _SeedChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    this.trailingLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (trailingLabel != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        trailingLabel!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
