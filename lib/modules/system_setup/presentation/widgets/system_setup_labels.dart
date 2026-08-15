import '../../../../app/localization/app_localizations.dart';
import '../../domain/entities/system_setup_state.dart';

String setupStepTitle(AppLocalizations l10n, SetupStepId id) {
  return switch (id) {
    SetupStepId.locale => l10n.systemSetupStepLocale,
    SetupStepId.primaryCurrency => l10n.systemSetupStepPrimaryCurrency,
    SetupStepId.welcomeMode => l10n.systemSetupStepWelcome,
    SetupStepId.companyProfile => l10n.systemSetupStepCompany,
    SetupStepId.seedLocal => l10n.systemSetupStepSeed,
    SetupStepId.externalConnection => l10n.systemSetupStepExternal,
    SetupStepId.initialSync => l10n.systemSetupStepSync,
  };
}

String setupStepHint(AppLocalizations l10n, SetupStepId id) {
  return switch (id) {
    SetupStepId.locale => l10n.systemSetupStepLocaleHint,
    SetupStepId.primaryCurrency => l10n.systemSetupStepPrimaryCurrencyHint,
    SetupStepId.welcomeMode => l10n.systemSetupStepWelcomeHint,
    SetupStepId.companyProfile => l10n.systemSetupStepCompanyHint,
    SetupStepId.seedLocal => l10n.systemSetupStepSeedHint,
    SetupStepId.externalConnection => l10n.systemSetupStepExternalHint,
    SetupStepId.initialSync => l10n.systemSetupStepSyncHint,
  };
}

String setupStepStatusLabel(AppLocalizations l10n, SetupStepStatus status) {
  return switch (status) {
    SetupStepStatus.pending => l10n.systemSetupStatusPending,
    SetupStepStatus.inProgress => l10n.systemSetupStatusInProgress,
    SetupStepStatus.completed => l10n.systemSetupStatusCompleted,
    SetupStepStatus.failed => l10n.systemSetupStatusFailed,
    SetupStepStatus.skipped => l10n.systemSetupStatusSkipped,
  };
}
