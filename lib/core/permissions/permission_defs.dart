import 'package:flutter/widgets.dart';

/// One grantable operation inside a service (view / create / import / …).
@immutable
class PermissionOperationDef {
  const PermissionOperationDef({
    required this.code,
    required this.icon,
    required this.labelBuilder,
    this.legacyCodes = const [],
  });

  /// Canonical code, preferably `module.service.operation`.
  final String code;

  final IconData icon;
  final String Function(BuildContext context) labelBuilder;
  final List<String> legacyCodes;

  String label(BuildContext context) => labelBuilder(context);
}

/// A service inside a package (e.g. Stock count, Products).
@immutable
class PermissionServiceDef {
  const PermissionServiceDef({
    required this.id,
    required this.icon,
    required this.titleBuilder,
    required this.subtitleBuilder,
    required this.operations,
  });

  final String id;
  final IconData icon;
  final String Function(BuildContext context) titleBuilder;
  final String Function(BuildContext context) subtitleBuilder;
  final List<PermissionOperationDef> operations;

  String title(BuildContext context) => titleBuilder(context);
  String subtitle(BuildContext context) => subtitleBuilder(context);

  List<String> get allCodes => [
        for (final op in operations) ...[op.code, ...op.legacyCodes],
      ];
}

/// A top-level permission package contributed by a module (or platform).
///
/// Modules register these via [AppModule.permissionPackage]. Adding/removing a
/// module from [ModuleRegistry] automatically updates Administration UI.
@immutable
class PermissionPackageDef {
  const PermissionPackageDef({
    required this.id,
    required this.icon,
    required this.titleBuilder,
    required this.subtitleBuilder,
    required this.services,
    this.sortOrder = 100,
  });

  final String id;
  final IconData icon;
  final String Function(BuildContext context) titleBuilder;
  final String Function(BuildContext context) subtitleBuilder;
  final List<PermissionServiceDef> services;

  /// Lower values appear first in Administration catalogs.
  final int sortOrder;

  String title(BuildContext context) => titleBuilder(context);
  String subtitle(BuildContext context) => subtitleBuilder(context);

  List<String> get allCodes => [
        for (final s in services) ...s.allCodes,
      ];
}
