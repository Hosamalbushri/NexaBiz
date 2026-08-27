import 'package:flutter/material.dart';

import '../../app/constants/app_constants.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactHeight = constraints.maxHeight < 110;
          final tightWidth = constraints.maxWidth < 140;
          final paddingVal = compactHeight || tightWidth ? 8.0 : 12.0;

          return Padding(
            padding: EdgeInsets.all(paddingVal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: compactHeight ? 10 : 13,
                      backgroundColor: color.withValues(alpha: 0.12),
                      foregroundColor: color,
                      child: Icon(icon, size: compactHeight ? 12 : 15),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          title,
                          maxLines: 1,
                          softWrap: false,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.15,
                                fontWeight: FontWeight.w600,
                                fontSize: compactHeight ? 11 : 12,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                              fontSize: compactHeight ? 26 : (tightWidth ? 30 : 38),
                              height: 1.05,
                              letterSpacing: -0.8,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
