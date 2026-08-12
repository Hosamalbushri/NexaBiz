import 'package:flutter/material.dart';

import 'app_dialog.dart';

/// Legacy wrapper — prefer [showAppDialog].
Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
}) {
  return showAppDialog(context: context, title: title, message: message);
}
