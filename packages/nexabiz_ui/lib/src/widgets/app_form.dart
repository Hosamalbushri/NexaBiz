import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../theme/tokens/tokens.dart';
import 'app_form_actions.dart';

/// Canonical NexaBiz Form Section Container.
///
/// Groups related form fields with a clear visual section header, description,
/// and rounded border container consistent with shadcn_flutter theme tokens.
class AppFormSection extends StatelessWidget {
  const AppFormSection({
    super.key,
    this.title,
    this.description,
    String? subtitle,
    this.icon,
    this.children = const [],
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.spacing = AppSpacing.md,
    this.topSpacing,
    this.bottomSpacing,
  }) : subtitle = subtitle ?? description;

  final String? title;
  final String? description;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final double? topSpacing;
  final double? bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final hasShadcnTheme =
        context.dependOnInheritedWidgetOfExactType<shadcn.Theme>() != null;
    if (!hasShadcnTheme) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return shadcn.Theme(
        data: isDark
            ? const shadcn.ThemeData.dark()
            : const shadcn.ThemeData(),
        child: Builder(
          builder: (context) => _buildSection(context),
        ),
      );
    }
    return _buildSection(context);
  }

  Widget _buildSection(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasHeader = title != null || description != null || icon != null;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.border.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: colorScheme.foreground,
                          ),
                        ),
                      if (description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.border.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: spacing),
          ],
        ],
      ),
    );
  }
}

/// Immutable configuration data passed down the widget tree via [shadcn.Data.inherit].
class AppFormConfiguration {
  const AppFormConfiguration({
    this.isSubmitting = false,
    this.enabled = true,
    this.readOnly = false,
    this.spacing = AppSpacing.lg,
  });

  final bool isSubmitting;
  final bool enabled;
  final bool readOnly;
  final double spacing;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppFormConfiguration &&
          runtimeType == other.runtimeType &&
          isSubmitting == other.isSubmitting &&
          enabled == other.enabled &&
          readOnly == other.readOnly &&
          spacing == other.spacing;

  @override
  int get hashCode => Object.hash(isSubmitting, enabled, readOnly, spacing);
}

/// Canonical Form Container for NexaBiz ERP.
///
/// Centralizes layout, form key binding, section spacing, submit/cancel action bar,
/// error banner presentation, and submitting state.
class AppForm extends StatelessWidget {
  const AppForm({
    super.key,
    this.formKey,
    this.title,
    this.subtitle,
    this.icon,
    this.errorMessage,
    required this.children,
    this.onSubmit,
    this.submitLabel = 'Save',
    this.onCancel,
    this.cancelLabel = 'Cancel',
    this.isSubmitting = false,
    this.maxWidth = 640,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.spacing = AppSpacing.lg,
    this.stickyActions = true,
    this.extraActions,
  });

  final GlobalKey<FormState>? formKey;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final String? errorMessage;
  final List<Widget> children;
  final VoidCallback? onSubmit;
  final String submitLabel;
  final VoidCallback? onCancel;
  final String cancelLabel;
  final bool isSubmitting;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final bool stickyActions;
  final List<Widget>? extraActions;

  @override
  Widget build(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasHeader = title != null || subtitle != null || icon != null;

    final formBody = shadcn.Data<AppFormConfiguration>.inherit(
      data: AppFormConfiguration(
        isSubmitting: isSubmitting,
        enabled: !isSubmitting,
        spacing: spacing,
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: padding,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                // Header Bar
                if (hasHeader) ...[
                  Row(
                    children: [
                      if (icon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(theme.radiusSm),
                          ),
                          child: Icon(
                            icon,
                            color: colorScheme.primary,
                            size: 24,
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
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.foreground,
                                ),
                              ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.mutedForeground,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Global Error Banner
                if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.destructive.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(theme.radiusMd),
                      border: Border.all(
                        color: colorScheme.destructive.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: colorScheme.destructive,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.destructive,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Form Children / Sections
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1) SizedBox(height: spacing),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

    final actionsWidget = AppFormActions(
      onSubmit: onSubmit,
      submitLabel: submitLabel,
      onCancel: onCancel,
      cancelLabel: cancelLabel,
      isLoading: isSubmitting,
      isSticky: stickyActions,
      extraActions: extraActions,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: formBody),
        actionsWidget,
      ],
    );
  }
}
