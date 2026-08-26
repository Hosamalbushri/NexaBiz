class ImportSessionResult {
  const ImportSessionResult({
    required this.importedCount,
    required this.ignoredCount,
  });

  final int importedCount;
  final int ignoredCount;
}

class CustomerUpsertResult {
  const CustomerUpsertResult({
    required this.insertedCount,
    required this.updatedCount,
  });

  final int insertedCount;
  final int updatedCount;

  int get totalCount => insertedCount + updatedCount;
}
