/// Domain errors for voucher book setup.
class VoucherBookException implements Exception {
  const VoucherBookException(this.message);

  final String message;

  @override
  String toString() => message;
}
