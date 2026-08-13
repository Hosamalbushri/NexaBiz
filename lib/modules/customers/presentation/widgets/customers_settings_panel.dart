import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/settings/widgets/settings_chrome.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/customer_providers.dart';

/// Customers module settings bundle (embedded in platform Settings).
class CustomersSettingsPanel extends ConsumerStatefulWidget {
  const CustomersSettingsPanel({super.key});

  @override
  ConsumerState<CustomersSettingsPanel> createState() =>
      _CustomersSettingsPanelState();
}

class _CustomersSettingsPanelState
    extends ConsumerState<CustomersSettingsPanel> {
  final _controller = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final input = _controller.text.trim();
    if (input.isEmpty) {
      showAppSnackBar(
        context,
        message: l10n.customersParentAccountInvalid,
        isSuccess: false,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final ok = await ref
          .read(customersParentAccountProvider.notifier)
          .setFromInput(input);
      if (!mounted) {
        return;
      }
      if (!ok) {
        showAppSnackBar(
          context,
          message: l10n.customersParentAccountInvalid,
          isSuccess: false,
        );
        return;
      }
      _controller.clear();
      showAppSnackBar(
        context,
        message: l10n.customersParentAccountSaved,
        isSuccess: true,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _useDefault() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(customersParentAccountProvider.notifier)
          .useSystemDefault();
      if (!mounted) {
        return;
      }
      _controller.clear();
      showAppSnackBar(
        context,
        message: l10n.customersParentAccountSaved,
        isSuccess: true,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final parentAsync = ref.watch(customersParentAccountProvider);

    return SettingsSubSection(
      title: l10n.customersParentAccountSectionTitle,
      subtitle: l10n.customersParentAccountSectionSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          parentAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(l10n.somethingWentWrong),
            data: (parent) {
              if (parent == null) {
                return Text(
                  l10n.customersParentAccountNotSet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                );
              }
              return Text(
                l10n.customersParentAccountCurrent(parent.code, parent.name),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            enabled: !_saving,
            decoration: InputDecoration(
              labelText: l10n.customersParentAccountField,
              helperText: l10n.customersParentAccountFieldHelper,
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: l10n.customersParentAccountUseDefault,
                  variant: AppButtonVariant.outlined,
                  expand: true,
                  onPressed: _saving ? null : _useDefault,
                  isLoading: _saving,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: l10n.confirm,
                  expand: true,
                  onPressed: _saving ? null : _save,
                  isLoading: _saving,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
