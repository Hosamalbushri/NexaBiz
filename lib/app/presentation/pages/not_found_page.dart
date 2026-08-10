import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../localization/app_localizations.dart';
import '../../router/app_routes.dart';
import '../../theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/custom_app_bar.dart';

/// Shown when GoRouter cannot match a location.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(title: l10n.notFoundTitle),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.notFoundTitle,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.notFoundMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l10n.goToDashboard,
                icon: Icons.dashboard_rounded,
                onPressed: () => context.go(AppRoutes.dashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
