import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../auth/presentation/providers/auth_state_core.dart';

/// Maximum number of pinned quick navigation items in the navigation sheet.
const int kMaxQuickNavItems = 12;

/// A platform quick navigation shortcut definition contributed by modules or system defaults.
@immutable
class QuickNavDefinition {
  const QuickNavDefinition({
    required this.id,
    required this.icon,
    required this.titleBuilder,
    required this.subtitleBuilder,
    required this.routePath,
    this.moduleId,
    this.requiredPermissions,
    this.isPrimary = false,
  });

  final String id;
  final IconData icon;
  final String Function(AppLocalizations l10n) titleBuilder;
  final String Function(AppLocalizations l10n) subtitleBuilder;

  /// Route path to navigate to when this shortcut is tapped.
  final String routePath;

  /// Optional business module ID associated with this shortcut.
  final String? moduleId;

  /// System permission codes needed to use/see this quick navigation shortcut.
  final List<String>? requiredPermissions;

  /// Whether this shortcut represents a primary exit destination (e.g. Dashboard).
  final bool isPrimary;

  String title(BuildContext context) => titleBuilder(AppLocalizations.of(context));
  String subtitle(BuildContext context) => subtitleBuilder(AppLocalizations.of(context));

  bool hasPermission(AuthState authState) {
    if (requiredPermissions == null || requiredPermissions!.isEmpty) {
      return true;
    }
    if (authState.session == null) {
      return true;
    }
    if (authState.session?.user.isSuperAdmin == true) {
      return true;
    }
    return authState.hasAnyPermission(requiredPermissions!);
  }
}
