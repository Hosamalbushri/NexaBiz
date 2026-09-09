/// Monotonic token for discarding stale async search results.
///
/// Call [next] when starting a request; apply UI updates only when
/// [isCurrent] is still true after the await completes.
class AsyncSearchToken {
  var _value = 0;

  int get value => _value;

  /// Advances and returns the token for the new in-flight request.
  int next() => ++_value;

  /// Whether [token] still matches the latest [next] call.
  bool isCurrent(int token) => token == _value;
}
