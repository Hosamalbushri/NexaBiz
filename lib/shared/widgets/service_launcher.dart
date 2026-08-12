import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../core/modules/app_module.dart';
import '../../core/widgets/app_empty_state.dart';
import 'service_grid.dart';

/// Generic service launcher that lists modules without knowing their types.
class ServiceLauncher extends StatelessWidget {
  const ServiceLauncher({
    super.key,
    required this.modules,
    required this.onModuleSelected,
    this.title,
    this.subtitle,
    this.emptyTitle,
    this.emptySubtitle,
  });

  final List<AppModule> modules;
  final ValueChanged<AppModule> onModuleSelected;
  final String? title;
  final String? subtitle;
  final String? emptyTitle;
  final String? emptySubtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.section),
        ],
        if (modules.isEmpty)
          AppEmptyState(
            title: emptyTitle ?? '—',
            subtitle: emptySubtitle ?? '',
            icon: Icons.apps_outage_outlined,
          )
        else
          ServiceGrid(modules: modules, onModuleSelected: onModuleSelected),
      ],
    );
  }
}
