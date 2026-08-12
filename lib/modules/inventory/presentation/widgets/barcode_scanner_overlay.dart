import 'package:flutter/material.dart';

/// Visual phase for the barcode scanner overlay.
enum ScannerOverlayStatus { scanning, processing, success, error }

/// Professional scanning UI layer rendered above an existing camera preview.
///
/// Does not own the camera or detection logic — only the overlay chrome,
/// laser animation, and status messaging.
class BarcodeScannerOverlay extends StatefulWidget {
  const BarcodeScannerOverlay({
    super.key,
    required this.status,
    required this.alignHint,
    required this.scanningLabel,
    required this.detectedLabel,
    required this.processingLabel,
    required this.errorLabel,
  });

  final ScannerOverlayStatus status;
  final String alignHint;
  final String scanningLabel;
  final String detectedLabel;
  final String processingLabel;
  final String errorLabel;

  @override
  State<BarcodeScannerOverlay> createState() => _BarcodeScannerOverlayState();
}

class _BarcodeScannerOverlayState extends State<BarcodeScannerOverlay>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _laserDuration = Duration(milliseconds: 1700);
  static const _pulseDuration = Duration(milliseconds: 2200);

  late final AnimationController _laserController;
  late final AnimationController _pulseController;
  late final Animation<double> _laserAnimation;
  late final Animation<double> _pulseAnimation;

  bool get _isActivelyScanning =>
      widget.status == ScannerOverlayStatus.scanning;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _laserController = AnimationController(
      vsync: this,
      duration: _laserDuration,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: _pulseDuration,
    );

    _laserAnimation = CurvedAnimation(
      parent: _laserController,
      curve: Curves.easeInOut,
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    if (_isActivelyScanning) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(covariant BarcodeScannerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status == widget.status) {
      return;
    }
    if (_isActivelyScanning) {
      _startAnimations();
    } else {
      _stopAnimations();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isActivelyScanning) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _startAnimations();
      return;
    }
    _stopAnimations();
  }

  void _startAnimations() {
    if (!_laserController.isAnimating) {
      _laserController.repeat(reverse: true);
    }
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _stopAnimations() {
    if (_laserController.isAnimating) {
      _laserController.stop();
    }
    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _laserController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String get _statusText {
    return switch (widget.status) {
      ScannerOverlayStatus.scanning => widget.scanningLabel,
      ScannerOverlayStatus.processing => widget.processingLabel,
      ScannerOverlayStatus.success => widget.detectedLabel,
      ScannerOverlayStatus.error => widget.errorLabel,
    };
  }

  Color _accentColor(ColorScheme scheme) {
    return switch (widget.status) {
      ScannerOverlayStatus.scanning => scheme.primary,
      ScannerOverlayStatus.processing => scheme.primary,
      ScannerOverlayStatus.success => scheme.tertiary,
      ScannerOverlayStatus.error => scheme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _accentColor(colorScheme);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final shortest = size.shortestSide;
        final cutoutSize = (shortest * 0.72).clamp(220.0, 340.0);
        // Near-square window suits both 1D barcodes and QR codes.
        final cutout = Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.42),
          width: cutoutSize,
          height: cutoutSize,
        );

        return IgnorePointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _ScannerDimPainter(cutout: cutout)),
              AnimatedBuilder(
                animation: Listenable.merge([_laserAnimation, _pulseAnimation]),
                builder: (context, _) {
                  final pulse = reduceMotion ? 1.0 : _pulseAnimation.value;
                  final laserT = reduceMotion ? 0.5 : _laserAnimation.value;
                  return CustomPaint(
                    painter: _ScannerFramePainter(
                      cutout: cutout,
                      accent: accent,
                      pulse: pulse,
                      laserT: laserT,
                      showLaser: widget.status == ScannerOverlayStatus.scanning,
                    ),
                  );
                },
              ),
              Positioned(
                left: cutout.left,
                right: size.width - cutout.right,
                top: cutout.bottom + 20,
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey(widget.status),
                        child: _StatusBadge(
                          status: widget.status,
                          accent: accent,
                          label: _statusText,
                          textStyle: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (widget.status == ScannerOverlayStatus.scanning) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.alignHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.accent,
    required this.label,
    required this.textStyle,
  });

  final ScannerOverlayStatus status;
  final Color accent;
  final String label;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final showCheck = status == ScannerOverlayStatus.success;
    final showSpinner = status == ScannerOverlayStatus.processing;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCheck)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.scale(scale: value, child: child),
              );
            },
            child: Icon(Icons.check_circle_rounded, color: accent, size: 22),
          )
        else if (showSpinner)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent),
          )
        else
          Icon(
            status == ScannerOverlayStatus.error
                ? Icons.error_outline_rounded
                : Icons.qr_code_scanner_rounded,
            color: accent,
            size: 20,
          ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label, textAlign: TextAlign.center, style: textStyle),
        ),
      ],
    );
  }
}

class _ScannerDimPainter extends CustomPainter {
  const _ScannerDimPainter({required this.cutout});

  final Rect cutout;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(cutout, const Radius.circular(16)));
    final dimmed = Path.combine(PathOperation.difference, overlay, hole);
    canvas.drawPath(
      dimmed,
      Paint()..color = Colors.black.withValues(alpha: 0.48),
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerDimPainter oldDelegate) {
    return oldDelegate.cutout != cutout;
  }
}

class _ScannerFramePainter extends CustomPainter {
  const _ScannerFramePainter({
    required this.cutout,
    required this.accent,
    required this.pulse,
    required this.laserT,
    required this.showLaser,
  });

  final Rect cutout;
  final Color accent;
  final double pulse;
  final double laserT;
  final bool showLaser;

  @override
  void paint(Canvas canvas, Size size) {
    final cornerLength = (cutout.shortestSide * 0.18).clamp(18.0, 28.0);
    final stroke = 3.0;
    final opacity = (0.72 + (pulse * 0.28)).clamp(0.72, 1.0);
    final paint = Paint()
      ..color = accent.withValues(alpha: opacity)
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void drawCorner(Offset a, Offset b, Offset c) {
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy);
      canvas.drawPath(path, paint);
    }

    final left = cutout.left;
    final right = cutout.right;
    final top = cutout.top;
    final bottom = cutout.bottom;

    // Top-left
    drawCorner(
      Offset(left, top + cornerLength),
      Offset(left, top),
      Offset(left + cornerLength, top),
    );
    // Top-right
    drawCorner(
      Offset(right - cornerLength, top),
      Offset(right, top),
      Offset(right, top + cornerLength),
    );
    // Bottom-left
    drawCorner(
      Offset(left, bottom - cornerLength),
      Offset(left, bottom),
      Offset(left + cornerLength, bottom),
    );
    // Bottom-right
    drawCorner(
      Offset(right - cornerLength, bottom),
      Offset(right, bottom),
      Offset(right, bottom - cornerLength),
    );

    if (!showLaser) {
      return;
    }

    final inset = 10.0;
    final y = cutout.top + inset + (cutout.height - inset * 2) * laserT;
    final lineLeft = cutout.left + inset;
    final lineRight = cutout.right - inset;

    final glowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0),
          accent.withValues(alpha: 0.35),
          accent.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(lineLeft, y - 10, lineRight - lineLeft, 20))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawRect(
      Rect.fromLTRB(lineLeft, y - 8, lineRight, y + 8),
      glowPaint,
    );

    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0),
          accent.withValues(alpha: 0.95),
          accent.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(lineLeft, y - 1, lineRight - lineLeft, 2))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(lineLeft, y), Offset(lineRight, y), linePaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) {
    return oldDelegate.cutout != cutout ||
        oldDelegate.accent != accent ||
        oldDelegate.pulse != pulse ||
        oldDelegate.laserT != laserT ||
        oldDelegate.showLaser != showLaser;
  }
}
