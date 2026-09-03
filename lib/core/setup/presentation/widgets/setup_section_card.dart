import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../domain/entities/account_role.dart';
import '../../setup.dart';
import 'setup_field_renderer.dart';

/// Card container widget for rendering a [SetupSection] and its fields.
class SetupSectionCard extends StatelessWidget {
  const SetupSectionCard({
    super.key,
    required this.section,
    required this.fieldValues,
    required this.onFieldValueChanged,
    required this.isArabic,
    this.availableAccounts = const [],
    this.accountRoles = const {},
    this.accountBindingModes = const {},
  });

  final SetupSection section;
  final Map<String, dynamic> fieldValues;
  final void Function(String fieldKey, dynamic newValue) onFieldValueChanged;
  final bool isArabic;
  final List<SetupAccountOption> availableAccounts;
  final Map<String, AccountRole> accountRoles;
  final Map<String, AccountBindingMode> accountBindingModes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = section.title(isArabic ? 'ar' : 'en');
    final description = section.description(isArabic ? 'ar' : 'en');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                section.id.contains('account')
                    ? Icons.account_balance_outlined
                    : Icons.tune_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          ...section.fields.map((field) {
            final currentValue = fieldValues[field.key];
            final role = accountRoles[field.key];
            final bindingMode = accountBindingModes[field.key] ?? AccountBindingMode.exact;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SetupFieldRenderer(
                field: field,
                currentValue: currentValue,
                isArabic: isArabic,
                accountRole: role,
                bindingMode: bindingMode,
                availableAccounts: availableAccounts,
                onChanged: (newValue) => onFieldValueChanged(field.key, newValue),
              ),
            );
          }),
        ],
      ),
    );
  }
}

