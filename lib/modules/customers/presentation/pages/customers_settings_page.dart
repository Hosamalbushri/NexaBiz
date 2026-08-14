import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../providers/customer_providers.dart';
import 'customers_routes.dart';

/// Hub list of all Customers-module settings.
class CustomersSettingsPage extends ConsumerWidget {
  const CustomersSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final parentAsync = ref.watch(customersParentAccountProvider);
    final autoLinkAsync = ref.watch(customersAutoLinkAccountProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.customersSettingsTitle,
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          Text(
            l10n.customersSettingsSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsNavTile(
            icon: Icons.account_tree_outlined,
            title: l10n.customersParentAccountSectionTitle,
            subtitle: parentAsync.when(
              loading: () => l10n.loading,
              error: (_, _) => l10n.customersParentAccountNotSet,
              data: (parent) {
                if (parent == null) {
                  return l10n.customersParentAccountNotSet;
                }
                return l10n.customersParentAccountCurrent(
                  parent.code,
                  parent.name,
                );
              },
            ),
            onTap: () => CustomersRoutes.pushParentAccountSettings(context),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsSwitchTile(
            icon: Icons.link_outlined,
            title: l10n.customersAutoLinkSectionTitle,
            subtitle: l10n.customersAutoLinkSectionSubtitle,
            value: autoLinkAsync.valueOrNull ?? true,
            enabled: !autoLinkAsync.isLoading,
            onChanged: (value) {
              ref
                  .read(customersAutoLinkAccountProvider.notifier)
                  .setEnabled(value);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsActionTile(
            icon: Icons.sync_alt_outlined,
            title: l10n.customersLinkMissingAccountsTitle,
            subtitle: l10n.customersLinkMissingAccountsSubtitle,
            actionLabel: l10n.customersLinkMissingAccountsAction,
            onPressed: () => _linkMissingAccounts(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _linkMissingAccounts(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final count = await ref.read(linkMissingCustomerAccountsProvider).call();
    if (!context.mounted) {
      return;
    }
    showAppSnackBar(
      context,
      message: l10n.customersLinkMissingAccountsDone(count),
      isSuccess: true,
    );
  }
}

class _SettingsNavTile extends StatelessWidget {
  const _SettingsNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
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
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: enabled ? onChanged : null),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.tonal(
                onPressed: onPressed,
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dedicated editor for the customers parent CoA group.
class CustomersParentAccountSettingsPage extends StatelessWidget {
  const CustomersParentAccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.customersParentAccountSectionTitle,
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: const [CustomersParentAccountSettingsBody()],
      ),
    );
  }
}

/// Shared parent-account editor body (module settings + platform Settings).
class CustomersParentAccountSettingsBody extends ConsumerStatefulWidget {
  const CustomersParentAccountSettingsBody({super.key});

  @override
  ConsumerState<CustomersParentAccountSettingsBody> createState() =>
      _CustomersParentAccountSettingsBodyState();
}

class _CustomersParentAccountSettingsBodyState
    extends ConsumerState<CustomersParentAccountSettingsBody> {
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

    return Column(
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
        Text(
          l10n.customersParentAccountSectionSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
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
              child: OutlinedButton(
                onPressed: _saving ? null : _useDefault,
                child: Text(l10n.customersParentAccountUseDefault),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.confirm),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
