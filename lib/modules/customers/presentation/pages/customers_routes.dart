import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Route paths owned by the Customers module.
class CustomersRoutes {
  const CustomersRoutes._();

  static const String root = '/customers';
  static const String list = '/customers/list';
  static const String create = '/customers/new';
  static const String importPath = '/customers/import';

  static String edit(int id) => '/customers/$id/edit';

  static String details(int id) => '/customers/$id';

  static void goRoot(BuildContext context) => context.go(root);

  static void goList(BuildContext context) => context.go(list);

  static void pushCreate(BuildContext context) => context.push(create);

  static void pushImport(BuildContext context) => context.push(importPath);

  static void pushEdit(BuildContext context, int id) => context.push(edit(id));

  static void pushDetails(BuildContext context, int id) =>
      context.push(details(id));
}
