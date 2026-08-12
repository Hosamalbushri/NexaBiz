import 'package:flutter/material.dart';

/// Decorative animated QR illustration for idle / empty scan surfaces.
///
/// Borderless, floating design — purely visual, no scan/business logic.
class AnimatedQrIllustration extends StatefulWidget {
  const AnimatedQrIllustration({
    super.key,
    this.size = 180,
    this.animate = true,
  });

  /// Outer size of the illustration.
  final double size;

  /// When false, shows a static QR without motion.
  final bool animate;

  @override
  State<AnimatedQrIllustration> createState() => _AnimatedQrIllustrationState();
}

class _AnimatedQrIllustrationState extends State<AnimatedQrIllustration>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _scanDuration = Duration(milliseconds: 2400);
  static const _pulseDuration = Duration(milliseconds: 2800);

  late final AnimationController _scanController;
  late final AnimationController _pulseController;
  late final Animation<double> _scanAnimation;
  late final Animation<double> _pulseAnimation;

  bool get _shouldAnimate =>
      widget.animate && !MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scanController = AnimationController(vsync: this, duration: _scanDuration);
    _pulseController = AnimationController(
      vsync: this,
      duration: _pulseDuration,
    );

    _scanAnimation = CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _shouldAnimate) {
        _start();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedQrIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate == widget.animate) {
      return;
    }
    if (_shouldAnimate) {
      _start();
    } else {
      _stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_shouldAnimate) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _start();
      return;
    }
    _stop();
  }

  void _start() {
    if (!_scanController.isAnimating) {
      _scanController.repeat(reverse: true);
    }
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _stop() {
    if (_scanController.isAnimating) {
      _scanController.stop();
    }
    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = widget.size;
    final animate = _shouldAnimate;

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_scanAnimation, _pulseAnimation]),
          builder: (context, _) {
            final pulseT = animate ? _pulseAnimation.value : 0.0;
            final scanT = animate ? _scanAnimation.value : 0.45;
            final opacity = 0.93 + (pulseT * 0.07);
            final scale = 1.0 + (pulseT * 0.015);

            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: CustomPaint(
                    size: Size.square(size),
                    painter: _FloatingQrPainter(
                      moduleColor: colorScheme.onSurface.withValues(
                        alpha: 0.88,
                      ),
                      accentColor: colorScheme.primary,
                      glowColor: colorScheme.primary.withValues(alpha: 0.16),
                      scanT: scanT,
                      showScan: animate,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FloatingQrPainter extends CustomPainter {
  const _FloatingQrPainter({
    required this.moduleColor,
    required this.accentColor,
    required this.glowColor,
    required this.scanT,
    required this.showScan,
  });

  final Color moduleColor;
  final Color accentColor;
  final Color glowColor;
  final double scanT;
  final bool showScan;

  /// Decorative QR body (excluding classic finder corners drawn separately).
  static const _body = <String>[
    '0000000010011000000',
    '0000000001100000000',
    '0000000010111000000',
    '0000000001001000000',
    '0000000011101000000',
    '0000000000010000000',
    '0000000010101000000',
    '0010110111011011010',
    '0101001000100100101',
    '0110110111011011011',
    '0001001000100100100',
    '0110110111011011011',
    '0100100100100101001',
    '0000000010010000000',
    '0000000001101000000',
    '0000000010001000000',
    '0000000001110000000',
    '0000000010101000000',
    '0000000001000000000',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final origin = Offset((size.width - side) / 2, (size.height - side) / 2);
    final qrRect = origin & Size.square(side);

    // Soft ambient glow — no hard container or border.
    final ambient = Paint()
      ..shader = RadialGradient(
        colors: [glowColor, glowColor.withValues(alpha: 0)],
      ).createShader(qrRect.inflate(side * 0.08))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.08);
    canvas.drawCircle(qrRect.center, side * 0.52, ambient);

    final inset = side * 0.08;
    final gridRect = Rect.fromLTRB(
      qrRect.left + inset,
      qrRect.top + inset,
      qrRect.right - inset,
      qrRect.bottom - inset,
    );

    _paintModules(canvas, gridRect);
    _paintFinder(canvas, gridRect, Alignment.topLeft);
    _paintFinder(canvas, gridRect, Alignment.topRight);
    _paintFinder(canvas, gridRect, Alignment.bottomLeft);
    _paintFinder(canvas, gridRect, Alignment.bottomRight);

    if (!showScan) {
      return;
    }

    _paintScanBeam(canvas, gridRect);
  }

  void _paintModules(Canvas canvas, Rect grid) {
    final rows = _body.length;
    final cols = _body.first.length;
    final cell = grid.width / cols;
    final paint = Paint()..color = moduleColor.withValues(alpha: 0.78);

    for (var r = 0; r < rows; r++) {
      final row = _body[r];
      for (var c = 0; c < cols && c < row.length; c++) {
        if (row[c] != '1') {
          continue;
        }
        // Keep classic finder zones clear — drawn as dedicated marks.
        if (_inFinderZone(r, c, rows, cols)) {
          continue;
        }
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            grid.left + c * cell + cell * 0.08,
            grid.top + r * cell + cell * 0.08,
            cell * 0.84,
            cell * 0.84,
          ),
          Radius.circular(cell * 0.22),
        );
        canvas.drawRRect(rect, paint);
      }
    }
  }

  bool _inFinderZone(int r, int c, int rows, int cols) {
    final inTopLeft = r < 7 && c < 7;
    final inTopRight = r < 7 && c >= cols - 7;
    final inBottomLeft = r >= rows - 7 && c < 7;
    final inBottomRight = r >= rows - 7 && c >= cols - 7;
    return inTopLeft || inTopRight || inBottomLeft || inBottomRight;
  }

  void _paintFinder(Canvas canvas, Rect grid, Alignment corner) {
    final cell = grid.width / 19;
    final mark = cell * 7;
    final topLeft = switch (corner) {
      Alignment.topRight => Offset(grid.right - mark, grid.top),
      Alignment.bottomLeft => Offset(grid.left, grid.bottom - mark),
      Alignment.bottomRight => Offset(grid.right - mark, grid.bottom - mark),
      _ => Offset(grid.left, grid.top),
    };

    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(topLeft.dx, topLeft.dy, mark, mark),
      Radius.circular(cell * 1.1),
    );
    final mid = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        topLeft.dx + cell,
        topLeft.dy + cell,
        mark - cell * 2,
        mark - cell * 2,
      ),
      Radius.circular(cell * 0.85),
    );
    final core = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        topLeft.dx + cell * 2.15,
        topLeft.dy + cell * 2.15,
        mark - cell * 4.3,
        mark - cell * 4.3,
      ),
      Radius.circular(cell * 0.55),
    );

    final ring = Paint()
      ..color = accentColor.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.95;
    final softRing = Paint()
      ..color = accentColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.35;
    final fill = Paint()..color = accentColor.withValues(alpha: 0.9);

    canvas.drawRRect(outer, ring);
    canvas.drawRRect(mid, softRing);
    canvas.drawRRect(core, fill);
  }

  void _paintScanBeam(Canvas canvas, Rect grid) {
    final bandHeight = grid.height * 0.18;
    final y = grid.top + bandHeight / 2 + (grid.height - bandHeight) * scanT;
    final top = y - bandHeight / 2;
    final bottom = y + bandHeight / 2;

    final wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0),
          accentColor.withValues(alpha: 0.14),
          accentColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTRB(grid.left, top, grid.right, bottom))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRect(Rect.fromLTRB(grid.left, top, grid.right, bottom), wash);

    final line = Paint()
      ..shader = LinearGradient(
        colors: [
          accentColor.withValues(alpha: 0),
          accentColor.withValues(alpha: 0.9),
          accentColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(grid.left, y - 1, grid.width, 2))
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(grid.left + grid.width * 0.06, y),
      Offset(grid.right - grid.width * 0.06, y),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _FloatingQrPainter oldDelegate) {
    return oldDelegate.moduleColor != moduleColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.scanT != scanT ||
        oldDelegate.showScan != showScan;
  }
}
