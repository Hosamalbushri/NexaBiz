import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/settings/company/app_currency.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/currency_rate.dart';
import '../providers/currency_rate_providers.dart';

/// Enabled currencies and their rates vs company base (add on demand).
class CurrencyRatesPage extends ConsumerWidget {
  const CurrencyRatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final base = ref.watch(accountingBaseCurrencyProvider);
    final listAsync = ref.watch(currencyRateListProvider);
    final availableToAdd = ref.watch(availableCurrenciesToAddProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.accountingCurrencyRatesTitle,
        showBackButton: true,
      ),
      floatingActionButton: availableToAdd.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addCurrency(context, ref, availableToAdd),
              icon: const Icon(Icons.add),
              label: Text(l10n.accountingCurrencyRatesAdd),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.pagePadding,
              AppSpacing.md,
              AppConstants.pagePadding,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.accountingCurrencyRatesSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppStatusBadge(
                  label: l10n.accountingCurrencyRatesBase(
                    base.code,
                    base.localizedName(isArabic),
                  ),
                  tone: AppStatusTone.info,
                  animate: false,
                ),
              ],
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const AppLoading(),
              error: (e, _) => AppErrorState(message: e.toString()),
              data: (items) {
                if (items.isEmpty) {
                  return AppEmptyState(
                    title: l10n.accountingCurrencyRatesEmptyTitle,
                    subtitle: l10n.accountingCurrencyRatesEmptyMessage,
                    icon: Icons.currency_exchange_outlined,
                  );
                }
                return ListView.separated(
                  padding: AppConstants.pageInsets(context).copyWith(
                    bottom: availableToAdd.isEmpty
                        ? AppConstants.pagePadding
                        : AppConstants.pagePadding + 72,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final currency = item.currency;
                    return Material(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: item.isBase
                            ? null
                            : () => _editRate(context, ref, item),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                  child: Text(
                                    currency.code,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currency.localizedName(isArabic),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.isBase
                                            ? l10n.accountingCurrencyRatesBaseHint
                                            : l10n.accountingCurrencyRatesEquals(
                                                currency.code,
                                                _formatRate(item.displayRate),
                                                base.code,
                                              ),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      if (item.rate != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.accountingCurrencyRatesUpdated(
                                            DateFormat.yMMMd(
                                              Localizations.localeOf(
                                                context,
                                              ).toString(),
                                            ).add_jm().format(
                                              item.rate!.updatedAt.toLocal(),
                                            ),
                                          ),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (item.isBase)
                                  AppStatusBadge(
                                    label:
                                        l10n.accountingCurrencyRatesBaseBadge,
                                    tone: AppStatusTone.success,
                                    animate: false,
                                  )
                                else ...[
                                  IconButton(
                                    tooltip: l10n.accountingCurrencyRatesRemove,
                                    onPressed: () =>
                                        _removeCurrency(context, ref, item),
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                  Icon(
                                    Icons.edit_outlined,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatRate(double value) {
    if (value == 0) {
      return '—';
    }
    final digits = value >= 100
        ? 2
        : value >= 1
        ? 4
        : 6;
    return value.toStringAsFixed(digits).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  Future<void> _addCurrency(
    BuildContext context,
    WidgetRef ref,
    List<AppCurrency> available,
  ) async {
    if (available.isEmpty) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final base = ref.read(accountingBaseCurrencyProvider);

    final result = await showDialog<_AddCurrencyResult>(
      context: context,
      builder: (dialogContext) {
        return _CurrencyRateAddDialog(
          title: l10n.accountingCurrencyRatesAddTitle,
          hint: l10n.accountingCurrencyRatesAddHint,
          currencyLabel: l10n.accountingCurrencyRatesCurrencyField,
          fieldLabel: l10n.accountingCurrencyRatesRateField,
          fieldHelper: l10n.accountingCurrencyRatesRateHelper(base.code),
          cancelLabel: l10n.cancel,
          confirmLabel: l10n.confirm,
          currencies: available,
          isArabic: isArabic,
        );
      },
    );

    if (result == null || !context.mounted) {
      return;
    }

    final rate = double.tryParse(result.rateText.trim().replaceAll(',', '.'));
    if (rate == null || rate <= 0) {
      showAppSnackBar(
        context,
        message: l10n.accountingCurrencyRatesInvalid,
        isSuccess: false,
      );
      return;
    }

    try {
      await ref
          .read(currencyRateRepositoryProvider)
          .upsert(
            CurrencyRateDraft(
              currencyCode: result.currency.code,
              rateToBase: rate,
            ),
          );
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.accountingCurrencyRatesSaved,
        isSuccess: true,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, message: e.toString(), isSuccess: false);
    }
  }

  Future<void> _removeCurrency(
    BuildContext context,
    WidgetRef ref,
    CurrencyRateListItem item,
  ) async {
    if (item.isBase) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.accountingCurrencyRatesRemoveTitle),
          content: Text(
            l10n.accountingCurrencyRatesRemoveMessage(
              item.currency.localizedName(isArabic),
              item.currency.code,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.accountingCurrencyRatesRemove),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(currencyRateRepositoryProvider)
          .deleteByCode(item.currency.code);
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.accountingCurrencyRatesRemoved,
        isSuccess: true,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, message: e.toString(), isSuccess: false);
    }
  }

  Future<void> _editRate(
    BuildContext context,
    WidgetRef ref,
    CurrencyRateListItem item,
  ) async {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final base = ref.read(accountingBaseCurrencyProvider);
    final initialText = item.rate == null
        ? ''
        : _formatRate(item.rate!.rateToBase);

    final raw = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _CurrencyRateEditDialog(
          title: l10n.accountingCurrencyRatesEditTitle(item.currency.code),
          hint: l10n.accountingCurrencyRatesEditHint(
            item.currency.localizedName(isArabic),
            base.code,
          ),
          fieldLabel: l10n.accountingCurrencyRatesRateField,
          fieldHelper: l10n.accountingCurrencyRatesRateHelper(base.code),
          cancelLabel: l10n.cancel,
          confirmLabel: l10n.confirm,
          initialText: initialText,
        );
      },
    );

    if (raw == null || !context.mounted) {
      return;
    }

    final rate = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (rate == null || rate <= 0) {
      showAppSnackBar(
        context,
        message: l10n.accountingCurrencyRatesInvalid,
        isSuccess: false,
      );
      return;
    }

    try {
      await ref
          .read(currencyRateRepositoryProvider)
          .upsert(
            CurrencyRateDraft(
              currencyCode: item.currency.code,
              rateToBase: rate,
            ),
          );
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.accountingCurrencyRatesSaved,
        isSuccess: true,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, message: e.toString(), isSuccess: false);
    }
  }
}

class _AddCurrencyResult {
  const _AddCurrencyResult({required this.currency, required this.rateText});

  final AppCurrency currency;
  final String rateText;
}

class _CurrencyRateAddDialog extends StatefulWidget {
  const _CurrencyRateAddDialog({
    required this.title,
    required this.hint,
    required this.currencyLabel,
    required this.fieldLabel,
    required this.fieldHelper,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.currencies,
    required this.isArabic,
  });

  final String title;
  final String hint;
  final String currencyLabel;
  final String fieldLabel;
  final String fieldHelper;
  final String cancelLabel;
  final String confirmLabel;
  final List<AppCurrency> currencies;
  final bool isArabic;

  @override
  State<_CurrencyRateAddDialog> createState() => _CurrencyRateAddDialogState();
}

class _CurrencyRateAddDialogState extends State<_CurrencyRateAddDialog> {
  late AppCurrency _selected;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _selected = widget.currencies.first;
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(
      context,
    ).pop(_AddCurrencyResult(currency: _selected, rateText: _controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.hint, style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<AppCurrency>(
                initialValue: _selected,
                decoration: InputDecoration(labelText: widget.currencyLabel),
                items: [
                  for (final currency in widget.currencies)
                    DropdownMenuItem(
                      value: currency,
                      child: Text(
                        '${currency.code} — ${currency.localizedName(widget.isArabic)}',
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _selected = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: widget.fieldLabel,
                  helperText: widget.fieldHelper,
                  helperMaxLines: 3,
                ),
                autofocus: true,
                onSubmitted: (_) => _submit(),
              ),
              SizedBox(height: media.viewInsets.bottom > 0 ? AppSpacing.md : 0),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

class _CurrencyRateEditDialog extends StatefulWidget {
  const _CurrencyRateEditDialog({
    required this.title,
    required this.hint,
    required this.fieldLabel,
    required this.fieldHelper,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.initialText,
  });

  final String title;
  final String hint;
  final String fieldLabel;
  final String fieldHelper;
  final String cancelLabel;
  final String confirmLabel;
  final String initialText;

  @override
  State<_CurrencyRateEditDialog> createState() =>
      _CurrencyRateEditDialogState();
}

class _CurrencyRateEditDialogState extends State<_CurrencyRateEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.hint, style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: widget.fieldLabel,
                  helperText: widget.fieldHelper,
                  helperMaxLines: 3,
                ),
                autofocus: true,
                onSubmitted: (_) => _submit(),
              ),
              SizedBox(height: media.viewInsets.bottom > 0 ? AppSpacing.md : 0),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
