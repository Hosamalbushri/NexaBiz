import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/services/loading_providers.dart';
import 'package:stock_count/core/widgets/app_dialog.dart';
import 'package:stock_count/core/widgets/app_error_state.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/core/domain/services/device_document_number.dart';
import '../../domain/entities/financial_transaction.dart';
import '../../domain/entities/transaction_status.dart';
import '../../domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/permissions/receipts_payments_permission_package.dart';
import '../providers/rp_providers.dart';
import '../providers/transaction_list_provider.dart';
import '../utils/rp_labels.dart';
import '../widgets/rp_entry_lines_readonly_table.dart';
import '../widgets/rp_error_messages.dart';
import '../widgets/transaction_status_badge.dart';
import 'package:stock_count/modules/receipts_payments/shared/presentation/pages/receipts_payments_routes.dart';

class FinancialTransactionDetailsPage extends ConsumerWidget {
  const FinancialTransactionDetailsPage({super.key, required this.transactionId});

  final int transactionId;

  void _back(BuildContext context, {TransactionType? type}) {
    if (type != null) {
      ReceiptsPaymentsRoutes.backToList(context, type: type);
      return;
    }
    // Loading / not-found: prefer stack pop when possible.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      ReceiptsPaymentsRoutes.goRoot(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncTxn = ref.watch(financialTransactionByIdProvider(transactionId));

    return asyncTxn.when(
      loading: () => Scaffold(
        backgroundColor:
            Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: CustomAppBar(
          title: l10n.rpDetailsTitle,
          showBackButton: true,
          onBack: () => _back(context),
        ),
        body: AppLoading(message: l10n.rpLoading),
      ),
      error: (error, _) => Scaffold(
        appBar: CustomAppBar(
          title: l10n.rpDetailsTitle,
          showBackButton: true,
          onBack: () => _back(context),
        ),
        body: AppErrorState(
          message: rpErrorMessage(l10n, error),
          onRetry: () =>
              ref.invalidate(financialTransactionByIdProvider(transactionId)),
        ),
      ),
      data: (txn) {
        if (txn == null) {
          return Scaffold(
            appBar: CustomAppBar(
              title: l10n.rpDetailsTitle,
              showBackButton: true,
              onBack: () => _back(context),
            ),
            body: AppErrorState(
              message: l10n.rpNotFound,
              onRetry: () => ref.invalidate(
                financialTransactionByIdProvider(transactionId),
              ),
            ),
          );
        }
        return _TransactionDetailsBody(transaction: txn);
      },
    );
  }
}

class _TransactionDetailsBody extends ConsumerWidget {
  const _TransactionDetailsBody({required this.transaction});

  final FinancialTransaction transaction;

  List<String> get _updatePermissions =>
      switch (transaction.transactionType) {
        TransactionType.receipt => ReceiptsPaymentsPermissions.receiptsUpdate,
        TransactionType.payment => ReceiptsPaymentsPermissions.paymentsUpdate,
        TransactionType.transfer => ReceiptsPaymentsPermissions.transfersUpdate,
        TransactionType.currencyExchange =>
          ReceiptsPaymentsPermissions.exchangesUpdate,
      };

  List<String> get _postPermissions => switch (transaction.transactionType) {
        TransactionType.receipt => ReceiptsPaymentsPermissions.receiptsPost,
        TransactionType.payment => ReceiptsPaymentsPermissions.paymentsPost,
        TransactionType.transfer => ReceiptsPaymentsPermissions.transfersPost,
        TransactionType.currencyExchange =>
          ReceiptsPaymentsPermissions.exchangesPost,
      };

  List<String> get _cancelPermissions =>
      switch (transaction.transactionType) {
        TransactionType.receipt => ReceiptsPaymentsPermissions.receiptsCancel,
        TransactionType.payment => ReceiptsPaymentsPermissions.paymentsCancel,
        TransactionType.transfer => ReceiptsPaymentsPermissions.transfersCancel,
        TransactionType.currencyExchange =>
          ReceiptsPaymentsPermissions.exchangesCancel,
      };

  Future<void> _runAction(
    BuildContext context,
    WidgetRef ref, {
    required String loadingMessage,
    required Future<void> Function() action,
    required String successMessage,
    VoidCallback? afterSuccess,
  }) async {
    final l10n = AppLocalizations.of(context);
    final loading = ref.read(loadingControllerProvider);
    if (loading.isVisible) {
      return;
    }
    await loading.run(
      message: loadingMessage,
      action: () async {
        try {
          await action();
          if (!context.mounted) {
            return;
          }
          showAppSnackBar(context, message: successMessage, isSuccess: true);
          ref.invalidate(financialTransactionByIdProvider(transaction.id));
          ref.invalidate(transactionListProvider);
          ref.invalidate(transactionDashboardProvider);
          afterSuccess?.call();
        } catch (e) {
          if (!context.mounted) {
            return;
          }
          showAppSnackBar(
            context,
            message: rpErrorMessage(l10n, e),
            isSuccess: false,
          );
        }
      },
    );
  }

  void _backToTypedList(BuildContext context) {
    ReceiptsPaymentsRoutes.backToList(
      context,
      type: transaction.transactionType,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auth = ref.watch(authStateProvider);
    final canUpdate = auth.hasAnyPermission(_updatePermissions);
    final canPost = auth.hasAnyPermission(_postPermissions);
    final canCancel = auth.hasAnyPermission(_cancelPermissions);
    final showPost = transaction.documentStatus.canPost && !transaction.isCancelled;
    final showUnpost =
        transaction.documentStatus.canUnpost && !transaction.isCancelled;
    final dateLabel =
        DateFormat('d/M/yyyy').format(transaction.transactionDate.toLocal());
    final showParty = transaction.transactionType.isReceipt;
    final party = transaction.partyDisplayName.trim().isNotEmpty
        ? transaction.partyDisplayName
        : l10n.rpNoParty;
    final amountColumnLabel = switch (transaction.transactionType) {
      TransactionType.receipt => l10n.rpLineAmountCredit,
      TransactionType.payment ||
      TransactionType.transfer ||
      TransactionType.currencyExchange => l10n.rpLineAmountDebit,
    };

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: formatSaleNumberPrimary(transaction.transactionNumber),
        showBackButton: true,
        actions: [
            if (transaction.documentStatus.isEditable &&
                canUpdate &&
                !transaction.isCancelled)
              CustomAppBarAction(
                icon: Icons.edit_outlined,
                tooltip: l10n.rpEditTitle,
                onPressed: () {
                  if (transaction.transactionType.isTransfer) {
                    ReceiptsPaymentsRoutes.pushEditTransfer(
                      context,
                      transaction.id,
                    );
                  } else if (transaction.transactionType.isCurrencyExchange) {
                    ReceiptsPaymentsRoutes.pushEditExchange(
                      context,
                      transaction.id,
                    );
                  } else {
                    ReceiptsPaymentsRoutes.pushEdit(context, transaction.id);
                  }
                },
              ),
            if ((showPost && canPost) ||
                (showUnpost && canPost) ||
                (transaction.documentStatus.canCancel &&
                    canCancel &&
                    !transaction.isCancelled))
              PopupMenuButton<String>(
                tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
                onSelected: (value) async {
                  switch (value) {
                    case 'post':
                      await _runAction(
                        context,
                        ref,
                        loadingMessage: l10n.rpPosting,
                        action: () async {
                          await ref
                              .read(postFinancialTransactionProvider)
                              .call(transaction.id);
                        },
                        successMessage: l10n.rpPosted,
                      );
                    case 'unpost':
                      await _runAction(
                        context,
                        ref,
                        loadingMessage: l10n.rpUnposting,
                        action: () async {
                          await ref
                              .read(unpostFinancialTransactionProvider)
                              .call(transaction.id);
                        },
                        successMessage: l10n.rpUnposted,
                      );
                    case 'cancel':
                      final ok = await showAppDialog(
                        context: context,
                        title: l10n.rpCancelTitle,
                        message: l10n.rpCancelMessage(
                          formatSaleNumberPrimary(transaction.transactionNumber),
                        ),
                        confirmLabel: l10n.rpCancelAction,
                        cancelLabel: l10n.cancel,
                        isDestructive: true,
                      );
                      if (!ok || !context.mounted) {
                        return;
                      }
                      await _runAction(
                        context,
                        ref,
                        loadingMessage: l10n.rpSaving,
                        action: () async {
                          await ref
                              .read(cancelFinancialTransactionProvider)
                              .call(transaction.id);
                        },
                        successMessage: l10n.rpCancelled,
                        afterSuccess: () {
                          if (context.mounted) {
                            _backToTypedList(context);
                          }
                        },
                      );
                  }
                },
                itemBuilder: (context) => [
                  if (showPost && canPost)
                    PopupMenuItem(value: 'post', child: Text(l10n.rpPost)),
                  if (showUnpost && canPost)
                    PopupMenuItem(value: 'unpost', child: Text(l10n.rpUnpost)),
                  if (transaction.documentStatus.canCancel &&
                      canCancel &&
                      !transaction.isCancelled)
                    PopupMenuItem(
                      value: 'cancel',
                      child: Text(l10n.rpCancelAction),
                    ),
                ],
                child: Material(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 22,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: (showPost && canPost) || (showUnpost && canPost)
            ? Material(
                color: scheme.surface,
                elevation: 8,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: FilledButton.icon(
                      onPressed: () {
                        if (showPost) {
                          _runAction(
                            context,
                            ref,
                            loadingMessage: l10n.rpPosting,
                            action: () async {
                              await ref
                                  .read(postFinancialTransactionProvider)
                                  .call(transaction.id);
                            },
                            successMessage: l10n.rpPosted,
                          );
                        } else {
                          _runAction(
                            context,
                            ref,
                            loadingMessage: l10n.rpUnposting,
                            action: () async {
                              await ref
                                  .read(unpostFinancialTransactionProvider)
                                  .call(transaction.id);
                            },
                            successMessage: l10n.rpUnposted,
                          );
                        }
                      },
                      icon: Icon(
                        showPost
                            ? Icons.check_circle_outline
                            : Icons.undo_outlined,
                      ),
                      label: Text(showPost ? l10n.rpPost : l10n.rpUnpost),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ),
              )
            : null,
        body: ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            _HeroCard(transaction: transaction),
            const SizedBox(height: AppSpacing.md),
            _MetaCard(
              children: [
                _InfoRow(label: l10n.rpDate, value: dateLabel),
                _InfoRow(
                  label: l10n.rpSource,
                  value: rpTransactionSourceLabel(l10n, transaction.source),
                ),
                _InfoRow(
                  label: l10n.rpPaymentMethod,
                  value: rpPaymentMethodLabel(l10n, transaction.paymentMethod),
                ),
                if (transaction.cashAccountName != null)
                  _InfoRow(
                    label: transaction.transactionType.isTransfer
                        ? l10n.rpTransferFromAccount
                        : (transaction.transactionType.isCurrencyExchange
                            ? l10n.rpExchangeCashAccount
                            : l10n.rpCashAccount),
                    value: [
                      if ((transaction.cashAccountCode ?? '').trim().isNotEmpty)
                        transaction.cashAccountCode!.trim(),
                      transaction.cashAccountName!.trim(),
                    ].join(' — '),
                  ),
                if (transaction.transactionType.isTransfer &&
                    (transaction.counterAccountName?.trim().isNotEmpty ??
                        false))
                  _InfoRow(
                    label: l10n.rpTransferToAccount,
                    value: [
                      if ((transaction.counterAccountCode ?? '')
                          .trim()
                          .isNotEmpty)
                        transaction.counterAccountCode!.trim(),
                      transaction.counterAccountName!.trim(),
                    ].join(' — '),
                  ),
                if (transaction.transactionType.isCurrencyExchange) ...[
                  _InfoRow(
                    label: l10n.rpExchangeFromCurrency,
                    value: transaction.currencyCode,
                  ),
                  if (transaction.counterCurrencyCode.trim().isNotEmpty)
                    _InfoRow(
                      label: l10n.rpExchangeToCurrency,
                      value: transaction.counterCurrencyCode,
                    ),
                ] else
                  _InfoRow(
                    label: l10n.rpCurrency,
                    value: transaction.currencyCode,
                  ),
                if (transaction.exchangeRate > 0 &&
                    transaction.exchangeRate != 1)
                  _InfoRow(
                    label: l10n.rpExchangeRate,
                    value: transaction.exchangeRate.toStringAsFixed(4),
                  ),
                if (transaction.reference?.trim().isNotEmpty ?? false)
                  _InfoRow(
                    label: l10n.rpReference,
                    value: transaction.reference!,
                  ),
                if (transaction.description?.trim().isNotEmpty ?? false)
                  _InfoRow(
                    label: l10n.rpDescription,
                    value: transaction.description!,
                  ),
              ],
            ),
            if (showParty) ...[
              const SizedBox(height: AppSpacing.md),
              _PartyCard(partyName: party),
            ],
            const SizedBox(height: AppSpacing.md),
            RpEntryLinesReadonlyTable(
              lines: transaction.resolvedLines,
              amountColumnLabel: amountColumnLabel,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.partyName});

  final String partyName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.18),
                  scheme.primary.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.person_rounded,
              color: scheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.rpPartyName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  partyName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(children: children),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.transaction});

  final FinancialTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatSaleNumberPrimary(transaction.transactionNumber),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TransactionStatusBadge(
                      status: transaction.documentStatus,
                      label: rpTransactionStatusLabel(
                        l10n,
                        transaction.documentStatus,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  transaction.currencyCode,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.rpCashAmount,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          RpMoneyText(
            transaction.amount,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.primary,
              letterSpacing: -1.2,
            ),
          ),
          if (transaction.counterCurrencyCode.trim().isNotEmpty &&
              (transaction.counterCurrencyCode != transaction.currencyCode ||
                  transaction.counterAmount != transaction.amount)) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '${l10n.rpAmount} (${transaction.counterCurrencyCode})',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            RpMoneyText(
              transaction.counterAmount > 0
                  ? transaction.counterAmount
                  : transaction.amount,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.tertiary,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
