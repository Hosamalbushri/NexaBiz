import 'package:stock_count/core/domain/services/device_document_number.dart';

/// Allocates human-readable sale numbers (offline-safe).
///
/// Numbers are plain integers. Multi-device uniqueness uses a silent numeric
/// lane per device (not shown as a device name/code in the UI).
abstract class SaleNumberAllocatorPort {
  Future<String> allocateNext();
}

/// Sequential local allocator backed by a callback for the next absolute number.
class LocalSaleNumberAllocator implements SaleNumberAllocatorPort {
  LocalSaleNumberAllocator({required Future<int> Function() nextSequence})
    : _nextSequence = nextSequence;

  final Future<int> Function() _nextSequence;

  @override
  Future<String> allocateNext() async {
    final n = await _nextSequence();
    return formatSaleNumber(n);
  }
}
