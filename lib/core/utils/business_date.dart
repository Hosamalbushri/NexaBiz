/// Calendar business day helpers for ledgers and statement filters.
///
/// UI date pickers and `DateTime.now()` are local wall-clock values. Storing or
/// filtering via `.toUtc().year/month/day` shifts the calendar day for timezones
/// east of UTC (e.g. Asia/Aden), which drops same-day invoices from statements.
class BusinessDate {
  const BusinessDate._();

  /// Local Y-M-D of [value], encoded as UTC midnight (date-only epoch).
  static DateTime utcDay(DateTime value) {
    final local = value.isUtc ? value.toLocal() : value;
    return DateTime.utc(local.year, local.month, local.day);
  }

  /// Epoch ms for [utcDay].
  static int utcDayMs(DateTime value) => utcDay(value).millisecondsSinceEpoch;
}
