import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/report_summary.dart';

class _StatusSlice {
  const _StatusSlice(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;
}

/// Doughnut chart summarizing inventory status breakdown.
class ReportStatusChart extends StatelessWidget {
  const ReportStatusChart({super.key, required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final slices = [
      _StatusSlice(localization.matched, summary.matched, AppColors.success),
      _StatusSlice(localization.shortage, summary.shortage, AppColors.warning),
      _StatusSlice(localization.overage, summary.overage, AppColors.info),
      _StatusSlice(
        localization.notCountedStatus,
        summary.remainingItems,
        Theme.of(context).colorScheme.outline,
      ),
    ].where((slice) => slice.count > 0).toList(growable: false);

    if (slices.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localization.statusBreakdown,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 220,
            child: SfCircularChart(
              legend: const Legend(
                isVisible: true,
                overflowMode: LegendItemOverflowMode.wrap,
                position: LegendPosition.bottom,
              ),
              series: <CircularSeries<_StatusSlice, String>>[
                DoughnutSeries<_StatusSlice, String>(
                  dataSource: slices,
                  xValueMapper: (slice, _) => slice.label,
                  yValueMapper: (slice, _) => slice.count,
                  pointColorMapper: (slice, _) => slice.color,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                  innerRadius: '55%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
