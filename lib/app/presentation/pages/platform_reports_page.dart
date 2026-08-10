import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../modules/inventory/presentation/pages/inventory_routes.dart';

/// Platform reports hub — links into module reports without owning their UI.
class PlatformReportsPage extends StatelessWidget {
  const PlatformReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(title: l10n.platformReportsTitle),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        children: [
          Text(
            l10n.platformReportsSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            onTap: () => context.push(InventoryRoutes.reports),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.inventory_2_outlined,
                color: colorScheme.primary,
              ),
              title: Text(
                l10n.platformReportsInventory,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.insights_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
              title: Text(
                l10n.moduleComingSoon,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(l10n.platformReportsComingSoon),
            ),
          ),
        ],
      ),
    );
  }
}
