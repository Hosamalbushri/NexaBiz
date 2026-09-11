import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// A canonical NexaBiz type-safe reorderable list component.
///
/// Built on top of [shadcn.SortableLayer] and [shadcn.Sortable<T>].
/// Enforces stable item identity keys to prevent widget state leakage during drag operations.
class AppSortableList<T> extends StatelessWidget {
  /// The collection of generic items to render.
  final List<T> items;

  /// Function mapping each item to a unique, stable identity Key.
  final Key Function(T item) itemKey;

  /// Builder for rendering each item.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Callback invoked when an item is reordered from [oldIndex] to [newIndex].
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// Layout axis (default: [Axis.vertical]).
  final Axis direction;

  /// Optional spacing between items.
  final double spacing;

  /// Optional fallback widget when list is empty.
  final Widget? emptyFallback;

  /// Creates an [AppSortableList].
  const AppSortableList({
    super.key,
    required this.items,
    required this.itemKey,
    required this.itemBuilder,
    this.onReorder,
    this.direction = Axis.vertical,
    this.spacing = 8.0,
    this.emptyFallback,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && emptyFallback != null) {
      return emptyFallback!;
    }

    return shadcn.SortableLayer(
      child: Flex(
        direction: direction,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0 && spacing > 0)
              direction == Axis.vertical
                  ? SizedBox(height: spacing)
                  : SizedBox(width: spacing),
            _buildSortableItem(context, i),
          ],
        ],
      ),
    );
  }

  Widget _buildSortableItem(BuildContext context, int index) {
    final item = items[index];
    final key = itemKey(item);

    return shadcn.Sortable<T>(
      key: key,
      data: shadcn.SortableData<T>(item),
      onAcceptTop: (dropped) => _handleReorder(dropped.data, index, isBefore: true),
      onAcceptBottom: (dropped) => _handleReorder(dropped.data, index, isBefore: false),
      onAcceptLeft: (dropped) => _handleReorder(dropped.data, index, isBefore: true),
      onAcceptRight: (dropped) => _handleReorder(dropped.data, index, isBefore: false),
      child: itemBuilder(context, item, index),
    );
  }

  void _handleReorder(T draggedItem, int targetIndex, {required bool isBefore}) {
    if (onReorder == null) return;
    final oldIndex = items.indexOf(draggedItem);
    if (oldIndex == -1) return;

    var newIndex = isBefore ? targetIndex : targetIndex + 1;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex != newIndex) {
      onReorder!(oldIndex, newIndex);
    }
  }
}
