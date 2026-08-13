import '../../../../core/services/loading_controller.dart';

/// Binds one page's loading flag to the global Lottie loader (ref-counted).
class SalesPageLoaderBinding {
  LoadingController? _loader;
  var _held = false;

  void sync(
    LoadingController loader, {
    required bool isLoading,
    required String message,
  }) {
    _loader = loader;
    if (isLoading && !_held) {
      loader.show(message: message);
      _held = true;
      return;
    }
    if (!isLoading && _held) {
      loader.hide();
      _held = false;
    }
  }

  /// Safe to call from [State.dispose] — does not need Riverpod [ref].
  ///
  /// Hides are deferred so we never notify [LoadingController] (a Riverpod
  /// ChangeNotifierProvider) during dispose/unmount.
  void dispose() {
    if (!_held) {
      return;
    }
    final loader = _loader;
    _held = false;
    _loader = null;
    if (loader == null) {
      return;
    }
    Future<void>(() => loader.hide());
  }
}
