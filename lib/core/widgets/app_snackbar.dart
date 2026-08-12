import 'package:flutter/material.dart';

/// Signature for the platform snackbar / toast bridge.
typedef ShowAppSnackBarFn =
    void Function(
      BuildContext context, {
      required String message,
      required bool isSuccess,
      Duration? duration,
      bool persistToHistory,
    });

ShowAppSnackBarFn? _showAppSnackBarImpl;

/// Registers the app-layer notification presenter (called once at startup).
void registerAppSnackBarHandler(ShowAppSnackBarFn handler) {
  _showAppSnackBarImpl = handler;
}

/// Displays a polished top notification that auto-dismisses.
///
/// Prefer [NotificationService] from feature code. This helper keeps existing
/// call sites working via the registered app-layer handler.
void showAppSnackBar(
  BuildContext context, {
  required String message,
  required bool isSuccess,
  Duration? duration,
  bool persistToHistory = false,
}) {
  final impl = _showAppSnackBarImpl;
  if (impl == null) {
    return;
  }
  impl(
    context,
    message: message,
    isSuccess: isSuccess,
    duration: duration,
    persistToHistory: persistToHistory,
  );
}
