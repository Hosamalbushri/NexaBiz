import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

/// UX-only gate. Backend still enforces the same permission.
class PermissionGate extends ConsumerWidget {
  const PermissionGate({
    super.key,
    this.permission,
    required this.child,
    this.anyOf,
    this.fallback = const SizedBox.shrink(),
  });

  final String? permission;
  final List<String>? anyOf;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(currentPermissionsProvider);
    final allowed = permission != null
        ? perms.contains(permission)
        : (anyOf?.any(perms.contains) ?? false);
    return allowed ? child : fallback;
  }
}

class RoleGate extends ConsumerWidget {
  const RoleGate({
    super.key,
    required this.role,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  final String role;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(authStateProvider).session?.roles ?? const [];
    return roles.contains(role) ? child : fallback;
  }
}

bool canAccess(WidgetRef ref, String permission) {
  return ref.read(currentPermissionsProvider).contains(permission);
}
