import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/app_notification.dart';
import '../../../../core/widgets/notification_banner.dart';
import '../../../router/app_navigator_keys.dart';
import '../../../theme/app_spacing.dart';
import '../providers/notifications_provider.dart';

/// Hosts floating toasts inside the root [Navigator] overlay.
///
/// Must not paint toast UI as a sibling of the navigator in [MaterialApp.builder]
/// — tooltips and material ink need an [Overlay] ancestor.
class NotificationToastHost extends ConsumerStatefulWidget {
  const NotificationToastHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationToastHost> createState() =>
      _NotificationToastHostState();
}

class _NotificationToastHostState extends ConsumerState<NotificationToastHost> {
  OverlayEntry? _entry;
  List<FloatingToast> _toasts = const [];

  @override
  void dispose() {
    _removeEntry();
    super.dispose();
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  void _scheduleSync(List<FloatingToast> toasts) {
    _toasts = toasts;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncOverlay();
    });
  }

  void _syncOverlay() {
    final overlay = appRootNavigatorKey.currentState?.overlay;
    if (overlay == null) {
      if (_toasts.isNotEmpty) {
        _scheduleSync(_toasts);
      }
      return;
    }

    if (_toasts.isEmpty) {
      _removeEntry();
      return;
    }

    if (_entry == null) {
      _entry = OverlayEntry(builder: _buildOverlay);
      overlay.insert(_entry!);
    } else {
      _entry!.markNeedsBuild();
    }
  }

  Widget _buildOverlay(BuildContext context) {
    final toasts = _toasts;
    return IgnorePointer(
      ignoring: false,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < toasts.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      _AnimatedToast(
                        key: ValueKey(toasts[i].notification.id),
                        notification: toasts[i].notification,
                        onClose: () {
                          ref
                              .read(floatingNotificationsProvider.notifier)
                              .dismiss(toasts[i].notification.id);
                        },
                        onAction: () => _handleAction(toasts[i].notification),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleAction(AppNotification notification) {
    ref.read(floatingNotificationsProvider.notifier).dismiss(notification.id);
    unawaited(
      ref.read(notificationServiceProvider).markAsRead(notification.id),
    );
    final route = notification.actionRoute;
    final navigator = appRootNavigatorKey.currentContext;
    if (route != null && route.isNotEmpty && navigator != null) {
      GoRouter.of(navigator).push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<FloatingToast>>(floatingNotificationsProvider, (
      previous,
      next,
    ) {
      _scheduleSync(next);
    });

    final toasts = ref.watch(floatingNotificationsProvider);
    if (!identical(toasts, _toasts)) {
      _scheduleSync(toasts);
    }

    return widget.child;
  }
}

class _AnimatedToast extends StatefulWidget {
  const _AnimatedToast({
    super.key,
    required this.notification,
    required this.onClose,
    required this.onAction,
  });

  final AppNotification notification;
  final VoidCallback onClose;
  final VoidCallback onAction;

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;
  var _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fade = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.12),
      end: Offset.zero,
    ).animate(curved);
    _scale = Tween<double>(begin: 0.97, end: 1).animate(curved);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing) {
      return;
    }
    _closing = true;
    await _controller.reverse();
    if (mounted) {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Dismissible(
            key: ValueKey('toast_${widget.notification.id}'),
            direction: widget.notification.isPersistent
                ? DismissDirection.none
                : DismissDirection.horizontal,
            onDismissed: (_) => widget.onClose(),
            child: NotificationBanner(
              notification: widget.notification,
              onClose: _close,
              onAction: widget.notification.actionLabel == null
                  ? null
                  : widget.onAction,
            ),
          ),
        ),
      ),
    );
  }
}
