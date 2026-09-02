import 'package:flutter/material.dart';
import '../../app/constants/app_constants.dart';
import '../../app/theme/app_breakpoints.dart';
import '../../app/theme/app_spacing.dart';

enum AppCollectionViewMode { list, grid }

/// Canonical responsive collection view supporting List and Grid layouts.
///
/// Owns list/grid view switching, responsive grid calculation, scroll physics,
/// and padding consistency. Does not manage network loading or empty states.
class AppCollectionView<T> extends StatelessWidget {
  const AppCollectionView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.viewMode = AppCollectionViewMode.list,
    this.scrollController,
    this.padding,
    this.gridMobileColumns = 2,
    this.gridTabletColumns = 3,
    this.gridDesktopColumns = 4,
    this.gridCrossAxisSpacing = AppSpacing.sm,
    this.gridMainAxisSpacing = AppSpacing.sm,
    this.childAspectRatio = 0.78,
    this.separatorBuilder,
    this.footerItemCount = 0,
    this.footerBuilder,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final AppCollectionViewMode viewMode;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  final int gridMobileColumns;
  final int gridTabletColumns;
  final int gridDesktopColumns;
  final double gridCrossAxisSpacing;
  final double gridMainAxisSpacing;
  final double childAspectRatio;
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Optional footer count (e.g. 1 when loading more).
  final int footerItemCount;

  /// Optional footer widget builder.
  final Widget Function(BuildContext context)? footerBuilder;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? AppConstants.pageInsets(context);
    final totalCount = items.length + footerItemCount;

    if (viewMode == AppCollectionViewMode.grid) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = _calculateCrossAxisCount(width);

          return GridView.builder(
            controller: scrollController,
            padding: effectivePadding,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: gridCrossAxisSpacing,
              mainAxisSpacing: gridMainAxisSpacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: totalCount,
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return footerBuilder!(context);
              }
              return itemBuilder(context, items[index], index);
            },
          );
        },
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: effectivePadding,
      itemCount: totalCount,
      separatorBuilder: separatorBuilder ??
          (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return footerBuilder?.call(context) ?? const SizedBox.shrink();
        }
        return itemBuilder(context, items[index], index);
      },
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width >= AppBreakpoints.desktop) {
      return gridDesktopColumns;
    }
    if (width >= AppBreakpoints.mobile) {
      return gridTabletColumns;
    }
    return gridMobileColumns;
  }
}
