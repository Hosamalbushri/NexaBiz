import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../widgets/app_form_actions.dart';
import '../../widgets/app_page_header.dart';
import 'app_page_shell.dart';

/// Canonical Form Page Pattern for NexaBiz ERP screens.
///
/// Standardizes Header + Form Body + Optional Desktop Side Panel (e.g. preview)
/// + Sticky Form Actions bar.
class AppFormPagePattern extends StatelessWidget {
  const AppFormPagePattern({
    super.key,
    required this.title,
    required this.body,
    required this.onSubmit,
    this.subtitle,
    this.breadcrumbs,
    this.formKey,
    this.submitLabel = 'Save',
    this.onCancel,
    this.cancelLabel = 'Cancel',
    this.isLoading = false,
    this.secondaryBody,
    this.headerActions,
  });

  final String title;
  final String? subtitle;
  final List<String>? breadcrumbs;
  final GlobalKey<FormState>? formKey;

  final Widget body;
  final VoidCallback? onSubmit;
  final String submitLabel;
  final VoidCallback? onCancel;
  final String cancelLabel;
  final bool isLoading;

  final Widget? secondaryBody;
  final List<Widget>? headerActions;

  void _handleSubmit() {
    if (isLoading || onSubmit == null) return;
    if (formKey != null && !formKey!.currentState!.validate()) {
      return;
    }
    onSubmit!();
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isDesktop = mediaWidth >= 900;

    final formContent = Form(
      key: formKey,
      child: isDesktop && secondaryBody != null
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: body),
                const SizedBox(width: AppSpacing.lg),
                Expanded(flex: 2, child: secondaryBody!),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                body,
                if (secondaryBody != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  secondaryBody!,
                ],
              ],
            ),
    );

    return AppPageShell(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeader(
            title: title,
            subtitle: subtitle,
            breadcrumbs: breadcrumbs,
            actions: headerActions,
          ),
          formContent,
          const SizedBox(height: AppSpacing.xl),
          AppFormActions(
            onSubmit: _handleSubmit,
            submitLabel: submitLabel,
            onCancel: onCancel,
            cancelLabel: cancelLabel,
            isLoading: isLoading,
            isSticky: false,
          ),
        ],
      ),
    );
  }
}
