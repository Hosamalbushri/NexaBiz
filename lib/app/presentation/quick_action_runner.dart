import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/quick_action_definition.dart';

/// Executes a pinned quick action by navigating to its route.
class QuickActionRunner {
  const QuickActionRunner();

  Future<void> run({
    required BuildContext sheetContext,
    required QuickActionDefinition action,
    VoidCallback? onClose,
  }) async {
    final router = GoRouter.of(sheetContext);
    if (onClose != null) {
      onClose();
    } else {
      Navigator.of(sheetContext).pop();
    }
    await Future<void>.delayed(Duration.zero);

    final path = action.routePath;
    if (path != null && path.isNotEmpty) {
      router.push(path);
    }
  }
}
