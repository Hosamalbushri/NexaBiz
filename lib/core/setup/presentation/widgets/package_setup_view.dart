import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../domain/entities/account_role.dart';
import '../../setup.dart';
import 'setup_field_renderer.dart';
import 'setup_section_card.dart';

/// View component rendering setup sections for a single [PackageSetupDefinition].
class PackageSetupView extends StatelessWidget {
  const PackageSetupView({
    super.key,
    required this.definition,
    required this.fieldValues,
    required this.onFieldValueChanged,
    required this.isArabic,
    this.status = SetupStatus.notConfigured,
    this.availableAccounts = const [],
    this.accountRoles = const {},
    this.accountBindingModes = const {},
  });

  final PackageSetupDefinition definition;
  final Map<String, dynamic> fieldValues;
  final void Function(String fieldKey, dynamic newValue) onFieldValueChanged;
  final bool isArabic;
  final SetupStatus status;
  final List<SetupAccountOption> availableAccounts;
  final Map<String, AccountRole> accountRoles;
  final Map<String, AccountBindingMode> accountBindingModes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final packageName = definition.displayName(isArabic ? 'ar' : 'en');

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    packageName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isArabic ? 'حزمة ${definition.packageId}' : 'Package: ${definition.packageId}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildStatusHeaderBadge(theme, status, isArabic),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (definition.sections.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                isArabic ? 'لا توجد أقسام إعدادات لهذه الحزمة' : 'No setup sections available for this package',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ...definition.sections.map((section) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: SetupSectionCard(
                section: section,
                fieldValues: fieldValues,
                onFieldValueChanged: onFieldValueChanged,
                isArabic: isArabic,
                availableAccounts: availableAccounts,
                accountRoles: accountRoles,
                accountBindingModes: accountBindingModes,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStatusHeaderBadge(ThemeData theme, SetupStatus status, bool isArabic) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case SetupStatus.configured:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        label = isArabic ? 'جاهز للعمل' : 'Configured';
        icon = Icons.check_circle_outline;
        break;
      case SetupStatus.partiallyConfigured:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        label = isArabic ? 'تهيئة جزئية' : 'Partially Configured';
        icon = Icons.warning_amber_rounded;
        break;
      case SetupStatus.invalid:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        label = isArabic ? 'غير صالح' : 'Invalid';
        icon = Icons.error_outline;
        break;
      case SetupStatus.notConfigured:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        label = isArabic ? 'غير مهيأ' : 'Not Configured';
        icon = Icons.info_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }
}
