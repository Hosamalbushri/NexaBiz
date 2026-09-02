import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/domain/services/device_document_number.dart';
import 'package:stock_count/core/presentation/scaffolds/module_list_scaffold.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/authentication/presentation/widgets/permission_gate.dart';
import 'package:stock_count/modules/receipts_payments/permissions/receipts_payments_permission_package.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_list_item.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/transactions/presentation/providers/transaction_list_provider.dart';
import 'package:stock_count/modules/receipts_payments/transactions/presentation/utils/rp_labels.dart';
import 'package:stock_count/modules/receipts_payments/transactions/presentation/widgets/rp_error_messages.dart';
import 'package:stock_count/modules/receipts_payments/transactions/presentation/widgets/transaction_status_badge.dart';
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
  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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

    final listState = asyncList.valueOrNull;
    final canCreate = ref
        .read(authStateProvider)
        .hasAnyPermission(createPermissions);

    return ModuleListScaffold<TransactionListItem>(
      title: title,
      searchQuery: filter.query,
      searchHint: l10n.salesSearchHint,
      onSearchChanged: (val) {
        final current = ref.read(transactionListFilterProvider);
        ref.read(transactionListFilterProvider.notifier).state =
            current.copyWith(query: val.trim());
      },
      isLoading: asyncList.isLoading && !asyncList.hasValue,
      error: asyncList.error != null ? rpErrorMessage(l10n, asyncList.error!) : null,
      onRetry: () => ref.read(transactionListProvider.notifier).reload(),
      onRefresh: () async {
        await ref.read(transactionListProvider.notifier).reload();
      },
      isLoadingMore: listState?.isLoadingMore ?? false,
      onLoadMore: () {
        if (listState?.hasMore == true) {
          ref.read(transactionListProvider.notifier).loadMore();
        }
      },
      emptyTitle: emptyTitle,
      emptyMessage: emptyMessage,
      emptyIcon: emptyIcon,
      emptyActionLabel: canCreate ? actionLabel : null,
      onEmptyAction: canCreate
          ? () {
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
            }
          : null,
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
      items: listState?.items ?? const [],
      itemBuilder: (context, item) => _TransactionListTile(item: item),
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
