import 'package:hive/hive.dart';

import 'package:stock_count/modules/sync/sync.dart';
import '../../domain/entities/inventory_item.dart';

/// Hive type adapter for [InventoryItem] (typeId: 0).
///
/// Field reads are coerced so legacy/numeric Excel imports (e.g. barcode as
/// double) do not crash the box open path.
///
/// Fields 0–7 are legacy; 8–14 are additive sync metadata.
class InventoryItemAdapter extends TypeAdapter<InventoryItem> {
  @override
  final int typeId = 0;

  @override
  InventoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final itemCode = _asString(fields[0]);
    final createdAt = _asDateTime(fields[9]);
    final updatedAt = _asDateTime(fields[10]);

    return InventoryItem(
      itemCode: itemCode,
      itemName: _asString(fields[1]),
      barcode: _asNullableString(fields[2]),
      packSize: _asNullableInt(fields[3]),
      systemQuantity: _asDouble(fields[4]) ?? 0,
      actualQuantity: _asDouble(fields[5]),
      mainQuantity: _asDouble(fields[6]),
      subQuantity: _asDouble(fields[7]),
      id: _asNullableString(fields[8]) ?? 'legacy:$itemCode',
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      syncStatus: SyncStatusX.fromStorage(fields[11] as String?),
      lastSyncedAt: _asDateTime(fields[12]),
      version: _asNullableInt(fields[13]) ?? 1,
      deletedAt: _asDateTime(fields[14]),
    );
  }

  @override
  void write(BinaryWriter writer, InventoryItem obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.itemCode)
      ..writeByte(1)
      ..write(obj.itemName)
      ..writeByte(2)
      ..write(obj.barcode)
      ..writeByte(3)
      ..write(obj.packSize)
      ..writeByte(4)
      ..write(obj.systemQuantity)
      ..writeByte(5)
      ..write(obj.actualQuantity)
      ..writeByte(6)
      ..write(obj.mainQuantity)
      ..writeByte(7)
      ..write(obj.subQuantity)
      ..writeByte(8)
      ..write(obj.id)
      ..writeByte(9)
      ..write(obj.createdAt.toUtc().millisecondsSinceEpoch)
      ..writeByte(10)
      ..write(obj.updatedAt.toUtc().millisecondsSinceEpoch)
      ..writeByte(11)
      ..write(obj.syncStatus.storageValue)
      ..writeByte(12)
      ..write(obj.lastSyncedAt?.toUtc().millisecondsSinceEpoch)
      ..writeByte(13)
      ..write(obj.version)
      ..writeByte(14)
      ..write(obj.deletedAt?.toUtc().millisecondsSinceEpoch);
  }

  static String _asString(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    if (value is num) {
      return value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toString();
    }
    return value.toString();
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = _asString(value).trim();
    return text.isEmpty ? null : text;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value.toString());
  }

  static double? _asDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString().replaceAll(',', ''));
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value.toUtc();
    }
    final millis = _asNullableInt(value);
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
}
