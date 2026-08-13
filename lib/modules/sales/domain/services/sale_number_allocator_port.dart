/// Allocates human-readable sale numbers (offline-safe).
///
/// Default local allocator uses plain sequential integers (`1`, `2`, …).
/// App may override with Accounting voucher-book allocation.
abstract class SaleNumberAllocatorPort {
  Future<String> allocateNext();
}

/// Sequential local allocator backed by a callback for the last used number.
class LocalSaleNumberAllocator implements SaleNumberAllocatorPort {
  LocalSaleNumberAllocator({required Future<int> Function() nextSequence})
    : _nextSequence = nextSequence;

  final Future<int> Function() _nextSequence;

  @override
  Future<String> allocateNext() async {
    final n = await _nextSequence();
    return n.toString();
  }
}
