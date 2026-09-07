import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_providers.dart';
import '../pages/app_lock_page.dart';
import '../providers/app_lock_providers.dart';

/// Global barrier wrapping the application root widget tree.
///
/// When App Lock is active for an authenticated session, this barrier
/// places an opaque, non-interactive [AppLockPage] directly over the entire
/// root navigator, shell branches, dialogs, bottom sheets, pickers, and overlays.
///
/// This prevents any sensitive content from being viewed or interacted with,
/// while preserving the underlying navigation and widget state intact for
/// seamless restoration upon unlock.
class AppLockGateBarrier extends ConsumerWidget {
  const AppLockGateBarrier({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final lockState = ref.watch(appLockControllerProvider);

    final showLockScreen = authState.isAuthenticated && lockState.isLocked;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (showLockScreen)
          const Positioned.fill(
            key: ValueKey('app_lock_gate_barrier_active'),
            child: AppLockPage(),
          ),
      ],
    );
  }
}
