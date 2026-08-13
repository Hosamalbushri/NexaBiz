import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies a picked image into the app documents folder for durable logo storage.
class CompanyLogoStore {
  const CompanyLogoStore();

  static const String _relativeDir = 'company';
  static const String _filePrefix = 'logo';

  Future<Directory> _logoDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _relativeDir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Saves [sourcePath] as the company logo and returns the stored absolute path.
  Future<String> saveFromPath(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Logo source file not found');
    }
    final dir = await _logoDirectory();
    final ext = p.extension(sourcePath).toLowerCase();
    final safeExt =
        (ext == '.png' ||
            ext == '.jpg' ||
            ext == '.jpeg' ||
            ext == '.webp' ||
            ext == '.gif')
        ? ext
        : '.png';
    final target = File(p.join(dir.path, '$_filePrefix$safeExt'));
    // Remove previous logo files with other extensions.
    await clear();
    await source.copy(target.path);
    return target.path;
  }

  Future<void> clear() async {
    final dir = await _logoDirectory();
    if (!await dir.exists()) {
      return;
    }
    await for (final entity in dir.list()) {
      if (entity is File && p.basename(entity.path).startsWith(_filePrefix)) {
        await entity.delete();
      }
    }
  }
}
