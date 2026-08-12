import 'package:flutter/material.dart';

import '../../app/theme/app_radius.dart';

/// Unread count badge with a one-shot scale pop when the count increases.
class NotificationBadge extends StatefulWidget {
  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
    this.maxCount = 99,
  });

  final int count;
  final Widget child;
  final int maxCount;

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  var _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.count;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.22), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.22, end: 1), weight: 60),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant NotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > _previousCount && widget.count > 0) {
      _controller.forward(from: 0);
    }
    _previousCount = widget.count;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final show = widget.count > 0;
    final label = widget.count > widget.maxCount
        ? '${widget.maxCount}+'
        : '${widget.count}';
    final isSingleDigit = widget.count <= 9;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        if (show)
          PositionedDirectional(
            top: -2,
            end: -2,
            child: ScaleTransition(
              scale: _scale,
              child: Semantics(
                label: label,
                liveRegion: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: colorScheme.surface,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.error.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: isSingleDigit ? 18 : 22,
                      minHeight: 18,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSingleDigit ? 0 : 5,
                        vertical: 2,
                      ),
                      child: Center(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.onError,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                height: 1.1,
                                letterSpacing: 0,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
