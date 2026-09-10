import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Route paths owned by the Purchases module.
class PurchasesRoutes {
  const PurchasesRoutes._();

  static const String root = '/purchases';
  static const String settings = '/purchases/settings';
  static const String suppliers = '/purchases/suppliers';
  static const String invoices = '/purchases/invoices';
  static const String createInvoice = '/purchases/invoices/new';
  static const String receipts = '/purchases/receipts';

  static void goRoot(BuildContext context) => context.go(root);

  static void pushSettings(BuildContext context) => context.push(settings);

  static void pushSuppliers(BuildContext context) => context.push(suppliers);

  static void pushInvoices(BuildContext context) => context.push(invoices);

  static void pushCreateInvoice(BuildContext context) => context.push(createInvoice);

  static void pushReceipts(BuildContext context) => context.push(receipts);

  static void backToHome(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      goRoot(context);
    }
  }
}
