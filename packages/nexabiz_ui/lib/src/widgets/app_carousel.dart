import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// A canonical NexaBiz composite carousel widget wrapping [shadcn.Carousel]
/// with integrated navigation controls, page indicators, and type-safe item list binding.
class AppCarousel<T> extends StatefulWidget {
  /// Creates an [AppCarousel].
  const AppCarousel({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.height = 220,
    this.showControls = true,
    this.showIndicators = true,
    this.autoplay = false,
    this.autoplaySpeed = const Duration(seconds: 4),
    this.transition = const shadcn.CarouselTransition.sliding(gap: 16),
    this.sizeConstraint = const shadcn.CarouselSizeConstraint.fractional(1.0),
    this.onIndexChanged,
  });

  /// The list of generic data items to render.
  final List<T> items;

  /// Builder for rendering each generic item.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// External [shadcn.CarouselController]. If omitted, an internal controller is managed.
  final shadcn.CarouselController? controller;

  /// Height of the carousel container.
  final double height;

  /// Whether to display previous/next navigation buttons.
  final bool showControls;

  /// Whether to display page indicators.
  final bool showIndicators;

  /// Whether slides should progress automatically.
  final bool autoplay;

  /// Duration between automatic slide transitions when [autoplay] is true.
  final Duration autoplaySpeed;

  /// Transition animation (sliding or fading).
  final shadcn.CarouselTransition transition;

  /// Size constraint for items (fixed or fractional).
  final shadcn.CarouselSizeConstraint sizeConstraint;

  /// Callback when active index changes.
  final ValueChanged<int>? onIndexChanged;

  @override
  State<AppCarousel<T>> createState() => _AppCarouselState<T>();
}

class _AppCarouselState<T> extends State<AppCarousel<T>> {
  shadcn.CarouselController? _internalController;
  int _currentIndex = 0;

  shadcn.CarouselController get _effectiveController =>
      widget.controller ?? (_internalController ??= shadcn.CarouselController());

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = shadcn.CarouselController();
    }
  }

  @override
  void didUpdateWidget(covariant AppCarousel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _internalController?.dispose();
        _internalController = null;
      }
      if (widget.controller == null) {
        _internalController = shadcn.CarouselController();
      }
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  void _handlePrevious() {
    _effectiveController.animatePrevious(const Duration(milliseconds: 300));
  }

  void _handleNext() {
    _effectiveController.animateNext(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: Text('No items to display')),
      );
    }

    final theme = shadcn.Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              shadcn.Carousel(
                controller: _effectiveController,
                itemCount: widget.items.length,
                transition: widget.transition,
                sizeConstraint: widget.sizeConstraint,
                autoplaySpeed: widget.autoplay ? widget.autoplaySpeed : null,
                onIndexChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  widget.onIndexChanged?.call(index);
                },
                itemBuilder: (context, index) {
                  final safeIndex = index % widget.items.length;
                  return widget.itemBuilder(
                    context,
                    widget.items[safeIndex],
                    safeIndex,
                  );
                },
              ),
              if (widget.showControls && widget.items.length > 1) ...[
                Positioned(
                  left: 8,
                  child: shadcn.OutlineButton(
                    density: shadcn.ButtonDensity.compact,
                    shape: shadcn.ButtonShape.circle,
                    onPressed: _handlePrevious,
                    child: const shadcn.Icon(
                      shadcn.LucideIcons.chevronLeft,
                      size: 18,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  child: shadcn.OutlineButton(
                    density: shadcn.ButtonDensity.compact,
                    shape: shadcn.ButtonShape.circle,
                    onPressed: _handleNext,
                    child: const shadcn.Icon(
                      shadcn.LucideIcons.chevronRight,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.showIndicators && widget.items.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.items.length,
              (index) {
                final isActive = index == _currentIndex;
                return GestureDetector(
                  onTap: () {
                    _effectiveController.animateTo(
                      index.toDouble(),
                      const Duration(milliseconds: 300),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.mutedForeground.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
