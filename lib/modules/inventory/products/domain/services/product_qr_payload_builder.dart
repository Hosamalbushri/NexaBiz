import 'dart:convert';

import 'package:stock_count/core/utils/grouped_decimal_input.dart';
import '../entities/product.dart';

/// Versioned, self-contained product QR payload (no URLs / network).
///
/// New codes use a camera-friendly plain-text layout so any phone camera can
/// show product details without this app. Legacy compact JSON remains readable.
///
/// Compression can be introduced later behind [encode] / [tryDecode].
class ProductQrPayloadBuilder {
  const ProductQrPayloadBuilder();

  /// Human-readable text format (current).
  static const int currentVersion = 2;

  /// Legacy compact JSON format.
  static const int legacyJsonVersion = 1;

  static const String typeProduct = 'product';

  /// Unicode RIGHT-TO-LEFT ISOLATE / POP DIRECTIONAL ISOLATE.
  static const String _rtlIsolate = '\u2067';
  static const String _popDirectional = '\u2069';

  /// Builds the QR string for [product]. Throws [ArgumentError] when required
  /// fields are empty.
  ///
  /// Camera apps show only: name, price, pack size, product code (RTL).
  String build(Product product) {
    final name = _singleLine(product.name);
    final itemCode = _singleLine(product.itemCode);
    if (name.isEmpty || itemCode.isEmpty) {
      throw ArgumentError('Product name and item code are required for QR.');
    }

    final price = _formatPrice(product.price);
    // Force RTL so phone camera apps render Arabic layout correctly,
    // including lines that mix Arabic labels with Latin codes / digits.
    final content =
        'الاسم: $name\n'
        'السعر: $price\n'
        'العبوة: ${product.packSize}\n'
        'رمز المنتج: $itemCode';
    return '$_rtlIsolate$content$_popDirectional';
  }

  /// Serializes a payload map (legacy/tests). Prefer [build] for QR output.
  String encode(Map<String, Object?> map) => jsonEncode(map);

  /// Parses a QR string into a typed payload, or `null` if invalid / unsupported.
  ProductQrPayload? tryDecode(String raw) {
    final trimmed = _stripDirectionalMarks(raw).trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final fromText = _tryDecodeText(trimmed);
    if (fromText != null) {
      return fromText;
    }
    return _tryDecodeJson(trimmed);
  }

  ProductQrPayload? _tryDecodeText(String raw) {
    final lines = raw
        .split(RegExp(r'\r?\n'))
        .map((line) => _stripDirectionalMarks(line).trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty || !_looksLikeLabeledProduct(lines)) {
      return null;
    }

    final fields = <String, String>{};
    for (final line in lines) {
      final separator = line.indexOf(':');
      if (separator <= 0) {
        continue;
      }
      final key = line.substring(0, separator).trim().toLowerCase();
      final value = line.substring(separator + 1).trim();
      if (value.isEmpty) {
        continue;
      }
      fields[_normalizeKey(key)] = value;
    }

    final name = fields['name'];
    final itemCode = fields['itemcode'];
    final priceRaw = fields['price'];
    final packRaw = fields['pack'];
    if (name == null ||
        itemCode == null ||
        priceRaw == null ||
        packRaw == null) {
      return null;
    }

    final price = parseGroupedDecimal(priceRaw);
    final packSize = int.tryParse(packRaw);
    if (price == null ||
        packSize == null ||
        packSize < 1 ||
        name.isEmpty ||
        itemCode.isEmpty) {
      return null;
    }

    final idRaw = fields['id'];
    final id = idRaw == null ? 0 : int.tryParse(idRaw);
    if (id == null) {
      return null;
    }

    final barcode = fields['barcode'];
    return ProductQrPayload(
      version: currentVersion,
      id: id,
      name: name,
      itemCode: itemCode,
      price: price,
      packSize: packSize,
      barcode: barcode == null || barcode.isEmpty ? null : barcode,
    );
  }

  ProductQrPayload? _tryDecodeJson(String raw) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }

    if (decoded is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(decoded);
    final version = map['v'];
    final type = map['t'];
    if (version is! int || version < 1 || type != typeProduct) {
      return null;
    }

    final id = map['id'];
    final name = map['name'];
    final itemCode = map['itemCode'];
    final price = map['price'];
    final packSize = map['packSize'];
    if (id is! int ||
        name is! String ||
        itemCode is! String ||
        name.trim().isEmpty ||
        itemCode.trim().isEmpty) {
      return null;
    }

    final parsedPrice = switch (price) {
      num value => value.toDouble(),
      _ => null,
    };
    final parsedPackSize = switch (packSize) {
      int value => value,
      num value => value.toInt(),
      _ => null,
    };
    if (parsedPrice == null || parsedPackSize == null || parsedPackSize < 1) {
      return null;
    }

    final barcodeRaw = map['barcode'];
    final barcode = barcodeRaw is String && barcodeRaw.trim().isNotEmpty
        ? barcodeRaw.trim()
        : null;

    return ProductQrPayload(
      version: version,
      id: id,
      name: name.trim(),
      itemCode: itemCode.trim(),
      price: parsedPrice,
      packSize: parsedPackSize,
      barcode: barcode,
    );
  }

  bool _looksLikeLabeledProduct(List<String> lines) {
    var hits = 0;
    for (final line in lines) {
      final key = line.split(':').first.trim().toLowerCase();
      final normalized = _normalizeKey(key);
      if (normalized == 'name' ||
          normalized == 'itemcode' ||
          normalized == 'price' ||
          normalized == 'pack') {
        hits++;
      }
    }
    return hits >= 4;
  }

  String _normalizeKey(String key) {
    final cleaned = key
        .replaceAll(RegExp(r'\s*/\s*'), '/')
        .trim()
        .toLowerCase();

    final parts = cleaned
        .split('/')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);
    for (final part in parts) {
      final normalized = _normalizeSingleKey(part);
      if (normalized != null) {
        return normalized;
      }
    }
    return cleaned.replaceAll(' ', '');
  }

  String? _normalizeSingleKey(String key) {
    switch (key) {
      case 'الاسم':
      case 'name':
        return 'name';
      case 'الكود':
      case 'رمز المنتج':
      case 'code':
      case 'sku':
      case 'itemcode':
      case 'item code':
      case 'product code':
        return 'itemcode';
      case 'الباركود':
      case 'barcode':
        return 'barcode';
      case 'السعر':
      case 'price':
        return 'price';
      case 'العبوة':
      case 'pack':
      case 'pack size':
      case 'packsize':
        return 'pack';
      case 'المعرف':
      case 'المعرّف':
      case 'id':
        return 'id';
      default:
        return null;
    }
  }

  String _singleLine(String value) =>
      value.trim().replaceAll(RegExp(r'[\r\n]+'), ' ');

  String _stripDirectionalMarks(String value) {
    return value.replaceAll(
      RegExp(r'[\u200E\u200F\u202A-\u202E\u2066-\u2069]'),
      '',
    );
  }

  String _formatPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.toStringAsFixed(0);
    }
    return price.toStringAsFixed(2);
  }
}

/// Decoded product QR payload (scanner-compatible).
class ProductQrPayload {
  const ProductQrPayload({
    required this.version,
    required this.id,
    required this.name,
    required this.itemCode,
    required this.price,
    required this.packSize,
    this.barcode,
  });

  final int version;

  /// May be `0` for text QR codes that omit the catalog id.
  final int id;
  final String name;
  final String itemCode;
  final double price;
  final int packSize;
  final String? barcode;

  String get type => ProductQrPayloadBuilder.typeProduct;
}
