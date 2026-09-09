import 'package:stock_count/shared/contracts/errors/currency_exception.dart';

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

/// Platform catalog of common business currencies (GCC, Arab countries + major FX).
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
  static const AppCurrency iqd = AppCurrency(
    code: 'IQD',
    nameEn: 'Iraqi Dinar',
    nameAr: 'دينار عراقي',
    symbol: 'د.ع',
    decimalDigits: 3,
  );
  static const AppCurrency lbp = AppCurrency(
    code: 'LBP',
    nameEn: 'Lebanese Pound',
    nameAr: 'ليرة لبنانية',
    symbol: 'ل.ل',
  );
  static const AppCurrency syp = AppCurrency(
    code: 'SYP',
    nameEn: 'Syrian Pound',
    nameAr: 'ليرة سورية',
    symbol: 'ل.س',
  );
  static const AppCurrency sdg = AppCurrency(
    code: 'SDG',
    nameEn: 'Sudanese Pound',
    nameAr: 'جنيه سوداني',
    symbol: 'ج.س',
  );
  static const AppCurrency lyd = AppCurrency(
    code: 'LYD',
    nameEn: 'Libyan Dinar',
    nameAr: 'دينار ليبي',
    symbol: 'د.ل',
    decimalDigits: 3,
  );
  static const AppCurrency tnd = AppCurrency(
    code: 'TND',
    nameEn: 'Tunisian Dinar',
    nameAr: 'دينار تونسي',
    symbol: 'د.ت',
    decimalDigits: 3,
  );
  static const AppCurrency dzd = AppCurrency(
    code: 'DZD',
    nameEn: 'Algerian Dinar',
    nameAr: 'دينار جزائري',
    symbol: 'د.ج',
  );
  static const AppCurrency mad = AppCurrency(
    code: 'MAD',
    nameEn: 'Moroccan Dirham',
    nameAr: 'درهم مغربي',
    symbol: 'د.م.',
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
  static const AppCurrency gbp = AppCurrency(
    code: 'GBP',
    nameEn: 'British Pound',
    nameAr: 'جنيه إسترليني',
    symbol: '£',
  );
  static const AppCurrency chf = AppCurrency(
    code: 'CHF',
    nameEn: 'Swiss Franc',
    nameAr: 'فرنك سويسري',
    symbol: 'CHF',
  );
  static const AppCurrency jpy = AppCurrency(
    code: 'JPY',
    nameEn: 'Japanese Yen',
    nameAr: 'ين ياباني',
    symbol: '¥',
    decimalDigits: 0,
  );
  static const AppCurrency cad = AppCurrency(
    code: 'CAD',
    nameEn: 'Canadian Dollar',
    nameAr: 'دولار كندي',
    symbol: 'CA\$',
  );
  static const AppCurrency aud = AppCurrency(
    code: 'AUD',
    nameEn: 'Australian Dollar',
    nameAr: 'دولار أسترالي',
    symbol: 'A\$',
  );
  static const AppCurrency cny = AppCurrency(
    code: 'CNY',
    nameEn: 'Chinese Yuan',
    nameAr: 'يوان صيني',
    symbol: '¥',
  );
  static const AppCurrency inr = AppCurrency(
    code: 'INR',
    nameEn: 'Indian Rupee',
    nameAr: 'روبية هندية',
    symbol: '₹',
  );
  static const AppCurrency pkr = AppCurrency(
    code: 'PKR',
    nameEn: 'Pakistani Rupee',
    nameAr: 'روبية باكستانية',
    symbol: '₨',
  );
  static const AppCurrency tryCurr = AppCurrency(
    code: 'TRY',
    nameEn: 'Turkish Lira',
    nameAr: 'ليرة تركية',
    symbol: '₺',
  );
  static const AppCurrency rub = AppCurrency(
    code: 'RUB',
    nameEn: 'Russian Ruble',
    nameAr: 'روبل روسي',
    symbol: '₽',
  );
  static const AppCurrency brl = AppCurrency(
    code: 'BRL',
    nameEn: 'Brazilian Real',
    nameAr: 'ريال برازيلي',
    symbol: 'R\$',
  );
  static const AppCurrency mxn = AppCurrency(
    code: 'MXN',
    nameEn: 'Mexican Peso',
    nameAr: 'بيزو مكسيكي',
    symbol: 'Mex\$',
  );
  static const AppCurrency krw = AppCurrency(
    code: 'KRW',
    nameEn: 'South Korean Won',
    nameAr: 'وون كوري جنوبي',
    symbol: '₩',
    decimalDigits: 0,
  );
  static const AppCurrency sgd = AppCurrency(
    code: 'SGD',
    nameEn: 'Singapore Dollar',
    nameAr: 'دولار سنغافوري',
    symbol: 'S\$',
  );
  static const AppCurrency myr = AppCurrency(
    code: 'MYR',
    nameEn: 'Malaysian Ringgit',
    nameAr: 'رينغيت ماليزي',
    symbol: 'RM',
  );
  static const AppCurrency idr = AppCurrency(
    code: 'IDR',
    nameEn: 'Indonesian Rupiah',
    nameAr: 'روبية إندونيسية',
    symbol: 'Rp',
  );
  static const AppCurrency thb = AppCurrency(
    code: 'THB',
    nameEn: 'Thai Baht',
    nameAr: 'بات تايلاندي',
    symbol: '฿',
  );
  static const AppCurrency nzd = AppCurrency(
    code: 'NZD',
    nameEn: 'New Zealand Dollar',
    nameAr: 'دولار نيوزيلندي',
    symbol: 'NZ\$',
  );
  static const AppCurrency zar = AppCurrency(
    code: 'ZAR',
    nameEn: 'South African Rand',
    nameAr: 'راند جنوب إفريقي',
    symbol: 'R',
  );
  static const AppCurrency sek = AppCurrency(
    code: 'SEK',
    nameEn: 'Swedish Krona',
    nameAr: 'كرونة سويدية',
    symbol: 'kr',
  );
  static const AppCurrency nok = AppCurrency(
    code: 'NOK',
    nameEn: 'Norwegian Krone',
    nameAr: 'كرونة نرويجية',
    symbol: 'kr',
  );
  static const AppCurrency dkk = AppCurrency(
    code: 'DKK',
    nameEn: 'Danish Krone',
    nameAr: 'كرونة دنماركية',
    symbol: 'kr',
  );
  static const AppCurrency pln = AppCurrency(
    code: 'PLN',
    nameEn: 'Polish Zloty',
    nameAr: 'زلوتي بولندي',
    symbol: 'zł',
  );
  static const AppCurrency hkd = AppCurrency(
    code: 'HKD',
    nameEn: 'Hong Kong Dollar',
    nameAr: 'دولار هونغ كونغ',
    symbol: 'HK\$',
  );
  static const AppCurrency php = AppCurrency(
    code: 'PHP',
    nameEn: 'Philippine Peso',
    nameAr: 'بيزو فلبيني',
    symbol: '₱',
  );
  static const AppCurrency vnd = AppCurrency(
    code: 'VND',
    nameEn: 'Vietnamese Dong',
    nameAr: 'دونغ فيتنامي',
    symbol: '₫',
    decimalDigits: 0,
  );
  static const AppCurrency ngn = AppCurrency(
    code: 'NGN',
    nameEn: 'Nigerian Naira',
    nameAr: 'نايرا نيجيرية',
    symbol: '₦',
  );
  static const AppCurrency kes = AppCurrency(
    code: 'KES',
    nameEn: 'Kenyan Shilling',
    nameAr: 'شيلينغ كيني',
    symbol: 'KSh',
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
    iqd,
    lbp,
    syp,
    sdg,
    lyd,
    tnd,
    dzd,
    mad,
    usd,
    eur,
    gbp,
    chf,
    jpy,
    cad,
    aud,
    cny,
    inr,
    pkr,
    tryCurr,
    rub,
    brl,
    mxn,
    krw,
    sgd,
    myr,
    idr,
    thb,
    nzd,
    zar,
    sek,
    nok,
    dkk,
    pln,
    hkd,
    php,
    vnd,
    ngn,
    kes,
  ];

  static AppCurrency byCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      throw const CurrencyRequiredException('Currency code is required.');
    }
    final normalized = code.trim().toUpperCase();
    for (final currency in all) {
      if (currency.code == normalized) {
        return currency;
      }
    }
    return AppCurrency(
      code: normalized,
      nameEn: normalized,
      nameAr: normalized,
      symbol: normalized,
    );
  }
}

