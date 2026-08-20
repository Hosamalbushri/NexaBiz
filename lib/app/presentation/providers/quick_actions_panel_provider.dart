import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Increment to request the shell close the quick-actions panel.
///
/// Used before opening other modal sheets (e.g. dashboard customize) so the
/// panel does not fight nested bottom sheets or back gestures.
final quickActionsCloseRequestProvider = StateProvider<int>((ref) => 0);

/// Whether the quick-actions panel is currently open.
final quickActionsOpenProvider = StateProvider<bool>((ref) => false);

void requestCloseQuickActions(WidgetRef ref) {
  ref.read(quickActionsCloseRequestProvider.notifier).state++;
}
