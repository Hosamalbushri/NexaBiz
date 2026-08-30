import '../entities/product.dart';
import '../repositories/product_repository.dart';
import 'product_qr_payload_builder.dart';

/// Outcome of resolving a camera / manual scan into a catalog product.
class ProductScanResolution {
  const ProductScanResolution({
    required this.product,
    required this.fromProductQr,
    required this.fromCatalog,
    this.payload,
  });

  final Product product;

  /// True when the raw scan was a versioned product QR payload.
  final bool fromProductQr;

  /// True when [product] was loaded from the local catalog.
  final bool fromCatalog;

  final ProductQrPayload? payload;
}

/// Resolves barcodes, item codes, and self-contained product QR payloads.
class ProductScanResolver {
  const ProductScanResolver(
    this._repository, {
    this.qrPayloadBuilder = const ProductQrPayloadBuilder(),
  });

  final ProductRepository _repository;
  final ProductQrPayloadBuilder qrPayloadBuilder;

  Future<ProductScanResolution?> resolve(String raw) async {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final payload = qrPayloadBuilder.tryDecode(trimmed);
    if (payload != null) {
      final fromCatalog = await _resolveFromPayload(payload);
      if (fromCatalog == null) {
        // UNTRUSTED QR PAYLOAD WITH UNKNOWN PRODUCT:
        // Do NOT construct trusted Product entity from untrusted QR payload fields.
        return null;
      }
      return ProductScanResolution(
        product: fromCatalog,
        fromProductQr: true,
        fromCatalog: true,
        payload: payload,
      );
    }

    final byBarcode = await _repository.getByBarcode(trimmed);
    if (byBarcode != null) {
      return ProductScanResolution(
        product: byBarcode,
        fromProductQr: false,
        fromCatalog: true,
      );
    }

    final byCode = await _repository.getByItemCode(trimmed);
    if (byCode != null) {
      return ProductScanResolution(
        product: byCode,
        fromProductQr: false,
        fromCatalog: true,
      );
    }

    return null;
  }

  Future<Product?> _resolveFromPayload(ProductQrPayload payload) async {
    if (payload.id > 0) {
      final byId = await _repository.getById(payload.id);
      if (byId != null) {
        return byId;
      }
    }

    final barcode = payload.barcode?.trim();
    if (barcode != null && barcode.isNotEmpty) {
      final byBarcode = await _repository.getByBarcode(barcode);
      if (byBarcode != null) {
        return byBarcode;
      }
    }

    final itemCode = payload.itemCode.trim();
    if (itemCode.isNotEmpty) {
      return _repository.getByItemCode(itemCode);
    }

    return null;
  }
}
