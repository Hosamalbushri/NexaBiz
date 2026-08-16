import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/permissions/permission_defs.dart';

/// Shared builders for common CRUD / workflow operations.
///
/// Modules compose these so permission catalogs stay consistent and flexible.
abstract final class StandardPermissionOps {
  static PermissionOperationDef view(
    String code, {
    List<String> legacyCodes = const [],
  }) {
    return PermissionOperationDef(
      code: code,
      icon: Icons.visibility_outlined,
      legacyCodes: legacyCodes,
      labelBuilder: (context) => AppLocalizations.of(context).adminPermActionView,
    );
  }

  static PermissionOperationDef create(
    String code, {
    List<String> legacyCodes = const [],
  }) {
    return PermissionOperationDef(
      code: code,
      icon: Icons.add_circle_outline,
      legacyCodes: legacyCodes,
      labelBuilder: (context) =>
          AppLocalizations.of(context).adminPermActionCreate,
    );
  }

  static PermissionOperationDef update(
    String code, {
    List<String> legacyCodes = const [],
  }) {
    return PermissionOperationDef(
      code: code,
      icon: Icons.edit_outlined,
      legacyCodes: legacyCodes,
      labelBuilder: (context) =>
          AppLocalizations.of(context).adminPermActionUpdate,
    );
  }

  static PermissionOperationDef delete(
    String code, {
    List<String> legacyCodes = const [],
  }) {
    return PermissionOperationDef(
      code: code,
      icon: Icons.delete_outline,
      legacyCodes: legacyCodes,
      labelBuilder: (context) =>
          AppLocalizations.of(context).adminPermActionDelete,
    );
  }

  static PermissionOperationDef manage(
    String code, {
    List<String> legacyCodes = const [],
  }) {
    return PermissionOperationDef(
      code: code,
      icon: Icons.admin_panel_settings_outlined,
      legacyCodes: legacyCodes,
      labelBuilder: (context) =>
          AppLocalizations.of(context).adminPermActionManage,
    );
  }

  static PermissionOperationDef importOp(
    String code, {
    List<String> legacyCodes = const [],
  }) {
    return PermissionOperationDef(
      code: code,
      icon: Icons.upload_file_outlined,
      legacyCodes: legacyCodes,
      labelBuilder: (context) => AppLocalizations.of(context).adminPermOpImport,
    );
  }

  static PermissionOperationDef exportOp(
    String code, {
    List<String> legacyCodes = const [],
  }) {
    return PermissionOperationDef(
      code: code,
      icon: Icons.download_outlined,
      legacyCodes: legacyCodes,
      labelBuilder: (context) => AppLocalizations.of(context).adminPermOpExport,
    );
  }

  static PermissionOperationDef custom({
    required String code,
    required IconData icon,
    required String Function(AppLocalizations l10n) label,
    List<String> legacyCodes = const [],
  }) {
    return PermissionOperationDef(
      code: code,
      icon: icon,
      legacyCodes: legacyCodes,
      labelBuilder: (context) => label(AppLocalizations.of(context)),
    );
  }
}
