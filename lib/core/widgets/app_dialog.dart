export 'package:nexabiz_ui/nexabiz_ui.dart';

import 'package:flutter/material.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

Future<bool> showAppDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
  VoidCallback? onConfirm,
}) async {
  final res = await AppConfirmationDialog.show(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel ?? 'تأكيد',
    cancelLabel: cancelLabel ?? 'إلغاء',
    tone: isDestructive ? AppDialogTone.danger : AppDialogTone.warning,
    onConfirm: () => onConfirm?.call(),
  );
  return res ?? false;
}
