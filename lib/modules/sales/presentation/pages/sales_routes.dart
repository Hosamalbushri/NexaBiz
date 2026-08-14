import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Route paths owned by the Sales module.
class SalesRoutes {
  const SalesRoutes._();

  static const String root = '/sales';
  static const String list = '/sales/list';
  static const String create = '/sales/create';
  static const String invoicePreview = '/sales/invoice-preview';

  static String details(int id) => '/sales/$id';

  static String edit(int id) => '/sales/$id/edit';

  static void goRoot(BuildContext context) => context.go(root);

  static void goList(BuildContext context) => context.go(list);

  static void goDetails(BuildContext context, int id) =>
      context.go(details(id));

  /// Leaves invoice screens (create / edit) for the sales hub.
  static void backToHome(BuildContext context) => goRoot(context);

  /// Leaves the details screen for the sales list.
  static void backToList(BuildContext context) => goList(context);

  static void pushCreate(BuildContext context) => context.push(create);

  static void pushDetails(BuildContext context, int id) =>
      context.push(details(id));

  static void pushEdit(BuildContext context, int id) => context.push(edit(id));

  static Future<void> pushInvoicePreview(BuildContext context) async {
    await context.push(invoicePreview);
  }
}
