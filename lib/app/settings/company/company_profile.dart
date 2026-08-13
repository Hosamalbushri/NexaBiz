import 'app_currency.dart';

/// Company / organization profile used across the platform.
class CompanyProfile {
  const CompanyProfile({
    this.name = '',
    this.legalName,
    this.logoPath,
    this.defaultCurrencyCode = 'SAR',
    this.taxNumber,
    this.commercialRegister,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.country,
    this.website,
    this.fiscalYearStartMonth = 1,
  });

  final String name;
  final String? legalName;

  /// Absolute local path to the company logo image (nullable).
  final String? logoPath;

  /// ISO-like currency code (e.g. `SAR`).
  final String defaultCurrencyCode;

  final String? taxNumber;
  final String? commercialRegister;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? country;
  final String? website;

  /// Calendar month (1–12) when the fiscal year starts.
  final int fiscalYearStartMonth;

  AppCurrency get defaultCurrency => AppCurrencies.byCode(defaultCurrencyCode);

  bool get hasLogo => logoPath != null && logoPath!.trim().isNotEmpty;

  CompanyProfile copyWith({
    String? name,
    String? legalName,
    bool clearLegalName = false,
    String? logoPath,
    bool clearLogoPath = false,
    String? defaultCurrencyCode,
    String? taxNumber,
    bool clearTaxNumber = false,
    String? commercialRegister,
    bool clearCommercialRegister = false,
    String? phone,
    bool clearPhone = false,
    String? email,
    bool clearEmail = false,
    String? address,
    bool clearAddress = false,
    String? city,
    bool clearCity = false,
    String? country,
    bool clearCountry = false,
    String? website,
    bool clearWebsite = false,
    int? fiscalYearStartMonth,
  }) {
    return CompanyProfile(
      name: name ?? this.name,
      legalName: clearLegalName ? null : (legalName ?? this.legalName),
      logoPath: clearLogoPath ? null : (logoPath ?? this.logoPath),
      defaultCurrencyCode: defaultCurrencyCode ?? this.defaultCurrencyCode,
      taxNumber: clearTaxNumber ? null : (taxNumber ?? this.taxNumber),
      commercialRegister: clearCommercialRegister
          ? null
          : (commercialRegister ?? this.commercialRegister),
      phone: clearPhone ? null : (phone ?? this.phone),
      email: clearEmail ? null : (email ?? this.email),
      address: clearAddress ? null : (address ?? this.address),
      city: clearCity ? null : (city ?? this.city),
      country: clearCountry ? null : (country ?? this.country),
      website: clearWebsite ? null : (website ?? this.website),
      fiscalYearStartMonth: fiscalYearStartMonth ?? this.fiscalYearStartMonth,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'legalName': legalName,
      'logoPath': logoPath,
      'defaultCurrencyCode': defaultCurrencyCode,
      'taxNumber': taxNumber,
      'commercialRegister': commercialRegister,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'country': country,
      'website': website,
      'fiscalYearStartMonth': fiscalYearStartMonth,
    };
  }

  factory CompanyProfile.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const CompanyProfile();
    }
    final month = map['fiscalYearStartMonth'];
    final parsedMonth = month is int
        ? month
        : int.tryParse(month?.toString() ?? '') ?? 1;
    return CompanyProfile(
      name: (map['name'] as String?)?.trim() ?? '',
      legalName: _optionalString(map['legalName']),
      logoPath: _optionalString(map['logoPath']),
      defaultCurrencyCode: AppCurrencies.byCode(
        map['defaultCurrencyCode'] as String?,
      ).code,
      taxNumber: _optionalString(map['taxNumber']),
      commercialRegister: _optionalString(map['commercialRegister']),
      phone: _optionalString(map['phone']),
      email: _optionalString(map['email']),
      address: _optionalString(map['address']),
      city: _optionalString(map['city']),
      country: _optionalString(map['country']),
      website: _optionalString(map['website']),
      fiscalYearStartMonth: parsedMonth.clamp(1, 12),
    );
  }

  static String? _optionalString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}
