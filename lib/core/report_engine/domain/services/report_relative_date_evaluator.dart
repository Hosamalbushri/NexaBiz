import 'package:flutter/material.dart';

/// Preset relative date options supported by the Report Engine.
enum ReportRelativeDateRange {
  today('today'),
  yesterday('yesterday'),
  thisWeek('this_week'),
  lastWeek('last_week'),
  thisMonth('this_month'),
  lastMonth('last_month'),
  thisYear('this_year'),
  lastYear('last_year'),
  custom('custom');

  const ReportRelativeDateRange(this.storageValue);

  final String storageValue;

  String label({required bool isArabic}) {
    switch (this) {
      case ReportRelativeDateRange.today:
        return isArabic ? 'اليوم' : 'Today';
      case ReportRelativeDateRange.yesterday:
        return isArabic ? 'الأمس' : 'Yesterday';
      case ReportRelativeDateRange.thisWeek:
        return isArabic ? 'هذا الأسبوع' : 'This Week';
      case ReportRelativeDateRange.lastWeek:
        return isArabic ? 'الأسبوع الماضي' : 'Last Week';
      case ReportRelativeDateRange.thisMonth:
        return isArabic ? 'هذا الشهر' : 'This Month';
      case ReportRelativeDateRange.lastMonth:
        return isArabic ? 'الشهر الماضي' : 'Last Month';
      case ReportRelativeDateRange.thisYear:
        return isArabic ? 'هذه السنة' : 'This Year';
      case ReportRelativeDateRange.lastYear:
        return isArabic ? 'السنة الماضية' : 'Last Year';
      case ReportRelativeDateRange.custom:
        return isArabic ? 'مخصص' : 'Custom';
    }
  }

  static ReportRelativeDateRange fromStorage(String? value) {
    if (value == null || value.isEmpty) return ReportRelativeDateRange.custom;
    for (final v in ReportRelativeDateRange.values) {
      if (v.storageValue == value.toLowerCase()) return v;
    }
    return ReportRelativeDateRange.custom;
  }
}

/// Evaluates relative date options into absolute DateTime bounds.
class ReportRelativeDateEvaluator {
  const ReportRelativeDateEvaluator();

  /// Resolves relative date preset into actual start/end [DateTimeRange] bounds.
  static DateTimeRange? evaluate(
    ReportRelativeDateRange option, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (option) {
      case ReportRelativeDateRange.today:
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: today, end: end);

      case ReportRelativeDateRange.yesterday:
        final start = today.subtract(const Duration(days: 1));
        final end = DateTime(start.year, start.month, start.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case ReportRelativeDateRange.thisWeek:
        // Week starting Monday (or Sunday)
        final weekday = today.weekday;
        final start = today.subtract(Duration(days: weekday - 1));
        final end = DateTime(today.year, today.month, today.day, 23, 59, 59)
            .add(Duration(days: 7 - weekday));
        return DateTimeRange(start: start, end: end);

      case ReportRelativeDateRange.lastWeek:
        final weekday = today.weekday;
        final endOfLastWeek = today.subtract(Duration(days: weekday));
        final startOfLastWeek = endOfLastWeek.subtract(const Duration(days: 6));
        final end = DateTime(
          endOfLastWeek.year,
          endOfLastWeek.month,
          endOfLastWeek.day,
          23,
          59,
          59,
        );
        return DateTimeRange(start: startOfLastWeek, end: end);

      case ReportRelativeDateRange.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        final end = DateTime(now.year, now.month, lastDay, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case ReportRelativeDateRange.lastMonth:
        final prevMonthYear = now.month == 1 ? now.year - 1 : now.year;
        final prevMonth = now.month == 1 ? 12 : now.month - 1;
        final start = DateTime(prevMonthYear, prevMonth, 1);
        final lastDay = DateTime(prevMonthYear, prevMonth + 1, 0).day;
        final end = DateTime(prevMonthYear, prevMonth, lastDay, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case ReportRelativeDateRange.thisYear:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case ReportRelativeDateRange.lastYear:
        final start = DateTime(now.year - 1, 1, 1);
        final end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case ReportRelativeDateRange.custom:
        return null;
    }
  }
}
