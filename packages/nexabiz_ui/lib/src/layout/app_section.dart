import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../theme/tokens/tokens.dart';
import 'app_layout_tokens.dart';

/// Canonical NexaBiz Layout Section component.
///
/// Groups related widgets with standard section title, description, icon header,
/// and consistent spacing tokens. Built on top of `shadcn_flutter` design tokens.
class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    this.title,
    this.description,
    String? subtitle,
    this.icon,
    this.children = const [],
    this.child,
    this.padding = AppLayoutTokens.sectionPaddingDirectional,
    this.spacing = AppLayoutTokens.sectionInnerGap,
    this.actions,
    this.showBorder = true,
  }) : subtitle = subtitle ?? description;

  final String? title;
  final String? description;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final List<Widget>? actions;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasHeader = title != null || description != null || icon != null || actions != null;
    final contentList = child != null ? [child!] : children;

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasHeader) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(theme.radiusSm),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ] else if (title != null) ...[
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(theme.radiusSm),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: theme.typography.p.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.foreground,
                        ),
                      ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        style: theme.typography.small.copyWith(
                          color: colorScheme.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppLayoutTokens.sectionTitleGap),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.border.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppLayoutTokens.sectionTitleGap),
        ],
        for (int i = 0; i < contentList.length; i++) ...[
          contentList[i],
          if (i < contentList.length - 1) SizedBox(height: spacing),
        ],
      ],
    );

    if (showBorder) {
      return shadcn.Card(
        padding: padding,
        child: column,
      );
    }

    return Padding(
      padding: padding,
      child: column,
    );
  }
}

