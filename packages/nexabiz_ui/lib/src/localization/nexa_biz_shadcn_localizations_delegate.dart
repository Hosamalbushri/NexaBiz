import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Custom [LocalizationsDelegate] for [shadcn.ShadcnLocalizations].
///
/// Ensures that [shadcn.ShadcnLocalizations.of(context)] never returns null
/// or throws a [NullCheckError] for application-supported locales (such as Arabic `'ar'`)
/// that are not natively built into `shadcn_flutter`'s default delegate.
class NexaBizShadcnLocalizationsDelegate
    extends LocalizationsDelegate<shadcn.ShadcnLocalizations> {
  const NexaBizShadcnLocalizationsDelegate();

  /// Canonical static delegate instance.
  static const LocalizationsDelegate<shadcn.ShadcnLocalizations> delegate =
      NexaBizShadcnLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Return true for all application-supported locales to prevent
    // Localizations.of<ShadcnLocalizations>(context) from throwing null errors.
    return true;
  }

  @override
  Future<shadcn.ShadcnLocalizations> load(Locale locale) {
    if (locale.languageCode == 'en') {
      return shadcn.ShadcnLocalizations.delegate.load(locale);
    }

    // Safe fallback: For Arabic ('ar') or any unsupported locale,
    // fallback to English ShadcnLocalizations.
    return shadcn.ShadcnLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(NexaBizShadcnLocalizationsDelegate old) => false;
}
