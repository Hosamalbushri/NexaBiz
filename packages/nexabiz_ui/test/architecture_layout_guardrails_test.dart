import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NexaBiz UI Layout Architecture Guardrails', () {
    late Directory layoutDir;

    setUpAll(() {
      final defaultDir = Directory('lib/src/layout');
      final packageDir = Directory('packages/nexabiz_ui/lib/src/layout');
      if (defaultDir.existsSync()) {
        layoutDir = defaultDir;
      } else if (packageDir.existsSync()) {
        layoutDir = packageDir;
      } else {
        fail('Could not locate lib/src/layout directory');
      }
    });

    test('GUARD-LAYOUT-01: Layout files do not use non-directional physical left/right in EdgeInsets', () {
      final dartFiles = layoutDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          content.contains('EdgeInsets.only(left:') || content.contains('EdgeInsets.only(right:'),
          isFalse,
          reason: 'File ${file.path} contains non-directional EdgeInsets.only(left/right)! Use EdgeInsetsDirectional instead.',
        );
      }
    });

    test('GUARD-LAYOUT-02: Layout components use AppLayoutTokens or AppBreakpoints for constraints and gaps', () {
      final dartFiles = layoutDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        if (file.path.endsWith('app_layout_tokens.dart') || file.path.endsWith('app_breakpoints.dart')) {
          continue;
        }
        final content = file.readAsStringSync();
        // Ensure no hardcoded raw pixel values like maxWidth: 9999 or random padding in layout files
        expect(
          RegExp(r'maxWidth:\s*9999').hasMatch(content),
          isFalse,
          reason: 'File ${file.path} contains unauthorized hardcoded maxWidth!',
        );
      }
    });

    test('GUARD-LAYOUT-03: All core layout files are present in lib/src/layout', () {
      final expectedFiles = [
        'app_layout_tokens.dart',
        'app_breakpoints.dart',
        'app_constraints.dart',
        'app_content.dart',
        'app_section.dart',
        'app_responsive.dart',
        'app_grid.dart',
        'app_page.dart',
        'app_form_page.dart',
        'app_list_page.dart',
        'app_details_page.dart',
        'app_table_page.dart',
        'app_dashboard_page.dart',
        'app_settings_page.dart',
        'app_master_detail_page.dart',
        'layout.dart',
      ];

      for (final fileName in expectedFiles) {
        final file = File('${layoutDir.path}/$fileName');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Required central layout file $fileName does not exist in ${layoutDir.path}!',
        );
      }
    });

    test('GUARD-LAYOUT-04: Layout components do not use raw hardcoded Colors or direct Color instantiations', () {
      final dartFiles = layoutDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        if (file.path.endsWith('app_layout_tokens.dart')) continue;
        final content = file.readAsStringSync();
        expect(
          content.contains('Colors.blue') ||
              content.contains('Colors.red') ||
              content.contains('Colors.grey') ||
              content.contains('Colors.black') ||
              content.contains('Colors.white'),
          isFalse,
          reason: 'File ${file.path} contains direct Material Colors reference! Use shadcn.Theme.of(context).colorScheme instead.',
        );
      }
    });

    test('GUARD-LAYOUT-05: Layout components do not define standalone TextStyle fontSize without shadcn typography', () {
      final dartFiles = layoutDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        if (file.path.endsWith('app_layout_tokens.dart')) continue;
        final content = file.readAsStringSync();
        expect(
          RegExp(r'TextStyle\(\s*fontSize:').hasMatch(content),
          isFalse,
          reason: 'File ${file.path} contains direct TextStyle(fontSize: ...)! Use shadcn.Theme.of(context).typography instead.',
        );
      }
    });
  });
}
