import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/app_lock_state.dart';
import '../providers/app_lock_providers.dart';

/// Settings UI for enabling/disabling App Lock and configuring policy.
class AppLockSettingsSection extends ConsumerWidget {
  const AppLockSettingsSection({super.key, this.embedded = true});

  final bool embedded;

  static String mapSetupError(AppLocalizations l10n, String code) {
    return switch (code) {
      'invalid' => l10n.appLockErrorInvalid,
      'lockout' => l10n.appLockErrorLockout,
      'length' => l10n.appLockErrorLength,
      'digits' => l10n.appLockErrorDigits,
      'mismatch' => l10n.appLockErrorMismatch,
      _ => l10n.appLockErrorInvalid,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(appLockControllerProvider);
    final tilePadding = embedded ? EdgeInsets.zero : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: tilePadding,
          secondary: Icon(
            Icons.lock_outline_rounded,
            size: 22,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(
            l10n.appLockSettingsTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            state.enabled
                ? l10n.appLockSettingsEnabledHint
                : l10n.appLockSettingsDisabledHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          value: state.enabled,
          onChanged: (value) async {
            if (value) {
              await _showEnableDialog(context, ref);
            } else {
              await _showDisableDialog(context, ref);
            }
          },
        ),
        if (state.enabled) ...[
          const Divider(height: 1),
          SwitchListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding: tilePadding,
            secondary: Icon(
              Icons.fingerprint_rounded,
              size: 22,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              l10n.appLockBiometricTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              state.biometricAvailable
                  ? l10n.appLockBiometricHint
                  : l10n.appLockBiometricUnavailable,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
            value: state.biometricEnabled,
            onChanged: !state.biometricAvailable
                ? null
                : (value) async {
                    final error = await ref
                        .read(appLockControllerProvider.notifier)
                        .setBiometricEnabled(
                          enabled: value,
                          localizedReason: l10n.appLockBiometricPrompt,
                        );
                    if (!context.mounted) return;
                    if (error == 'unavailable') {
                      showAppSnackBar(
                        context,
                        message: l10n.appLockBiometricUnavailable,
                        isSuccess: false,
                      );
                    } else if (error == null && value) {
                      showAppSnackBar(
                        context,
                        message: l10n.appLockBiometricEnabledSuccess,
                        isSuccess: true,
                      );
                    }
                  },
          ),
          const Divider(height: 1),
          _PolicyAccordion(embedded: embedded),
          const Divider(height: 1),
          _ChangePinAccordion(embedded: embedded),
        ],
      ],
    );
  }

  Future<void> _showEnableDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<_PinPairResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _EnablePinDialog(),
    );
    if (result == null || !context.mounted) return;

    final error = await ref.read(appLockControllerProvider.notifier).enableWithPin(
          pin: result.pin,
          confirmPin: result.confirm,
          policy: AppLockPolicy.onResume,
        );
    if (!context.mounted) return;
    if (error != null) {
      showAppSnackBar(
        context,
        message: mapSetupError(l10n, error),
        isSuccess: false,
      );
    } else {
      showAppSnackBar(
        context,
        message: l10n.appLockEnabledSuccess,
        isSuccess: true,
      );
    }
  }

  Future<void> _showDisableDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DisablePinDialog(),
    );
    if (pin == null || !context.mounted) return;

    final error =
        await ref.read(appLockControllerProvider.notifier).disable(pin: pin);
    if (!context.mounted) return;
    if (error != null) {
      showAppSnackBar(
        context,
        message: mapSetupError(l10n, error),
        isSuccess: false,
      );
    } else {
      showAppSnackBar(
        context,
        message: l10n.appLockDisabledSuccess,
        isSuccess: true,
      );
    }
  }
}

class _PinPairResult {
  const _PinPairResult({required this.pin, required this.confirm});
  final String pin;
  final String confirm;
}

String _policyLabel(AppLocalizations l10n, AppLockPolicy policy) {
  return switch (policy) {
    AppLockPolicy.disabled => l10n.appLockPolicyDisabled,
    AppLockPolicy.onColdStart => l10n.appLockPolicyColdStart,
    AppLockPolicy.onResume => l10n.appLockPolicyOnResume,
  };
}

class _PolicyAccordion extends ConsumerWidget {
  const _PolicyAccordion({required this.embedded});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final current = ref.watch(appLockControllerProvider).policy;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        tilePadding: embedded ? EdgeInsets.zero : null,
        childrenPadding: EdgeInsets.zero,
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        leading: Icon(
          Icons.timer_outlined,
          size: 22,
          color: colorScheme.onSurfaceVariant,
        ),
        title: Text(
          l10n.appLockPolicyLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _policyLabel(l10n, current),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.25,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                children: [
                  _PolicyOptionTile(
                    title: l10n.appLockPolicyOnResume,
                    subtitle: l10n.appLockPolicyOnResumeHint,
                    selected: current == AppLockPolicy.onResume,
                    onTap: () => ref
                        .read(appLockControllerProvider.notifier)
                        .setPolicy(AppLockPolicy.onResume),
                  ),
                  Divider(
                    height: 1,
                    indent: AppSpacing.sm,
                    endIndent: AppSpacing.sm,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  _PolicyOptionTile(
                    title: l10n.appLockPolicyColdStart,
                    subtitle: l10n.appLockPolicyColdStartHint,
                    selected: current == AppLockPolicy.onColdStart,
                    onTap: () => ref
                        .read(appLockControllerProvider.notifier)
                        .setPolicy(AppLockPolicy.onColdStart),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyOptionTile extends StatelessWidget {
  const _PolicyOptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangePinAccordion extends ConsumerStatefulWidget {
  const _ChangePinAccordion({required this.embedded});

  final bool embedded;

  @override
  ConsumerState<_ChangePinAccordion> createState() =>
      _ChangePinAccordionState();
}

class _ChangePinAccordionState extends ConsumerState<_ChangePinAccordion> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _expanded = false;
  var _busy = false;
  var _panelEpoch = 0;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _resetFields() {
    _current.clear();
    _next.clear();
    _confirm.clear();
  }

  void _collapse() {
    _resetFields();
    setState(() {
      _expanded = false;
      _panelEpoch++;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final error = await ref.read(appLockControllerProvider.notifier).changePin(
          currentPin: _current.text,
          newPin: _next.text,
          confirmPin: _confirm.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      showAppSnackBar(
        context,
        message: AppLockSettingsSection.mapSetupError(l10n, error),
        isSuccess: false,
      );
      return;
    }

    _collapse();
    showAppSnackBar(
      context,
      message: l10n.appLockPinChangedSuccess,
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: ValueKey(_panelEpoch),
        initiallyExpanded: false,
        maintainState: true,
        dense: true,
        visualDensity: VisualDensity.compact,
        tilePadding: widget.embedded ? EdgeInsets.zero : null,
        childrenPadding: EdgeInsets.zero,
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        leading: Icon(
          Icons.lock_reset_rounded,
          size: 22,
          color: colorScheme.onSurfaceVariant,
        ),
        title: Text(
          l10n.appLockChangePin,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          l10n.appLockChangePinHint,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.25,
          ),
        ),
        onExpansionChanged: (open) {
          setState(() => _expanded = open);
          if (!open) {
            _resetFields();
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ChangePinSectionLabel(
                        icon: Icons.verified_user_outlined,
                        label: l10n.appLockCurrentPinLabel,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _PinTextField(
                        controller: _current,
                        label: l10n.appLockCurrentPinLabel,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) {
                            return l10n.appLockErrorInvalid;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ChangePinSectionLabel(
                        icon: Icons.password_rounded,
                        label: l10n.appLockNewPinLabel,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _PinTextField(
                        controller: _next,
                        label: l10n.appLockNewPinLabel,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.length < AppLockController.minPinLength) {
                            return l10n.appLockErrorLength;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _PinTextField(
                        controller: _confirm,
                        label: l10n.appLockConfirmPinLabel,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: (v) {
                          if ((v ?? '') != _next.text) {
                            return l10n.appLockErrorMismatch;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                minimumSize: const Size.fromHeight(40),
                              ),
                              onPressed: _busy ? null : _collapse,
                              child: Text(l10n.cancel),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                minimumSize: const Size.fromHeight(40),
                              ),
                              onPressed: _busy || !_expanded ? null : _submit,
                              icon: _busy
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.onPrimary,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded, size: 18),
                              label: Text(l10n.confirm),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePinSectionLabel extends StatelessWidget {
  const _ChangePinSectionLabel({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 14, color: colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _EnablePinDialog extends StatefulWidget {
  const _EnablePinDialog();

  @override
  State<_EnablePinDialog> createState() => _EnablePinDialogState();
}

class _EnablePinDialogState extends State<_EnablePinDialog> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _AppLockPinDialogScaffold(
      icon: Icons.lock_outline_rounded,
      title: l10n.appLockEnableTitle,
      message: l10n.appLockEnableMessage,
      confirmLabel: l10n.confirm,
      onCancel: () => Navigator.pop(context),
      onConfirm: () {
        if (_formKey.currentState?.validate() ?? false) {
          Navigator.pop(
            context,
            _PinPairResult(pin: _pin.text, confirm: _confirm.text),
          );
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PinTextField(
              controller: _pin,
              label: l10n.appLockPinLabel,
              autofocus: true,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.length < AppLockController.minPinLength) {
                  return l10n.appLockErrorLength;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _PinTextField(
              controller: _confirm,
              label: l10n.appLockConfirmPinLabel,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_formKey.currentState?.validate() ?? false) {
                  Navigator.pop(
                    context,
                    _PinPairResult(pin: _pin.text, confirm: _confirm.text),
                  );
                }
              },
              validator: (v) {
                if ((v ?? '') != _pin.text) {
                  return l10n.appLockErrorMismatch;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DisablePinDialog extends StatefulWidget {
  const _DisablePinDialog();

  @override
  State<_DisablePinDialog> createState() => _DisablePinDialogState();
}

class _DisablePinDialogState extends State<_DisablePinDialog> {
  final _pin = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, _pin.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _AppLockPinDialogScaffold(
      icon: Icons.lock_open_rounded,
      title: l10n.appLockDisableTitle,
      message: l10n.appLockDisableMessage,
      confirmLabel: l10n.confirm,
      isDestructive: true,
      onCancel: () => Navigator.pop(context),
      onConfirm: _submit,
      child: Form(
        key: _formKey,
        child: _PinTextField(
          controller: _pin,
          label: l10n.appLockPinLabel,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.length < AppLockController.minPinLength) {
              return l10n.appLockErrorLength;
            }
            return null;
          },
        ),
      ),
    );
  }
}

/// Shared shell matching [showAppDialog] layout for App Lock PIN flows.
class _AppLockPinDialogScaffold extends StatelessWidget {
  const _AppLockPinDialogScaffold({
    required this.icon,
    required this.title,
    required this.message,
    required this.child,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget child;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = isDestructive ? colorScheme.error : colorScheme.primary;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.surface),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: AppLocalizations.of(context).cancel,
                    variant: AppButtonVariant.outlined,
                    expand: true,
                    onPressed: onCancel,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: isDestructive
                      ? FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                          ),
                          onPressed: onConfirm,
                          child: Text(confirmLabel),
                        )
                      : AppButton(
                          label: confirmLabel,
                          variant: AppButtonVariant.filled,
                          expand: true,
                          onPressed: onConfirm,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PinTextField extends StatefulWidget {
  const _PinTextField({
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  State<_PinTextField> createState() => _PinTextFieldState();
}

class _PinTextFieldState extends State<_PinTextField> {
  var _obscure = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.number,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: AppLockController.maxPinLength,
      obscuringCharacter: '•',
      style: theme.textTheme.bodyMedium?.copyWith(
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        isDense: true,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        prefixIcon: Icon(
          Icons.password_rounded,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
        suffixIcon: IconButton(
          tooltip: _obscure ? l10n.appLockShowPin : l10n.appLockHidePin,
          visualDensity: VisualDensity.compact,
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
          ),
        ),
      ),
    );
  }
}
