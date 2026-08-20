import 'package:flutter/material.dart';

import '../../app/theme/app_breakpoints.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/modules/app_module.dart';
import 'service_add_card.dart';
import 'service_card.dart';

/// Responsive grid of [ServiceCard] widgets with an optional trailing add tile.
class ServiceGrid extends StatelessWidget {
  const ServiceGrid({
    super.key,
    required this.modules,
    required this.onModuleSelected,
    this.onAddPressed,
    this.addLabel,
    this.showSubtitle = true,
    this.fillWidth = false,
    this.walletStyle = false,
    this.maxSlots,
  });

  final List<AppModule> modules;
  final ValueChanged<AppModule> onModuleSelected;
  final VoidCallback? onAddPressed;
  final String? addLabel;

  /// When false, module cards use the professional dashboard tile (no subtitle).
  final bool showSubtitle;

  /// Tighter gaps so tiles use more of the available width (dashboard panel).
  final bool fillWidth;

  /// Wallet-home tiles: flatter dark squares filling the row width.
  final bool walletStyle;

  /// Cap visible modules; show the add tile only while under this count.
  final int? maxSlots;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final dashboard = !showSubtitle;

        // Wallet / dashboard max-slot grid: 3 columns that always span full width.
        if (walletStyle || (dashboard && maxSlots != null)) {
          return _FillWidthServiceGrid(
            modules: modules,
            onModuleSelected: onModuleSelected,
            onAddPressed: onAddPressed,
            addLabel: addLabel,
            showSubtitle: showSubtitle,
            walletStyle: walletStyle,
            maxSlots: maxSlots,
            crossAxisCount: 3,
            gap: fillWidth || walletStyle ? AppSpacing.xs : AppSpacing.sm,
          );
        }

        final crossAxisCount = AppBreakpoints.isDesktop(width)
            ? 4
            : AppBreakpoints.isTablet(width)
            ? 3
            : 2;

        final childAspectRatio = AppBreakpoints.isMobile(width) ? 0.82 : 0.95;
        final gap = AppSpacing.md;
        final showAdd = onAddPressed != null;
        final itemCount = modules.length + (showAdd ? 1 : 0);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            if (showAdd && index == modules.length) {
              return ServiceAddCard(
                onTap: onAddPressed!,
                label: addLabel,
                compact: false,
                dashboardStyle: dashboard,
              );
            }
            final module = modules[index];
            return ServiceCard(
              module: module,
              showSubtitle: showSubtitle,
              onTap: () => onModuleSelected(module),
            );
          },
        );
      },
    );
  }
}

/// Equal-width rows so tiles always span the full container width.
class _FillWidthServiceGrid extends StatelessWidget {
  const _FillWidthServiceGrid({
    required this.modules,
    required this.onModuleSelected,
    required this.onAddPressed,
    required this.addLabel,
    required this.showSubtitle,
    required this.walletStyle,
    required this.maxSlots,
    required this.crossAxisCount,
    required this.gap,
  });

  final List<AppModule> modules;
  final ValueChanged<AppModule> onModuleSelected;
  final VoidCallback? onAddPressed;
  final String? addLabel;
  final bool showSubtitle;
  final bool walletStyle;
  final int? maxSlots;
  final int crossAxisCount;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final visibleModules = maxSlots == null
        ? modules
        : modules.take(maxSlots!).toList(growable: false);
    final showAdd =
        onAddPressed != null &&
        (maxSlots == null || visibleModules.length < maxSlots!);

    // Dashboard tiles are taller than wide so service names fit.
    final dashboard = !showSubtitle && maxSlots != null;
    final tileAspectRatio = dashboard ? 0.95 : 1.0;

    final tiles = <Widget>[
      for (final module in visibleModules)
        ServiceCard(
          module: module,
          showSubtitle: showSubtitle,
          walletStyle: walletStyle,
          onTap: () => onModuleSelected(module),
        ),
      if (showAdd)
        ServiceAddCard(
          onTap: onAddPressed!,
          label: addLabel,
          compact: false,
          dashboardStyle: !showSubtitle,
          walletStyle: walletStyle,
        ),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += crossAxisCount) {
      final rowTiles = tiles.skip(i).take(crossAxisCount).toList();
      rows.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: i + crossAxisCount < tiles.length ? gap : 0,
          ),
          child: Row(
            children: [
              for (var j = 0; j < crossAxisCount; j++) ...[
                if (j > 0) SizedBox(width: gap),
                Expanded(
                  child: j < rowTiles.length
                      ? AspectRatio(
                          aspectRatio: tileAspectRatio,
                          child: rowTiles[j],
                        )
                      : AspectRatio(
                          aspectRatio: tileAspectRatio,
                          child: const SizedBox.shrink(),
                        ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
