import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Canonical ERP modal form-in-sheet container built on `shadcn_flutter`.
///
/// Features a standardized header, scrollable `Form` body, validation feedback,
/// async submission handling, and automatic dismissal on success.
class AppFormSheet extends StatefulWidget {
  const AppFormSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.onSubmit,
    this.controller,
    this.submitLabel = 'حفظ',
    this.cancelLabel = 'إلغاء',
    this.onClose,
  });

  /// The form fields child widget tree.
  final Widget child;

  /// Optional header title.
  final String? title;

  /// Optional header subtitle.
  final String? subtitle;

  /// Optional header leading icon.
  final IconData? icon;

  /// Async form submission callback receiving form values.
  final FutureOr<void> Function(BuildContext context, shadcn.FormMapValues values)? onSubmit;

  /// Optional external form controller.
  final shadcn.FormController? controller;

  /// Submit button label text.
  final String submitLabel;

  /// Cancel button label text.
  final String cancelLabel;

  /// Optional callback invoked when close / cancel button is pressed.
  final VoidCallback? onClose;

  /// Opens an [AppFormSheet] as an overlay sheet via [shadcn.openSheetOverlay].
  static shadcn.DrawerOverlayCompleter<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    IconData? icon,
    FutureOr<void> Function(BuildContext context, shadcn.FormMapValues values)? onSubmit,
    shadcn.FormController? controller,
    String submitLabel = 'حفظ',
    String cancelLabel = 'إلغاء',
    bool barrierDismissible = true,
    shadcn.OverlayPosition position = shadcn.OverlayPosition.bottom,
  }) {
    return shadcn.openSheetOverlay<T>(
      context: context,
      position: position,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        return AppFormSheet(
          title: title,
          subtitle: subtitle,
          icon: icon,
          onSubmit: onSubmit,
          controller: controller,
          submitLabel: submitLabel,
          cancelLabel: cancelLabel,
          child: child,
        );
      },
    );
  }

  @override
  State<AppFormSheet> createState() => _AppFormSheetState();
}

class _AppFormSheetState extends State<AppFormSheet> {
  late shadcn.FormController _controller;
  bool _isInternalController = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = shadcn.FormController();
      _isInternalController = true;
    }
  }

  @override
  void didUpdateWidget(covariant AppFormSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller && widget.controller != null) {
      if (_isInternalController) {
        _controller.dispose();
        _isInternalController = false;
      }
      _controller = widget.controller!;
    }
  }

  @override
  void dispose() {
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit(BuildContext context) async {
    if (_isSubmitting) return;

    setState(() {
      _errorMessage = null;
    });

    final result = await context.submitForm();
    if (result.errors.isNotEmpty || !context.mounted) {
      return;
    }

    if (widget.onSubmit != null) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await widget.onSubmit!(context, result.values);
        if (context.mounted) {
          shadcn.closeSheet(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
            _isSubmitting = false;
          });
        }
      }
    } else {
      if (context.mounted) {
        shadcn.closeSheet(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return shadcn.Form(
      controller: _controller,
      child: Builder(
        builder: (formContext) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              if (widget.title != null || widget.icon != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: theme.colorScheme.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.title != null)
                              Text(
                                widget.title!,
                                style: theme.typography.semiBold.copyWith(
                                  fontSize: 16,
                                  color: theme.colorScheme.foreground,
                                ),
                              ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle!,
                                style: theme.typography.small.copyWith(
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      shadcn.IconButton.ghost(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          if (widget.onClose != null) {
                            widget.onClose!();
                          } else {
                            shadcn.closeSheet(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              // Error banner if any
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: theme.colorScheme.destructive.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 16, color: theme.colorScheme.destructive),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.typography.small.copyWith(
                            color: theme.colorScheme.destructive,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Scrollable Form Body with Keyboard Padding
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
                  child: widget.child,
                ),
              ),
              // Footer Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.border),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    shadcn.Button.outline(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              if (widget.onClose != null) {
                                widget.onClose!();
                              } else {
                                shadcn.closeSheet(context);
                              }
                            },
                      child: Text(widget.cancelLabel),
                    ),
                    const SizedBox(width: 8),
                    shadcn.Button.primary(
                      onPressed: _isSubmitting ? null : () => _handleSubmit(formContext),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.submitLabel),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
