/// Application-level route constants for the Universal Import Engine.
class ImportEngineRoutes {
  const ImportEngineRoutes._();

  static const String root = '/import-engine';
  static const String universal = '/import';
  static const String wizard = '$root/wizard';
  static const String jobs = '$root/jobs';
  static const String jobDetails = '$root/jobs/:id';
  static const String report = '$root/reports/:id';

  static String jobDetailsPath(String jobId) => '$root/jobs/$jobId';
  static String reportPath(String reportId) => '$root/reports/$reportId';
}

