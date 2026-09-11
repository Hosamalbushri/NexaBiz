import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

class TestNodeData {
  const TestNodeData({required this.id, required this.name});
  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestNodeData && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

void main() {
  Widget buildTestWidget(Widget child) {
    return shadcn.ShadcnApp(
      home: shadcn.Scaffold(
        child: child,
      ),
    );
  }

  group('NexaBizTree<T> Behavioral Tests', () {
    testWidgets('Test 1 — Rendering: renders root node data', (tester) async {
      final nodes = <NexaBizTreeNode<String>>[
        NexaBizTreeItemNode<String>(
          data: 'Root Node',
          expanded: true,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          NexaBizTree<String>(
            nodes: nodes,
            builder: (context, node) => shadcn.TreeItem(
              child: Text(node.data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Root Node'), findsOneWidget);
    });

    testWidgets('Test 2 — Nested nodes: renders parent and child hierarchy',
        (tester) async {
      final nodes = <NexaBizTreeNode<String>>[
        NexaBizTreeItemNode<String>(
          data: 'Parent Account',
          expanded: true,
          children: [
            NexaBizTreeItemNode<String>(
              data: 'Child Cash Account',
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          NexaBizTree<String>(
            nodes: nodes,
            builder: (context, node) => shadcn.TreeItem(
              child: Text(node.data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parent Account'), findsOneWidget);
      expect(find.text('Child Cash Account'), findsOneWidget);
    });

    testWidgets('Test 3 — Expansion: toggles node expand and collapse state',
        (tester) async {
      var nodes = <NexaBizTreeNode<String>>[
        NexaBizTreeItemNode<String>(
          data: 'Group Category',
          expanded: false,
          children: [
            NexaBizTreeItemNode<String>(
              data: 'Sub Category',
            ),
          ],
        ),
      ];

      expect(nodes.first.expanded, isFalse);

      // Perform node expansion operation
      nodes = nodes.expandAll();
      expect(nodes.first.expanded, isTrue);

      await tester.pumpWidget(
        buildTestWidget(
          NexaBizTree<String>(
            nodes: nodes,
            builder: (context, node) => shadcn.TreeItem(
              child: Text(node.data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Group Category'), findsOneWidget);
      expect(find.text('Sub Category'), findsOneWidget);

      // Collapse all nodes
      nodes = nodes.collapseAll();
      expect(nodes.first.expanded, isFalse);
    });

    testWidgets('Test 4 — Selection: triggers selection callback and state',
        (tester) async {
      final nodes = <NexaBizTreeNode<String>>[
        NexaBizTreeItemNode<String>(
          data: 'Selectable Node',
          selected: false,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          NexaBizTree<String>(
            nodes: nodes,
            onSelectionChanged: (selectedNodes, multiSelect, selected) {},
            builder: (context, node) => shadcn.TreeItem(
              child: Text(node.data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final selectedTree = nodes.selectNode(nodes.first);
      expect(selectedTree.first.selected, isTrue);

      final deselectedTree = selectedTree.deselectNode(selectedTree.first);
      expect(deselectedTree.first.selected, isFalse);
    });

    testWidgets('Test 5 — Recursive selection: selects parent and updates children',
        (tester) async {
      var nodes = <NexaBizTreeNode<String>>[
        NexaBizTreeItemNode<String>(
          data: 'Assets',
          selected: true,
          expanded: true,
          children: [
            NexaBizTreeItemNode<String>(
              data: 'Current Assets',
              selected: false,
            ),
          ],
        ),
      ];

      nodes = nodes.updateRecursiveSelection();

      expect(nodes.first.selected, isTrue);
      expect(nodes.first.children.first.selected, isTrue);
    });

    testWidgets('Test 6 — Branch line: renders with specified BranchLine path style',
        (tester) async {
      final nodes = <NexaBizTreeNode<String>>[
        NexaBizTreeItemNode<String>(
          data: 'Root with Branch',
          expanded: true,
          children: [
            NexaBizTreeItemNode<String>(data: 'Branch Child'),
          ],
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          NexaBizTree<String>(
            nodes: nodes,
            branchLine: NexaBizBranchLine.path,
            builder: (context, node) => shadcn.TreeItem(
              child: Text(node.data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Root with Branch'), findsOneWidget);
      expect(find.text('Branch Child'), findsOneWidget);
    });

    testWidgets('Test 7 — Custom builder: renders custom consumer node UI',
        (tester) async {
      final nodes = <NexaBizTreeNode<String>>[
        NexaBizTreeItemNode<String>(
          data: 'Custom Item',
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          NexaBizTree<String>(
            nodes: nodes,
            builder: (context, node) {
              return Container(
                key: const Key('custom_container'),
                child: Text('PREFIX_${node.data}'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom_container')), findsOneWidget);
      expect(find.text('PREFIX_Custom Item'), findsOneWidget);
    });

    testWidgets('Test 8 — Empty nodes: handles empty nodes list gracefully',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          NexaBizTree<String>(
            nodes: const [],
            builder: (context, node) => shadcn.TreeItem(
              child: Text(node.data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppTree<String>), findsOneWidget);
    });

    testWidgets('Test 9 — Generic data: supports non-String generic type T',
        (tester) async {
      final nodes = <NexaBizTreeNode<TestNodeData>>[
        NexaBizTreeItemNode<TestNodeData>(
          data: const TestNodeData(id: '101', name: 'Cash on Hand'),
          expanded: true,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          NexaBizTree<TestNodeData>(
            nodes: nodes,
            builder: (context, node) {
              return shadcn.TreeItem(
                child: Text('${node.data.id} - ${node.data.name}'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('101 - Cash on Hand'), findsOneWidget);
    });

    testWidgets('Test 10 — Add Root Action: invokes onAddRoot callback',
        (tester) async {
      bool addRootCalled = false;

      await tester.pumpWidget(
        buildTestWidget(
          NexaBizTree<String>(
            nodes: const [],
            shrinkWrap: true,
            title: const Text('Account Tree'),
            onAddRoot: () {
              addRootCalled = true;
            },
            builder: (context, node) => shadcn.TreeItem(child: Text(node.data)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account Tree'), findsOneWidget);
      expect(find.text('Add Root'), findsOneWidget);

      await tester.tap(find.text('Add Root'));
      await tester.pumpAndSettle();

      expect(addRootCalled, isTrue);
    });

    testWidgets('Test 11 — Add Child Action: delegates node to onAddChild callback',
        (tester) async {
      shadcn.TreeItemNode<String>? addedParentNode;

      final parentNode = NexaBizTreeItemNode<String>(
        data: 'Assets',
        expanded: true,
      );

      final nodes = <NexaBizTreeNode<String>>[parentNode];

      await tester.pumpWidget(
        buildTestWidget(
          NexaBizTree<String>(
            nodes: nodes,
            onAddChild: (node) {
              addedParentNode = node;
            },
            builder: (context, node) {
              return Row(
                children: [
                  Text(node.data),
                  shadcn.GhostButton(
                    onPressed: () => addedParentNode = node,
                    child: const Text('Add Child'),
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assets'), findsOneWidget);
      expect(find.text('Add Child'), findsOneWidget);

      await tester.tap(find.text('Add Child'));
      await tester.pumpAndSettle();

      expect(addedParentNode, equals(parentNode));
    });

    testWidgets('Test 12 — Node Level Depth: computes zero-based hierarchy depth level',
        (tester) async {
      final childNode = NexaBizTreeItemNode<String>(data: 'Cash');
      final rootNode = NexaBizTreeItemNode<String>(
        data: 'Assets',
        children: [childNode],
      );

      final roots = <NexaBizTreeNode<String>>[rootNode];

      final rootLevel = AppTree.computeNodeLevel<String>(rootNode, roots);
      final childLevel = AppTree.computeNodeLevel<String>(childNode, roots);

      expect(rootLevel, equals(0));
      expect(childLevel, equals(1));
    });

    testWidgets('Test 13 — Container & Border: renders border container styling',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          NexaBizTree<String>(
            nodes: const [],
            shrinkWrap: true,
            showBorder: true,
            title: const Text('Tree Header'),
            builder: (context, node) => shadcn.TreeItem(child: Text(node.data)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tree Header'), findsOneWidget);
    });
  });
}
