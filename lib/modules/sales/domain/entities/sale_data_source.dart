/// Origin of a sale record.
enum SaleDataSource { local, imported, synchronized, external }

extension SaleDataSourceX on SaleDataSource {
  String get storageValue => name;

  static SaleDataSource fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return SaleDataSource.local;
    }
    return SaleDataSource.values.firstWhere(
      (s) => s.name == value,
      orElse: () => SaleDataSource.local,
    );
  }
}
