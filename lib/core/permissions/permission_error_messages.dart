import '../../app/localization/app_localizations.dart';
import 'permission_guard.dart';

/// Localized message when a domain [PermissionGuard] rejects an action.
String? permissionDeniedMessage(AppLocalizations l10n, Object error) {
  if (error is PermissionDeniedException) {
    return l10n.permissionDenied;
  }
  return null;
}
