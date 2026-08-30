import 'package:stock_count/modules/accounting/journals/domain/services/journal_money.dart';

/// Cent-safe helpers for receipt/payment amounts (supports 3-decimal currencies like KWD/OMR/BHD).
abstract final class RpMoney {
  static double round(double value, {int decimalPlaces = 2}) {
    return JournalMoney.round(value, decimalPlaces: decimalPlaces);
  }

  static int toCents(double value, {int decimalPlaces = 2}) {
    return JournalMoney.toCents(value, decimalPlaces: decimalPlaces);
  }

  static double fromCents(int cents, {int decimalPlaces = 2}) {
    return JournalMoney.fromCents(cents, decimalPlaces: decimalPlaces);
  }
}

