import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/sales/invoices/presentation/utils/sale_autocomplete.dart';

void main() {
  test('AutocompleteSearchSession ignores stale tokens', () async {
    final session = AutocompleteSearchSession();
    final completed = <int>[];

    session.schedule(
      delay: const Duration(milliseconds: 40),
      run: (token) async {
        await Future<void>.delayed(const Duration(milliseconds: 60));
        if (session.isCurrent(token)) {
          completed.add(token);
        }
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));
    session.schedule(
      delay: const Duration(milliseconds: 40),
      run: (token) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (session.isCurrent(token)) {
          completed.add(token);
        }
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(completed, hasLength(1));
    session.dispose();
  });

  test('invalidate cancels pending debounce work', () async {
    final session = AutocompleteSearchSession();
    var ran = false;
    session.schedule(
      delay: const Duration(milliseconds: 50),
      run: (_) => ran = true,
    );
    session.invalidate();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(ran, isFalse);
    session.dispose();
  });
}
