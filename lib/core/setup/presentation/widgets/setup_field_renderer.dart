import 'package:flutter/material.dart';
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
        final boolVal = (currentValue as bool?) ?? (field.defaultValue as bool? ?? false);
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          value: boolVal,
          onChanged: onChanged,
        );

      case SetupFieldType.text:
        final strVal = currentValue?.toString() ?? field.defaultValue?.toString() ?? '';
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
        final numVal = currentValue?.toString() ?? field.defaultValue?.toString() ?? '';
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
        final options = field.allowedValues?.map((e) => e.toString()).toList() ?? [];
        final selected = currentValue?.toString() ?? field.defaultValue?.toString();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: DropdownButtonFormField<String>(
            initialValue: options.contains(selected) ? selected : (options.isNotEmpty ? options.first : null),
            decoration: InputDecoration(
              labelText: label + (field.isRequired ? ' *' : ''),
              border: const OutlineInputBorder(),
            ),
            items: options.map((opt) {
              return DropdownMenuItem<String>(
                value: opt,
                child: Text(opt),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        );

      case SetupFieldType.reference:
        final selectedUuid = currentValue?.toString();
        final isConfigured = selectedUuid != null && selectedUuid.isNotEmpty;
        final isParent = bindingMode == AccountBindingMode.parent;

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
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
              InputDecorator(
                decoration: InputDecoration(
                  labelText: isParent
                      ? (isArabic ? 'اختر حساباً رئيسياً (مجموعة)' : 'Select Parent Group Account')
                      : (isArabic ? 'اختر حساباً تفصيلياً من الدليل' : 'Select Account from COA'),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: availableAccounts.any((a) => a.uuid == selectedUuid) ? selectedUuid : null,
                    hint: Text(
                      isArabic ? 'غير محدد (اختر حساباً)' : 'Not Configured (Select Account)',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          isArabic ? '-- بدون حساب (غير محدد) --' : '-- No Account (Unbound) --',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                      ...availableAccounts.map((account) {
                        final typeLabel = account.isGroup
                            ? (isArabic ? ' [حساب رئيسي]' : ' [Group]')
                            : '';
                        return DropdownMenuItem<String>(
                          value: account.uuid,
                          child: Text(
                            '${account.code} - ${account.name}$typeLabel',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: account.isGroup ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }),
                    ],
                    onChanged: onChanged,
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
        color: isParent ? Colors.purple.withValues(alpha: 0.12) : Colors.blue.withValues(alpha: 0.12),
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

  Widget _buildStatusBadge(ThemeData theme, bool isConfigured, bool isRequired) {
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
            Icon(Icons.check_circle_outline, size: 14, color: Colors.green.shade700),
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

