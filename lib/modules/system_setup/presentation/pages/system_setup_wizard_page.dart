import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/settings/company/app_currency.dart';
import '../../../../app/settings/company/company_profile.dart';
import '../../../../app/settings/company/company_profile_providers.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/system_setup_state.dart';
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
    } catch (_) {
      await _refresh();
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.systemSetupErrorGeneric,
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final asyncProgress = ref.watch(systemSetupProgressProvider);

    return PopScope(
      canPop: asyncProgress.valueOrNull?.isReady ?? false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: CustomAppBar(
          title: l10n.moduleSystemSetup,
          showBackButton: asyncProgress.valueOrNull?.isReady ?? false,
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
              return SystemSettingsHub(
                progress: progress,
                onReviewSetup: () => setState(() => _reviewSetup = true),
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
          l10n.systemSetupOptionalSection,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              for (final id in SetupStepId.optionalIds)
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
      SetupStepId.welcomeMode => _WelcomeModeStep(
        busy: busy,
        failed: state.status == SetupStepStatus.failed,
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
      SetupStepId.externalConnection => _ExternalStep(
        busy: busy,
        onRun: onRun,
      ),
      SetupStepId.initialSync => _InitialSyncStep(
        busy: busy,
        state: state,
        onRun: onRun,
      ),
    };
  }
}

class _WelcomeModeStep extends ConsumerWidget {
  const _WelcomeModeStep({
    required this.busy,
    required this.failed,
    required this.onRun,
  });

  final bool busy;
  final bool failed;
  final Future<void> Function(
    Future<SetupProgress> Function() action, {
    String? successMessage,
  })
  onRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.systemSetupModeStandaloneHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: failed ? l10n.systemSetupRetry : l10n.systemSetupContinue,
            isLoading: busy,
            expand: true,
            onPressed: busy
                ? null
                : () => onRun(() async {
                    final coordinator = ref.read(
                      systemInitializationCoordinatorProvider,
                    );
                    return coordinator.runStep(SetupStepId.welcomeMode, () async {
                      // Local accounting is the only operating mode.
                    });
                  }),
          ),
        ],
      ),
    );
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

class _SeedLocalStep extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final done = state.status == SetupStepStatus.completed;
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
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: state.status == SetupStepStatus.failed
                ? l10n.systemSetupRetry
                : l10n.systemSetupContinue,
            isLoading: busy,
            expand: true,
            onPressed: busy
                ? null
                : () async {
                    final container = ProviderScope.containerOf(context);
                    await onRun(
                      () => container
                          .read(systemInitializationCoordinatorProvider)
                          .runSeedLocal(),
                      successMessage: l10n.systemSetupSeedDone,
                    );
                  },
          ),
        ],
      ),
    );
  }
}

class _ExternalStep extends ConsumerWidget {
  const _ExternalStep({required this.busy, required this.onRun});

  final bool busy;
  final Future<void> Function(
    Future<SetupProgress> Function() action, {
    String? successMessage,
  })
  onRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.systemSetupExternalPlaceholder),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.systemSetupSkip,
            variant: AppButtonVariant.outlined,
            expand: true,
            onPressed: busy
                ? null
                : () => onRun(
                    () => ref
                        .read(systemInitializationCoordinatorProvider)
                        .skipOptionalStep(SetupStepId.externalConnection),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l10n.systemSetupContinue,
            isLoading: busy,
            expand: true,
            onPressed: busy
                ? null
                : () => onRun(
                    () => ref
                        .read(systemInitializationCoordinatorProvider)
                        .markStepCompleted(SetupStepId.externalConnection),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InitialSyncStep extends ConsumerWidget {
  const _InitialSyncStep({
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            state.status == SetupStepStatus.completed
                ? l10n.systemSetupSyncDone
                : l10n.systemSetupSyncSkippedHint,
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.systemSetupContinue,
            isLoading: busy,
            expand: true,
            onPressed: busy
                ? null
                : () => onRun(
                    () {
                      final runner = ref.read(systemSetupSyncRunnerProvider);
                      return ref
                          .read(systemInitializationCoordinatorProvider)
                          .runStep(SetupStepId.initialSync, runner);
                    },
                    successMessage: l10n.systemSetupSyncDone,
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l10n.systemSetupSkip,
            variant: AppButtonVariant.outlined,
            expand: true,
            onPressed: busy
                ? null
                : () => onRun(
                    () => ref
                        .read(systemInitializationCoordinatorProvider)
                        .skipOptionalStep(SetupStepId.initialSync),
                  ),
          ),
        ],
      ),
    );
  }
}
