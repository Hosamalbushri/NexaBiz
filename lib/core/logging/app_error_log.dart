import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Append-only local error log (no third-party crash service).
///
/// Writes under the app documents directory: `logs/app_errors.log`.
/// Failures while logging are swallowed so crash handling never recurses.
class AppErrorLog {
  AppErrorLog._();

  static const _relativePath = 'logs/app_errors.log';
  static const _maxBytes = 512 * 1024;

  static Future<void> record(
    Object error,
    StackTrace? stack, {
    String source = 'app',
  }) async {
    final stamp = DateTime.now().toUtc().toIso8601String();
    final buffer = StringBuffer()
      ..writeln('--- $stamp [$source] ---')
      ..writeln(error);
    if (stack != null) {
      buffer.writeln(stack);
    }
    buffer.writeln();

    final text = buffer.toString();
    debugPrint(text);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, _relativePath));
      await file.parent.create(recursive: true);
      if (await file.exists() && await file.length() > _maxBytes) {
        await file.writeAsString(text, mode: FileMode.write, flush: true);
      } else {
        await file.writeAsString(text, mode: FileMode.append, flush: true);
      }
    } catch (_) {
      // Never throw from the error logger.
    }
  }
}

/// Installs Flutter / platform / zone error hooks that call [AppErrorLog].
void installAppErrorLogging() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      AppErrorLog.record(
        details.exceptionAsString(),
        details.stack,
        source: 'flutter',
      ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(AppErrorLog.record(error, stack, source: 'platform'));
    return true;
  };
}
