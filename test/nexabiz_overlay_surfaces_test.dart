import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

Widget _buildTestApp(Widget child) {
  return shadcn.ShadcnApp(
    home: shadcn.DrawerOverlay(
      child: Scaffold(
        body: Center(child: child),
      ),
    ),
  );
}

void main() {
  group('AppDrawerSheet Behavioral Tests', () {
    testWidgets('renders drawer header, content, and action buttons', (tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        _buildTestApp(
          AppDrawerSheet(
            title: 'Test Drawer',
            subtitle: 'Drawer Subtitle',
            icon: Icons.tune,
            actions: [
              TextButton(
                onPressed: () {
                  actionPressed = true;
                },
                child: const Text('Apply'),
              ),
            ],
            child: const Text('Body Content'),
          ),
        ),
      );

      expect(find.text('Test Drawer'), findsOneWidget);
      expect(find.text('Drawer Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.text('Body Content'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);

      await tester.tap(find.text('Apply'));
      expect(actionPressed, isTrue);
    });
  });

  group('AppHoverPreview Behavioral Tests', () {
    testWidgets('renders trigger child and hover preview metadata fields', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const AppHoverPreview(
            title: 'Supplier Info',
            subtitle: 'Vendor #1042',
            icon: Icons.store,
            badge: 'Active',
            fields: [
              AppHoverPreviewField(label: 'Balance', value: '\$1,250.00'),
              AppHoverPreviewField(label: 'Terms', value: 'Net 30'),
            ],
            child: Text('Hover Trigger'),
          ),
        ),
      );

      expect(find.text('Hover Trigger'), findsOneWidget);
    });
  });

  group('AppPinnedDockSheet Behavioral Tests', () {
    testWidgets('renders dock sheet with controller and snaps stages', (tester) async {
      final controller = shadcn.SheetController();

      await tester.pumpWidget(
        _buildTestApp(
          AppPinnedDockSheet(
            controller: controller,
            title: 'Staged Dock Panel',
            icon: Icons.dock,
            child: const SizedBox(
              height: 200,
              child: Text('Dock Panel Content'),
            ),
          ),
        ),
      );

      expect(find.text('Staged Dock Panel'), findsOneWidget);
      expect(find.byIcon(Icons.dock), findsOneWidget);
      expect(find.text('Dock Panel Content'), findsOneWidget);

      controller.dispose();
    });
  });
}
