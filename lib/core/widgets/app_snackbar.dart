import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';

OverlayEntry? _activeToastEntry;
Timer? _activeToastTimer;
final GlobalKey<_TopToastState> _toastStateKey = GlobalKey<_TopToastState>();

/// Displays a polished top notification that auto-dismisses.
void showAppSnackBar(
  BuildContext context, {
  required String message,
  required bool isSuccess,
  Duration duration = const Duration(seconds: 3),
}) {
  _dismissActiveToast();

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    return;
  }

  final entry = OverlayEntry(
    builder: (context) {
      return _TopToast(
        key: _toastStateKey,
        message: message,
        isSuccess: isSuccess,
        duration: duration,
      );
    },
  );

  _activeToastEntry = entry;
  overlay.insert(entry);
  _activeToastTimer = Timer(duration, () {
    final state = _toastStateKey.currentState;
    if (state != null) {
      state.close();
    } else {
      _dismissActiveToast();
    }
  });
}

void _dismissActiveToast() {
  _activeToastTimer?.cancel();
  _activeToastTimer = null;
  _activeToastEntry?.remove();
  _activeToastEntry = null;
}

class _TopToast extends StatefulWidget {
  const _TopToast({
    super.key,
    required this.message,
    required this.isSuccess,
    required this.duration,
  });

  final String message;
  final bool isSuccess;
  final Duration duration;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _progressController;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();

    final curved = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(curved);
    _fade = curved;
    _scale = Tween<double>(begin: 0.94, end: 1).animate(curved);
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> close() async {
    if (_closing) {
      return;
    }
    _closing = true;
    _progressController.stop();
    await _entranceController.reverse();
    _dismissActiveToast();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final localization = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accent = widget.isSuccess ? AppColors.success : AppColors.error;
    final icon = widget.isSuccess
        ? Icons.check_rounded
        : Icons.priority_high_rounded;
    final title =
        widget.isSuccess ? localization.success : localization.failure;

    final cardColor = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.18 : 0.08),
      colorScheme.surface,
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Material(
                  color: Colors.transparent,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: cardColor.withValues(alpha: 0.96),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.22),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.35 : 0.12,
                                  ),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.10),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.md,
                                    AppSpacing.md,
                                    AppSpacing.sm,
                                    AppSpacing.md,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              accent.withValues(alpha: 0.95),
                                              accent.withValues(alpha: 0.75),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: accent.withValues(
                                                alpha: 0.28,
                                              ),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          icon,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: textTheme.titleSmall
                                                    ?.copyWith(
                                                  color: accent,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                widget.message,
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.4,
                                                  color:
                                                      colorScheme.onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Tooltip(
                                        message:
                                            MaterialLocalizations.of(context)
                                                .closeButtonTooltip,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: close,
                                            customBorder:
                                                const CircleBorder(),
                                            child: Ink(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: colorScheme
                                                    .errorContainer
                                                    .withValues(alpha: 0.95),
                                                border: Border.all(
                                                  color: colorScheme.error
                                                      .withValues(
                                                    alpha: 0.35,
                                                  ),
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.close_rounded,
                                                size: 18,
                                                color: colorScheme.error,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (context, _) {
                                    return LinearProgressIndicator(
                                      value: 1 - _progressController.value,
                                      minHeight: 3,
                                      backgroundColor:
                                          accent.withValues(alpha: 0.10),
                                      valueColor: AlwaysStoppedAnimation(
                                        accent.withValues(alpha: 0.75),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
