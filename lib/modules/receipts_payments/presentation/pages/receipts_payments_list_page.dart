import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../authentication/presentation/widgets/permission_gate.dart';
import '../../../sales/domain/services/device_sale_number.dart';
import '../../domain/entities/transaction_list_item.dart';
import '../../domain/entities/transaction_type.dart';
import '../../permissions/receipts_payments_permission_package.dart';
import '../providers/transaction_list_provider.dart';
import '../utils/rp_labels.dart';
import '../widgets/rp_error_messages.dart';
import '../widgets/transaction_filter_bar.dart';
import '../widgets/transaction_status_badge.dart';
import 'receipts_payments_routes.dart';

class ReceiptsPaymentsListPage extends ConsumerStatefulWidget {
  const ReceiptsPaymentsListPage({super.key, this.initialType});

  final TransactionType? initialType;

  @override
  ConsumerState<ReceiptsPaymentsListPage> createState() =>
      _ReceiptsPaymentsListPageState();
}

class _ReceiptsPaymentsListPageState
    extends ConsumerState<ReceiptsPaymentsListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final current = ref.read(transactionListFilterProvider);
        ref.read(transactionListFilterProvider.notifier).state =
            current.copyWith(transactionType: widget.initialType);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      ref.read(transactionListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final asyncList = ref.watch(transactionListProvider);
    final filter = ref.watch(transactionListFilterProvider);
    final type = filter.transactionType;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: switch (type) {
          TransactionType.receipt => l10n.rpListTitleReceipts,
          TransactionType.payment => l10n.rpListTitlePayments,
          null => l10n.rpListTitle,
        },
        showBackButton: true,
      ),
      floatingActionButton: _buildFab(context, l10n, type),
      body: Column(
        children: [
          const TransactionFilterBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.pagePadding,
                0,
                AppConstants.pagePadding,
                AppConstants.pagePadding,
              ),
              child: asyncList.when(
                loading: () => AppLoading(message: l10n.rpLoading),
                error: (error, _) => AppErrorState(
                  message: rpErrorMessage(l10n, error),
                  onRetry: () =>
                      ref.read(transactionListProvider.notifier).reload(),
                ),
                data: (listState) {
                  final items = listState.items;
                  if (items.isEmpty) {
                    return AppEmptyState(
                      title: l10n.rpEmptyTitle,
                      subtitle: l10n.rpEmptyMessage,
                      icon: Icons.account_balance_wallet_outlined,
                      actionLabel: _emptyActionLabel(l10n, type),
                      onAction: _emptyAction(context, type),
                    );
                  }
                  final footer = listState.hasMore ? 1 : 0;
                  return ListView.separated(
                    controller: _scrollController,
                    itemCount: items.length + footer,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index >= items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return _TransactionListTile(item: items[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFab(
    BuildContext context,
    AppLocalizations l10n,
    TransactionType? type,
  ) {
    if (type == TransactionType.receipt) {
      return PermissionGate(
        anyOf: ReceiptsPaymentsPermissions.receiptsCreate,
        child: FloatingActionButton.extended(
          onPressed: () => ReceiptsPaymentsRoutes.pushCreateReceipt(context),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.rpActionNewReceipt),
        ),
      );
    }
    if (type == TransactionType.payment) {
      return PermissionGate(
        anyOf: ReceiptsPaymentsPermissions.paymentsCreate,
        child: FloatingActionButton.extended(
          onPressed: () => ReceiptsPaymentsRoutes.pushCreatePayment(context),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.rpActionNewPayment),
        ),
      );
    }
    return PermissionGate(
      anyOf: [
        ...ReceiptsPaymentsPermissions.receiptsCreate,
        ...ReceiptsPaymentsPermissions.paymentsCreate,
      ],
      child: FloatingActionButton(
        onPressed: () => _showCreateMenu(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showCreateMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authStateProvider);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (auth.hasAnyPermission(ReceiptsPaymentsPermissions.receiptsCreate))
                ListTile(
                  leading: const Icon(Icons.call_received_outlined),
                  title: Text(l10n.rpActionNewReceipt),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ReceiptsPaymentsRoutes.pushCreateReceipt(context);
                  },
                ),
              if (auth.hasAnyPermission(ReceiptsPaymentsPermissions.paymentsCreate))
                ListTile(
                  leading: const Icon(Icons.call_made_outlined),
                  title: Text(l10n.rpActionNewPayment),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ReceiptsPaymentsRoutes.pushCreatePayment(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  String? _emptyActionLabel(AppLocalizations l10n, TransactionType? type) {
    final auth = ref.read(authStateProvider);
    if (type == TransactionType.receipt &&
        auth.hasAnyPermission(ReceiptsPaymentsPermissions.receiptsCreate)) {
      return l10n.rpActionNewReceipt;
    }
    if (type == TransactionType.payment &&
        auth.hasAnyPermission(ReceiptsPaymentsPermissions.paymentsCreate)) {
      return l10n.rpActionNewPayment;
    }
    return null;
  }

  VoidCallback? _emptyAction(BuildContext context, TransactionType? type) {
    final auth = ref.read(authStateProvider);
    if (type == TransactionType.receipt &&
        auth.hasAnyPermission(ReceiptsPaymentsPermissions.receiptsCreate)) {
      return () => ReceiptsPaymentsRoutes.pushCreateReceipt(context);
    }
    if (type == TransactionType.payment &&
        auth.hasAnyPermission(ReceiptsPaymentsPermissions.paymentsCreate)) {
      return () => ReceiptsPaymentsRoutes.pushCreatePayment(context);
    }
    return null;
  }
}

class _TransactionListTile extends StatelessWidget {
  const _TransactionListTile({required this.item});

  final TransactionListItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = DateFormat('d/M/yyyy').format(item.transactionDate.toLocal());
    final party = (item.partyDisplayName?.trim().isNotEmpty ?? false)
        ? item.partyDisplayName!.trim()
        : l10n.rpNoParty;
    final typeIcon = item.transactionType.isReceipt
        ? Icons.call_received_outlined
        : Icons.call_made_outlined;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ReceiptsPaymentsRoutes.pushDetails(context, item.id),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
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
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(typeIcon, color: scheme.primary, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatSaleNumberPrimary(item.transactionNumber),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            party,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RpMoneyText(
                          item.amount,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.currencyCode,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      rpTransactionTypeLabel(l10n, item.transactionType),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TransactionStatusBadge(
                  status: item.documentStatus,
                  label: rpTransactionStatusLabel(l10n, item.documentStatus),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
