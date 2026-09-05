/// Customer status representation in the domain layer.
enum CustomerStatus {
  active('active'),
  inactive('inactive'),
  blocked('blocked');

  const CustomerStatus(this.storageValue);

  final String storageValue;

  static CustomerStatus fromStorage(String? value) {
    if (value == null) return CustomerStatus.active;
    return CustomerStatus.values.firstWhere(
      (e) => e.storageValue == value.trim().toLowerCase(),
      orElse: () => CustomerStatus.active,
    );
  }
}
