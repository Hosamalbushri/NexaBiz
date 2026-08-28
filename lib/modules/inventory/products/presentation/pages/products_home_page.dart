import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_breakpoints.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_shadows.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_responsive.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/inventory/permissions/inventory_permission_package.dart';
import 'package:stock_count/modules/inventory/shared/presentation/pages/inventory_routes.dart';

/// Products service home — grid of list / import.
class ProductsHomePage extends ConsumerWidget {
  const ProductsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = ref.watch(authStateProvider);

    final features = <_ProductsFeature>[
      if (auth.hasAnyPermission(InventoryPermissions.productsView))
        _ProductsFeature(
          icon: Icons.list_alt_outlined,
          title: l10n.productsListTitle,
          subtitle: l10n.productsListSubtitle,
          path: InventoryRoutes.productsList,
        ),
      if (auth.hasAnyPermission(InventoryPermissions.productsView))
        _ProductsFeature(
          icon: Icons.account_tree_outlined,
          title: l10n.localeName == 'ar' ? 'تصنيفات المنتجات' : 'Product Categories',
          subtitle: l10n.localeName == 'ar' ? 'شجرة التصنيفات المرتبطة بالمستودعات وطرق التكلفة' : 'Warehouse-rooted categories & valuation methods',
          path: InventoryRoutes.categoriesSettings,
        ),
      if (auth.hasAnyPermission(InventoryPermissions.productsBarcode))
        _ProductsFeature(
          icon: Icons.qr_code_2_outlined,
          title: l10n.productsBarcodeTitle,
          subtitle: l10n.productsBarcodeSubtitle,
          path: InventoryRoutes.productsBarcode,
        ),
      if (auth.hasAnyPermission(InventoryPermissions.productsImport))
        _ProductsFeature(
          icon: Icons.upload_file_outlined,
          title: l10n.productsImportTitle,
          subtitle: l10n.productsImportSubtitle,
          path: InventoryRoutes.productsImport,
        ),
    ];

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.productsHubTitle,
        showBackButton: true,
      ),
      body: AppContentConstraint(
        child: ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            Text(
              l10n.productsHubDescription,
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
                    return _ProductsFeatureCard(
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
      ),
    );
  }
}

class _ProductsFeature {
  const _ProductsFeature({
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

class _ProductsFeatureCard extends StatelessWidget {
  const _ProductsFeatureCard({
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxHeight < 130;
                  final circleSize = isCompact ? 44.0 : 56.0;
                  final iconSize = isCompact ? 22.0 : 28.0;
                  final spacing = isCompact ? AppSpacing.xs : AppSpacing.sm;

                  return Column(
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
                          width: circleSize,
                          height: circleSize,
                          child: Icon(icon, color: colorScheme.primary, size: iconSize),
                        ),
                      ),
                      SizedBox(height: spacing),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: (isCompact
                                ? theme.textTheme.titleSmall
                                : theme.textTheme.titleMedium)
                            ?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          subtitle,
                          maxLines: isCompact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.2,
                            fontSize: isCompact ? 11 : null,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
