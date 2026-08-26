import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/constants/app_constants.dart';
import '../../../../../app/localization/app_localizations.dart';
import '../../../../../app/settings/widgets/settings_chrome.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../core/widgets/custom_app_bar.dart';

/// Dedicated settings page for the Products catalog service unit.
class ProductsSettingsPage extends ConsumerStatefulWidget {
  const ProductsSettingsPage({super.key});

  @override
  ConsumerState<ProductsSettingsPage> createState() => _ProductsSettingsPageState();
}

class _ProductsSettingsPageState extends ConsumerState<ProductsSettingsPage> {
  bool _autoGenerateBarcode = true;
  bool _enableLowStockAlerts = true;
  bool _allowDecimalQuantities = true;
  double _defaultTaxRate = 15.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.productSettingsTitle,
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              l10n.productSettingsSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SettingsGroupLabel(
            l10n.localeName == 'ar' ? 'الباركود والتكويد' : 'Barcode & Coding',
          ),
          SettingsGroup(
            children: [
              SwitchListTile(
                value: _autoGenerateBarcode,
                onChanged: (val) {
                  setState(() => _autoGenerateBarcode = val);
                  _showSavedMessage(context, l10n);
                },
                secondary: const Icon(Icons.qr_code_2_rounded),
                title: Text(l10n.localeName == 'ar' ? 'توليد الباركود تلقائياً' : 'Auto-Generate Barcode'),
                subtitle: Text(
                  l10n.localeName == 'ar'
                      ? 'إنشاء باركود تسلسلي افتراضي عند إضافة منتج جديد بلا باركود'
                      : 'Generate sequential barcode when adding a product without one',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsGroupLabel(
            l10n.localeName == 'ar' ? 'التسعير والكميات والضريبة' : 'Pricing, Quantities & Tax',
          ),
          SettingsGroup(
            children: [
              SwitchListTile(
                value: _enableLowStockAlerts,
                onChanged: (val) {
                  setState(() => _enableLowStockAlerts = val);
                  _showSavedMessage(context, l10n);
                },
                secondary: const Icon(Icons.notifications_active_outlined),
                title: Text(l10n.localeName == 'ar' ? 'تنبيهات نقص المخزون' : 'Low Stock Alerts'),
                subtitle: Text(
                  l10n.localeName == 'ar'
                      ? 'إظهار تنبيه عند انخفاض رصيد المنتج عن الحد الأدنى'
                      : 'Show warning when product stock reaches reorder level',
                ),
              ),
              SwitchListTile(
                value: _allowDecimalQuantities,
                onChanged: (val) {
                  setState(() => _allowDecimalQuantities = val);
                  _showSavedMessage(context, l10n);
                },
                secondary: const Icon(Icons.pin_outlined),
                title: Text(l10n.localeName == 'ar' ? 'السماح بالكميات الكسرية' : 'Allow Fractional Quantities'),
                subtitle: Text(
                  l10n.localeName == 'ar'
                      ? 'السماح بإدخال كميات كسور (مثل 1.5 كجم أو 2.25 متر)'
                      : 'Allow entering decimal quantities (e.g. 1.5 kg or 2.25 m)',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.percent_rounded),
                title: Text(l10n.localeName == 'ar' ? 'نسبة الضريبة الافتراضية' : 'Default Tax Rate'),
                subtitle: Text('$_defaultTaxRate%'),
                trailing: SizedBox(
                  width: 120,
                  child: DropdownButton<double>(
                    value: _defaultTaxRate,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 0.0, child: Text('0% (معفى)')),
                      DropdownMenuItem(value: 5.0, child: Text('5%')),
                      DropdownMenuItem(value: 15.0, child: Text('15%')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _defaultTaxRate = val);
                        _showSavedMessage(context, l10n);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSavedMessage(BuildContext context, AppLocalizations l10n) {
    showAppSnackBar(
      context,
      message: l10n.localeName == 'ar' ? 'تم حفظ التغييرات' : 'Settings saved',
      isSuccess: true,
    );
  }
}
