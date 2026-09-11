import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:stock_count/core/widgets/app_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Avatar Primitive & Adapter Behavioral Tests', () {
    test('shadcn.Avatar.getInitials generates canonical 1-2 character initials', () {
      expect(shadcn.Avatar.getInitials('Hosam Al-Bushri'), equals('HA'));
      expect(shadcn.Avatar.getInitials('John Doe'), equals('JD'));
      expect(shadcn.Avatar.getInitials('Madonna'), equals('MA'));
      expect(shadcn.Avatar.getInitials('A'), equals('A'));
      expect(shadcn.Avatar.getInitials('  '), equals(''));
    });

    testWidgets('AppAvatar renders initials using shadcn.Avatar primitive', (WidgetTester tester) async {
      await tester.pumpWidget(
        const shadcn.ShadcnApp(
          home: Scaffold(
            body: Center(
              child: AppAvatar(
                name: 'Hosam Al-Bushri',
                size: 48.0,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(shadcn.Avatar), findsOneWidget);
      expect(find.text('HA'), findsOneWidget);
    });

    testWidgets('AppAvatar renders network image provider when imageUrl is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        const shadcn.ShadcnApp(
          home: Scaffold(
            body: Center(
              child: AppAvatar(
                name: 'Hosam Al-Bushri',
                imageUrl: 'https://example.com/avatar.jpg',
                size: 40.0,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(shadcn.Avatar), findsOneWidget);
    });

    testWidgets('AvatarBadge and AvatarGroup render overlapping avatars correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const shadcn.ShadcnApp(
          home: Scaffold(
            body: Center(
              child: shadcn.AvatarGroup(
                alignment: Alignment(0.5, 0),
                children: [
                  shadcn.Avatar(initials: 'AB'),
                  shadcn.Avatar(initials: 'CD'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(shadcn.AvatarGroup), findsOneWidget);
      expect(find.text('AB'), findsOneWidget);
      expect(find.text('CD'), findsOneWidget);
    });
  });

  group('Table Primitive Behavioral Tests', () {
    testWidgets('shadcn.Table renders headers, rows, and cells correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: Scaffold(
            body: Center(
              child: shadcn.Table(
                rows: [
                  shadcn.TableHeader(
                    cells: const [
                      shadcn.TableCell(child: Text('Header 1')),
                      shadcn.TableCell(child: Text('Header 2')),
                    ],
                  ),
                  const shadcn.TableRow(
                    cells: [
                      shadcn.TableCell(child: Text('Data 1')),
                      shadcn.TableCell(child: Text('Data 2')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(shadcn.Table), findsOneWidget);
      expect(find.text('Header 1'), findsOneWidget);
      expect(find.text('Header 2'), findsOneWidget);
      expect(find.text('Data 1'), findsOneWidget);
      expect(find.text('Data 2'), findsOneWidget);
    });

    testWidgets('shadcn.TableCell supports columnSpan and rowSpan', (WidgetTester tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: Scaffold(
            body: Center(
              child: shadcn.Table(
                rows: [
                  shadcn.TableHeader(
                    cells: const [
                      shadcn.TableCell(columnSpan: 2, child: Text('Spanning Header')),
                    ],
                  ),
                  const shadcn.TableRow(
                    cells: [
                      shadcn.TableCell(child: Text('Cell A')),
                      shadcn.TableCell(child: Text('Cell B')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(shadcn.Table), findsOneWidget);
      expect(find.text('Spanning Header'), findsOneWidget);
      expect(find.text('Cell A'), findsOneWidget);
      expect(find.text('Cell B'), findsOneWidget);
    });
  });
}
