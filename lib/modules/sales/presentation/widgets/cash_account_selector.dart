import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/services/sale_treasury_account_port.dart';
import '../providers/sale_providers.dart';
import 'sale_account_labels.dart';

Future<SaleAccountRef?> showSaleCashAccountSelector(BuildContext context) {
  return showModalBottomSheet<SaleAccountRef>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _CashAccountSheet(),
  );
}

class _CashAccountSheet extends ConsumerStatefulWidget {
  const _CashAccountSheet();

  @override
  ConsumerState<_CashAccountSheet> createState() => _CashAccountSheetState();
}

class _CashAccountSheetState extends ConsumerState<_CashAccountSheet> {
  var _loading = true;
  List<SaleAccountRef> _accounts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = await ref
        .read(saleTreasuryAccountPortProvider)
        .listCashBoxAccounts();
    if (!mounted) {
      return;
    }
    setState(() {
      _accounts = accounts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.55,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.salesCashAccount,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _accounts.isEmpty
                ? Center(child: Text(l10n.salesCashAccountEmpty))
                : ListView.separated(
                    itemCount: _accounts.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final account = _accounts[index];
                      return ListTile(
                        title: Text(
                          SaleAccountLabels.displayName(l10n, account),
                        ),
                        onTap: () => Navigator.of(context).pop(account),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
