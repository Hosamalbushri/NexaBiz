import 'package:flutter/material.dart';

/// Reusable ERP Module Form Page Scaffold.
///
/// Standardizes app bar, form validation key binding, submit actions, loading indicators,
/// and responsive layout adaptation across all form screens.
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

  /// Optional secondary body slot for desktop dual-column layouts (e.g. preview, summary panel).
  final Widget? secondaryBody;

  void _handleSave(BuildContext context) {
    if (isSaving || onSave == null) return;
    if (formKey != null && !formKey!.currentState!.validate()) {
      return;
    }
    onSave!();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 900;

    final primarySaveButton = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48, minWidth: 100),
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : () => _handleSave(context),
        icon: isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_rounded, size: 20),
        label: Text(saveLabel),
      ),
    );

    final formContent = Form(
      key: formKey,
      child: isDesktop && secondaryBody != null
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: body,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: secondaryBody!,
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  body,
                  if (secondaryBody != null) ...[
                    const SizedBox(height: 16),
                    secondaryBody!,
                  ],
                ],
              ),
            ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...?actions,
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: primarySaveButton,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: formContent),
            if (!isDesktop)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (onCancel != null) ...[
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: isSaving ? null : onCancel,
                            child: Text(cancelLabel),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: primarySaveButton,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
