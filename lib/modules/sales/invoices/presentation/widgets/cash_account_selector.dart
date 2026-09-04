import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/router/app_routes.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_treasury_account_port.dart';
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
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 48,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'إعدادات الحسابات النقدية غير مكتملة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              'يجب ربط الحساب النقدي أولاً قبل تحديد الصندوق/الحساب النقدي.',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.push(AppRoutes.settingsSetup);
                              },
                              icon: const Icon(Icons.settings),
                              label: const Text('إعداد الحسابات / Configure Accounting'),
                            ),
                          ],
                        ),
                      )
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
