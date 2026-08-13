import 'package:flutter/material.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/digit_normalization.dart';

/// In-page expandable search for Chart of Accounts.
///
/// Collapsed: zero height. Open via AppBar search icon.
class AccountExpandableSearch extends StatefulWidget {
  const AccountExpandableSearch({
    super.key,
    required this.expanded,
    required this.onExpandedChanged,
    required this.onQueryChanged,
    this.controller,
    this.focusNode,
  });

  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final ValueChanged<String> onQueryChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  @override
  State<AccountExpandableSearch> createState() =>
      _AccountExpandableSearchState();
}

class _AccountExpandableSearchState extends State<AccountExpandableSearch> {
  static const Duration _duration = Duration(milliseconds: 280);

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
    _controller.addListener(_onControllerTick);
    _focusNode.addListener(_onFocusTick);
    _focused = _focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(covariant AccountExpandableSearch oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : _duration;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: widget.expanded
          ? Padding(
              padding: AppConstants.pageInsets(
                context,
              ).copyWith(top: AppSpacing.md, bottom: AppSpacing.sm),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: widget.expanded ? 1 : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: _focused
                          ? colorScheme.primary.withValues(alpha: 0.45)
                          : colorScheme.outlineVariant.withValues(alpha: 0.55),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: _focused
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            textInputAction: TextInputAction.search,
                            inputFormatters: const [
                              WesternDigitsInputFormatter(),
                            ],
                            onChanged: _handleChanged,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: l10n.accountingSearchHint,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        if (_hasText)
                          IconButton(
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).deleteButtonTooltip,
                            onPressed: _clear,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close_rounded, size: 20),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
