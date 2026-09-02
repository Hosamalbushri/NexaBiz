import 'dart:async';
import 'package:flutter/material.dart';

/// Standardized search and filter bar component.
class SearchFilterBar extends StatefulWidget {
  const SearchFilterBar({
    super.key,
    this.searchQuery = '',
    this.onSearchChanged,
    this.searchHint = 'بحث...',
    this.debounceMs = 300,
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.activeFilterChips = const [],
    this.trailingAction,
  });

  final String searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;
  final int debounceMs;
  final VoidCallback? onFilterTap;
  final int activeFilterCount;
  final List<Widget> activeFilterChips;
  final Widget? trailingAction;

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant SearchFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery &&
        widget.searchQuery != _controller.text) {
      _controller.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    if (widget.onSearchChanged == null) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
      if (mounted) {
        widget.onSearchChanged!(value);
      }
    });
  }

  void _onClear() {
    _controller.clear();
    _debounceTimer?.cancel();
    if (widget.onSearchChanged != null) {
      widget.onSearchChanged!('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final showClear = _controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48, // Touch target minimum 48dp
                  child: TextField(
                    controller: _controller,
                    onChanged: _onChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: showClear
                          ? Semantics(
                              label: 'مسح البحث',
                              button: true,
                              child: IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: _onClear,
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.onFilterTap != null) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: Semantics(
                    label: 'تصفية النتائج',
                    button: true,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      onPressed: widget.onFilterTap,
                      child: Badge(
                        isLabelVisible: widget.activeFilterCount > 0,
                        label: Text(widget.activeFilterCount.toString()),
                        child: const Icon(Icons.filter_list_rounded),
                      ),
                    ),
                  ),
                ),
              ],
              if (widget.trailingAction != null) ...[
                const SizedBox(width: 8),
                widget.trailingAction!,
              ],
            ],
          ),
          if (widget.activeFilterChips.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.activeFilterChips,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
