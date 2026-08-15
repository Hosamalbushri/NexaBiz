import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/app_lock_state.dart';
import '../providers/app_lock_providers.dart';

/// Settings UI for enabling/disabling App Lock and configuring policy.
class AppLockSettingsSection extends ConsumerWidget {
  const AppLockSettingsSection({super.key, this.embedded = true});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appLockControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: embedded ? EdgeInsets.zero : null,
          secondary: const Icon(Icons.lock_outline_rounded),
          title: Text(l10n.appLockSettingsTitle),
          subtitle: Text(
            state.enabled
                ? l10n.appLockSettingsEnabledHint
                : l10n.appLockSettingsDisabledHint,
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
          ListTile(
            contentPadding: embedded ? EdgeInsets.zero : null,
            leading: const Icon(Icons.timer_outlined),
            title: Text(l10n.appLockPolicyLabel),
            subtitle: Text(_policyLabel(l10n, state.policy)),
            onTap: () => _showPolicyPicker(context, ref, state.policy),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: embedded ? EdgeInsets.zero : null,
            leading: const Icon(Icons.pin_outlined),
            title: Text(l10n.appLockChangePin),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePinDialog(context, ref),
          ),
        ],
      ],
    );
  }

  String _policyLabel(AppLocalizations l10n, AppLockPolicy policy) {
    return switch (policy) {
      AppLockPolicy.disabled => l10n.appLockPolicyDisabled,
      AppLockPolicy.onColdStart => l10n.appLockPolicyColdStart,
      AppLockPolicy.onResume => l10n.appLockPolicyOnResume,
    };
  }

  Future<void> _showPolicyPicker(
    BuildContext context,
    WidgetRef ref,
    AppLockPolicy current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<AppLockPolicy>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.appLockPolicyOnResume),
                subtitle: Text(l10n.appLockPolicyOnResumeHint),
                selected: current == AppLockPolicy.onResume,
                onTap: () => Navigator.pop(ctx, AppLockPolicy.onResume),
              ),
              ListTile(
                title: Text(l10n.appLockPolicyColdStart),
                subtitle: Text(l10n.appLockPolicyColdStartHint),
                selected: current == AppLockPolicy.onColdStart,
                onTap: () => Navigator.pop(ctx, AppLockPolicy.onColdStart),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null || !context.mounted) return;
    await ref.read(appLockControllerProvider.notifier).setPolicy(selected);
  }

  Future<void> _showEnableDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final pin = TextEditingController();
    final confirm = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.appLockEnableTitle),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.appLockEnableMessage),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: pin,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: AppLockController.maxPinLength,
                  decoration: InputDecoration(
                    labelText: l10n.appLockPinLabel,
                    counterText: '',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.length < AppLockController.minPinLength) {
                      return l10n.appLockErrorLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: confirm,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: AppLockController.maxPinLength,
                  decoration: InputDecoration(
                    labelText: l10n.appLockConfirmPinLabel,
                    counterText: '',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if ((v ?? '') != pin.text) {
                      return l10n.appLockErrorMismatch;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx, true);
                }
              },
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );

    if (saved != true || !context.mounted) {
      pin.dispose();
      confirm.dispose();
      return;
    }

    final error = await ref.read(appLockControllerProvider.notifier).enableWithPin(
          pin: pin.text,
          confirmPin: confirm.text,
          policy: AppLockPolicy.onResume,
        );
    pin.dispose();
    confirm.dispose();
    if (!context.mounted) return;
    if (error != null) {
      showAppSnackBar(
        context,
        message: _mapSetupError(l10n, error),
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
    final pin = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.appLockDisableTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.appLockDisableMessage),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: pin,
                obscureText: true,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: AppLockController.maxPinLength,
                decoration: InputDecoration(
                  labelText: l10n.appLockPinLabel,
                  counterText: '',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      pin.dispose();
      return;
    }

    final error = await ref
        .read(appLockControllerProvider.notifier)
        .disable(pin: pin.text);
    pin.dispose();
    if (!context.mounted) return;
    if (error != null) {
      showAppSnackBar(
        context,
        message: _mapSetupError(l10n, error),
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

  Future<void> _showChangePinDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.appLockChangePin),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: current,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: AppLockController.maxPinLength,
                  decoration: InputDecoration(
                    labelText: l10n.appLockCurrentPinLabel,
                    counterText: '',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: next,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: AppLockController.maxPinLength,
                  decoration: InputDecoration(
                    labelText: l10n.appLockNewPinLabel,
                    counterText: '',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.length < AppLockController.minPinLength) {
                      return l10n.appLockErrorLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: confirm,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: AppLockController.maxPinLength,
                  decoration: InputDecoration(
                    labelText: l10n.appLockConfirmPinLabel,
                    counterText: '',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if ((v ?? '') != next.text) {
                      return l10n.appLockErrorMismatch;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx, true);
                }
              },
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );

    if (saved != true || !context.mounted) {
      current.dispose();
      next.dispose();
      confirm.dispose();
      return;
    }

    final error = await ref.read(appLockControllerProvider.notifier).changePin(
          currentPin: current.text,
          newPin: next.text,
          confirmPin: confirm.text,
        );
    current.dispose();
    next.dispose();
    confirm.dispose();
    if (!context.mounted) return;
    if (error != null) {
      showAppSnackBar(
        context,
        message: _mapSetupError(l10n, error),
        isSuccess: false,
      );
    } else {
      showAppSnackBar(
        context,
        message: l10n.appLockPinChangedSuccess,
        isSuccess: true,
      );
    }
  }

  String _mapSetupError(AppLocalizations l10n, String code) {
    return switch (code) {
      'invalid' => l10n.appLockErrorInvalid,
      'lockout' => l10n.appLockErrorLockout,
      'length' => l10n.appLockErrorLength,
      'digits' => l10n.appLockErrorDigits,
      'mismatch' => l10n.appLockErrorMismatch,
      _ => l10n.appLockErrorInvalid,
    };
  }
}
