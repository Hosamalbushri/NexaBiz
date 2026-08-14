import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class _StatSlide {
  const _StatSlide({
    required this.icon,
    required this.label,
    required this.period,
    required this.value,
    required this.unit,
    required this.deltaLabel,
    required this.deltaPositive,
    required this.secondaryLabel,
    required this.secondaryValue,
    required this.cardColor,
    required this.onCardColor,
    required this.mutedOnCard,
  });

  final IconData icon;
  final String label;
  final String period;
  final String value;
  final String unit;
  final String deltaLabel;
  final bool deltaPositive;
  final String secondaryLabel;
  final String secondaryValue;
  final Color cardColor;
  final Color onCardColor;
  final Color mutedOnCard;
}

/// Horizontal cover-flow stats carousel (wallet-style peek + tilt).
///
/// Demo metrics for now — replace values from live providers later.
class DashboardStatsSlider extends StatefulWidget {
  const DashboardStatsSlider({super.key, this.embedded = false});

  /// Kept for callers; cover-flow layout is used in both modes.
  final bool embedded;

  @override
  State<DashboardStatsSlider> createState() => _DashboardStatsSliderState();
}

class _DashboardStatsSliderState extends State<DashboardStatsSlider> {
  static const _autoPlayInterval = Duration(seconds: 4);
  static const _animDuration = Duration(milliseconds: 520);
  static const _viewportFraction = 0.86;

  late final PageController _controller;
  Timer? _autoPlay;
  var _index = 0;
  var _userInteracting = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: _viewportFraction);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlay?.cancel();
    _autoPlay = Timer.periodic(_autoPlayInterval, (_) {
      if (!mounted || _userInteracting || !_controller.hasClients) {
        return;
      }
      final count = 3;
      final next = (_index + 1) % count;
      _controller.animateToPage(
        next,
        duration: _animDuration,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  List<_StatSlide> _slides(
    AppLocalizations l10n,
    ColorScheme scheme, {
    required bool isDark,
  }) {
    final primary = scheme.primary;
    final side = isDark
        ? const Color(0xFF1C1C1E)
        : const Color(0xFF2C3440);
    final teal = AppColors.secondaryTeal;
    final onPrimary = scheme.onPrimary;
    final onSide = Colors.white;

    return [
      _StatSlide(
        icon: Icons.payments_outlined,
        label: l10n.dashboardStatsSlideSalesTitle,
        period: l10n.dashboardStatsPeriodToday,
        value: '128,450',
        unit: l10n.dashboardStatsCurrencyHint,
        deltaLabel: '+12.4%',
        deltaPositive: true,
        secondaryLabel: l10n.dashboardStatsInvoicesLabel,
        secondaryValue: '24',
        cardColor: primary,
        onCardColor: onPrimary,
        mutedOnCard: onPrimary.withValues(alpha: 0.78),
      ),
      _StatSlide(
        icon: Icons.account_balance_wallet_outlined,
        label: l10n.dashboardStatsSlideBalanceTitle,
        period: l10n.dashboardStatsPeriodMonth,
        value: '86,920',
        unit: l10n.dashboardStatsCurrencyHint,
        deltaLabel: '+4.1%',
        deltaPositive: true,
        secondaryLabel: l10n.dashboardStatsCustomersLabel,
        secondaryValue: '18',
        cardColor: teal,
        onCardColor: onSide,
        mutedOnCard: onSide.withValues(alpha: 0.78),
      ),
      _StatSlide(
        icon: Icons.inventory_2_outlined,
        label: l10n.dashboardStatsSlideOverviewTitle,
        period: l10n.dashboardStatsPeriodWeek,
        value: '1,246',
        unit: l10n.dashboardStatsItemsLabel,
        deltaLabel: '-2.3%',
        deltaPositive: false,
        secondaryLabel: l10n.dashboardStatsLowStockLabel,
        secondaryValue: '7',
        cardColor: side,
        onCardColor: onSide,
        mutedOnCard: onSide.withValues(alpha: 0.72),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final slides = _slides(l10n, colorScheme, isDark: isDark);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 188,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _userInteracting = true;
                _autoPlay?.cancel();
              } else if (notification is ScrollEndNotification) {
                _userInteracting = false;
                _startAutoPlay();
              }
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: slides.length,
              padEnds: true,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, index) {
                final slide = slides[index];
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    var page = _index.toDouble();
                    if (_controller.hasClients &&
                        _controller.position.haveDimensions) {
                      page = _controller.page ?? page;
                    }
                    final delta = (page - index).clamp(-1.0, 1.0);
                    final abs = delta.abs();
                    final scale = 1.0 - (abs * 0.1);
                    final tilt = (isRtl ? -delta : delta) * 0.42;
                    final yLift = abs * 10.0;

                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.00135)
                        ..translateByDouble(0.0, yLift, 0.0, 1.0)
                        ..rotateY(tilt)
                        ..scaleByDouble(scale, scale, 1.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        child: _DashboardCoverCard(
                          slide: slide,
                          theme: theme,
                          active: index == _index,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _index
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.28),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DashboardCoverCard extends StatelessWidget {
  const _DashboardCoverCard({
    required this.slide,
    required this.theme,
    required this.active,
  });

  final _StatSlide slide;
  final ThemeData theme;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final on = slide.onCardColor;
    final muted = slide.mutedOnCard;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: slide.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: active ? 0.28 : 0.16),
            blurRadius: active ? 18 : 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          children: [
            PositionedDirectional(
              start: -8,
              bottom: -18,
              child: CustomPaint(
                size: const Size(120, 90),
                painter: _ArcPatternPainter(
                  color: on.withValues(alpha: 0.14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(slide.icon, color: on, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          slide.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: on,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        slide.period,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    slide.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: on,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.05,
                      fontFeatures: const [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          slide.unit,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        slide.deltaPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 16,
                        color: muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        slide.deltaLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          slide.secondaryLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: muted,
                          ),
                        ),
                      ),
                      Text(
                        slide.secondaryValue,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: on,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcPatternPainter extends CustomPainter {
  const _ArcPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 4; i++) {
      final r = 28.0 + (i * 16);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(8, size.height - 8), radius: r),
        -math.pi * 0.05,
        -math.pi * 0.55,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
