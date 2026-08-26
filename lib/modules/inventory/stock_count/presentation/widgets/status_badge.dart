import 'package:flutter/material.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
import '../../domain/entities/item_status.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);

    return AppStatusBadge(
      label: _label(localization, status),
      tone: _tone(status),
    );
  }

  String _label(AppLocalizations localization, ItemStatus status) {
    switch (status) {
      case ItemStatus.matched:
        return localization.matchedStatus;
      case ItemStatus.shortage:
        return localization.shortageStatus;
      case ItemStatus.overage:
        return localization.overageStatus;
      case ItemStatus.notCounted:
        return localization.notCountedStatus;
    }
  }

  AppStatusTone _tone(ItemStatus status) {
    switch (status) {
      case ItemStatus.matched:
        return AppStatusTone.success;
      case ItemStatus.shortage:
        return AppStatusTone.warning;
      case ItemStatus.overage:
        return AppStatusTone.info;
      case ItemStatus.notCounted:
        return AppStatusTone.neutral;
    }
  }
}
