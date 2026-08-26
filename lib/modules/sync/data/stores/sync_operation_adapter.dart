import 'package:hive/hive.dart';

import 'package:stock_count/modules/sync/domain/entities/sync_operation.dart';
import 'package:stock_count/modules/sync/domain/entities/sync_status.dart';

/// Hive type adapter for [SyncOperation] (typeId: 2).
class SyncOperationAdapter extends TypeAdapter<SyncOperation> {
  @override
  final int typeId = 2;

  @override
  SyncOperation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final payloadRaw = fields[5];
    final payload = <String, dynamic>{};
    if (payloadRaw is Map) {
      payloadRaw.forEach((key, value) {
        payload[key.toString()] = value;
      });
    }

    return SyncOperation(
      id: fields[0] as String? ?? '',
      entityType: fields[1] as String? ?? '',
      entityId: fields[2] as String? ?? '',
      type: SyncOperationType.values[_asInt(fields[3]) ?? 0],
      status: SyncStatusX.fromStorage(fields[4] as String?),
      payload: payload,
      createdAt:
          _asDateTime(fields[6]) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _asDateTime(fields[7]) ?? DateTime.fromMillisecondsSinceEpoch(0),
      attemptCount: _asInt(fields[8]) ?? 0,
      lastError: fields[9] as String?,
      nextRetryAt: _asDateTime(fields[10]),
      baseVersion: _asInt(fields[11]) ?? 0,
      companyId: fields[12] as String?,
      deviceId: fields[13] as String?,
      firstFailureAt: _asDateTime(fields[14]),
      lastFailureAt: _asDateTime(fields[15]),
      quarantinedAt: _asDateTime(fields[16]),
    );
  }

  @override
  void write(BinaryWriter writer, SyncOperation obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.entityType)
      ..writeByte(2)
      ..write(obj.entityId)
      ..writeByte(3)
      ..write(obj.type.index)
      ..writeByte(4)
      ..write(obj.status.storageValue)
      ..writeByte(5)
      ..write(obj.payload)
      ..writeByte(6)
      ..write(obj.createdAt.toUtc().millisecondsSinceEpoch)
      ..writeByte(7)
      ..write(obj.updatedAt.toUtc().millisecondsSinceEpoch)
      ..writeByte(8)
      ..write(obj.attemptCount)
      ..writeByte(9)
      ..write(obj.lastError)
      ..writeByte(10)
      ..write(obj.nextRetryAt?.toUtc().millisecondsSinceEpoch)
      ..writeByte(11)
      ..write(obj.baseVersion)
      ..writeByte(12)
      ..write(obj.companyId)
      ..writeByte(13)
      ..write(obj.deviceId)
      ..writeByte(14)
      ..write(obj.firstFailureAt?.toUtc().millisecondsSinceEpoch)
      ..writeByte(15)
      ..write(obj.lastFailureAt?.toUtc().millisecondsSinceEpoch)
      ..writeByte(16)
      ..write(obj.quarantinedAt?.toUtc().millisecondsSinceEpoch);
  }

  int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  DateTime? _asDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value.toUtc();
    }
    final millis = _asInt(value);
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
}
