import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Generic searchable select dropdown field for NexaBiz ERP.
///
/// Wraps `shadcn_flutter` [shadcn.Select] with a searchable popup dialog,
/// client-side filtering matching `searchQuery`, label with required indicator,
/// and error/helper text footers.
class AppSearchableSelect<T> extends StatefulWidget {
  const AppSearchableSelect({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.value,
    this.onChanged,
    this.searchValueBuilder,
    this.valueBuilder,
    this.label,
    this.hint,
    this.placeholder,
    this.searchPlaceholder = 'بحث...',
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.helperText,
    this.emptyBuilder,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String Function(T item)? searchValueBuilder;
  final Widget Function(BuildContext context, T item)? valueBuilder;
  final String? label;
  final String? hint;
  final Widget? placeholder;
  final String searchPlaceholder;
  final bool required;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? helperText;
  final Widget Function(BuildContext context)? emptyBuilder;

  @override
  State<AppSearchableSelect<T>> createState() => _AppSearchableSelectState<T>();
}

class _AppSearchableSelectState<T> extends State<AppSearchableSelect<T>> {
  String _searchQuery = '';

  String _getSearchText(T item) {
    if (widget.searchValueBuilder != null) {
      return widget.searchValueBuilder!(item);
    }
    return item.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final isInteractive = widget.enabled && !widget.readOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null && widget.label!.isNotEmpty) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label!,
                style: theme.typography.small.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isInteractive
                      ? theme.colorScheme.foreground
                      : theme.colorScheme.mutedForeground,
                ),
              ),
              if (widget.required) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(
                    color: theme.colorScheme.destructive,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
        ],
        shadcn.Select<T>(
          value: widget.value,
          onChanged: isInteractive ? widget.onChanged : null,
          enabled: isInteractive,
          placeholder: widget.placeholder ?? (widget.hint != null ? Text(widget.hint!) : null),
          itemBuilder: (context, value) {
            if (widget.valueBuilder != null) {
              return widget.valueBuilder!(context, value);
            }
            return widget.itemBuilder(context, value);
          },
          popup: (context) {
            return StatefulBuilder(
              builder: (context, setPopupState) {
                final filteredItems = widget.items.where((item) {
                  if (_searchQuery.isEmpty) return true;
                  final searchText = _getSearchText(item).toLowerCase();
                  return searchText.contains(_searchQuery.toLowerCase());
                }).toList();

                return Container(
                  constraints: const BoxConstraints(maxHeight: 300, minWidth: 220),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      shadcn.TextField(
                        placeholder: Text(widget.searchPlaceholder),
                        onChanged: (query) {
                          setPopupState(() {
                            _searchQuery = query;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: filteredItems.isEmpty
                            ? (widget.emptyBuilder != null
                                ? widget.emptyBuilder!(context)
                                : Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'لا توجد نتائج',
                                        style: theme.typography.small.copyWith(
                                          color: theme.colorScheme.mutedForeground,
                                        ),
                                      ),
                                    ),
                                  ))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  return shadcn.SelectItemButton<T>(
                                    value: item,
                                    child: widget.itemBuilder(context, item),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: theme.typography.small.copyWith(
              color: theme.colorScheme.destructive,
              fontWeight: FontWeight.w500,
            ),
          ),
        ] else if (widget.helperText != null && widget.helperText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: theme.typography.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }
}
