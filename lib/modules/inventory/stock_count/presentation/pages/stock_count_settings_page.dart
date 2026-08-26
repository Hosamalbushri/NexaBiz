import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/constants/app_constants.dart';
import '../../../../../app/localization/app_localizations.dart';
import '../../../../../app/settings/widgets/settings_chrome.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../core/widgets/custom_app_bar.dart';

/// Dedicated settings page for the Stock Count service unit.
class StockCountSettingsPage extends ConsumerStatefulWidget {
  const StockCountSettingsPage({super.key});

  @override
  ConsumerState<StockCountSettingsPage> createState() => _StockCountSettingsPageState();
}

class _StockCountSettingsPageState extends ConsumerState<StockCountSettingsPage> {
  bool _requireVarianceApproval = true;
  bool _continuousBarcodeMode = false;
  bool _allowNegativeStockAdjust = false;
  int _autoSaveIntervalSeconds = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.stockCountSettingsTitle,
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              l10n.stockCountSettingsSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SettingsGroupLabel(
            l10n.localeName == 'ar' ? 'سياسات الجرد والتسوية' : 'Counting & Adjustment Policies',
          ),
          SettingsGroup(
            children: [
              SwitchListTile(
                value: _requireVarianceApproval,
                onChanged: (val) {
                  setState(() => _requireVarianceApproval = val);
                  _showSavedMessage(context, l10n);
                },
                secondary: const Icon(Icons.fact_check_outlined),
                title: Text(l10n.localeName == 'ar' ? 'اشتراط واعتماد الفوارق' : 'Require Variance Approval'),
                subtitle: Text(
                  l10n.localeName == 'ar'
                      ? 'يتطلب اعتماد المشرف عند وجود فارق بين الكمية الفعلية والدفترية'
                      : 'Requires manager sign-off when count differs from book stock',
                ),
              ),
              SwitchListTile(
                value: _allowNegativeStockAdjust,
                onChanged: (val) {
                  setState(() => _allowNegativeStockAdjust = val);
                  _showSavedMessage(context, l10n);
                },
                secondary: const Icon(Icons.warning_amber_rounded),
                title: Text(l10n.localeName == 'ar' ? 'السماح بتسوية الفروق السالبة' : 'Allow Negative Adjustments'),
                subtitle: Text(
                  l10n.localeName == 'ar'
                      ? 'السماح بتسوية الأصناف حتى وإن تسببت برصيد مخزون بالسالب'
                      : 'Allow adjusting items even if book quantity goes negative',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsGroupLabel(
            l10n.localeName == 'ar' ? 'خيارات الماسح والحفظ' : 'Scanner & Auto-Save Options',
          ),
          SettingsGroup(
            children: [
              SwitchListTile(
                value: _continuousBarcodeMode,
                onChanged: (val) {
                  setState(() => _continuousBarcodeMode = val);
                  _showSavedMessage(context, l10n);
                },
                secondary: const Icon(Icons.qr_code_scanner_rounded),
                title: Text(l10n.localeName == 'ar' ? 'وضع المسح المستمر للباركود' : 'Continuous Barcode Scanning'),
                subtitle: Text(
                  l10n.localeName == 'ar'
                      ? 'زيادة الكمية تلقائياً بقيمة 1 عند كل عملية مسح دون إغلاق الماسح'
                      : 'Automatically increment quantity by 1 on each scan without closing camera',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text(l10n.localeName == 'ar' ? 'فترة الحفظ التلقائي المسودات' : 'Draft Auto-Save Interval'),
                subtitle: Text(
                  l10n.localeName == 'ar'
                      ? 'حفظ تلقائي كل $_autoSaveIntervalSeconds ثانية أثناء إجراء الجرد'
                      : 'Auto-save every $_autoSaveIntervalSeconds seconds during counting',
                ),
                trailing: DropdownButton<int>(
                  value: _autoSaveIntervalSeconds,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('15s')),
                    DropdownMenuItem(value: 30, child: Text('30s')),
                    DropdownMenuItem(value: 60, child: Text('60s')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _autoSaveIntervalSeconds = val);
                      _showSavedMessage(context, l10n);
                    }
                  },
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
