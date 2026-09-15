import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NexaBiz UI Architecture Guardrails', () {
    late Directory srcDir;

    setUpAll(() {
      final defaultDir = Directory('lib/src');
      final packageDir = Directory('packages/nexabiz_ui/lib/src');
      if (defaultDir.existsSync()) {
        srcDir = defaultDir;
      } else if (packageDir.existsSync()) {
        srcDir = packageDir;
      } else {
        fail('Could not locate lib/src directory');
      }
    });

    test('GUARD-01: flex_color_scheme is never imported', () {
      final dartFiles = srcDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          content.contains('flex_color_scheme'),
          isFalse,
          reason: 'File ${file.path} contains unauthorized flex_color_scheme import!',
        );
      }
    });

    test('GUARD-02: Fallback inline shadcn.ThemeData is never instantiated', () {
      final dartFiles = srcDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          content.contains('dependOnInheritedWidgetOfExactType<shadcn.Theme>'),
          isFalse,
          reason: 'File ${file.path} contains inline fallback shadcn.Theme check!',
        );
      }
    });

    test('GUARD-03: Material DropdownButton is not used in nexabiz_ui components', () {
      final dartFiles = srcDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          content.contains('DropdownButton'),
          isFalse,
          reason: 'File ${file.path} contains unauthorized Material DropdownButton!',
        );
      }
    });

    test('GUARD-04: Direct Material buttons (ElevatedButton, TextButton, OutlinedButton) instantiation is not used in nexabiz_ui widgets', () {
      final widgetsDir = Directory('${srcDir.path}/widgets');
      if (!widgetsDir.existsSync()) return;

      final dartFiles = widgetsDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final forbidden in ['ElevatedButton(', 'TextButton(', 'OutlinedButton(']) {
          expect(
            content.contains(forbidden),
            isFalse,
            reason: 'File ${file.path} contains unauthorized Material button $forbidden!',
          );
        }
      }
    });

    test('GUARD-05: Material Card widget instantiation is not used directly in nexabiz_ui widgets', () {
      final widgetsDir = Directory('${srcDir.path}/widgets');
      if (!widgetsDir.existsSync()) return;

      final dartFiles = widgetsDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        if (file.path.endsWith('app_card.dart')) continue;
        final content = file.readAsStringSync();
        expect(
          RegExp(r'(?<!shadcn\.)\bCard\(').hasMatch(content),
          isFalse,
          reason: 'File ${file.path} contains direct Material Card widget!',
        );
      }

    });

    test('GUARD-06: Third-party form packages like flutter_form_builder are not imported', () {
      final dartFiles = srcDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          content.contains('flutter_form_builder'),
          isFalse,
          reason: 'File ${file.path} contains unauthorized flutter_form_builder import!',
        );
      }
    });
  });
}
