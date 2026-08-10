import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Platform'**
  String get appTitle;

  /// No description provided for @servicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesTitle;

  /// No description provided for @servicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a business module to get started.'**
  String get servicesSubtitle;

  /// No description provided for @moduleInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get moduleInventory;

  /// No description provided for @moduleInventoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Counting, import, and stock reports.'**
  String get moduleInventoryDescription;

  /// No description provided for @modulePlaceholderMessage.
  ///
  /// In en, this message translates to:
  /// **'This module is registered and ready. Business features will be added in the next stages.'**
  String get modulePlaceholderMessage;

  /// No description provided for @inventoryOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get inventoryOverview;

  /// No description provided for @inventoryCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory Count'**
  String get inventoryCountTitle;

  /// No description provided for @inventoryCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search items and enter counted quantities.'**
  String get inventoryCountSubtitle;

  /// No description provided for @searchItems.
  ///
  /// In en, this message translates to:
  /// **'Search Items'**
  String get searchItems;

  /// No description provided for @searchItemsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or code'**
  String get searchItemsHint;

  /// No description provided for @searchResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String searchResultsCount(int count);

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noItemSelected.
  ///
  /// In en, this message translates to:
  /// **'No item selected'**
  String get noItemSelected;

  /// No description provided for @saveCount.
  ///
  /// In en, this message translates to:
  /// **'Save Count'**
  String get saveCount;

  /// No description provided for @editCount.
  ///
  /// In en, this message translates to:
  /// **'Edit Count'**
  String get editCount;

  /// No description provided for @editCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Count'**
  String get editCountTitle;

  /// No description provided for @editCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the new count quantities.'**
  String get editCountSubtitle;

  /// No description provided for @countSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Count saved successfully.'**
  String get countSavedSuccess;

  /// No description provided for @negativeQuantityNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Negative quantities are not allowed.'**
  String get negativeQuantityNotAllowed;

  /// No description provided for @packSize.
  ///
  /// In en, this message translates to:
  /// **'Pack Size'**
  String get packSize;

  /// No description provided for @packSizeMissingWarning.
  ///
  /// In en, this message translates to:
  /// **'This product has no pack size. Enter the pack size before counting.'**
  String get packSizeMissingWarning;

  /// No description provided for @packSizeIncompleteMarkerWarning.
  ///
  /// In en, this message translates to:
  /// **'The product name has * without a pack number. Enter the pack size to continue.'**
  String get packSizeIncompleteMarkerWarning;

  /// No description provided for @packSizeInvalidWarning.
  ///
  /// In en, this message translates to:
  /// **'The pack size in the product name is invalid. Enter a valid pack size.'**
  String get packSizeInvalidWarning;

  /// No description provided for @packSizeRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 24'**
  String get packSizeRequiredHint;

  /// No description provided for @savePackSize.
  ///
  /// In en, this message translates to:
  /// **'Save Pack Size'**
  String get savePackSize;

  /// No description provided for @packSizeSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pack size saved successfully.'**
  String get packSizeSavedSuccess;

  /// No description provided for @packSizeRequiredBeforeCount.
  ///
  /// In en, this message translates to:
  /// **'Enter the pack size before counting.'**
  String get packSizeRequiredBeforeCount;

  /// No description provided for @invalidPackSize.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid pack size greater than zero.'**
  String get invalidPackSize;

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get codeLabel;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @mainQuantity.
  ///
  /// In en, this message translates to:
  /// **'Main Quantity'**
  String get mainQuantity;

  /// No description provided for @subQuantity.
  ///
  /// In en, this message translates to:
  /// **'Sub Quantity'**
  String get subQuantity;

  /// No description provided for @systemQuantity.
  ///
  /// In en, this message translates to:
  /// **'System Quantity'**
  String get systemQuantity;

  /// No description provided for @actualQuantity.
  ///
  /// In en, this message translates to:
  /// **'Actual Quantity'**
  String get actualQuantity;

  /// No description provided for @difference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get difference;

  /// No description provided for @countDetails.
  ///
  /// In en, this message translates to:
  /// **'Count Details'**
  String get countDetails;

  /// No description provided for @shortageQuantity.
  ///
  /// In en, this message translates to:
  /// **'Shortage Quantity'**
  String get shortageQuantity;

  /// No description provided for @overageQuantity.
  ///
  /// In en, this message translates to:
  /// **'Overage Quantity'**
  String get overageQuantity;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

  /// No description provided for @countedItems.
  ///
  /// In en, this message translates to:
  /// **'Counted Items'**
  String get countedItems;

  /// No description provided for @remainingItems.
  ///
  /// In en, this message translates to:
  /// **'Remaining Items'**
  String get remainingItems;

  /// No description provided for @matched.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get matched;

  /// No description provided for @shortage.
  ///
  /// In en, this message translates to:
  /// **'Shortage'**
  String get shortage;

  /// No description provided for @overage.
  ///
  /// In en, this message translates to:
  /// **'Overage'**
  String get overage;

  /// No description provided for @matchedStatus.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get matchedStatus;

  /// No description provided for @shortageStatus.
  ///
  /// In en, this message translates to:
  /// **'Shortage'**
  String get shortageStatus;

  /// No description provided for @overageStatus.
  ///
  /// In en, this message translates to:
  /// **'Overage'**
  String get overageStatus;

  /// No description provided for @notCountedStatus.
  ///
  /// In en, this message translates to:
  /// **'Not Counted'**
  String get notCountedStatus;

  /// No description provided for @allItems.
  ///
  /// In en, this message translates to:
  /// **'All Items'**
  String get allItems;

  /// No description provided for @matchedItems.
  ///
  /// In en, this message translates to:
  /// **'Matched Items'**
  String get matchedItems;

  /// No description provided for @shortageItems.
  ///
  /// In en, this message translates to:
  /// **'Shortages'**
  String get shortageItems;

  /// No description provided for @overageItems.
  ///
  /// In en, this message translates to:
  /// **'Overages'**
  String get overageItems;

  /// No description provided for @notCountedItems.
  ///
  /// In en, this message translates to:
  /// **'Not Counted Items'**
  String get notCountedItems;

  /// No description provided for @emptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get emptyStateTitle;

  /// No description provided for @emptyStateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or import inventory first.'**
  String get emptyStateSubtitle;

  /// No description provided for @importPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Inventory'**
  String get importPageTitle;

  /// No description provided for @selectExcelFile.
  ///
  /// In en, this message translates to:
  /// **'Select Excel File'**
  String get selectExcelFile;

  /// No description provided for @selectedFileName.
  ///
  /// In en, this message translates to:
  /// **'Selected File'**
  String get selectedFileName;

  /// No description provided for @noFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get noFileSelected;

  /// No description provided for @importButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importButton;

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get importing;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import completed successfully.'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed.'**
  String get importFailed;

  /// No description provided for @importedItemsCount.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} items'**
  String importedItemsCount(int count);

  /// No description provided for @ignoredRowsCount.
  ///
  /// In en, this message translates to:
  /// **'Ignored {count} rows'**
  String ignoredRowsCount(int count);

  /// No description provided for @invalidFile.
  ///
  /// In en, this message translates to:
  /// **'The selected file is not a valid Excel file.'**
  String get invalidFile;

  /// No description provided for @fileSelectedPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select an Excel file to continue.'**
  String get fileSelectedPrompt;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get exportReport;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report exported successfully.'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Report export failed.'**
  String get exportFailed;

  /// No description provided for @exportNoItems.
  ///
  /// In en, this message translates to:
  /// **'There are no items to print for the current filter.'**
  String get exportNoItems;

  /// No description provided for @exportDataNotReady.
  ///
  /// In en, this message translates to:
  /// **'Inventory data is not ready yet. Please wait and try again.'**
  String get exportDataNotReady;

  /// No description provided for @inventoryReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory Count Report'**
  String get inventoryReportTitle;

  /// No description provided for @systemMainQuantity.
  ///
  /// In en, this message translates to:
  /// **'System Main Qty'**
  String get systemMainQuantity;

  /// No description provided for @systemSubQuantity.
  ///
  /// In en, this message translates to:
  /// **'System Sub Qty'**
  String get systemSubQuantity;

  /// No description provided for @countedMainQuantity.
  ///
  /// In en, this message translates to:
  /// **'Counted Main Qty'**
  String get countedMainQuantity;

  /// No description provided for @countedSubQuantity.
  ///
  /// In en, this message translates to:
  /// **'Counted Sub Qty'**
  String get countedSubQuantity;

  /// No description provided for @varianceQuantity.
  ///
  /// In en, this message translates to:
  /// **'Shortage / Overage'**
  String get varianceQuantity;

  /// No description provided for @varianceMainQuantity.
  ///
  /// In en, this message translates to:
  /// **'Main Shortage/Overage'**
  String get varianceMainQuantity;

  /// No description provided for @varianceSubQuantity.
  ///
  /// In en, this message translates to:
  /// **'Sub Shortage/Overage'**
  String get varianceSubQuantity;

  /// No description provided for @reportSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get reportSection;

  /// No description provided for @generatedAt.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get generatedAt;

  /// No description provided for @inventorySheetName.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventorySheetName;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get systemTheme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @applicationName.
  ///
  /// In en, this message translates to:
  /// **'Application Name'**
  String get applicationName;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get buildNumber;

  /// No description provided for @resetApplication.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get resetApplication;

  /// No description provided for @resetApplicationConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset settings?'**
  String get resetApplicationConfirmationTitle;

  /// No description provided for @resetApplicationConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Theme and language preferences will be restored to defaults.'**
  String get resetApplicationConfirmationMessage;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @failure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get failure;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @exitAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit the app?'**
  String get exitAppTitle;

  /// No description provided for @exitAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to close the application now?'**
  String get exitAppMessage;

  /// No description provided for @exitAppConfirm.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitAppConfirm;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @errorStateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please try again. If the problem continues, check your data and return later.'**
  String get errorStateSubtitle;

  /// No description provided for @moduleComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get moduleComingSoon;

  /// No description provided for @navigationHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navigationHome;

  /// No description provided for @availableQuantity.
  ///
  /// In en, this message translates to:
  /// **'Available Quantity'**
  String get availableQuantity;

  /// No description provided for @statusBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Status Breakdown'**
  String get statusBreakdown;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @exportAs.
  ///
  /// In en, this message translates to:
  /// **'Export as'**
  String get exportAs;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Excel (.xlsx)'**
  String get exportExcel;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF (.pdf)'**
  String get exportPdf;

  /// No description provided for @exportPath.
  ///
  /// In en, this message translates to:
  /// **'Saved to: {path}'**
  String exportPath(String path);

  /// No description provided for @shareExport.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareExport;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get previousPage;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPage;

  /// No description provided for @paginationPage.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String paginationPage(int current, int total);

  /// No description provided for @paginationRange.
  ///
  /// In en, this message translates to:
  /// **'{from}-{to} of {total}'**
  String paginationRange(int from, int to, int total);

  /// No description provided for @importParsing.
  ///
  /// In en, this message translates to:
  /// **'Parsing Excel file...'**
  String get importParsing;

  /// No description provided for @importSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving items...'**
  String get importSaving;

  /// No description provided for @emptyWorkbook.
  ///
  /// In en, this message translates to:
  /// **'The Excel file is empty or has no sheets.'**
  String get emptyWorkbook;

  /// No description provided for @noValidRows.
  ///
  /// In en, this message translates to:
  /// **'No valid inventory rows were found in the file.'**
  String get noValidRows;

  /// No description provided for @duplicateRowsCount.
  ///
  /// In en, this message translates to:
  /// **'Replaced {count} duplicate item codes'**
  String duplicateRowsCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
