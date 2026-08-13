/// Supported default currencies for company setup.
class AppCurrency {
  const AppCurrency({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.symbol,
    this.decimalDigits = 2,
  });

  final String code;
  final String nameEn;
  final String nameAr;
  final String symbol;
  final int decimalDigits;

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;
}

/// Platform catalog of common business currencies (GCC + major FX).
class AppCurrencies {
  const AppCurrencies._();

  static const AppCurrency sar = AppCurrency(
    code: 'SAR',
    nameEn: 'Saudi Riyal',
    nameAr: 'ريال سعودي',
    symbol: 'ر.س',
  );
  static const AppCurrency aed = AppCurrency(
    code: 'AED',
    nameEn: 'UAE Dirham',
    nameAr: 'درهم إماراتي',
    symbol: 'د.إ',
  );
  static const AppCurrency egp = AppCurrency(
    code: 'EGP',
    nameEn: 'Egyptian Pound',
    nameAr: 'جنيه مصري',
    symbol: 'ج.م',
  );
  static const AppCurrency kwd = AppCurrency(
    code: 'KWD',
    nameEn: 'Kuwaiti Dinar',
    nameAr: 'دينار كويتي',
    symbol: 'د.ك',
    decimalDigits: 3,
  );
  static const AppCurrency qar = AppCurrency(
    code: 'QAR',
    nameEn: 'Qatari Riyal',
    nameAr: 'ريال قطري',
    symbol: 'ر.ق',
  );
  static const AppCurrency bhd = AppCurrency(
    code: 'BHD',
    nameEn: 'Bahraini Dinar',
    nameAr: 'دينار بحريني',
    symbol: 'د.ب',
    decimalDigits: 3,
  );
  static const AppCurrency omr = AppCurrency(
    code: 'OMR',
    nameEn: 'Omani Rial',
    nameAr: 'ريال عماني',
    symbol: 'ر.ع',
    decimalDigits: 3,
  );
  static const AppCurrency jod = AppCurrency(
    code: 'JOD',
    nameEn: 'Jordanian Dinar',
    nameAr: 'دينار أردني',
    symbol: 'د.أ',
    decimalDigits: 3,
  );
  static const AppCurrency yer = AppCurrency(
    code: 'YER',
    nameEn: 'Yemeni Rial',
    nameAr: 'ريال يمني',
    symbol: 'ر.ي',
  );
  static const AppCurrency usd = AppCurrency(
    code: 'USD',
    nameEn: 'US Dollar',
    nameAr: 'دولار أمريكي',
    symbol: '\$',
  );
  static const AppCurrency eur = AppCurrency(
    code: 'EUR',
    nameEn: 'Euro',
    nameAr: 'يورو',
    symbol: '€',
  );

  /// Full catalog — pick from here when enabling a currency for the business.
  static const List<AppCurrency> all = [
    sar,
    aed,
    egp,
    kwd,
    qar,
    bhd,
    omr,
    jod,
    yer,
    usd,
    eur,
  ];

  static AppCurrency byCode(String? code) {
    final normalized = (code ?? 'SAR').trim().toUpperCase();
    for (final currency in all) {
      if (currency.code == normalized) {
        return currency;
      }
    }
    return sar;
  }
}
