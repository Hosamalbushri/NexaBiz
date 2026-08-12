import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'loading_controller.dart';

/// Global blocking loading controller (one instance for the app).
final loadingControllerProvider = ChangeNotifierProvider<LoadingController>((
  ref,
) {
  final controller = LoadingController();
  ref.onDispose(controller.dispose);
  return controller;
});
