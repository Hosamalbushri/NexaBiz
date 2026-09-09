import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/app_spacing.dart';

enum AppLoadingStyle { circular, linear, skeletonList }

/// Loading indicator with optional skeleton placeholders backed by shadcn_flutter.
class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.style = AppLoadingStyle.circular,
    this.message,
    this.progress,
    this.skeletonItemCount = 6,
  });

  final AppLoadingStyle style;
  final String? message;
  final double? progress;
  final int skeletonItemCount;

  @override
  Widget build(BuildContext context) {
    final label = message ?? 'Loading...';

    switch (style) {
      case AppLoadingStyle.circular:
        final hasShadcnTheme =
            context.findAncestorWidgetOfExactType<shadcn.ComponentTheme>() != null ||
                context.findAncestorWidgetOfExactType<shadcn.Theme>() != null;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              hasShadcnTheme
                  ? const shadcn.CircularProgressIndicator()
                  : const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(label),
            ],
          ),
        );
      case AppLoadingStyle.linear:
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(value: progress),
            ],
          ),
        );
      case AppLoadingStyle.skeletonList:
        return Skeletonizer(
          enabled: true,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: skeletonItemCount,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              return const Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('A')),
                  title: Text('Loading item title placeholder'),
                  subtitle: Text('Secondary loading line placeholder'),
                ),
              );
            },
          ),
        );
    }
  }
}
