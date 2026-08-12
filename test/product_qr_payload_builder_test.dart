import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/inventory/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/domain/services/product_qr_payload_builder.dart';

void main() {
  const builder = ProductQrPayloadBuilder();
  final now = DateTime.utc(2026, 1, 1);

  Product product({
    int id = 125,
    String itemCode = 'AB-001',
    String name = 'عباية سوداء',
    String? barcode = 'AB-001',
    int packSize = 1,
    double price = 25000,
  }) {
    return Product(
      id: id,
      itemCode: itemCode,
      name: name,
      barcode: barcode,
      packSize: packSize,
      price: price,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('build shows only name, price, pack, and product code in RTL', () {
    final raw = builder.build(product());

    expect(raw.contains('\u2067'), isTrue);
    expect(raw.contains('\u2069'), isTrue);
    expect(raw.contains('الاسم: عباية سوداء'), isTrue);
    expect(raw.contains('السعر: 25000'), isTrue);
    expect(raw.contains('العبوة: 1'), isTrue);
    expect(raw.contains('رمز المنتج: AB-001'), isTrue);
    expect(raw.contains('Barcode'), isFalse);
    expect(raw.contains('الباركود'), isFalse);
    expect(raw.contains('Id'), isFalse);
    expect(raw.contains('المعرّف'), isFalse);
    expect(raw.contains('http'), isFalse);

    final payload = builder.tryDecode(raw);
    expect(payload, isNotNull);
    expect(payload!.version, 2);
    expect(payload.name, 'عباية سوداء');
    expect(payload.itemCode, 'AB-001');
    expect(payload.price, 25000);
    expect(payload.packSize, 1);
    expect(payload.id, 0);
    expect(payload.barcode, isNull);
  });

  test('build rejects empty name', () {
    expect(() => builder.build(product(name: '   ')), throwsArgumentError);
  });

  test('tryDecode still supports legacy JSON payloads', () {
    const legacy =
        '{"v":1,"t":"product","id":125,"name":"عباية سوداء","itemCode":"AB-001","barcode":"AB-001","price":25000,"packSize":1}';
    final payload = builder.tryDecode(legacy);
    expect(payload, isNotNull);
    expect(payload!.version, 1);
    expect(payload.name, 'عباية سوداء');
    expect(payload.itemCode, 'AB-001');
    expect(payload.id, 125);
  });

  test('tryDecode rejects unstructured or wrong-type payloads', () {
    expect(builder.tryDecode('عباية سوداء-AB001-25000'), isNull);
    expect(
      builder.tryDecode(
        '{"v":1,"t":"order","id":1,"name":"x","itemCode":"y","price":1,"packSize":1}',
      ),
      isNull,
    );
  });
}
