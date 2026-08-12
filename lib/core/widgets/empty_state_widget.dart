import 'package:flutter/material.dart';

import 'app_empty_state.dart';

/// Legacy wrapper — prefer [AppEmptyState].
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(title: title, subtitle: subtitle, icon: icon);
  }
}
