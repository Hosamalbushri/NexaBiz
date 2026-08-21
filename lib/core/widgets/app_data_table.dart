import 'package:flutter/material.dart';
import '../../app/theme/app_breakpoints.dart';
import '../../app/theme/app_spacing.dart';
import 'app_card.dart';
import 'app_empty_state.dart';
import 'app_loading.dart';

/// Standardized responsive table widget with desktop DataTable and mobile card list fallback.
class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.items,
    required this.columns,
    required this.rowBuilder,
    required this.cardBuilder,
    this.isLoading = false,
    this.emptyState,
    this.title,
    this.actions,
  });

  final List<T> items;
  final List<DataColumn> columns;
  final DataRow Function(T item) rowBuilder;
  final Widget Function(BuildContext context, T item) cardBuilder;
  final bool isLoading;
  final Widget? emptyState;
  final String? title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppLoading();
    }

    if (items.isEmpty) {
      return emptyState ?? const AppEmptyState(title: 'No records found');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = AppBreakpoints.isMobile(constraints.maxWidth);

        if (isMobile) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, index) => cardBuilder(context, items[index]),
          );
        }

        return AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null || (actions != null && actions!.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      if (actions != null) ...actions!,
                    ],
                  ),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columns: columns,
                    rows: items.map(rowBuilder).toList(),
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
