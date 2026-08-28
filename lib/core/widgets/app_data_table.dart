import 'package:flutter/material.dart';
import '../../app/theme/app_breakpoints.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import 'app_card.dart';
import 'app_empty_state.dart';
import 'app_loading.dart';

/// Standardized responsive table widget supporting desktop DataTable with sticky headers
/// and mobile card list fallback with optional expandable row details.
class AppDataTable<T> extends StatefulWidget {
  const AppDataTable({
    super.key,
    required this.items,
    required this.columns,
    required this.rowBuilder,
    required this.cardBuilder,
    this.expandableCardBuilder,
    this.isLoading = false,
    this.emptyState,
    this.title,
    this.actions,
    this.onRowTap,
    this.minWidth = 700.0,
  });

  final List<T> items;
  final List<DataColumn> columns;
  final DataRow Function(T item) rowBuilder;
  final Widget Function(BuildContext context, T item) cardBuilder;
  final Widget Function(BuildContext context, T item)? expandableCardBuilder;
  final bool isLoading;
  final Widget? emptyState;
  final String? title;
  final List<Widget>? actions;
  final ValueChanged<T>? onRowTap;
  final double minWidth;

  @override
  State<AppDataTable<T>> createState() => _AppDataTableState<T>();
}

class _AppDataTableState<T> extends State<AppDataTable<T>> {
  final Set<int> _expandedIndices = {};

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const AppLoading();
    }

    if (widget.items.isEmpty) {
      return widget.emptyState ?? const AppEmptyState(title: 'No records found');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = AppBreakpoints.isMobile(constraints.maxWidth);

        if (isMobile) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final isExpanded = _expandedIndices.contains(index);

              if (widget.expandableCardBuilder == null) {
                return InkWell(
                  onTap: widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: widget.cardBuilder(context, item),
                );
              }

              return AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedIndices.remove(index);
                          } else {
                            _expandedIndices.add(index);
                          }
                        });
                        if (widget.onRowTap != null) {
                          widget.onRowTap!(item);
                        }
                      },
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(child: widget.cardBuilder(context, item)),
                            const SizedBox(width: AppSpacing.xs),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.sm,
                          0,
                          AppSpacing.sm,
                          AppSpacing.sm,
                        ),
                        child: Column(
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: AppSpacing.xs),
                            widget.expandableCardBuilder!(context, item),
                          ],
                        ),
                      ),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                  ],
                ),
              );
            },
          );
        }

        return AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.title != null || (widget.actions != null && widget.actions!.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      if (widget.title != null)
                        Expanded(
                          child: Text(
                            widget.title!,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      if (widget.actions != null) ...widget.actions!,
                    ],
                  ),
                ),
              Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth > widget.minWidth
                          ? constraints.maxWidth
                          : widget.minWidth,
                    ),
                    child: DataTable(
                      columns: widget.columns,
                      rows: widget.items.map((item) {
                        final row = widget.rowBuilder(item);
                        if (widget.onRowTap == null) return row;
                        return DataRow(
                          key: row.key,
                          selected: row.selected,
                          onSelectChanged: (_) => widget.onRowTap!(item),
                          color: row.color,
                          cells: row.cells,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

