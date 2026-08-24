import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_spacing.dart';
import '../connectivity/network_status.dart';

/// Visually communicates network connectivity state to the user.
///
/// Supports compact (icon + text pill) or icon-only display modes.
class NetworkStatusIndicator extends ConsumerWidget {
  const NetworkStatusIndicator({
    super.key,
    this.compact = false,
    this.showLabel = true,
  });

  /// When true, renders a small badge suitable for app bar headers.
  final bool compact;

  /// Whether to display the text status label next to the icon.
  final bool showLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color badgeColor;
    final Color textColor;
    final IconData icon;
    final String labelText;

    switch (status) {
      case NetworkStatus.online:
        badgeColor = isDark
            ? const Color(0xFF1B5E20).withValues(alpha: 0.85)
            : const Color(0xFFE8F5E9);
        textColor = isDark ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32);
        icon = Icons.wifi_rounded;
        labelText = l10n.syncConnectionOnline;
        break;

      case NetworkStatus.offline:
        badgeColor = isDark
            ? const Color(0xFF37474F).withValues(alpha: 0.85)
            : const Color(0xFFECEFF1);
        textColor = isDark ? const Color(0xFFCFD8DC) : const Color(0xFF546E7A);
        icon = Icons.wifi_off_rounded;
        labelText = l10n.syncConnectionOffline;
        break;

      case NetworkStatus.reconnecting:
        badgeColor = isDark
            ? const Color(0xFF0D47A1).withValues(alpha: 0.85)
            : const Color(0xFFE3F2FD);
        textColor = isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);
        icon = Icons.sync_rounded;
        labelText = l10n.syncStatusSyncing;
        break;
    }

    if (!showLabel) {
      return Tooltip(
        message: labelText,
        child: Icon(
          icon,
          size: compact ? 18 : 22,
          color: textColor,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs + 2 : AppSpacing.sm,
        vertical: compact ? 3 : AppSpacing.xxs + 1,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == NetworkStatus.reconnecting)
            SizedBox(
              width: compact ? 12 : 14,
              height: compact ? 12 : 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
              ),
            )
          else
            Icon(
              icon,
              size: compact ? 14 : 16,
              color: textColor,
            ),
          const SizedBox(width: 5),
          Text(
            labelText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 11 : 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
