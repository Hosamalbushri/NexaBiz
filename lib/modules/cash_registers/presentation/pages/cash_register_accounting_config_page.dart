import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/widgets/settings_chrome.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';

import '../../domain/entities/cash_register.dart';
import '../../domain/services/default_cash_register_resolver.dart';
import '../providers/cash_register_providers.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

/// Cash Register & Accounting Bindings Configuration Page matching the standardized Module Settings design pattern.
class CashRegisterAccountingConfigPage extends ConsumerStatefulWidget {
  const CashRegisterAccountingConfigPage({super.key});

  @override
  ConsumerState<CashRegisterAccountingConfigPage> createState() =>
      _CashRegisterAccountingConfigPageState();
}

class _CashRegisterAccountingConfigPageState
    extends ConsumerState<CashRegisterAccountingConfigPage> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(cashRegistersProvider);
    ref.invalidate(accountingReadyCashRegistersProvider);
    ref.invalidate(cashModuleReadinessSummaryProvider);
    ref.invalidate(defaultCashRegisterResultProvider);
  }

  Future<void> _addRegisterDialog(
    String companyId,
    AppLocalizations l10n,
  ) async {
    _nameController.clear();
    _codeController.clear();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cashRegisterAddTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.cashRegisterNameLabel,
                hintText: l10n.cashRegisterNameHint,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: l10n.cashRegisterCodeLabel,
                hintText: l10n.cashRegisterCodeHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (result != true) return;
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    if (name.isEmpty) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(cashRegisterRepositoryProvider);
      final newReg = CashRegister(
        id: 'cr-${DateTime.now().millisecondsSinceEpoch}',
        companyId: companyId,
        name: name,
        code: code.isEmpty
            ? 'CR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
            : code,
        isActive: true,
        accountingAccountId: null,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      await repo.createCashRegister(newReg);
      _refresh();
      if (mounted) {
        showAppSnackBar(
          context,
          message: l10n.cashRegisterCreateSuccessNotLinked,
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: 'Error: $e', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openAccountLinkPicker(
    CashRegister register,
    String companyId,
    AppLocalizations l10n,
  ) async {
    final accountsAsync = ref.read(accountsProvider);
    final accounts = accountsAsync.valueOrNull ?? [];

    final selectedAccount = await showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _AccountPickerSheet(
        register: register,
        accounts: accounts,
        companyId: companyId,
        l10n: l10n,
      ),
    );

    if (selectedAccount == null) return;

    if (selectedAccount.accountType != AccountType.asset) {
      if (mounted) {
        showAppSnackBar(
          context,
          message: l10n.cashRegisterAccountTypeMismatch,
          isSuccess: false,
        );
      }
      return;
    }

    setState(() => _busy = true);
    try {
      final repo = ref.read(cashRegisterRepositoryProvider);
      await repo.linkAccountingAccount(
        registerId: register.id,
        accountId: selectedAccount.uuid,
        companyId: companyId,
      );
      _refresh();
      if (mounted) {
        showAppSnackBar(
          context,
          message: l10n.cashRegisterLinkSuccess(
            selectedAccount.accountCode,
            selectedAccount.name,
          ),
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        final String errorMessage =
            e.toString().contains('REGISTER_HAS_MOVEMENTS') ||
                e.toString().contains('movements')
            ? 'لا يمكن تغيير الحساب المحاسبي للصندوق لوجود حركات مالية مسجلة عليه.'
            : l10n.cashRegisterLinkFailed(e.toString());
        showAppSnackBar(context, message: errorMessage, isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlinkAccount(
    CashRegister register,
    String companyId,
    AppLocalizations l10n,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cashRegisterUnlinkTitle),
        content: Text(l10n.cashRegisterUnlinkConfirm(register.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.cashRegisterUnlinkConfirmAction),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(cashRegisterRepositoryProvider);
      await repo.unlinkAccountingAccount(
        registerId: register.id,
        companyId: companyId,
      );
      _refresh();
      if (mounted) {
        showAppSnackBar(
          context,
          message: l10n.cashRegisterUnlinkSuccess,
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        final String errorMessage =
            e.toString().contains('REGISTER_HAS_MOVEMENTS') ||
                e.toString().contains('movements')
            ? 'لا يمكن إلغاء ربط الحساب لأن الصندوق يحتوي على حركات مالية مسجلة.'
            : 'Unlink error: $e';
        showAppSnackBar(context, message: errorMessage, isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDefaultRegisterPicker(
    String companyId,
    AppLocalizations l10n,
  ) async {
    final readyRegisters = await ref.read(
      accountingReadyCashRegistersProvider.future,
    );

    if (readyRegisters.isEmpty) {
      if (mounted) {
        showAppSnackBar(
          context,
          message: l10n.cashRegisterNoReadyRegisters,
          isSuccess: false,
        );
      }
      return;
    }

    if (!mounted) return;

    final selected = await showModalBottomSheet<CashRegister>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _DefaultRegisterPickerSheet(
        readyRegisters: readyRegisters,
        l10n: l10n,
      ),
    );

    if (selected == null) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(cashRegisterRepositoryProvider);
      await repo.setDefaultCashRegisterId(
        companyId: companyId,
        registerId: selected.id,
      );
      _refresh();
      if (mounted) {
        showAppSnackBar(
          context,
          message: l10n.cashRegisterDefaultSetSuccess(selected.name),
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: 'Error: $e', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearDefaultRegister(
    String companyId,
    AppLocalizations l10n,
  ) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(cashRegisterRepositoryProvider);
      await repo.setDefaultCashRegisterId(
        companyId: companyId,
        registerId: null,
      );
      _refresh();
      if (mounted) {
        showAppSnackBar(
          context,
          message: l10n.cashRegisterDefaultClearSuccess,
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: 'Error: $e', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    final asyncRegisters = ref.watch(cashRegistersProvider);
    final asyncSummary = ref.watch(cashModuleReadinessSummaryProvider);
    final asyncAccounts = ref.watch(accountsProvider);
    final asyncDefaultResult = ref.watch(defaultCashRegisterResultProvider);

    final companyState = ref
        .watch(companyInitializationRepositoryProvider)
        .getState();

    return FutureBuilder(
      future: companyState,
      builder: (context, snapshot) {
        final companyId = snapshot.data?.companyId.isNotEmpty == true
            ? snapshot.data!.companyId
            : 'default';

        return ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            // Hero Header
            _buildHeroHeader(theme, isAr),
            const SizedBox(height: AppSpacing.md),

            // Section 1: Readiness Summary
            SettingsGroupLabel(
              isAr ? 'حالة الجاهزية والملخص' : 'Readiness & Bindings Summary',
            ),
            asyncSummary.when(
              loading: () => const AppLoading(style: AppLoadingStyle.linear),
              error: (_, _) => const SizedBox(),
              data: (summary) => _buildSummaryGroup(theme, l10n, summary, isAr),
            ),
            const SizedBox(height: AppSpacing.md),

            // Section 2: Default Cash Register
            SettingsGroupLabel(
              isAr
                  ? 'الصندوق الافتراضي لعمليات القبض والصرف'
                  : 'Default Cash Register for Documents',
            ),
            _buildDefaultRegisterGroup(
              theme,
              l10n,
              asyncDefaultResult,
              companyId,
              isAr,
            ),
            const SizedBox(height: AppSpacing.md),

            // Section 3: Cash Registers & Accounts Binding List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SettingsGroupLabel(
                    isAr ? 'قائمة الصناديق والخزائن' : 'Cash Registers List',
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: AppButton(
                    label: isAr ? 'إضافة صندوق' : 'Add Register',
                    icon: Icons.add,
                    variant: AppButtonVariant.outlined,
                    onPressed: _busy
                        ? null
                        : () => _addRegisterDialog(companyId, l10n),
                  ),
                ),
              ],
            ),

            asyncRegisters.when(
              loading: () => const AppLoading(style: AppLoadingStyle.circular),
              error: (err, _) =>
                  AppErrorState(message: err.toString(), onRetry: _refresh),
              data: (registers) {
                if (registers.isEmpty) {
                  return AppEmptyState(
                    title: l10n.cashRegisterEmptyTitle,
                    subtitle: l10n.cashRegisterEmptySubtitle,
                    icon: Icons.point_of_sale_outlined,
                    actionLabel: l10n.cashRegisterAddAction,
                    onAction: _busy
                        ? null
                        : () => _addRegisterDialog(companyId, l10n),
                  );
                }

                final accountsList = asyncAccounts.valueOrNull ?? [];

                return SettingsGroup(
                  children: registers.map((reg) {
                    Account? linkedAcc;
                    if (reg.isLinked) {
                      for (final acc in accountsList) {
                        if (acc.uuid == reg.accountingAccountId ||
                            acc.accountCode == reg.accountingAccountId) {
                          linkedAcc = acc;
                          break;
                        }
                      }
                    }

                    final status = reg.evaluateStatus(
                      linkedAcc,
                      targetCompanyId: companyId,
                    );

                    return _buildRegisterTile(
                      context,
                      theme,
                      l10n,
                      reg,
                      linkedAcc,
                      status,
                      companyId,
                      isAr,
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      },
    );
  }

  Widget _buildHeroHeader(ThemeData theme, bool isAr) {
    return AppCard(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: theme.colorScheme.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr
                      ? 'مركز تهيئة الصناديق والربط المحاسبي'
                      : 'Cash Registers & Accounting Bindings Center',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'إدارة الصناديق المالية، تعيين الصندوق الافتراضي، وربط كل صندوق بحسابه في دليل الحسابات'
                      : 'Manage cash registers, set document default register, and bind registers to Chart of Accounts',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGroup(
    ThemeData theme,
    AppLocalizations l10n,
    CashModuleReadinessSummary summary,
    bool isAr,
  ) {
    final badgeColor = summary.isReady
        ? Colors.green
        : (summary.linkedRegisters > 0 ? Colors.amber.shade700 : Colors.red);

    return SettingsGroup(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SettingsIconBadge(
                    icon: summary.isReady
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color: badgeColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.cashRegisterReadinessTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAr ? summary.statusLabelAr : summary.statusLabelEn,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: badgeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryStat(
                    theme,
                    label: l10n.cashRegisterTotalRegisters,
                    value: '${summary.totalRegisters}',
                  ),
                  _summaryStat(
                    theme,
                    label: l10n.cashRegisterLinkedAndReady,
                    value: '${summary.linkedRegisters}',
                    color: Colors.green,
                  ),
                  _summaryStat(
                    theme,
                    label: l10n.cashRegisterNotLinked,
                    value: '${summary.unlinkedRegisters}',
                    color: Colors.orange.shade800,
                  ),
                  if (summary.invalidRegisters > 0)
                    _summaryStat(
                      theme,
                      label: l10n.cashRegisterInvalidLink,
                      value: '${summary.invalidRegisters}',
                      color: Colors.red,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryStat(
    ThemeData theme, {
    required String label,
    required String value,
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultRegisterGroup(
    ThemeData theme,
    AppLocalizations l10n,
    AsyncValue<DefaultCashRegisterResult> asyncDefaultResult,
    String companyId,
    bool isAr,
  ) {
    return asyncDefaultResult.when(
      loading: () => const AppLoading(style: AppLoadingStyle.linear),
      error: (err, _) => AppErrorState(message: err.toString()),
      data: (result) {
        final reg = result.register;
        final linkedAcc = result.linkedAccount;

        final String subtitleText;
        if (result.isValid && reg != null && linkedAcc != null) {
          subtitleText =
              '${reg.name} (${reg.code}) — ${linkedAcc.accountCode} ${linkedAcc.name}';
        } else if (reg != null) {
          subtitleText = isAr
              ? '${reg.name} (غير جاهز للمحاسبة ⚠️)'
              : '${reg.name} (Not accounting ready ⚠️)';
        } else {
          subtitleText = isAr
              ? 'لم يتم تحديد صندوق افتراضي بعد'
              : 'No default cash register configured';
        }

        return SettingsGroup(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SettingsIconBadge(
                        icon: Icons.star_rounded,
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.cashRegisterDefaultTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitleText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (reg != null) ...[
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _clearDefaultRegister(companyId, l10n),
                          child: Text(
                            isAr ? 'مسح' : 'Clear',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      AppButton(
                        label: reg != null
                            ? (isAr ? 'تغيير الصندوق' : 'Change Default')
                            : (isAr ? 'تحديد صندوق افتراضي' : 'Set Default'),
                        variant: AppButtonVariant.outlined,
                        onPressed: _busy
                            ? null
                            : () => _openDefaultRegisterPicker(companyId, l10n),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRegisterTile(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    CashRegister reg,
    Account? linkedAcc,
    CashRegisterAccountingStatus status,
    String companyId,
    bool isAr,
  ) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case CashRegisterAccountingStatus.ready:
        statusColor = Colors.green;
        statusText = l10n.cashRegisterStatusReady;
        statusIcon = Icons.check_circle_rounded;
        break;
      case CashRegisterAccountingStatus.invalid:
        statusColor = Colors.red;
        statusText = l10n.cashRegisterStatusInvalid;
        statusIcon = Icons.error_outline_rounded;
        break;
      case CashRegisterAccountingStatus.notLinked:
        statusColor = Colors.orange.shade800;
        statusText = l10n.cashRegisterStatusNotLinked;
        statusIcon = Icons.link_off_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row: Name & Code + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SettingsIconBadge(
                icon: Icons.point_of_sale_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reg.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.cashRegisterCodeLabel}: ${reg.code}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 2. Middle Block: Linked Chart of Accounts Detail
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: linkedAcc != null
                      ? Text(
                          '${isAr ? "الحساب المحاسبي" : "Account"}: ${linkedAcc.accountCode} — ${linkedAcc.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Text(
                          isAr ? 'غير مرتبط بحساب محاسبي' : 'No account linked',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 3. Bottom Row: Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (reg.isLinked) ...[
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _unlinkAccount(reg, companyId, l10n),
                  icon: const Icon(Icons.link_off, size: 16, color: Colors.red),
                  label: Text(
                    isAr ? 'إلغاء الربط' : 'Unlink',
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppButton(
                  label: isAr ? 'تغيير الحساب' : 'Change Account',
                  icon: Icons.edit_outlined,
                  variant: AppButtonVariant.outlined,
                  onPressed: _busy
                      ? null
                      : () => _openAccountLinkPicker(reg, companyId, l10n),
                ),
              ] else ...[
                AppButton(
                  label: isAr ? 'ربط بحساب محاسبي' : 'Link Account',
                  icon: Icons.link,
                  onPressed: _busy
                      ? null
                      : () => _openAccountLinkPicker(reg, companyId, l10n),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountPickerSheet extends StatelessWidget {
  const _AccountPickerSheet({
    required this.register,
    required this.accounts,
    required this.companyId,
    required this.l10n,
  });

  final CashRegister register;
  final List<Account> accounts;
  final String companyId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final candidateAccounts = accounts.where((a) {
      if (a.isGroup || !a.isActive || a.isDeleted || !a.canPost) return false;
      if (a.companyId != null &&
          a.companyId!.isNotEmpty &&
          a.companyId != companyId) {
        return false;
      }
      return true;
    }).toList();

    candidateAccounts.sort((a, b) => a.accountCode.compareTo(b.accountCode));

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.65,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Text(
                  l10n.cashRegisterSelectAccountTitle(register.name),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.cashRegisterSelectAccountHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: candidateAccounts.isEmpty
                ? AppEmptyState(
                    title: l10n.cashRegisterNoCompatibleAccounts,
                    icon: Icons.account_balance_outlined,
                  )
                : ListView.separated(
                    itemCount: candidateAccounts.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final acc = candidateAccounts[index];
                      final isCompatible = acc.accountType == AccountType.asset;

                      return ListTile(
                        title: Text('${acc.accountCode} — ${acc.name}'),
                        subtitle: Text(
                          '${acc.accountType.name.toUpperCase()} | ${acc.canPost ? l10n.stockIssueAccountLabel : l10n.accountingUnspecified}',
                          style: TextStyle(
                            color: isCompatible
                                ? theme.colorScheme.onSurfaceVariant
                                : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        trailing: isCompatible
                            ? const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                              )
                            : const Icon(Icons.block, color: Colors.red),
                        onTap: () {
                          Navigator.of(ctx).pop(acc);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DefaultRegisterPickerSheet extends StatelessWidget {
  const _DefaultRegisterPickerSheet({
    required this.readyRegisters,
    required this.l10n,
  });

  final List<CashRegister> readyRegisters;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.5,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Text(
                  l10n.cashRegisterSelectDefaultTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.cashRegisterSelectDefaultHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: readyRegisters.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, index) {
                final reg = readyRegisters[index];
                return ListTile(
                  leading: Icon(
                    Icons.point_of_sale,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(reg.name),
                  subtitle: Text('${l10n.cashRegisterCodeLabel}: ${reg.code}'),
                  onTap: () => Navigator.of(ctx).pop(reg),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
