import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Contract every business module must implement.
///
/// The application shell and Dashboard depend only on this abstraction—
/// never on concrete module types.
abstract class AppModule {
  /// Stable unique identifier (e.g. `inventory`).
  String get id;

  /// Localization / analytics key (not shown directly in UI).
  String get nameKey;

  /// Icon shown on the service launcher card.
  IconData get icon;

  /// Root path contributed by this module (e.g. `/inventory`).
  String get rootRoute;

  /// Whether the module is available in the launcher.
  bool get isEnabled => true;

  /// Localized display name for UI surfaces.
  String label(BuildContext context);

  /// Optional short description for the launcher card.
  String? description(BuildContext context) => null;

  /// Routes owned by this module. Composed by the app router.
  List<RouteBase> get routes;

  /// Optional Riverpod overrides contributed at module bootstrap.
  List<Override> get providerOverrides => const [];
}
