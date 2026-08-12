import 'package:hive/hive.dart';

import '../../../../core/notifications/app_notification.dart';
import '../../../../core/notifications/notification_type.dart';

/// Hive type adapter for [AppNotification] (typeId: 1).
class AppNotificationAdapter extends TypeAdapter<AppNotification> {
  @override
  final int typeId = 1;

  @override
  AppNotification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return AppNotification(
      id: fields[0] as String? ?? '',
      type: NotificationType.values[_asInt(fields[1]) ?? 0],
      category: NotificationCategory.values[_asInt(fields[2]) ?? 0],
      title: fields[3] as String? ?? '',
      message: fields[4] as String?,
      createdAt: fields[5] is DateTime
          ? fields[5] as DateTime
          : DateTime.fromMillisecondsSinceEpoch(_asInt(fields[5]) ?? 0),
      isRead: fields[6] as bool? ?? false,
      isPersistent: fields[7] as bool? ?? false,
      actionLabel: fields[8] as String?,
      actionRoute: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppNotification obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type.index)
      ..writeByte(2)
      ..write(obj.category.index)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.message)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.isRead)
      ..writeByte(7)
      ..write(obj.isPersistent)
      ..writeByte(8)
      ..write(obj.actionLabel)
      ..writeByte(9)
      ..write(obj.actionRoute);
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
}
