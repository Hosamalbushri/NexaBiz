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
  /// **'NexaBiz'**
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
  /// **'Inventory services including stock count, and more over time.'**
  String get moduleInventoryDescription;

  /// No description provided for @inventoryStockCountService.
  ///
  /// In en, this message translates to:
  /// **'Stock count'**
  String get inventoryStockCountService;

  /// No description provided for @inventoryStockCountServiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Count items, import stock lists, and view count reports.'**
  String get inventoryStockCountServiceDescription;

  /// No description provided for @inventoryProductsService.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get inventoryProductsService;

  /// No description provided for @inventoryProductsServiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage the product catalog, prices, and pack sizes.'**
  String get inventoryProductsServiceDescription;

  /// No description provided for @productsHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsHubTitle;

  /// No description provided for @productsHubDescription.
  ///
  /// In en, this message translates to:
  /// **'Browse the catalog, manage barcodes, or import from Excel.'**
  String get productsHubDescription;

  /// No description provided for @productsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Product list'**
  String get productsListTitle;

  /// No description provided for @productsListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search, add, edit, and delete products.'**
  String get productsListSubtitle;

  /// No description provided for @productsImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import products'**
  String get productsImportTitle;

  /// No description provided for @productsImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import catalog rows from an Excel file.'**
  String get productsImportSubtitle;

  /// No description provided for @productsBarcodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Barcodes'**
  String get productsBarcodeTitle;

  /// No description provided for @productsBarcodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate, scan, preview, and print product barcodes.'**
  String get productsBarcodeSubtitle;

  /// No description provided for @productsBarcodeSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Search or scan to select a product.'**
  String get productsBarcodeSelectHint;

  /// No description provided for @productsBarcodeSearchResults.
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String productsBarcodeSearchResults(int count);

  /// No description provided for @productsBarcodeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No products match your search.'**
  String get productsBarcodeNoResults;

  /// No description provided for @productsBarcodeChangeProduct.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get productsBarcodeChangeProduct;

  /// No description provided for @productsBarcodeHasCode.
  ///
  /// In en, this message translates to:
  /// **'Has barcode'**
  String get productsBarcodeHasCode;

  /// No description provided for @productsBarcodeNoCode.
  ///
  /// In en, this message translates to:
  /// **'No barcode'**
  String get productsBarcodeNoCode;

  /// No description provided for @productsBarcodeReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace barcode?'**
  String get productsBarcodeReplaceTitle;

  /// No description provided for @productsBarcodeReplaceMessage.
  ///
  /// In en, this message translates to:
  /// **'This product already has a barcode. Generate a new one and save it?'**
  String get productsBarcodeReplaceMessage;

  /// No description provided for @productsBarcodeSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Barcode saved successfully.'**
  String get productsBarcodeSavedSuccess;

  /// No description provided for @productsBarcodeMissingForPrint.
  ///
  /// In en, this message translates to:
  /// **'Generate or assign a barcode before printing.'**
  String get productsBarcodeMissingForPrint;

  /// No description provided for @productsBarcodePrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get productsBarcodePrint;

  /// No description provided for @productsBarcodeShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get productsBarcodeShare;

  /// No description provided for @productsBarcodeThermalPrint.
  ///
  /// In en, this message translates to:
  /// **'Thermal printer'**
  String get productsBarcodeThermalPrint;

  /// No description provided for @productsBarcodeThermalComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Thermal printing will be available in a future update.'**
  String get productsBarcodeThermalComingSoon;

  /// No description provided for @productsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by code, name, or barcode'**
  String get productsSearchHint;

  /// No description provided for @catalogSearchFieldAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catalogSearchFieldAll;

  /// No description provided for @catalogSearchFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get catalogSearchFieldName;

  /// No description provided for @catalogSearchFieldCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get catalogSearchFieldCode;

  /// No description provided for @catalogSearchFieldBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get catalogSearchFieldBarcode;

  /// No description provided for @catalogSearchHintName.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get catalogSearchHintName;

  /// No description provided for @catalogSearchHintCode.
  ///
  /// In en, this message translates to:
  /// **'Search by code'**
  String get catalogSearchHintCode;

  /// No description provided for @catalogSearchHintBarcode.
  ///
  /// In en, this message translates to:
  /// **'Search by barcode'**
  String get catalogSearchHintBarcode;

  /// No description provided for @catalogSearchFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Search in'**
  String get catalogSearchFilterLabel;

  /// No description provided for @productsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get productsEmptyTitle;

  /// No description provided for @productsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a product manually or import an Excel catalog.'**
  String get productsEmptyMessage;

  /// No description provided for @productsGoToImport.
  ///
  /// In en, this message translates to:
  /// **'Go to import'**
  String get productsGoToImport;

  /// No description provided for @productsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get productsAdd;

  /// No description provided for @productsViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get productsViewList;

  /// No description provided for @productsViewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get productsViewGrid;

  /// No description provided for @productsViewModeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change product layout'**
  String get productsViewModeTooltip;

  /// No description provided for @productsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get productsEdit;

  /// No description provided for @productsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get productsDelete;

  /// No description provided for @productsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete product?'**
  String get productsDeleteConfirmTitle;

  /// No description provided for @productsDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes the product from the catalog. Stock-count data is not changed.'**
  String get productsDeleteConfirmMessage;

  /// No description provided for @productsSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product saved successfully.'**
  String get productsSavedSuccess;

  /// No description provided for @productsDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product deleted.'**
  String get productsDeletedSuccess;

  /// No description provided for @productsDuplicateCode.
  ///
  /// In en, this message translates to:
  /// **'A product with this item code already exists.'**
  String get productsDuplicateCode;

  /// No description provided for @productsDuplicateBarcode.
  ///
  /// In en, this message translates to:
  /// **'A product with this barcode already exists.'**
  String get productsDuplicateBarcode;

  /// No description provided for @productsInvalidForm.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid code, name, pack size, and price.'**
  String get productsInvalidForm;

  /// No description provided for @productsItemCodeAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Generated automatically and cannot be edited.'**
  String get productsItemCodeAutoHint;

  /// No description provided for @productsFieldLockedHint.
  ///
  /// In en, this message translates to:
  /// **'This field cannot be edited.'**
  String get productsFieldLockedHint;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @priceRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 12.50'**
  String get priceRequiredHint;

  /// No description provided for @productsImportPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Import products'**
  String get productsImportPageTitle;

  /// No description provided for @productsImportFormatHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Products Excel layout'**
  String get productsImportFormatHintTitle;

  /// No description provided for @productsImportFormatHintIntro.
  ///
  /// In en, this message translates to:
  /// **'First row = headers. Required columns only. Use .xlsx or .xls.'**
  String get productsImportFormatHintIntro;

  /// No description provided for @productsImportFormatColPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get productsImportFormatColPrice;

  /// No description provided for @productsImportFormatColPriceAliases.
  ///
  /// In en, this message translates to:
  /// **'Price · Unit Price · السعر'**
  String get productsImportFormatColPriceAliases;

  /// No description provided for @productsImportFormatColPackAliases.
  ///
  /// In en, this message translates to:
  /// **'Pack Size · Pack · العبوة'**
  String get productsImportFormatColPackAliases;

  /// No description provided for @productsImportFormatSampleNote.
  ///
  /// In en, this message translates to:
  /// **'Without headers, columns are read as: code, name, pack size, price.'**
  String get productsImportFormatSampleNote;

  /// No description provided for @productsImportFormatSamplePriceHeader.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get productsImportFormatSamplePriceHeader;

  /// No description provided for @productsImportInsertedCount.
  ///
  /// In en, this message translates to:
  /// **'Inserted {count} products'**
  String productsImportInsertedCount(int count);

  /// No description provided for @productsImportUpdatedCount.
  ///
  /// In en, this message translates to:
  /// **'Updated {count} products'**
  String productsImportUpdatedCount(int count);

  /// No description provided for @productsNoValidRows.
  ///
  /// In en, this message translates to:
  /// **'No valid product rows were found in the file.'**
  String get productsNoValidRows;

  /// No description provided for @productsScanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode or QR'**
  String get productsScanBarcode;

  /// No description provided for @productsScanAction.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get productsScanAction;

  /// No description provided for @productsScannerAlignHint.
  ///
  /// In en, this message translates to:
  /// **'Align barcode or QR code here'**
  String get productsScannerAlignHint;

  /// No description provided for @productsScannerScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get productsScannerScanning;

  /// No description provided for @productsScannerDetected.
  ///
  /// In en, this message translates to:
  /// **'Code detected'**
  String get productsScannerDetected;

  /// No description provided for @productsScannerProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get productsScannerProcessing;

  /// No description provided for @productsScannerInvalid.
  ///
  /// In en, this message translates to:
  /// **'Unsupported code'**
  String get productsScannerInvalid;

  /// No description provided for @productsGenerateBarcode.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get productsGenerateBarcode;

  /// No description provided for @productsGenerateBarcodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Generate a unique barcode value'**
  String get productsGenerateBarcodeTooltip;

  /// No description provided for @productsBarcodePreview.
  ///
  /// In en, this message translates to:
  /// **'Barcode preview'**
  String get productsBarcodePreview;

  /// No description provided for @productsBarcodeTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode type'**
  String get productsBarcodeTypeLabel;

  /// No description provided for @productsBarcodeFormatBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get productsBarcodeFormatBarcode;

  /// No description provided for @productsBarcodeFormatQr.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get productsBarcodeFormatQr;

  /// No description provided for @productsQrCodePreview.
  ///
  /// In en, this message translates to:
  /// **'QR Code preview'**
  String get productsQrCodePreview;

  /// No description provided for @productsGenerateQrCode.
  ///
  /// In en, this message translates to:
  /// **'Generate QR Code'**
  String get productsGenerateQrCode;

  /// No description provided for @productsSaveQrCode.
  ///
  /// In en, this message translates to:
  /// **'Save QR Code'**
  String get productsSaveQrCode;

  /// No description provided for @productsShareQrCode.
  ///
  /// In en, this message translates to:
  /// **'Share QR Code'**
  String get productsShareQrCode;

  /// No description provided for @productsInvalidProductData.
  ///
  /// In en, this message translates to:
  /// **'Invalid product data'**
  String get productsInvalidProductData;

  /// No description provided for @productsQrScanRecognized.
  ///
  /// In en, this message translates to:
  /// **'Product loaded from QR Code'**
  String get productsQrScanRecognized;

  /// No description provided for @productsQrScanOfflineData.
  ///
  /// In en, this message translates to:
  /// **'Product shown from QR data (not found in catalog)'**
  String get productsQrScanOfflineData;

  /// No description provided for @productsQrProductDetails.
  ///
  /// In en, this message translates to:
  /// **'Product details'**
  String get productsQrProductDetails;

  /// No description provided for @productsCodesSection.
  ///
  /// In en, this message translates to:
  /// **'Product codes'**
  String get productsCodesSection;

  /// No description provided for @productsPrintBarcode.
  ///
  /// In en, this message translates to:
  /// **'Print barcode'**
  String get productsPrintBarcode;

  /// No description provided for @productsPrintQr.
  ///
  /// In en, this message translates to:
  /// **'Print QR Code'**
  String get productsPrintQr;

  /// No description provided for @productsBarcodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No product found for this barcode.'**
  String get productsBarcodeNotFound;

  /// No description provided for @productsCameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan barcodes.'**
  String get productsCameraPermissionDenied;

  /// No description provided for @productsCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera is not available on this device.'**
  String get productsCameraUnavailable;

  /// No description provided for @productsEnterBarcodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the barcode manually, or use camera scan on Android/iOS after a full app restart.'**
  String get productsEnterBarcodeHint;

  /// No description provided for @inventoryOpenStockCount.
  ///
  /// In en, this message translates to:
  /// **'Open stock count'**
  String get inventoryOpenStockCount;

  /// No description provided for @inventoryCustomizeServices.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get inventoryCustomizeServices;

  /// No description provided for @inventoryCustomizeServicesHint.
  ///
  /// In en, this message translates to:
  /// **'Choose services to show, then drag to change their order.'**
  String get inventoryCustomizeServicesHint;

  /// No description provided for @inventorySaveServices.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get inventorySaveServices;

  /// No description provided for @inventoryPinnedServices.
  ///
  /// In en, this message translates to:
  /// **'Pinned services'**
  String get inventoryPinnedServices;

  /// No description provided for @inventoryAvailableServices.
  ///
  /// In en, this message translates to:
  /// **'Available services'**
  String get inventoryAvailableServices;

  /// No description provided for @inventoryAddService.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get inventoryAddService;

  /// No description provided for @inventoryRemoveService.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get inventoryRemoveService;

  /// No description provided for @inventoryNoServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'No services on inventory home'**
  String get inventoryNoServicesTitle;

  /// No description provided for @inventoryNoServicesMessage.
  ///
  /// In en, this message translates to:
  /// **'Customize to pin the inventory services you use most.'**
  String get inventoryNoServicesMessage;

  /// No description provided for @inventoryNoServicesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No inventory services are available yet.'**
  String get inventoryNoServicesAvailable;

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
  /// **'Count'**
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

  /// No description provided for @inventoryEmptyNeedsImportTitle.
  ///
  /// In en, this message translates to:
  /// **'No inventory items yet'**
  String get inventoryEmptyNeedsImportTitle;

  /// No description provided for @inventoryEmptyNeedsImportMessage.
  ///
  /// In en, this message translates to:
  /// **'Import an Excel list to start counting and viewing reports.'**
  String get inventoryEmptyNeedsImportMessage;

  /// No description provided for @inventoryGoToImport.
  ///
  /// In en, this message translates to:
  /// **'Go to Import'**
  String get inventoryGoToImport;

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

  /// No description provided for @importFormatHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Excel file layout'**
  String get importFormatHintTitle;

  /// No description provided for @importFormatHintIntro.
  ///
  /// In en, this message translates to:
  /// **'First row = headers. Use .xlsx or .xls.'**
  String get importFormatHintIntro;

  /// No description provided for @importFormatRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get importFormatRequired;

  /// No description provided for @importFormatOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get importFormatOptional;

  /// No description provided for @importFormatColCode.
  ///
  /// In en, this message translates to:
  /// **'Item code'**
  String get importFormatColCode;

  /// No description provided for @importFormatColCodeAliases.
  ///
  /// In en, this message translates to:
  /// **'Item Code · Code · رقم السلعة'**
  String get importFormatColCodeAliases;

  /// No description provided for @importFormatColName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get importFormatColName;

  /// No description provided for @importFormatColNameAliases.
  ///
  /// In en, this message translates to:
  /// **'Item Name · Name · اسم السلعة'**
  String get importFormatColNameAliases;

  /// No description provided for @importFormatColMainQty.
  ///
  /// In en, this message translates to:
  /// **'Main quantity'**
  String get importFormatColMainQty;

  /// No description provided for @importFormatColMainQtyAliases.
  ///
  /// In en, this message translates to:
  /// **'Main Quantity · الكمية الرئيسية'**
  String get importFormatColMainQtyAliases;

  /// No description provided for @importFormatColSubQty.
  ///
  /// In en, this message translates to:
  /// **'Sub quantity'**
  String get importFormatColSubQty;

  /// No description provided for @importFormatColSubQtyAliases.
  ///
  /// In en, this message translates to:
  /// **'Sub Quantity · الكمية الفرعية'**
  String get importFormatColSubQtyAliases;

  /// No description provided for @importFormatColBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get importFormatColBarcode;

  /// No description provided for @importFormatColBarcodeAliases.
  ///
  /// In en, this message translates to:
  /// **'Barcode · الباركود'**
  String get importFormatColBarcodeAliases;

  /// No description provided for @importFormatColPack.
  ///
  /// In en, this message translates to:
  /// **'Pack size'**
  String get importFormatColPack;

  /// No description provided for @importFormatColPackAliases.
  ///
  /// In en, this message translates to:
  /// **'Pack Size · حجم العبوة'**
  String get importFormatColPackAliases;

  /// No description provided for @importFormatSampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get importFormatSampleTitle;

  /// No description provided for @importFormatSampleNote.
  ///
  /// In en, this message translates to:
  /// **'Without headers, columns are read as: code, name, main qty, sub qty.'**
  String get importFormatSampleNote;

  /// No description provided for @importFormatSampleCodeHeader.
  ///
  /// In en, this message translates to:
  /// **'Item Code'**
  String get importFormatSampleCodeHeader;

  /// No description provided for @importFormatSampleNameHeader.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get importFormatSampleNameHeader;

  /// No description provided for @importFormatSampleMainHeader.
  ///
  /// In en, this message translates to:
  /// **'Main Qty'**
  String get importFormatSampleMainHeader;

  /// No description provided for @importFormatSampleSubHeader.
  ///
  /// In en, this message translates to:
  /// **'Sub Qty'**
  String get importFormatSampleSubHeader;

  /// No description provided for @importFormatSamplePackHeader.
  ///
  /// In en, this message translates to:
  /// **'Pack Size'**
  String get importFormatSamplePackHeader;

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

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get notificationsEmptyMessage;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTooltip;

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
  /// **'Exit Application?'**
  String get exitAppTitle;

  /// No description provided for @exitAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the application?'**
  String get exitAppMessage;

  /// No description provided for @exitAppConfirm.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitAppConfirm;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Business Management Platform'**
  String get splashSubtitle;

  /// No description provided for @splashInitErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to start application'**
  String get splashInitErrorTitle;

  /// No description provided for @splashInitErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while initializing the application.'**
  String get splashInitErrorMessage;

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

  /// No description provided for @navigationDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navigationDashboard;

  /// No description provided for @navigationServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get navigationServices;

  /// No description provided for @navigationReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navigationReports;

  /// No description provided for @quickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActionsTitle;

  /// No description provided for @quickActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your pinned shortcuts. Customize to add or reorder.'**
  String get quickActionsSubtitle;

  /// No description provided for @quickActionsCreateProduct.
  ///
  /// In en, this message translates to:
  /// **'Create product'**
  String get quickActionsCreateProduct;

  /// No description provided for @quickActionsCreateProductSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the new product form.'**
  String get quickActionsCreateProductSubtitle;

  /// No description provided for @quickActionsScanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode or QR'**
  String get quickActionsScanBarcode;

  /// No description provided for @quickActionsScanBarcodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode or QR and open the product.'**
  String get quickActionsScanBarcodeSubtitle;

  /// No description provided for @quickActionsCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get quickActionsCustomize;

  /// No description provided for @quickActionsCustomizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize quick actions'**
  String get quickActionsCustomizeTitle;

  /// No description provided for @quickActionsCustomizeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose actions to show, then drag to change their order.'**
  String get quickActionsCustomizeHint;

  /// No description provided for @quickActionsPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned actions'**
  String get quickActionsPinned;

  /// No description provided for @quickActionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available actions'**
  String get quickActionsAvailable;

  /// No description provided for @quickActionsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get quickActionsAdd;

  /// No description provided for @quickActionsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get quickActionsRemove;

  /// No description provided for @quickActionsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get quickActionsSave;

  /// No description provided for @quickActionsPinnedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max} pinned'**
  String quickActionsPinnedCount(int count, int max);

  /// No description provided for @quickActionsMaxReached.
  ///
  /// In en, this message translates to:
  /// **'You can pin up to {max} quick actions.'**
  String quickActionsMaxReached(int max);

  /// No description provided for @quickActionsEmptyPinned.
  ///
  /// In en, this message translates to:
  /// **'No shortcuts pinned yet. Tap Customize to add some.'**
  String get quickActionsEmptyPinned;

  /// No description provided for @quickActionsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Pin shortcuts here for faster access. You will be able to customize them later.'**
  String get quickActionsEmptyMessage;

  /// No description provided for @quickActionsAddLabel.
  ///
  /// In en, this message translates to:
  /// **'Add action'**
  String get quickActionsAddLabel;

  /// No description provided for @quickActionsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Quick action customization is coming soon.'**
  String get quickActionsComingSoon;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Overview of your business platform.'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardOpenServices.
  ///
  /// In en, this message translates to:
  /// **'Browse all services'**
  String get dashboardOpenServices;

  /// No description provided for @dashboardOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get dashboardOpenSettings;

  /// No description provided for @dashboardMyServices.
  ///
  /// In en, this message translates to:
  /// **'My services'**
  String get dashboardMyServices;

  /// No description provided for @dashboardCustomizeServices.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get dashboardCustomizeServices;

  /// No description provided for @dashboardCustomizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize dashboard services'**
  String get dashboardCustomizeTitle;

  /// No description provided for @dashboardCustomizeServicesHint.
  ///
  /// In en, this message translates to:
  /// **'Choose which services appear on your dashboard, then drag to reorder.'**
  String get dashboardCustomizeServicesHint;

  /// No description provided for @dashboardPinnedServices.
  ///
  /// In en, this message translates to:
  /// **'Pinned services'**
  String get dashboardPinnedServices;

  /// No description provided for @dashboardAvailableServices.
  ///
  /// In en, this message translates to:
  /// **'Available services'**
  String get dashboardAvailableServices;

  /// No description provided for @dashboardAddService.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get dashboardAddService;

  /// No description provided for @dashboardRemoveService.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get dashboardRemoveService;

  /// No description provided for @dashboardSaveServices.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dashboardSaveServices;

  /// No description provided for @dashboardNoServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'No services on dashboard'**
  String get dashboardNoServicesTitle;

  /// No description provided for @dashboardNoServicesMessage.
  ///
  /// In en, this message translates to:
  /// **'Customize your dashboard to add the services you use most.'**
  String get dashboardNoServicesMessage;

  /// No description provided for @dashboardNoModulesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No services are available yet.'**
  String get dashboardNoModulesAvailable;

  /// No description provided for @platformReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get platformReportsTitle;

  /// No description provided for @platformReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a module to browse its service reports.'**
  String get platformReportsSubtitle;

  /// No description provided for @platformReportsInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory reports'**
  String get platformReportsInventory;

  /// No description provided for @platformReportsInventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stock count and product reports.'**
  String get platformReportsInventorySubtitle;

  /// No description provided for @platformReportsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Cross-module reports will be available in a future release.'**
  String get platformReportsComingSoon;

  /// No description provided for @platformReportsStockCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock count report'**
  String get platformReportsStockCountTitle;

  /// No description provided for @platformReportsStockCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Count summary, variances, and export.'**
  String get platformReportsStockCountSubtitle;

  /// No description provided for @platformReportsProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products report'**
  String get platformReportsProductsTitle;

  /// No description provided for @platformReportsServiceComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Reports for this service are coming soon.'**
  String get platformReportsServiceComingSoon;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// No description provided for @notFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The page you are looking for does not exist.'**
  String get notFoundMessage;

  /// No description provided for @goToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get goToDashboard;

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

  /// No description provided for @paginationItemsPerPage.
  ///
  /// In en, this message translates to:
  /// **'Items per page'**
  String get paginationItemsPerPage;

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
