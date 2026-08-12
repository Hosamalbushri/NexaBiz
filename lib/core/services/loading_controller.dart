import 'package:flutter/foundation.dart';

/// Centralized blocking-loader controller with reference counting.
///
/// Nested [show]/[hide] pairs keep the overlay visible until the last
/// operation finishes. Prefer [run] so the overlay always clears on errors.
class LoadingController extends ChangeNotifier {
  int _depth = 0;
  String? _message;

  /// Whether the blocking overlay should be visible.
  bool get isVisible => _depth > 0;

  /// Optional localized message shown under the spinner.
  String? get message => _message;

  /// Active nested operation count (for tests / diagnostics).
  @visibleForTesting
  int get depth => _depth;

  /// Shows the overlay (or increments the ref-count if already visible).
  void show({String? message}) {
    _depth++;
    if (message != null) {
      _message = message;
    }
    notifyListeners();
  }

  /// Updates the message without changing the ref-count.
  void updateMessage(String? message) {
    if (!isVisible) {
      return;
    }
    if (_message == message) {
      return;
    }
    _message = message;
    notifyListeners();
  }

  /// Decrements the ref-count; hides when it reaches zero.
  void hide() {
    if (_depth <= 0) {
      _depth = 0;
      return;
    }
    _depth--;
    if (_depth == 0) {
      _message = null;
    }
    notifyListeners();
  }

  /// Forces the overlay closed (e.g. recovery). Prefer [run] / [hide].
  void reset() {
    if (_depth == 0 && _message == null) {
      return;
    }
    _depth = 0;
    _message = null;
    notifyListeners();
  }

  /// Runs [action] while showing the overlay; always hides in `finally`.
  Future<T> run<T>({
    String? message,
    required Future<T> Function() action,
  }) async {
    show(message: message);
    try {
      return await action();
    } finally {
      hide();
    }
  }
}
