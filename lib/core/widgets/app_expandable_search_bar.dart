import 'package:flutter/material.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/utils/digit_normalization.dart';

/// Canonical in-page expandable search bar widget for NexaBiz UI architecture.
class AppExpandableSearchBar extends StatefulWidget {
  const AppExpandableSearchBar({
    super.key,
    required this.expanded,
    required this.onExpandedChanged,
    required this.onChanged,
    this.controller,
    this.focusNode,
    this.hint,
    this.padding,
    this.trailing,
  });

  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final EdgeInsetsGeometry? padding;
  final Widget? trailing;

  @override
  State<AppExpandableSearchBar> createState() => _AppExpandableSearchBarState();
}

class _AppExpandableSearchBarState extends State<AppExpandableSearchBar> {
  static const Duration _duration = Duration(milliseconds: 300);

  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final bool _ownsController = widget.controller == null;
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  late final bool _ownsFocusNode = widget.focusNode == null;
  late var _hasText = _controller.text.isNotEmpty;
  var _focused = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTick);
    _focusNode.addListener(_onFocusTick);
    _focused = _focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(covariant AppExpandableSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded && !oldWidget.expanded) {
      _requestFocusSoon();
    }
    if (!widget.expanded && oldWidget.expanded) {
      _focusNode.unfocus();
      if (_controller.text.isNotEmpty) {
        _clear();
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _focusNode.removeListener(_onFocusTick);
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _requestFocusSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.expanded) {
        _focusNode.requestFocus();
      }
    });
  }

  void _onTick() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText == _hasText || !mounted) {
      return;
    }
    setState(() => _hasText = hasText);
  }

  void _onFocusTick() {
    if (!mounted || _focused == _focusNode.hasFocus) {
      return;
    }
    setState(() => _focused = _focusNode.hasFocus);
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : _duration;

    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: widget.expanded
          ? Padding(
              padding:
                  widget.padding ??
                  const EdgeInsets.fromLTRB(
                    AppConstants.pagePadding,
                    AppSpacing.md,
                    AppConstants.pagePadding,
                    AppSpacing.sm,
                  ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(
                        alpha: isDark ? 0.24 : 0.05,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: _focused
                                  ? colorScheme.primary.withValues(alpha: 0.5)
                                  : colorScheme.outlineVariant.withValues(
                                      alpha: 0.4,
                                    ),
                              width: _focused ? 1.4 : 1,
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            textInputAction: TextInputAction.search,
                            inputFormatters: const [
                              WesternDigitsInputFormatter(),
                            ],
                            onChanged: (value) => widget.onChanged(
                              normalizeDigitsToWestern(value),
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            cursorColor: colorScheme.primary,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: widget.hint,
                              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                height: 1.2,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: _focused
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 52,
                              ),
                              suffixIcon: _hasText
                                  ? IconButton(
                                      tooltip: MaterialLocalizations.of(
                                        context,
                                      ).deleteButtonTooltip,
                                      onPressed: _clear,
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        Icons.cancel_rounded,
                                        size: 18,
                                        color: colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      if (widget.trailing != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        widget.trailing!,
                      ],
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
