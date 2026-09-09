import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/cash_registers/presentation/pages/cash_register_accounting_config_page.dart';

/// Master Settings & Treasury Setup Hub for Receipts & Payments Module (`/receipts-payments/settings`).
///
/// Provides direct interface for adding cash registers/treasuries, setting default cash registers,
/// and linking/unlinking them with Chart of Accounts accounts.
class ReceiptsPaymentsMasterSettingsPage extends ConsumerWidget {
  const ReceiptsPaymentsMasterSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isAr = l10n.localeName == 'ar';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isAr
            ? 'إعداد تهيئة الصناديق والربط المحاسبي'
            : 'Cash Registers & Accounting Bindings Setup',
        showBackButton: true,
      ),
      body: const CashRegisterAccountingConfigPage(),
    );
  }
}
