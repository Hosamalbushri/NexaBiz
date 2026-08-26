import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../auth/presentation/providers/auth_state_core.dart';

/// How a quick action is executed.
enum QuickActionKind { route }

/// Maximum number of pinned quick actions on the shell add sheet.
const int kMaxQuickActions = 9;

/// A platform quick-action shortcut offered in the shell add sheet.
@immutable
class QuickActionDefinition {
  const QuickActionDefinition({
    required this.id,
    required this.icon,
    required this.kind,
    required this.titleBuilder,
    required this.subtitleBuilder,
    this.routePath,
    this.requiredPermissions,
  });

  final String id;
  final IconData icon;
  final QuickActionKind kind;
  final String Function(AppLocalizations l10n) titleBuilder;
  final String Function(AppLocalizations l10n) subtitleBuilder;

  /// Used when [kind] is [QuickActionKind.route].
  final String? routePath;

  /// System permission codes needed to use/see this quick action.
  final List<String>? requiredPermissions;

  String title(AppLocalizations l10n) => titleBuilder(l10n);
  String subtitle(AppLocalizations l10n) => subtitleBuilder(l10n);

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
