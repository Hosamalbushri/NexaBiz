import 'dart:async';

import 'package:stock_count/modules/sales/invoices/domain/services/sale_autocomplete_defaults.dart';

export 'package:stock_count/modules/sales/invoices/domain/services/sale_autocomplete_defaults.dart';

/// Debounced search with generation tokens so stale async results are ignored.
@Deprecated('Use AsyncSearchToken and AppAsyncAutocompleteField instead')
final class AutocompleteSearchSession {
  Timer? _debounce;
  var _token = 0;

  /// Cancels any pending debounce and schedules [run] after [delay].
  ///
  /// [run] receives the token for this schedule; pass it back through
  /// [isCurrent] after an await.
  void schedule({
    Duration delay = const Duration(
      milliseconds: SaleAutocompleteDefaults.debounceMs,
    ),
    required void Function(int token) run,
  }) {
    _debounce?.cancel();
    final token = ++_token;
    _debounce = Timer(delay, () => run(token));
  }

  /// Invalidates in-flight work (e.g. when the query becomes too short).
  void invalidate() {
    _debounce?.cancel();
    _token++;
  }

  bool isCurrent(int token) => token == _token;

  void dispose() {
    _debounce?.cancel();
  }
}

