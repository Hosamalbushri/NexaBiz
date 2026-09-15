import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NexaBiz Application Architecture & Performance Guardrails', () {
    late Directory libDir;

    setUpAll(() {
      libDir = Directory('lib');
      if (!libDir.existsSync()) {
        fail('Could not locate lib directory');
      }
    });

    test('GUARD-01: flex_color_scheme is never imported in application code', () {
      final dartFiles = libDir
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

    test('GUARD-02: Material DropdownButton is not instantiated in application presentation screens', () {
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          RegExp(r'\bDropdownButton\(').hasMatch(content),
          isFalse,
          reason: 'File ${file.path} contains unauthorized Material DropdownButton instantiation!',
        );
      }
    });

    test('GUARD-03: Material buttons (ElevatedButton, TextButton, OutlinedButton) are replaced by AppButton', () {
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final forbidden in ['ElevatedButton(', 'TextButton(', 'OutlinedButton(']) {
          expect(
            content.contains(forbidden),
            isFalse,
            reason: 'File ${file.path} contains direct Material button $forbidden instead of AppButton!',
          );
        }
      }
    });

    test('GUARD-04: Material Card widget is replaced by canonical AppCard/AppSurface', () {
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          RegExp(r'(?<!shadcn\.)\bCard\(').hasMatch(content),
          isFalse,
          reason: 'File ${file.path} contains direct Material Card widget instead of AppCard/AppSurface!',
        );
      }
    });

    test('GUARD-05: Direct fallback shadcn.ThemeData is never instantiated inline in app screens', () {
      final dartFiles = libDir
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
  });
}
