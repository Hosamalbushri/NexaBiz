import 'package:flutter/material.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/utils/digit_normalization.dart';
import '../../domain/models/catalog_search_field.dart';
import 'catalog_search_field_selector.dart';

/// In-page expandable catalog search panel.
///
/// Collapsed: occupies **zero** body height (open via AppBar search icon).
/// Expanded: animates open inside the page below the AppBar.
class CatalogExpandableSearchPanel extends StatefulWidget {
  const CatalogExpandableSearchPanel({
    super.key,
    required this.expanded,
    required this.onExpandedChanged,
    required this.onQueryChanged,
    required this.searchField,
    required this.onSearchFieldChanged,
    this.controller,
    this.focusNode,
    this.trailing,
    this.padding,
  });

  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final ValueChanged<String> onQueryChanged;
  final CatalogSearchField searchField;
  final ValueChanged<CatalogSearchField> onSearchFieldChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  State<CatalogExpandableSearchPanel> createState() =>
      _CatalogExpandableSearchPanelState();
}

class _CatalogExpandableSearchPanelState
    extends State<CatalogExpandableSearchPanel> {
  static const Duration _duration = Duration(milliseconds: 300);

  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final bool _ownsController = widget.controller == null;
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  late final bool _ownsFocusNode = widget.focusNode == null;
  late var _hasText = _controller.text.isNotEmpty;
  var _focused = false;
  var _filtersVisible = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerTick);
    _focusNode.addListener(_onFocusTick);
    _focused = _focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(covariant CatalogExpandableSearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded && !oldWidget.expanded) {
      _requestFocusSoon();
    }
    if (!widget.expanded && oldWidget.expanded) {
      _focusNode.unfocus();
      if (_controller.text.isNotEmpty) {
        _clear();
      }
      if (_filtersVisible) {
        _filtersVisible = false;
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerTick);
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

  void _onControllerTick() {
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

  void _handleChanged(String value) {
    widget.onQueryChanged(normalizeDigitsToWestern(value));
  }

  void _clear() {
    _controller.clear();
    widget.onQueryChanged('');
  }

  void _toggleFilters() {
    setState(() => _filtersVisible = !_filtersVisible);
  }

  @override
  Widget build(BuildContext context) {
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
              child: _buildPanel(context, duration),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildPanel(BuildContext context, Duration duration) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final filterActive =
        _filtersVisible || widget.searchField != CatalogSearchField.all;
    final clearTooltip = MaterialLocalizations.of(context).deleteButtonTooltip;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      opacity: widget.expanded ? 1 : 0,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _SearchInputShell(
                      focused: _focused,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.search,
                        inputFormatters: const [WesternDigitsInputFormatter()],
                        onChanged: _handleChanged,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        cursorColor: colorScheme.primary,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: widget.searchField.hint(l10n),
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
                          suffixIcon: _SearchFieldTrailingActions(
                            hasText: _hasText,
                            clearTooltip: clearTooltip,
                            onClear: _clear,
                            filterActive: filterActive,
                            filterTooltip: l10n.catalogSearchFilterLabel,
                            onFilter: _toggleFilters,
                          ),
                          suffixIconConstraints: BoxConstraints(
                            minHeight: 52,
                            minWidth: _hasText ? 84 : 44,
                          ),
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
            AnimatedSize(
              duration: duration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _filtersVisible
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xs,
                        0,
                        AppSpacing.xs,
                        AppSpacing.xs,
                      ),
                      child: CatalogSearchFieldSelector(
                        value: widget.searchField,
                        onChanged: widget.onSearchFieldChanged,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple in-page expandable search for non-catalog screens (e.g. reports).
class ExpandableSearchPanel extends StatefulWidget {
  const ExpandableSearchPanel({
    super.key,
    required this.expanded,
    required this.onExpandedChanged,
    required this.onChanged,
    this.controller,
    this.focusNode,
    this.hint,
    this.padding,
  });

  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final EdgeInsetsGeometry? padding;

  @override
  State<ExpandableSearchPanel> createState() => _ExpandableSearchPanelState();
}

class _ExpandableSearchPanelState extends State<ExpandableSearchPanel> {
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
  void didUpdateWidget(covariant ExpandableSearchPanel oldWidget) {
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
                  child: _SearchInputShell(
                    focused: _focused,
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
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Shared search-field chrome: soft fill + focus ring.
class _SearchInputShell extends StatelessWidget {
  const _SearchInputShell({
    required this.focused,
    required this.child,
  });

  final bool focused;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: focused
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: focused ? 1.4 : 1,
        ),
      ),
      child: child,
    );
  }
}

/// Clear + filter controls inside the search field.
class _SearchFieldTrailingActions extends StatelessWidget {
  const _SearchFieldTrailingActions({
    required this.hasText,
    required this.clearTooltip,
    required this.onClear,
    required this.filterActive,
    required this.filterTooltip,
    required this.onFilter,
  });

  final bool hasText;
  final String clearTooltip;
  final VoidCallback onClear;
  final bool filterActive;
  final String filterTooltip;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasText)
          IconButton(
            tooltip: clearTooltip,
            onPressed: onClear,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            icon: Icon(
              Icons.cancel_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        IconButton(
          tooltip: filterTooltip,
          onPressed: onFilter,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          icon: Icon(
            Icons.tune_rounded,
            size: 18,
            color: filterActive
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
