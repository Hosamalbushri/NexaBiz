import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class LocalDatasetRecordCounter {
  Future<int> countRecords();
}

/// Lightweight local dataset inspector to check if business data exists locally.
class LocalDatasetInspector {
  const LocalDatasetInspector([this._counters = const []]);

  final List<LocalDatasetRecordCounter> _counters;

  /// Returns the total aggregated count of business domain records in local storage.
  Future<int> inspectLocalBusinessRecordCount() async {
    var total = 0;
    for (final counter in _counters) {
      try {
        total += await counter.countRecords();
      } catch (_) {}
    }
    return total;
  }
}

final localDatasetRecordCountersProvider = StateProvider<List<LocalDatasetRecordCounter>>((ref) => []);

final localDatasetInspectorProvider = Provider<LocalDatasetInspector>((ref) {
  final counters = ref.watch(localDatasetRecordCountersProvider);
  return LocalDatasetInspector(counters);
});
