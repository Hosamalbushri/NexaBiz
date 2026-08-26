class ImportSessionResult {
  const ImportSessionResult({
    required this.importedCount,
    required this.ignoredCount,
  });

  final int importedCount;
  final int ignoredCount;
}
