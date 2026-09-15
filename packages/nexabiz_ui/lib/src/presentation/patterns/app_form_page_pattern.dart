import 'package:flutter/material.dart';

import '../../layout/app_form_page.dart';

/// Legacy compatible Form Page pattern delegating to canonical [AppFormPage].
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

  @override
  Widget build(BuildContext context) {
    return AppFormPage(
      title: title,
      subtitle: subtitle,
      breadcrumbs: breadcrumbs,
      formKey: formKey,
      body: body,
      onSubmit: onSubmit,
      submitLabel: submitLabel,
      onCancel: onCancel,
      cancelLabel: cancelLabel,
      isLoading: isLoading,
      secondaryBody: secondaryBody,
      headerActions: headerActions,
    );
  }
}
