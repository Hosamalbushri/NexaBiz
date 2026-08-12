import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../app/theme/app_spacing.dart';
import '../services/loading_controller.dart';
import '../services/loading_providers.dart';

/// Hosts the global blocking [LoadingOverlay] above [child].
///
/// Place in [MaterialApp.builder] so it covers all routes.
class LoadingOverlayHost extends ConsumerWidget {
  const LoadingOverlayHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(loadingControllerProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        LoadingOverlay(
          visible: controller.isVisible,
          message: controller.message,
          absorbBackButton: true,
        ),
      ],
    );
  }
}

/// Theme-aware blocking loading overlay with smooth enter/exit motion.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.visible,
    this.message,
    this.absorbBackButton = true,
  });

  final bool visible;
  final String? message;
  final bool absorbBackButton;

  static const Duration _enterDuration = Duration(milliseconds: 240);
  static const Duration _exitDuration = Duration(milliseconds: 180);

  /// Bundled Lottie loading animation.
  static const String animationAsset = 'assets/animations/loading.json';

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSwitcher(
        duration: _enterDuration,
        reverseDuration: _exitDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: visible
            ? _BlockingLayer(
                key: const ValueKey<String>('loading-overlay'),
                message: message,
                absorbBackButton: absorbBackButton,
              )
            : const SizedBox.shrink(key: ValueKey<String>('loading-empty')),
      ),
    );
  }
}

class _BlockingLayer extends StatelessWidget {
  const _BlockingLayer({
    super.key,
    required this.message,
    required this.absorbBackButton,
  });

  final String? message;
  final bool absorbBackButton;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barrierColor = colorScheme.scrim.withValues(
      alpha: isDark ? 0.55 : 0.45,
    );

    final content = Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ModalBarrier(dismissible: false, color: barrierColor),
          SafeArea(
            child: Center(
              child: _LoadingCard(message: message),
            ),
          ),
        ],
      ),
    );

    if (!absorbBackButton) {
      return content;
    }

    return PopScope(canPop: false, child: content);
  }
}

class _LoadingCard extends StatefulWidget {
  const _LoadingCard({this.message});

  final String? message;

  @override
  State<_LoadingCard> createState() => _LoadingCardState();
}

class _LoadingCardState extends State<_LoadingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _scale = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trimmed = widget.message?.trim();
    final hasMessage = trimmed != null && trimmed.isNotEmpty;

    return ScaleTransition(
      scale: _scale,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(
                LoadingOverlay.animationAsset,
                fit: BoxFit.contain,
                repeat: true,
                frameRate: FrameRate.max,
                errorBuilder: (context, error, stackTrace) {
                  return CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colorScheme.primary,
                  );
                },
              ),
            ),
            if (hasMessage) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                trimmed,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  shadows: const [
                    Shadow(
                      color: Color(0x66000000),
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Convenience aliases matching a service-style API.
extension LoadingControllerX on LoadingController {
  void showLoading({String? message}) => show(message: message);

  void hideLoading() => hide();
}
