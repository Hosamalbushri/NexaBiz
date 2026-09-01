import 'package:flutter/material.dart';

/// Reusable ERP Module Form Page Scaffold.
///
/// Standardizes app bar, save/submit actions, scrollable body, and loading states
/// across form screens in all business modules.
class ModuleFormScaffold extends StatelessWidget {
  const ModuleFormScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.onSave,
    this.isSaving = false,
    this.saveLabel = 'حفظ',
    this.actions,
  });

  final String title;
  final Widget body;
  final VoidCallback? onSave;
  final bool isSaving;
  final String saveLabel;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (actions != null) ...actions!,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(saveLabel),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: body,
        ),
      ),
    );
  }
}
