import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/settings/widgets/settings_chrome.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../pages/customers_settings_page.dart';
import '../providers/customer_providers.dart';

/// Customers module settings bundle (embedded in the Settings module hub).
class CustomersSettingsPanel extends ConsumerWidget {
  const CustomersSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final autoLinkAsync = ref.watch(customersAutoLinkAccountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSubSection(
          title: l10n.customersParentAccountSectionTitle,
          subtitle: l10n.customersParentAccountSectionSubtitle,
          child: const CustomersParentAccountSettingsBody(),
        ),
        const SizedBox(height: 16),
        SettingsSubSection(
          title: l10n.customersAutoLinkSectionTitle,
          subtitle: l10n.customersAutoLinkSectionSubtitle,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.customersAutoLinkToggle),
            value: autoLinkAsync.valueOrNull ?? true,
            onChanged: autoLinkAsync.isLoading
                ? null
                : (value) {
                    ref
                        .read(customersAutoLinkAccountProvider.notifier)
                        .setEnabled(value);
                  },
          ),
        ),
        const SizedBox(height: 16),
        SettingsSubSection(
          title: l10n.customersLinkMissingAccountsTitle,
          subtitle: l10n.customersLinkMissingAccountsSubtitle,
          child: FilledButton.tonal(
            onPressed: () async {
              final count = await ref
                  .read(linkMissingCustomerAccountsProvider)
                  .call();
              if (!context.mounted) {
                return;
              }
              showAppSnackBar(
                context,
                message: l10n.customersLinkMissingAccountsDone(count),
                isSuccess: true,
              );
            },
            child: Text(l10n.customersLinkMissingAccountsAction),
          ),
        ),
      ],
    );
  }
}
