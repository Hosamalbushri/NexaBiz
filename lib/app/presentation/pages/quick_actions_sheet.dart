import 'package:flutter/material.dart';

import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/service_add_card.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_spacing.dart';

/// Opens the quick-actions sheet (customizable shortcuts — placeholder for now).
Future<void> showQuickActionsSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);

  return showAppBottomSheet<void>(
    context: context,
    title: l10n.quickActionsTitle,
    child: const QuickActionsSheetBody(),
  );
}

/// Body for the quick-actions bottom sheet.
class QuickActionsSheetBody extends StatelessWidget {
  const QuickActionsSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.quickActionsEmptyMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 112,
          child: ServiceAddCard(
            label: l10n.quickActionsAddLabel,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.quickActionsComingSoon)),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
