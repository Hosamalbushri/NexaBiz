import 'package:flutter/material.dart';

import '../theme/tokens/tokens.dart';

/// Canonical avatar primitive for NexaBiz ERP.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = 40.0,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String? name;
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  String get _initials {
    if (name == null || name!.trim().isEmpty) return '?';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.primaryContainer;
    final fg = foregroundColor ?? scheme.onPrimaryContainer;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: bg,
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bg,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
