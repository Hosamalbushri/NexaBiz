import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_breakpoints.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_shadows.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/inventory/permissions/inventory_permission_package.dart';
import 'package:stock_count/modules/inventory/shared/presentation/pages/inventory_routes.dart';

/// Stock-count service home — grid of count / import / reports (no tabs).
class StockCountHomePage extends ConsumerWidget {
  const StockCountHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = ref.watch(authStateProvider);

    final features = <_StockCountFeature>[
      if (auth.hasAnyPermission(InventoryPermissions.stockAdjust))
        _StockCountFeature(
          icon: Icons.fact_check_outlined,
          title: l10n.inventoryCountTitle,
          subtitle: l10n.inventoryCountSubtitle,
          path: InventoryRoutes.count,
        ),
      if (auth.hasAnyPermission(InventoryPermissions.stockImport))
        _StockCountFeature(
          icon: Icons.upload_file_outlined,
          title: l10n.importPageTitle,
          subtitle: l10n.selectExcelFile,
          path: InventoryRoutes.import,
        ),
      if (auth.hasAnyPermission(InventoryPermissions.stockExport))
        _StockCountFeature(
          icon: Icons.assessment_outlined,
          title: l10n.reportsTitle,
          subtitle: l10n.exportReport,
          path: InventoryRoutes.reports,
        ),
    ];

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.inventoryStockCountService,
        showBackButton: true,
      ),
      body: ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            Text(
              l10n.inventoryStockCountServiceDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = AppBreakpoints.isDesktop(width)
                    ? 4
                    : AppBreakpoints.isTablet(width)
                    ? 3
                    : 2;
                final childAspectRatio = AppBreakpoints.isMobile(width)
                    ? 0.82
                    : 0.95;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: features.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final feature = features[index];
                    return _StockCountFeatureCard(
                      icon: feature.icon,
                      title: feature.title,
                      subtitle: feature.subtitle,
                      onTap: () => context.push(feature.path),
                    );
                  },
                );
              },
            ),
          ],
        ),
    );
  }
}

class _StockCountFeature {
  const _StockCountFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.path,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String path;
}

class _StockCountFeatureCard extends StatelessWidget {
  const _StockCountFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
              boxShadow: AppShadows.card(brightness),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.16),
                          colorScheme.secondary.withValues(alpha: 0.10),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Icon(icon, color: colorScheme.primary, size: 32),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
