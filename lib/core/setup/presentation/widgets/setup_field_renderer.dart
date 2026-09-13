import 'package:flutter/material.dart';
import '../../../widgets/app_account_search_picker.dart';
import '../../../domain/entities/account_role.dart';
import '../../setup.dart';

/// Dynamic widget renderer for a single [SetupField].
class SetupFieldRenderer extends StatelessWidget {
  const SetupFieldRenderer({
    super.key,
    required this.field,
    required this.currentValue,
    required this.onChanged,
    required this.isArabic,
    this.accountRole,
    this.bindingMode = AccountBindingMode.exact,
    this.availableAccounts = const [],
  });

  final SetupField field;
  final dynamic currentValue;
  final ValueChanged<dynamic> onChanged;
  final bool isArabic;
  final AccountRole? accountRole;
  final AccountBindingMode bindingMode;
  final List<SetupAccountOption> availableAccounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = field.label(isArabic ? 'ar' : 'en');

    switch (field.fieldType) {
      case SetupFieldType.boolean:
        final boolVal =
            (currentValue as bool?) ?? (field.defaultValue as bool? ?? false);
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          value: boolVal,
          onChanged: onChanged,
        );

      case SetupFieldType.text:
        final strVal =
            currentValue?.toString() ?? field.defaultValue?.toString() ?? '';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: TextFormField(
            initialValue: strVal,
            decoration: InputDecoration(
              labelText: label + (field.isRequired ? ' *' : ''),
              border: const OutlineInputBorder(),
            ),
            onChanged: onChanged,
          ),
        );

      case SetupFieldType.number:
        final numVal =
            currentValue?.toString() ?? field.defaultValue?.toString() ?? '';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: TextFormField(
            initialValue: numVal,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: label + (field.isRequired ? ' *' : ''),
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) {
              final parsed = num.tryParse(val);
              onChanged(parsed ?? val);
            },
          ),
        );

      case SetupFieldType.select:
        final options =
            field.allowedValues?.map((e) => e.toString()).toList() ?? [];
        final selected =
            currentValue?.toString() ?? field.defaultValue?.toString();

        String getOptionLabel(String opt) {
          if (field.key == 'inventoryValuationCurrencyId' ||
              field.id == 'inventoryValuationCurrencyId') {
            switch (opt.toUpperCase()) {
              case 'YER':
                return isArabic ? 'ريال يمني (YER)' : 'Yemeni Rial (YER)';
              case 'SAR':
                return isArabic ? 'ريال سعودي (SAR)' : 'Saudi Riyal (SAR)';
              case 'USD':
                return isArabic ? 'دولار أمريكي (USD)' : 'US Dollar (USD)';
              default:
                return opt;
            }
          }
          return opt;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: options.contains(selected)
                ? selected
                : (options.isNotEmpty ? options.first : null),
            decoration: InputDecoration(
              labelText: label + (field.isRequired ? ' *' : ''),
              border: const OutlineInputBorder(),
              prefixIcon:
                  (field.key == 'inventoryValuationCurrencyId' ||
                      field.id == 'inventoryValuationCurrencyId')
                  ? const Icon(Icons.currency_exchange_rounded)
                  : null,
            ),
            items: options.map((opt) {
              return DropdownMenuItem<String>(
                value: opt,
                child: Text(
                  getOptionLabel(opt),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        );

      case SetupFieldType.reference:
        if (field.key == 'defaultWarehouseId' ||
            field.id == 'defaultWarehouseId') {
          final warehouseOptions =
              field.allowedValues?.map((e) => e.toString()).toList() ??
              ['wh_main', 'wh_sales', 'wh_central'];
          final selectedWh = currentValue?.toString();
          final isConfiguredWh = selectedWh != null && selectedWh.isNotEmpty;

          String getWhLabel(String val) {
            switch (val) {
              case 'wh_main':
              case 'المستودع الرئيسي (الافتراضي)':
                return isArabic
                    ? 'المستودع الرئيسي (الافتراضي)'
                    : 'Main Primary Warehouse (Default)';
              case 'wh_sales':
              case 'مستودع المعرض الرئيسي':
                return isArabic
                    ? 'مستودع المعرض الرئيسي'
                    : 'Main Showroom Warehouse';
              case 'wh_central':
              case 'مستودع البضائع المركزي':
                return isArabic
                    ? 'مستودع البضائع المركزي'
                    : 'Central Goods Warehouse';
              default:
                return val;
            }
          }

          final initialWh = warehouseOptions.contains(selectedWh)
              ? selectedWh
              : (selectedWh != null && selectedWh.isNotEmpty
                    ? selectedWh
                    : warehouseOptions.first);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label + (field.isRequired ? ' *' : ''),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _buildStatusBadge(theme, isConfiguredWh, field.isRequired),
                  ],
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: initialWh,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.warehouse_outlined),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: [
                    ...warehouseOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt,
                        child: Row(
                          children: [
                            const Icon(Icons.store_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                getWhLabel(opt),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (selectedWh != null &&
                        !warehouseOptions.contains(selectedWh))
                      DropdownMenuItem<String>(
                        value: selectedWh,
                        child: Row(
                          children: [
                            const Icon(Icons.store_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                getWhLabel(selectedWh),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  onChanged: onChanged,
                ),
              ],
            ),
          );
        }

        final selectedUuid = currentValue?.toString();
        final isConfigured = selectedUuid != null && selectedUuid.isNotEmpty;
        final isParent = bindingMode == AccountBindingMode.parent;
        final selectedAccount = availableAccounts.firstWhere(
          (a) => a.uuid == selectedUuid,
          orElse: () => SetupAccountOption(
            uuid: selectedUuid ?? '',
            code: '',
            name: isArabic ? 'غير محدد' : 'Not Configured',
          ),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            label + (field.isRequired ? ' *' : ''),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildBindingModeChip(theme, isParent),
                      ],
                    ),
                  ),
                  _buildStatusBadge(theme, isConfigured, field.isRequired),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final picked = await showAppAccountPicker(
                    context,
                    title: label,
                    selectedUuid: selectedUuid,
                    postingOnlyDefault: !isParent,
                  );
                  if (picked != null) {
                    onChanged(picked.id);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isConfigured
                          ? theme.colorScheme.primary.withValues(alpha: 0.6)
                          : theme.colorScheme.outlineVariant,
                      width: isConfigured ? 1.2 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_tree_outlined,
                        size: 20,
                        color: isConfigured
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: isConfigured
                            ? Text(
                                selectedAccount.code.isNotEmpty
                                    ? '${selectedAccount.code} - ${selectedAccount.name}'
                                    : selectedUuid!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(
                                isArabic
                                    ? 'اضغط للبحث واختيار حساب من الدليل...'
                                    : 'Tap to search & select account...',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                      if (isConfigured)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          tooltip: isArabic ? 'إلغاء التحديد' : 'Clear',
                          onPressed: () => onChanged(null),
                        )
                      else
                        Icon(
                          Icons.arrow_drop_down,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildBindingModeChip(ThemeData theme, bool isParent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isParent
            ? Colors.purple.withValues(alpha: 0.12)
            : Colors.blue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isParent ? Colors.purple.shade400 : Colors.blue.shade400,
          width: 0.6,
        ),
      ),
      child: Text(
        isParent
            ? (isArabic ? 'حساب رئيسي' : 'Parent Account')
            : (isArabic ? 'حساب تفصيلي' : 'Exact Account'),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isParent ? Colors.purple.shade800 : Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    ThemeData theme,
    bool isConfigured,
    bool isRequired,
  ) {
    if (isConfigured) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade600, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 14,
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              isArabic ? 'مربوط' : 'CONFIGURED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isRequired ? Colors.amber.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRequired ? Colors.amber.shade700 : Colors.grey.shade400,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRequired ? Icons.warning_amber_rounded : Icons.info_outline,
            size: 14,
            color: isRequired ? Colors.amber.shade900 : Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isArabic ? 'غير مهيأ' : 'NOT CONFIGURED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isRequired ? Colors.amber.shade900 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

/// DTO representing an account option for account picker dropdowns.
class SetupAccountOption {
  const SetupAccountOption({
    required this.uuid,
    required this.code,
    required this.name,
    this.isGroup = false,
    this.role,
  });

  final String uuid;
  final String code;
  final String name;
  final bool isGroup;
  final AccountRole? role;
}
