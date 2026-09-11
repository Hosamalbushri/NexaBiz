import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:stock_count/core/widgets/app_chip.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

void main() {
  group('NexaBiz Chip Governance Tests', () {
    testWidgets('shadcn.Chip renders child and responds to tap', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.ComponentTheme(
            data: const shadcn.ChipTheme(),
            child: shadcn.Chip(
              onPressed: () => pressed = true,
              leading: const shadcn.Icon(shadcn.LucideIcons.tag),
              trailing: shadcn.ChipButton(
                onPressed: () {},
                child: const shadcn.Icon(shadcn.LucideIcons.x),
              ),
              child: const shadcn.Text('Sales Filter'),
            ),
          ),
        ),
      );

      expect(find.text('Sales Filter'), findsOneWidget);
      await tester.tap(find.text('Sales Filter'));
      expect(pressed, isTrue);
    });

    testWidgets('AppChip wraps shadcn.Chip natively for choice and action variants', (tester) async {
      bool selected = false;
      bool actionPressed = false;

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Column(
            children: [
              AppChip(
                label: 'Choice Chip',
                selected: selected,
                onSelected: (val) => selected = val,
                variant: AppChipVariant.choice,
              ),
              AppChip(
                label: 'Action Chip',
                onPressed: () => actionPressed = true,
                variant: AppChipVariant.action,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Choice Chip'), findsOneWidget);
      expect(find.text('Action Chip'), findsOneWidget);

      await tester.tap(find.text('Choice Chip'));
      expect(selected, isTrue);

      await tester.tap(find.text('Action Chip'));
      expect(actionPressed, isTrue);
    });
  });

  group('NexaBiz Command Governance Tests', () {
    testWidgets('shadcn.Command performs real-time search filtering', (tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Command(
            debounceDuration: Duration.zero,
            builder: (context, query) async* {
              final items = [
                'Create Invoice',
                'View Products',
                'Generate Report',
              ];
              final filtered = query == null || query.isEmpty
                  ? items
                  : items.where((item) => item.toLowerCase().contains(query.toLowerCase())).toList();

              yield [
                shadcn.CommandCategory(
                  title: const shadcn.Text('Actions'),
                  children: filtered
                      .map((item) => shadcn.CommandItem(
                            title: shadcn.Text(item),
                            onTap: () {},
                          ))
                      .toList(),
                )
              ];
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Create Invoice'), findsOneWidget);
      expect(find.text('View Products'), findsOneWidget);

      await tester.enterText(find.byType(shadcn.TextField), 'Invoice');
      await tester.pumpAndSettle();

      expect(find.text('Create Invoice'), findsOneWidget);
      expect(find.text('View Products'), findsNothing);
    });
  });

  group('NexaBiz Dropdown & Select Governance Tests', () {
    testWidgets('shadcn.DropdownMenu renders items correctly', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.DropdownMenu(
            children: [
              shadcn.MenuButton(
                onPressed: (context) {
                  tapped = true;
                },
                child: const shadcn.Text('Edit Profile'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Edit Profile'), findsOneWidget);
      await tester.tap(find.text('Edit Profile'));
      expect(tapped, isTrue);
    });

    testWidgets('AppDropdown uses shadcn.Select natively', (tester) async {
      String? selectedValue = 'SAR';

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: AppDropdown<String>(
            label: 'Currency',
            value: selectedValue,
            items: const [
              AppDropdownItem(value: 'SAR', label: 'Saudi Riyal (SAR)'),
              AppDropdownItem(value: 'USD', label: 'US Dollar (USD)'),
            ],
            onChanged: (val) => selectedValue = val,
          ),
        ),
      );

      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Saudi Riyal (SAR)'), findsOneWidget);
    });
  });

  group('NexaBiz OverflowMarquee Governance Tests', () {
    testWidgets('shadcn.OverflowMarquee renders child text without layout errors', (tester) async {
      await tester.pumpWidget(
        const shadcn.ShadcnApp(
          home: shadcn.SizedBox(
            width: 100,
            child: shadcn.OverflowMarquee(
              duration: Duration(seconds: 2),
              child: shadcn.Text('This is a very long text string that will overflow the container'),
            ),
          ),
        ),
      );

      expect(find.text('This is a very long text string that will overflow the container'), findsOneWidget);
    });
  });
}
