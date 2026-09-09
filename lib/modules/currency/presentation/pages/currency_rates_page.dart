import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_amount_field.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';
import 'package:stock_count/core/widgets/app_error_state.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';

import 'currencies_manage_page.dart';
import '../../domain/entities/app_currency.dart';
import '../../domain/entities/currency_rate.dart';
import '../providers/currency_rate_providers.dart';
import '../widgets/missing_currency_dialog.dart';

/// Enabled currencies and their rates vs company base (add on demand).
class CurrencyRatesPage extends ConsumerWidget {
  const CurrencyRatesPage({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final base = ref.watch(accountingBaseCurrencyProvider);
    final listAsync = ref.watch(currencyRateListProvider);
    final availableToAdd = ref.watch(availableCurrenciesToAddProvider);

    final listWidget = listAsync.when(
      loading: () => const AppLoading(),
      error: (e, _) {
        final message = e.toString().contains('MissingCompanyContextException')
            ? 'سياق الشركة مفقود. يرجى تحديد الشركة أو تسجيل الدخول لعرض وتحديث أسعار الصرف.'
            : e.toString();
        return AppErrorState(message: message);
      },
      data: (items) {
        if (items.isEmpty) {
          final hasAvailableToAdd = availableToAdd.isNotEmpty;
          return AppEmptyState(
            title: isArabic ? 'لا توجد أسعار صرف مصارفة' : 'No Exchange Rates Configured',
            subtitle: base == null
                ? (isArabic
                    ? 'لم يتم إعداد العملة الافتراضية للنظام بعد. يرجى إضافة وتعيين عملة رئيسية من قائمة العملات.'
                    : 'System base currency is not configured. Please add and set a base currency from currencies catalog.')
                : (isArabic
                    ? 'لم يتم إضافة أسعار صرف مصارفة للعملات الأجنبية مقابل العملة الافتراضية للنظام (${base.code}).'
                    : 'No exchange rates configured against the system base currency (${base.code}).'),
            icon: Icons.currency_exchange_outlined,
            actionLabel: base == null
                ? (isArabic ? 'إعداد العملة الرئيسية' : 'Set Up Base Currency')
                : (hasAvailableToAdd
                    ? (isArabic ? 'إضافة مصارفة' : 'Add Exchange Rate')
                    : (isArabic ? 'إدارة قائمة العملات' : 'Manage Currencies Catalog')),
            onAction: () {
              if (base == null) {
                showMissingCurrencyDialog(context);
              } else if (hasAvailableToAdd) {
                _addCurrency(context, ref, availableToAdd);
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CurrenciesManagePage(),
                  ),
                );
              }
            },
          );
        }
        return ListView.separated(
          shrinkWrap: !showAppBar,
          physics: showAppBar ? null : const NeverScrollableScrollPhysics(),
          padding: showAppBar
              ? AppConstants.pageInsets(context).copyWith(
                  bottom: availableToAdd.isEmpty
                      ? AppConstants.pagePadding
                      : AppConstants.pagePadding + 72,
                )
              : EdgeInsets.zero,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currency.localizedName(isArabic),
                                style: theme.textTheme.titleSmall?.copyWith(
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
                                        base?.code ?? '',
                                      ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (item.rate != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  l10n.accountingCurrencyRatesUpdated(
                                    DateFormat.yMMMd(
                                      Localizations.localeOf(context).toString(),
                                    ).add_jm().format(
                                      item.rate!.updatedAt.toLocal(),
                                    ),
                                  ),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!item.isBase) ...[
                          IconButton(
                            onPressed: () => _removeCurrency(context, ref, item),
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
    );

    final contentColumn = Column(
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
              // System Base Default Currency Card
              _SystemDefaultCurrencyCard(base: base, isArabic: isArabic),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isArabic
                    ? 'أسعار الصرف والمصارفة المسجلة'
                    : 'Configured Exchange Rates',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (showAppBar) Expanded(child: listWidget) else listWidget,
      ],
    );

    if (!showAppBar) {
      return contentColumn;
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isArabic ? 'خدمة المصارفة (أسعار الصرف)' : 'Exchange Rates Service',
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (base == null) {
            showMissingCurrencyDialog(context);
          } else if (availableToAdd.isNotEmpty) {
            _addCurrency(context, ref, availableToAdd);
          } else {
            showAppSnackBar(
              context,
              message: isArabic
                  ? 'تم إضافة جميع أسعار الصرف للعملات المتاحة بالفعل'
                  : 'All available currency exchange rates are already added',
              isSuccess: false,
            );
          }
        },
        icon: const Icon(Icons.currency_exchange_rounded),
        label: Text(
          isArabic ? 'إضافة مصارفة' : 'Add Exchange Rate',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: contentColumn,
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
    if (base == null) {
      return;
    }

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

    final rate = result.rate;
    if (rate <= 0) {
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
    if (base == null) {
      return;
    }
    final baseCode = base.code;
    final initialRate = item.rate?.rateToBase ?? 0;

    final rate = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return _CurrencyRateEditDialog(
          title: l10n.accountingCurrencyRatesEditTitle(item.currency.code),
          hint: l10n.accountingCurrencyRatesEditHint(
            item.currency.localizedName(isArabic),
            baseCode,
          ),
          fieldLabel: l10n.accountingCurrencyRatesRateField,
          fieldHelper: l10n.accountingCurrencyRatesRateHelper(baseCode),
          cancelLabel: l10n.cancel,
          confirmLabel: l10n.confirm,
          initialRate: initialRate,
        );
      },
    );

    if (rate == null || !context.mounted) {
      return;
    }

    if (rate <= 0) {
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
  const _AddCurrencyResult({required this.currency, required this.rate});

  final AppCurrency currency;
  final double rate;
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
  var _rate = 0.0;

  @override
  void initState() {
    super.initState();
    _selected = widget.currencies.first;
  }

  void _submit() {
    Navigator.of(
      context,
    ).pop(_AddCurrencyResult(currency: _selected, rate: _rate));
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
              AppAmountField(
                value: _rate,
                onChanged: (value) => setState(() => _rate = value),
                decimalPlaces: 6,
                emptyWhenZero: true,
                trimTrailingZeros: true,
                label: widget.fieldLabel,
                hint: widget.fieldHelper,
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
    required this.initialRate,
  });

  final String title;
  final String hint;
  final String fieldLabel;
  final String fieldHelper;
  final String cancelLabel;
  final String confirmLabel;
  final double initialRate;

  @override
  State<_CurrencyRateEditDialog> createState() =>
      _CurrencyRateEditDialogState();
}

class _CurrencyRateEditDialogState extends State<_CurrencyRateEditDialog> {
  late double _rate;

  @override
  void initState() {
    super.initState();
    _rate = widget.initialRate;
  }

  void _submit() {
    Navigator.of(context).pop(_rate);
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
              AppAmountField(
                value: _rate,
                onChanged: (value) => setState(() => _rate = value),
                decimalPlaces: 6,
                emptyWhenZero: true,
                trimTrailingZeros: true,
                label: widget.fieldLabel,
                hint: widget.fieldHelper,
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

/// Header Card displaying the system default base currency on the Exchange Rates page
class _SystemDefaultCurrencyCard extends StatelessWidget {
  const _SystemDefaultCurrencyCard({
    required this.base,
    required this.isArabic,
  });

  final AppCurrency? base;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConfigured = base != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isConfigured
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isConfigured
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : Colors.amber.shade400,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: isConfigured
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConfigured ? Icons.account_balance_outlined : Icons.warning_amber_rounded,
              color: isConfigured
                  ? theme.colorScheme.primary
                  : Colors.amber.shade900,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isArabic ? 'العملة الافتراضية للنظام: ' : 'System Default Currency: ',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isConfigured)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          base!.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      )
                    else
                      Text(
                        isArabic ? 'غير محددة' : 'Not Configured',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isConfigured
                      ? (isArabic
                          ? '${base!.localizedName(isArabic)} (${base!.code}) — يتم حساب وتقويم جميع أسعار الصرف والمصارفة مقابلها.'
                          : '${base!.localizedName(isArabic)} (${base!.code}) — base for all exchange rates.')
                      : (isArabic
                          ? 'يرجى إعداد العملة الرئيسية من قائمة العملات لتشغيل خدمة المصارفة.'
                          : 'Please configure primary base currency to enable exchange rates.'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isConfigured
                        ? theme.colorScheme.onSurface
                        : Colors.amber.shade900,
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
