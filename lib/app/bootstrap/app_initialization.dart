import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_bootstrap.dart';

/// Minimum time the splash stays visible after launch (includes bootstrap work).
const Duration kMinSplashDuration = Duration(milliseconds: 1600);

/// Drives application startup. Watched by [SplashPage]; invalidate to retry.
final appInitializationProvider = FutureProvider<void>((ref) async {
  final started = DateTime.now();
  await AppBootstrap.initialize(ref);

  final elapsed = DateTime.now().difference(started);
  if (elapsed < kMinSplashDuration) {
    await Future<void>.delayed(kMinSplashDuration - elapsed);
  }
});
