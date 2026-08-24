/// Explicit mode for user authentication context.
enum AuthenticationMode {
  /// Local offline authentication using stored salted hashes.
  local,

  /// Server / remote synchronization authentication using OAuth/JWT.
  sync;

  /// Returns true if this is [AuthenticationMode.sync].
  bool get isSync => this == AuthenticationMode.sync;

  /// Returns true if this is [AuthenticationMode.local].
  bool get isLocal => this == AuthenticationMode.local;
}
