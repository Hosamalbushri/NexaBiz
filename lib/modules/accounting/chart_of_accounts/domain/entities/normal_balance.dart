/// Side on which an account normally increases.
enum NormalBalance {
  debit,
  credit;

  String get storageValue => name;

  static NormalBalance fromStorage(String value) {
    return NormalBalance.values.firstWhere(
      (b) => b.name == value,
      orElse: () => throw ArgumentError.value(value, 'value', 'Unknown balance'),
    );
  }
}
