import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Canonical avatar primitive adapter for NexaBiz ERP.
///
/// Wraps and delegates directly to `shadcn.Avatar` for uniform avatar rendering,
/// image loading error fallbacks, and intelligent initials generation.
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

  @override
  Widget build(BuildContext context) {
    final initials = (name != null && name!.trim().isNotEmpty)
        ? shadcn.Avatar.getInitials(name!)
        : '?';

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return shadcn.Avatar.network(
        photoUrl: imageUrl!,
        initials: initials,
        size: size,
        backgroundColor: backgroundColor,
      );
    }

    return shadcn.Avatar(
      initials: initials,
      size: size,
      backgroundColor: backgroundColor,
    );
  }
}
