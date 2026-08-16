/// Declares which permissions are required to open a path under a module.
///
/// Used by GoRouter redirects. Prefer listing both primary and legacy codes
/// in [anyOf] so remote and local snapshots both work.
class RouteAccessRule {
  const RouteAccessRule({
    required this.anyOf,
    this.pathEquals,
    this.pathPrefix,
    this.pathRegex,
  }) : assert(
          pathEquals != null || pathPrefix != null || pathRegex != null,
          'RouteAccessRule needs a path matcher',
        );

  /// Exact path match (e.g. `/sales/create`).
  final String? pathEquals;

  /// Prefix match (e.g. `/administration` covers nested admin routes).
  final String? pathPrefix;

  /// Full-path regex (e.g. `^/sales/\\d+/edit\$`).
  final RegExp? pathRegex;

  /// Caller needs any one of these permission codes.
  final List<String> anyOf;

  bool matches(String path) {
    if (pathEquals != null && path == pathEquals) {
      return true;
    }
    if (pathPrefix != null) {
      final prefix = pathPrefix!;
      if (path == prefix || path.startsWith('$prefix/')) {
        return true;
      }
    }
    if (pathRegex != null && pathRegex!.hasMatch(path)) {
      return true;
    }
    return false;
  }

  /// Prefer more specific rules (longer literal / denser regex source).
  int get specificity {
    if (pathEquals != null) {
      return pathEquals!.length * 10;
    }
    if (pathRegex != null) {
      return pathRegex!.pattern.length * 5;
    }
    return pathPrefix?.length ?? 0;
  }
}
