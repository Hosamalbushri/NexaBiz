import 'package:flutter/material.dart';

import '../patterns/app_form_page_pattern.dart';

/// Reusable ERP Module Form Page Scaffold.
///
/// Delegates to canonical [AppFormPagePattern] while maintaining backwards compatibility.
class ModuleFormScaffold extends StatelessWidget {
  const ModuleFormScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.onSave,
    this.formKey,
    this.isSaving = false,
    this.saveLabel = 'حفظ',
    this.cancelLabel = 'إلغاء',
    this.onCancel,
    this.actions,
    this.secondaryBody,
  });

  final String title;
  final Widget body;
  final GlobalKey<FormState>? formKey;
  final Future<void> Function()? onSave;
  final bool isSaving;
  final String saveLabel;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final List<Widget>? actions;
  final Widget? secondaryBody;

  @override
  Widget build(BuildContext context) {
    return AppFormPagePattern(
      title: title,
      headerActions: actions,
      formKey: formKey,
      body: body,
      secondaryBody: secondaryBody,
      onSubmit: onSave != null ? () => onSave!() : null,
      submitLabel: saveLabel,
      onCancel: onCancel,
      cancelLabel: cancelLabel,
      isLoading: isSaving,
    );
  }
}
