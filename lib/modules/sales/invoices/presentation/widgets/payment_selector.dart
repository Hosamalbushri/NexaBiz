import 'package:flutter/material.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import '../../domain/entities/payment_method.dart';

Future<PaymentMethod?> showSalePaymentSelector(
  BuildContext context, {
  PaymentMethod? current,
}) {
  return showModalBottomSheet<PaymentMethod>(
    context: context,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      String label(PaymentMethod method) {
        return switch (method) {
          PaymentMethod.cash => l10n.salesPaymentCash,
          PaymentMethod.card => l10n.salesPaymentCard,
          PaymentMethod.bankTransfer => l10n.salesPaymentBankTransfer,
          PaymentMethod.credit => l10n.salesPaymentCredit,
          PaymentMethod.other => l10n.salesPaymentOther,
        };
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(l10n.salesPaymentMethod)),
            for (final method in PaymentMethod.values)
              ListTile(
                title: Text(label(method)),
                trailing: current == method ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(ctx).pop(method),
              ),
          ],
        ),
      );
    },
  );
}
