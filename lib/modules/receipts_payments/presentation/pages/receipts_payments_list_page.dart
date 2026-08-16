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

/// Typed list of receipt or payment vouchers (separate routes per type).
class ReceiptsPaymentsListPage extends ConsumerStatefulWidget {
  const ReceiptsPaymentsListPage({super.key, required this.transactionType});

  final TransactionType transactionType;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _lockTypeFilter();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ReceiptsPaymentsListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactionType != widget.transactionType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _lockTypeFilter();
        }
      });
    }
  }

  void _lockTypeFilter() {
    final current = ref.read(transactionListFilterProvider);
    if (current.transactionType == widget.transactionType) {
      return;
    }
    ref.read(transactionListFilterProvider.notifier).state =
        current.copyWith(transactionType: widget.transactionType);
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
    final filter = ref.watch(transactionListFilterProvider);
    if (filter.transactionType != widget.transactionType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _lockTypeFilter();
        }
      });
    }
    final asyncList = ref.watch(transactionListProvider);
    final type = widget.transactionType;
    final title = switch (type) {
      TransactionType.receipt => l10n.rpListTitleReceipts,
      TransactionType.payment => l10n.rpListTitlePayments,
      TransactionType.transfer => l10n.rpListTitleTransfers,
      TransactionType.currencyExchange => l10n.rpListTitleExchanges,
    };
    final createPermissions = switch (type) {
      TransactionType.receipt => ReceiptsPaymentsPermissions.receiptsCreate,
      TransactionType.payment => ReceiptsPaymentsPermissions.paymentsCreate,
      TransactionType.transfer => ReceiptsPaymentsPermissions.transfersCreate,
      TransactionType.currencyExchange =>
        ReceiptsPaymentsPermissions.exchangesCreate,
    };
    final actionLabel = switch (type) {
      TransactionType.receipt => l10n.rpActionNewReceipt,
      TransactionType.payment => l10n.rpActionNewPayment,
      TransactionType.transfer => l10n.rpActionNewTransfer,
      TransactionType.currencyExchange => l10n.rpActionNewExchange,
    };
    final emptyTitle = switch (type) {
      TransactionType.receipt => l10n.rpEmptyTitleReceipts,
      TransactionType.payment => l10n.rpEmptyTitlePayments,
      TransactionType.transfer => l10n.rpEmptyTitleTransfers,
      TransactionType.currencyExchange => l10n.rpEmptyTitleExchanges,
    };
    final emptyMessage = switch (type) {
      TransactionType.receipt => l10n.rpEmptyMessageReceipts,
      TransactionType.payment => l10n.rpEmptyMessagePayments,
      TransactionType.transfer => l10n.rpEmptyMessageTransfers,
      TransactionType.currencyExchange => l10n.rpEmptyMessageExchanges,
    };
    final emptyIcon = switch (type) {
      TransactionType.receipt => Icons.call_received_outlined,
      TransactionType.payment => Icons.call_made_outlined,
      TransactionType.transfer => Icons.swap_horiz_outlined,
      TransactionType.currencyExchange => Icons.currency_exchange_outlined,
    };

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: title,
        showBackButton: true,
      ),
      floatingActionButton: PermissionGate(
        anyOf: createPermissions,
        child: FloatingActionButton.extended(
          onPressed: () {
            switch (type) {
              case TransactionType.receipt:
                ReceiptsPaymentsRoutes.pushCreateReceipt(context);
              case TransactionType.payment:
                ReceiptsPaymentsRoutes.pushCreatePayment(context);
              case TransactionType.transfer:
                ReceiptsPaymentsRoutes.pushCreateTransfer(context);
              case TransactionType.currencyExchange:
                ReceiptsPaymentsRoutes.pushCreateExchange(context);
            }
          },
          icon: const Icon(Icons.add_rounded),
          label: Text(actionLabel),
        ),
      ),
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
                    final canCreate = ref
                        .read(authStateProvider)
                        .hasAnyPermission(createPermissions);
                    return AppEmptyState(
                      title: emptyTitle,
                      subtitle: emptyMessage,
                      icon: emptyIcon,
                      actionLabel: canCreate ? actionLabel : null,
                      onAction: canCreate
                          ? () {
                              switch (type) {
                                case TransactionType.receipt:
                                  ReceiptsPaymentsRoutes.pushCreateReceipt(
                                    context,
                                  );
                                case TransactionType.payment:
                                  ReceiptsPaymentsRoutes.pushCreatePayment(
                                    context,
                                  );
                                case TransactionType.transfer:
                                  ReceiptsPaymentsRoutes.pushCreateTransfer(
                                    context,
                                  );
                                case TransactionType.currencyExchange:
                                  ReceiptsPaymentsRoutes.pushCreateExchange(
                                    context,
                                  );
                              }
                            }
                          : null,
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
    final showParty = item.transactionType.isReceipt;
    final party = (item.partyDisplayName?.trim().isNotEmpty ?? false)
        ? item.partyDisplayName!.trim()
        : l10n.rpNoParty;
    final description = item.description?.trim() ?? '';
    final typeIcon = switch (item.transactionType) {
      TransactionType.receipt => Icons.call_received_outlined,
      TransactionType.payment => Icons.call_made_outlined,
      TransactionType.transfer => Icons.swap_horiz_outlined,
      TransactionType.currencyExchange => Icons.currency_exchange_outlined,
    };

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
                          if (showParty) ...[
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
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
                    const Spacer(),
                    TransactionStatusBadge(
                      status: item.documentStatus,
                      label: rpTransactionStatusLabel(
                        l10n,
                        item.documentStatus,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
