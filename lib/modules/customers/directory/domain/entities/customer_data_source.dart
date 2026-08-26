/// Origin of a customer master record.
enum CustomerDataSource {
  /// Created and owned inside this app.
  local,

  /// Imported or maintained from an external accounting/ERP system.
  external,
}

extension CustomerDataSourceX on CustomerDataSource {
  String get storageValue => name;

  static CustomerDataSource fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return CustomerDataSource.local;
    }
    return CustomerDataSource.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CustomerDataSource.local,
    );
  }
}
