import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Canonical generic hierarchical Tree component for NexaBiz ERP.
///
/// Wraps [shadcn.Tree] to provide standardized layout constraints,
/// generic node rendering, branch line visual connections, container border styling,
/// level depth detection, and action callbacks (`onAddRoot`, `onAddChild`, `onEdit`, `onDelete`).
class AppTree<T> extends StatelessWidget {
  /// Creates a canonical [AppTree] widget.
  const AppTree({
    super.key,
    required this.nodes,
    required this.builder,
    this.width,
    this.height,
    this.constraints,
    this.shrinkWrap = false,
    this.controller,
    this.branchLine,
    this.padding,
    this.expandIcon,
    this.allowMultiSelect,
    this.focusNode,
    this.onSelectionChanged,
    this.recursiveSelection,
    this.title,
    this.headerActions,
    this.showBorder = false,
    this.onAddRoot,
    this.onAddChild,
    this.onEdit,
    this.onDelete,
  });

  /// The root-level tree nodes to render.
  final List<shadcn.TreeNode<T>> nodes;

  /// Builder function called for each tree item node.
  final Widget Function(BuildContext context, shadcn.TreeItemNode<T> node)
      builder;

  /// Explicit width constraint for the tree surface container.
  final double? width;

  /// Explicit height constraint for the tree surface container.
  final double? height;

  /// Additional box constraints for layout.
  final BoxConstraints? constraints;

  /// Whether the tree view should size itself to its content.
  final bool shrinkWrap;

  /// Scroll controller for the tree scroll view.
  final ScrollController? controller;

  /// Style of branch lines connecting tree nodes ([shadcn.BranchLine.path], [shadcn.BranchLine.line], or [shadcn.BranchLine.none]).
  final shadcn.BranchLine? branchLine;

  /// Content padding around the tree view.
  final EdgeInsetsGeometry? padding;

  /// Whether to render expand/collapse icons for nodes with children.
  final bool? expandIcon;

  /// Whether multi-selection of nodes is permitted.
  final bool? allowMultiSelect;

  /// Focus node for keyboard navigation.
  final FocusScopeNode? focusNode;

  /// Callback when node selection state changes.
  final shadcn.TreeNodeSelectionChanged<T>? onSelectionChanged;

  /// Whether selecting a parent recursively selects descendant nodes.
  final bool? recursiveSelection;

  /// Optional header title widget or label shown in the tree container header.
  final Widget? title;

  /// Optional header action widgets rendered in the header toolbar.
  final List<Widget>? headerActions;

  /// Whether to render an explicit container border around the tree container.
  final bool showBorder;

  /// Callback invoked when adding a new root-level tree node.
  final VoidCallback? onAddRoot;

  /// Callback invoked when adding a child node under [node].
  final void Function(shadcn.TreeItemNode<T> node)? onAddChild;

  /// Callback invoked when editing [node].
  final void Function(shadcn.TreeItemNode<T> node)? onEdit;

  /// Callback invoked when deleting [node].
  final void Function(shadcn.TreeItemNode<T> node)? onDelete;

  /// Computes the zero-based hierarchy depth level of a [targetNode] within [roots].
  static int computeNodeLevel<T>(
    shadcn.TreeItemNode<T> targetNode,
    List<shadcn.TreeNode<T>> roots,
  ) {
    int? findDepth(List<shadcn.TreeNode<T>> list, int currentLevel) {
      for (final node in list) {
        if (node == targetNode) return currentLevel;
        if (node is shadcn.TreeItemNode<T> && node.children.isNotEmpty) {
          final depth = findDepth(node.children, currentLevel + 1);
          if (depth != null) return depth;
        }
      }
      return null;
    }

    return findDepth(roots, 0) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    Widget treeWidget = shadcn.Tree<T>(
      nodes: nodes,
      builder: builder,
      shrinkWrap: shrinkWrap,
      controller: controller,
      branchLine: branchLine,
      padding: padding,
      expandIcon: expandIcon,
      allowMultiSelect: allowMultiSelect,
      focusNode: focusNode,
      onSelectionChanged: onSelectionChanged,
      recursiveSelection: recursiveSelection,
    );

    if (width != null || height != null || constraints != null) {
      BoxConstraints effectiveConstraints =
          constraints ?? const BoxConstraints();
      if (width != null) {
        effectiveConstraints = effectiveConstraints.copyWith(
          minWidth: width,
          maxWidth: width,
        );
      }
      if (height != null) {
        effectiveConstraints = effectiveConstraints.copyWith(
          minHeight: height,
          maxHeight: height,
        );
      }
      treeWidget = ConstrainedBox(
        constraints: effectiveConstraints,
        child: treeWidget,
      );
    }

    final hasHeader = title != null || (headerActions != null && headerActions!.isNotEmpty) || onAddRoot != null;

    if (hasHeader || showBorder) {
      final theme = shadcn.Theme.of(context);
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(theme.radiusMd),
          border: Border.all(
            color: theme.colorScheme.border,
          ),
        ),
        child: Column(
          mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasHeader)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.border,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (title != null) Expanded(child: title!),
                    if (title == null) const Spacer(),
                    ...?headerActions,
                    if (onAddRoot != null)
                      shadcn.GhostButton(
                        onPressed: onAddRoot,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(shadcn.Icons.add, size: 16),
                            SizedBox(width: 4),
                            Text('Add Root'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            treeWidget,
          ],
        ),
      );
    }

    return treeWidget;
  }
}

/// Canonical reusable node item presentation row widget for NexaBiz trees.
class AppTreeNodeRow<T> extends StatelessWidget {
  const AppTreeNodeRow({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.level,
    this.badges,
    this.trailing,
    this.onAddChild,
    this.onEdit,
    this.onDelete,
    this.actions,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  /// Primary title widget.
  final Widget title;

  /// Optional leading icon or avatar widget.
  final Widget? leading;

  /// Optional subtitle widget.
  final Widget? subtitle;

  /// Optional zero-based depth level. Automatically displays level pill when provided.
  final int? level;

  /// Optional additional badge widgets rendered in a responsive [Wrap].
  final List<Widget>? badges;

  /// Optional trailing widget (e.g. code badge).
  final Widget? trailing;

  /// Callback to add a child under this node.
  final VoidCallback? onAddChild;

  /// Callback to edit this node.
  final VoidCallback? onEdit;

  /// Callback to delete this node.
  final VoidCallback? onDelete;

  /// Optional custom popup menu or action widgets.
  final List<Widget>? actions;

  /// Padding around the row.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasMenu = onAddChild != null || onEdit != null || onDelete != null || (actions != null && actions!.isNotEmpty);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (level != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'L${level! + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ...?badges,
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  subtitle!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
          if (hasMenu)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (val) {
                if (val == 'add_child') {
                  onAddChild?.call();
                } else if (val == 'edit') {
                  onEdit?.call();
                } else if (val == 'delete') {
                  onDelete?.call();
                }
              },
              itemBuilder: (ctx) => [
                if (onAddChild != null)
                  const PopupMenuItem(
                    value: 'add_child',
                    child: Row(
                      children: [
                        Icon(Icons.create_new_folder_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Add Sub-item'),
                      ],
                    ),
                  ),
                if (onEdit != null)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                if (onDelete != null) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
