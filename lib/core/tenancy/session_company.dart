import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session company used to isolate on-device Drift/Hive files.
///
/// Authentication overrides this with the live session `currentCompanyId`.
/// Default `null` keeps historical (bootstrap) storage names.
final sessionCompanyIdProvider = Provider<String?>((ref) => null);
