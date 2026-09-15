import 'package:flutter/material.dart';

import '../widgets/app_error_state.dart';
import '../widgets/app_form_actions.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_page_header.dart';
import 'app_layout_tokens.dart';
import 'app_page.dart';

/// Canonical Form Page layout component for NexaBiz screens.
///
/// Standardizes Header + Main Form Body + Optional Desktop Side Panel + Form Actions Bar.
class AppFormPage extends StatelessWidget {
  const AppFormPage({
    super.key,
    required this.title,
    required this.body,
    this.onSubmit,
    this.subtitle,
    this.breadcrumbs,
    this.formKey,
    this.submitLabel = 'Save',
    this.onCancel,
    this.cancelLabel = 'Cancel',
    this.isLoading = false,
    this.isPageLoading = false,
    this.errorText,
    this.onRetry,
    this.retryLabel,
    this.secondaryBody,
    this.actions,
    this.headerActions,
    this.showBackButton,
    this.onBack,
    this.showFormActions = true,
    this.scrollable,
    this.maxWidth = AppLayoutTokens.maxFormWidth,
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

  // Page initialization feedback states
  final bool isPageLoading;
  final String? errorText;
  final VoidCallback? onRetry;
  final String? retryLabel;

  final Widget? secondaryBody;
  final List<Widget>? actions;
  final List<Widget>? headerActions;
  final bool? showBackButton;
  final VoidCallback? onBack;
  final bool showFormActions;
  final bool? scrollable;
  final double maxWidth;

  void _handleSubmit() {
    if (isLoading || onSubmit == null) return;
    if (formKey != null && !formKey!.currentState!.validate()) {
      return;
    }
    onSubmit!();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveActions = actions ?? headerActions;
    final isBodyScrollView = body is ScrollView;
    final effectiveScrollable = (scrollable ?? true) && !isBodyScrollView;

    if (isPageLoading) {
      return AppPage(
        maxWidth: secondaryBody != null ? AppLayoutTokens.maxWideFormWidth : maxWidth,
        scrollable: effectiveScrollable,
        header: AppPageHeader(
          title: title,
          subtitle: subtitle,
          breadcrumbs: breadcrumbs,
          actions: effectiveActions,
          showBackButton: showBackButton,
          onBack: onBack,
        ),
        child: const AppLoading(),
      );
    }

    if (errorText != null) {
      return AppPage(
        maxWidth: secondaryBody != null ? AppLayoutTokens.maxWideFormWidth : maxWidth,
        scrollable: effectiveScrollable,
        header: AppPageHeader(
          title: title,
          subtitle: subtitle,
          breadcrumbs: breadcrumbs,
          actions: effectiveActions,
          showBackButton: showBackButton,
          onBack: onBack,
        ),
        child: AppErrorState(
          message: errorText,
          onRetry: onRetry,
          retryLabel: retryLabel,
        ),
      );
    }

    final mediaWidth = MediaQuery.of(context).size.width;
    final isDesktop = mediaWidth >= AppLayoutTokens.maxFormWidth;

    final formContent = Form(
      key: formKey,
      child: isDesktop && secondaryBody != null
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: body),
                const SizedBox(width: AppLayoutTokens.formGroupGap),
                Expanded(flex: 2, child: secondaryBody!),
              ],
            )
          : (isBodyScrollView
              ? body
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    body,
                    if (secondaryBody != null) ...[
                      const SizedBox(height: AppLayoutTokens.formGroupGap),
                      secondaryBody!,
                    ],
                  ],
                )),
    );

    final formChildren = [
      if (isBodyScrollView) Expanded(child: formContent) else formContent,
      if (showFormActions && (onSubmit != null || onCancel != null)) ...[
        const SizedBox(height: AppLayoutTokens.formGroupGap),
        AppFormActions(
          onSubmit: _handleSubmit,
          submitLabel: submitLabel,
          onCancel: onCancel,
          cancelLabel: cancelLabel,
          isLoading: isLoading,
          isSticky: false,
        ),
      ],
    ];

    return AppPage(
      maxWidth: secondaryBody != null ? AppLayoutTokens.maxWideFormWidth : maxWidth,
      scrollable: effectiveScrollable,
      header: AppPageHeader(
        title: title,
        subtitle: subtitle,
        breadcrumbs: breadcrumbs,
        actions: effectiveActions,
        showBackButton: showBackButton,
        onBack: onBack,
      ),
      child: isBodyScrollView
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: formChildren,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: formChildren,
            ),
    );
  }
}
