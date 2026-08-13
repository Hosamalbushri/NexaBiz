import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';

/// Captures a barcode / QR string for sale line entry.
///
/// Default: manual entry dialog. App overrides with Inventory camera scanner.
typedef SaleBarcodeCapture = Future<String?> Function(BuildContext context);

Future<String?> defaultSaleBarcodeCapture(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n.salesScanProduct),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.salesScanHint),
          onSubmitted: (value) => Navigator.of(ctx).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.confirm),
          ),
        ],
      );
    },
  );
  controller.dispose();
  if (result == null || result.isEmpty) {
    return null;
  }
  return result;
}

final saleBarcodeCaptureProvider = Provider<SaleBarcodeCapture>((ref) {
  return defaultSaleBarcodeCapture;
});
