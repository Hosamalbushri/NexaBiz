// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NexaBiz';

  @override
  String get servicesTitle => 'Services';

  @override
  String get servicesSubtitle => 'Choose a business module to get started.';

  @override
  String get moduleInventory => 'Inventory';

  @override
  String get moduleInventoryDescription =>
      'Inventory services including stock count, and more over time.';

  @override
  String get inventoryStockCountService => 'Stock count';

  @override
  String get inventoryStockCountServiceDescription =>
      'Count items, import stock lists, and view count reports.';

  @override
  String get inventoryProductsService => 'Products';

  @override
  String get inventoryProductsServiceDescription =>
      'Manage the product catalog, prices, and pack sizes.';

  @override
  String get productsHubTitle => 'Products';

  @override
  String get productsHubDescription =>
      'Browse the catalog, manage barcodes, or import from Excel.';

  @override
  String get productsListTitle => 'Product list';

  @override
  String get productsListSubtitle => 'Search, add, edit, and delete products.';

  @override
  String get productsImportTitle => 'Import products';

  @override
  String get productsImportSubtitle =>
      'Import catalog rows from an Excel file.';

  @override
  String get productsBarcodeTitle => 'Barcodes';

  @override
  String get productsBarcodeSubtitle =>
      'Generate, scan, preview, and print product barcodes.';

  @override
  String get productsBarcodeSelectHint => 'Search or scan to select a product.';

  @override
  String productsBarcodeSearchResults(int count) {
    return '$count products';
  }

  @override
  String get productsBarcodeNoResults => 'No products match your search.';

  @override
  String get productsBarcodeChangeProduct => 'Change';

  @override
  String get productsBarcodeHasCode => 'Has barcode';

  @override
  String get productsBarcodeNoCode => 'No barcode';

  @override
  String get productsBarcodeReplaceTitle => 'Replace barcode?';

  @override
  String get productsBarcodeReplaceMessage =>
      'This product already has a barcode. Generate a new one and save it?';

  @override
  String get productsBarcodeSavedSuccess => 'Barcode saved successfully.';

  @override
  String get productsBarcodeMissingForPrint =>
      'Generate or assign a barcode before printing.';

  @override
  String get productsBarcodePrint => 'Print';

  @override
  String get productsBarcodeShare => 'Share';

  @override
  String get productsBarcodeThermalPrint => 'Thermal printer';

  @override
  String get productsBarcodeThermalComingSoon =>
      'Thermal printing will be available in a future update.';

  @override
  String get productsSearchHint => 'Search by code, name, or barcode';

  @override
  String get catalogSearchFieldAll => 'All';

  @override
  String get catalogSearchFieldName => 'Name';

  @override
  String get catalogSearchFieldCode => 'Code';

  @override
  String get catalogSearchFieldBarcode => 'Barcode';

  @override
  String get catalogSearchHintName => 'Search by name';

  @override
  String get catalogSearchHintCode => 'Search by code';

  @override
  String get catalogSearchHintBarcode => 'Search by barcode';

  @override
  String get catalogSearchFilterLabel => 'Search in';

  @override
  String get productsEmptyTitle => 'No products yet';

  @override
  String get productsEmptyMessage =>
      'Add a product manually or import an Excel catalog.';

  @override
  String get productsGoToImport => 'Go to import';

  @override
  String get productsAdd => 'Add product';

  @override
  String get productsViewList => 'List';

  @override
  String get productsViewGrid => 'Grid';

  @override
  String get productsViewModeTooltip => 'Change product layout';

  @override
  String get productsEdit => 'Edit product';

  @override
  String get productsDelete => 'Delete';

  @override
  String get productsDeleteConfirmTitle => 'Delete product?';

  @override
  String get productsDeleteConfirmMessage =>
      'This removes the product from the catalog. Stock-count data is not changed.';

  @override
  String get productsSavedSuccess => 'Product saved successfully.';

  @override
  String get productsDeletedSuccess => 'Product deleted.';

  @override
  String get productsDuplicateCode =>
      'A product with this item code already exists.';

  @override
  String get productsDuplicateBarcode =>
      'A product with this barcode already exists.';

  @override
  String get productsInvalidForm =>
      'Enter a valid code, name, pack size, and price.';

  @override
  String get productsItemCodeAutoHint =>
      'Generated automatically and cannot be edited.';

  @override
  String get productsFieldLockedHint => 'This field cannot be edited.';

  @override
  String get price => 'Price';

  @override
  String get priceRequiredHint => 'e.g. 12.50';

  @override
  String get productsImportPageTitle => 'Import products';

  @override
  String get productsImportFormatHintTitle => 'Products Excel layout';

  @override
  String get productsImportFormatHintIntro =>
      'First row = headers. Required columns only. Use .xlsx or .xls.';

  @override
  String get productsImportFormatColPrice => 'Price';

  @override
  String get productsImportFormatColPriceAliases =>
      'Price · Unit Price · السعر';

  @override
  String get productsImportFormatColPackAliases => 'Pack Size · Pack · العبوة';

  @override
  String get productsImportFormatSampleNote =>
      'Without headers, columns are read as: code, name, pack size, price.';

  @override
  String get productsImportFormatSamplePriceHeader => 'Price';

  @override
  String productsImportInsertedCount(int count) {
    return 'Inserted $count products';
  }

  @override
  String productsImportUpdatedCount(int count) {
    return 'Updated $count products';
  }

  @override
  String get productsNoValidRows =>
      'No valid product rows were found in the file.';

  @override
  String get productsScanBarcode => 'Scan barcode or QR';

  @override
  String get productsScanAction => 'Scan';

  @override
  String get productsScannerAlignHint => 'Align barcode or QR code here';

  @override
  String get productsScannerScanning => 'Scanning...';

  @override
  String get productsScannerDetected => 'Code detected';

  @override
  String get productsScannerProcessing => 'Processing...';

  @override
  String get productsScannerInvalid => 'Unsupported code';

  @override
  String get productsGenerateBarcode => 'Generate';

  @override
  String get productsGenerateBarcodeTooltip =>
      'Generate a unique barcode value';

  @override
  String get productsBarcodePreview => 'Barcode preview';

  @override
  String get productsBarcodeTypeLabel => 'Barcode type';

  @override
  String get productsBarcodeFormatBarcode => 'Barcode';

  @override
  String get productsBarcodeFormatQr => 'QR Code';

  @override
  String get productsQrCodePreview => 'QR Code preview';

  @override
  String get productsGenerateQrCode => 'Generate QR Code';

  @override
  String get productsSaveQrCode => 'Save QR Code';

  @override
  String get productsShareQrCode => 'Share QR Code';

  @override
  String get productsInvalidProductData => 'Invalid product data';

  @override
  String get productsQrScanRecognized => 'Product loaded from QR Code';

  @override
  String get productsQrScanOfflineData =>
      'Product shown from QR data (not found in catalog)';

  @override
  String get productsQrProductDetails => 'Product details';

  @override
  String get productsCodesSection => 'Product codes';

  @override
  String get productsPrintBarcode => 'Print barcode';

  @override
  String get productsPrintQr => 'Print QR Code';

  @override
  String get productsBarcodeNotFound => 'No product found for this barcode.';

  @override
  String get productsCameraPermissionDenied =>
      'Camera permission is required to scan barcodes.';

  @override
  String get productsCameraUnavailable =>
      'Camera is not available on this device.';

  @override
  String get productsEnterBarcodeHint =>
      'Enter the barcode manually, or use camera scan on Android/iOS after a full app restart.';

  @override
  String get inventoryOpenStockCount => 'Open stock count';

  @override
  String get inventoryCustomizeServices => 'Customize';

  @override
  String get inventoryCustomizeServicesHint =>
      'Choose services to show, then drag to change their order.';

  @override
  String get inventorySaveServices => 'Save';

  @override
  String get inventoryPinnedServices => 'Pinned services';

  @override
  String get inventoryAvailableServices => 'Available services';

  @override
  String get inventoryAddService => 'Add';

  @override
  String get inventoryRemoveService => 'Remove';

  @override
  String get inventoryNoServicesTitle => 'No services on inventory home';

  @override
  String get inventoryNoServicesMessage =>
      'Customize to pin the inventory services you use most.';

  @override
  String get inventoryNoServicesAvailable =>
      'No inventory services are available yet.';

  @override
  String get modulePlaceholderMessage =>
      'This module is registered and ready. Business features will be added in the next stages.';

  @override
  String get inventoryOverview => 'Overview';

  @override
  String get inventoryCountTitle => 'Count';

  @override
  String get inventoryCountSubtitle =>
      'Search items and enter counted quantities.';

  @override
  String get searchItems => 'Search Items';

  @override
  String get searchItemsHint => 'Search by name or code';

  @override
  String searchResultsCount(int count) {
    return '$count results';
  }

  @override
  String get search => 'Search';

  @override
  String get refresh => 'Refresh';

  @override
  String get noItemSelected => 'No item selected';

  @override
  String get saveCount => 'Save Count';

  @override
  String get editCount => 'Edit Count';

  @override
  String get editCountTitle => 'Edit Count';

  @override
  String get editCountSubtitle => 'Enter the new count quantities.';

  @override
  String get countSavedSuccess => 'Count saved successfully.';

  @override
  String get negativeQuantityNotAllowed =>
      'Negative quantities are not allowed.';

  @override
  String get packSize => 'Pack Size';

  @override
  String get packSizeMissingWarning =>
      'This product has no pack size. Enter the pack size before counting.';

  @override
  String get packSizeIncompleteMarkerWarning =>
      'The product name has * without a pack number. Enter the pack size to continue.';

  @override
  String get packSizeInvalidWarning =>
      'The pack size in the product name is invalid. Enter a valid pack size.';

  @override
  String get packSizeRequiredHint => 'e.g. 24';

  @override
  String get savePackSize => 'Save Pack Size';

  @override
  String get packSizeSavedSuccess => 'Pack size saved successfully.';

  @override
  String get packSizeRequiredBeforeCount =>
      'Enter the pack size before counting.';

  @override
  String get invalidPackSize => 'Enter a valid pack size greater than zero.';

  @override
  String get codeLabel => 'Code';

  @override
  String get barcode => 'Barcode';

  @override
  String get mainQuantity => 'Main Quantity';

  @override
  String get subQuantity => 'Sub Quantity';

  @override
  String get systemQuantity => 'System Quantity';

  @override
  String get actualQuantity => 'Actual Quantity';

  @override
  String get difference => 'Difference';

  @override
  String get countDetails => 'Count Details';

  @override
  String get shortageQuantity => 'Shortage Quantity';

  @override
  String get overageQuantity => 'Overage Quantity';

  @override
  String get totalItems => 'Total Items';

  @override
  String get countedItems => 'Counted Items';

  @override
  String get remainingItems => 'Remaining Items';

  @override
  String get matched => 'Matched';

  @override
  String get shortage => 'Shortage';

  @override
  String get overage => 'Overage';

  @override
  String get matchedStatus => 'Matched';

  @override
  String get shortageStatus => 'Shortage';

  @override
  String get overageStatus => 'Overage';

  @override
  String get notCountedStatus => 'Not Counted';

  @override
  String get allItems => 'All Items';

  @override
  String get matchedItems => 'Matched Items';

  @override
  String get shortageItems => 'Shortages';

  @override
  String get overageItems => 'Overages';

  @override
  String get notCountedItems => 'Not Counted Items';

  @override
  String get emptyStateTitle => 'No items found';

  @override
  String get emptyStateSubtitle =>
      'Try a different search or import inventory first.';

  @override
  String get inventoryEmptyNeedsImportTitle => 'No inventory items yet';

  @override
  String get inventoryEmptyNeedsImportMessage =>
      'Import an Excel list to start counting and viewing reports.';

  @override
  String get inventoryGoToImport => 'Go to Import';

  @override
  String get importPageTitle => 'Import Inventory';

  @override
  String get selectExcelFile => 'Select Excel File';

  @override
  String get selectedFileName => 'Selected File';

  @override
  String get noFileSelected => 'No file selected';

  @override
  String get importButton => 'Import';

  @override
  String get importFormatHintTitle => 'Excel file layout';

  @override
  String get importFormatHintIntro => 'First row = headers. Use .xlsx or .xls.';

  @override
  String get importFormatRequired => 'Required';

  @override
  String get importFormatOptional => 'Optional';

  @override
  String get importFormatColCode => 'Item code';

  @override
  String get importFormatColCodeAliases => 'Item Code · Code · رقم السلعة';

  @override
  String get importFormatColName => 'Item name';

  @override
  String get importFormatColNameAliases => 'Item Name · Name · اسم السلعة';

  @override
  String get importFormatColMainQty => 'Main quantity';

  @override
  String get importFormatColMainQtyAliases => 'Main Quantity · الكمية الرئيسية';

  @override
  String get importFormatColSubQty => 'Sub quantity';

  @override
  String get importFormatColSubQtyAliases => 'Sub Quantity · الكمية الفرعية';

  @override
  String get importFormatColBarcode => 'Barcode';

  @override
  String get importFormatColBarcodeAliases => 'Barcode · الباركود';

  @override
  String get importFormatColPack => 'Pack size';

  @override
  String get importFormatColPackAliases => 'Pack Size · حجم العبوة';

  @override
  String get importFormatSampleTitle => 'Sample';

  @override
  String get importFormatSampleNote =>
      'Without headers, columns are read as: code, name, main qty, sub qty.';

  @override
  String get importFormatSampleCodeHeader => 'Item Code';

  @override
  String get importFormatSampleNameHeader => 'Item Name';

  @override
  String get importFormatSampleMainHeader => 'Main Qty';

  @override
  String get importFormatSampleSubHeader => 'Sub Qty';

  @override
  String get importFormatSamplePackHeader => 'Pack Size';

  @override
  String get importing => 'Importing...';

  @override
  String get importSuccess => 'Import completed successfully.';

  @override
  String get importFailed => 'Import failed.';

  @override
  String importedItemsCount(int count) {
    return 'Imported $count items';
  }

  @override
  String ignoredRowsCount(int count) {
    return 'Ignored $count rows';
  }

  @override
  String get invalidFile => 'The selected file is not a valid Excel file.';

  @override
  String get fileSelectedPrompt => 'Please select an Excel file to continue.';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get exportReport => 'Export Report';

  @override
  String get exportSuccess => 'Report exported successfully.';

  @override
  String get exportFailed => 'Report export failed.';

  @override
  String get exportNoItems =>
      'There are no items to print for the current filter.';

  @override
  String get exportDataNotReady =>
      'Inventory data is not ready yet. Please wait and try again.';

  @override
  String get inventoryReportTitle => 'Inventory Count Report';

  @override
  String get systemMainQuantity => 'System Main Qty';

  @override
  String get systemSubQuantity => 'System Sub Qty';

  @override
  String get countedMainQuantity => 'Counted Main Qty';

  @override
  String get countedSubQuantity => 'Counted Sub Qty';

  @override
  String get varianceQuantity => 'Shortage / Overage';

  @override
  String get varianceMainQuantity => 'Main Shortage/Overage';

  @override
  String get varianceSubQuantity => 'Sub Shortage/Overage';

  @override
  String get reportSection => 'Section';

  @override
  String get generatedAt => 'Generated';

  @override
  String get inventorySheetName => 'Inventory';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get lightTheme => 'Light Theme';

  @override
  String get darkTheme => 'Dark Theme';

  @override
  String get systemTheme => 'System Theme';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get about => 'About';

  @override
  String get applicationName => 'Application Name';

  @override
  String get version => 'Version';

  @override
  String get buildNumber => 'Build Number';

  @override
  String get resetApplication => 'Reset Settings';

  @override
  String get resetApplicationConfirmationTitle => 'Reset settings?';

  @override
  String get resetApplicationConfirmationMessage =>
      'Theme and language preferences will be restored to defaults.';

  @override
  String get success => 'Success';

  @override
  String get failure => 'Failure';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationsEmptyMessage => 'You\'re all caught up.';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String get notificationsUnreadBadge => 'Unread';

  @override
  String notificationsSummaryTotal(int count) {
    return '$count notifications';
  }

  @override
  String notificationsSummaryUnread(int count) {
    return '$count unread';
  }

  @override
  String get notificationsSummaryAllRead => 'All caught up';

  @override
  String get notificationsTimeJustNow => 'Just now';

  @override
  String notificationsTimeMinutes(int count) {
    return '${count}m ago';
  }

  @override
  String notificationsTimeHours(int count) {
    return '${count}h ago';
  }

  @override
  String notificationsTimeDays(int count) {
    return '${count}d ago';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get exitAppTitle => 'Exit Application?';

  @override
  String get exitAppMessage => 'Are you sure you want to exit the application?';

  @override
  String get exitAppConfirm => 'Exit';

  @override
  String get splashSubtitle => 'Business Management Platform';

  @override
  String get splashInitErrorTitle => 'Unable to start application';

  @override
  String get splashInitErrorMessage =>
      'Something went wrong while initializing the application.';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get errorStateSubtitle =>
      'Please try again. If the problem continues, check your data and return later.';

  @override
  String get moduleComingSoon => 'Coming soon';

  @override
  String get navigationHome => 'Home';

  @override
  String get navigationDashboard => 'Dashboard';

  @override
  String get navigationServices => 'Services';

  @override
  String get navigationReports => 'Reports';

  @override
  String get quickActionsTitle => 'Quick actions';

  @override
  String get quickActionsSubtitle =>
      'Your pinned shortcuts. Customize to add or reorder.';

  @override
  String get quickActionsCreateProduct => 'Create product';

  @override
  String get quickActionsCreateProductSubtitle => 'Open the new product form.';

  @override
  String get quickActionsScanBarcode => 'Scan barcode or QR';

  @override
  String get quickActionsScanBarcodeSubtitle =>
      'Scan a barcode or QR and open the product.';

  @override
  String get quickActionsCustomize => 'Customize';

  @override
  String get quickActionsCustomizeTitle => 'Customize quick actions';

  @override
  String get quickActionsCustomizeHint =>
      'Choose actions to show, then drag to change their order.';

  @override
  String get quickActionsPinned => 'Pinned actions';

  @override
  String get quickActionsAvailable => 'Available actions';

  @override
  String get quickActionsAdd => 'Add';

  @override
  String get quickActionsRemove => 'Remove';

  @override
  String get quickActionsSave => 'Save';

  @override
  String quickActionsPinnedCount(int count, int max) {
    return '$count / $max pinned';
  }

  @override
  String quickActionsMaxReached(int max) {
    return 'You can pin up to $max quick actions.';
  }

  @override
  String get quickActionsEmptyPinned =>
      'No shortcuts pinned yet. Tap Customize to add some.';

  @override
  String get quickActionsEmptyMessage =>
      'Pin shortcuts here for faster access. You will be able to customize them later.';

  @override
  String get quickActionsAddLabel => 'Add action';

  @override
  String get quickActionsComingSoon =>
      'Quick action customization is coming soon.';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardSubtitle => 'Overview of your business platform.';

  @override
  String get dashboardOpenServices => 'Browse all services';

  @override
  String get dashboardOpenSettings => 'Open settings';

  @override
  String get dashboardMyServices => 'My services';

  @override
  String get dashboardCustomizeServices => 'Customize';

  @override
  String get dashboardCustomizeTitle => 'Customize dashboard services';

  @override
  String get dashboardCustomizeServicesHint =>
      'Choose which services appear on your dashboard, then drag to reorder.';

  @override
  String get dashboardPinnedServices => 'Pinned services';

  @override
  String get dashboardAvailableServices => 'Available services';

  @override
  String get dashboardAddService => 'Add';

  @override
  String get dashboardRemoveService => 'Remove';

  @override
  String get dashboardSaveServices => 'Save';

  @override
  String get dashboardNoServicesTitle => 'No services on dashboard';

  @override
  String get dashboardNoServicesMessage =>
      'Customize your dashboard to add the services you use most.';

  @override
  String get dashboardNoModulesAvailable => 'No services are available yet.';

  @override
  String get platformReportsTitle => 'Reports';

  @override
  String get platformReportsSubtitle =>
      'Choose a module to browse its service reports.';

  @override
  String get platformReportsInventory => 'Inventory reports';

  @override
  String get platformReportsInventorySubtitle =>
      'Stock count and product reports.';

  @override
  String get platformReportsComingSoon =>
      'Cross-module reports will be available in a future release.';

  @override
  String get platformReportsStockCountTitle => 'Stock count report';

  @override
  String get platformReportsStockCountSubtitle =>
      'Count summary, variances, and export.';

  @override
  String get platformReportsProductsTitle => 'Products report';

  @override
  String get platformReportsServiceComingSoon =>
      'Reports for this service are coming soon.';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundMessage => 'The page you are looking for does not exist.';

  @override
  String get goToDashboard => 'Go to Dashboard';

  @override
  String get availableQuantity => 'Available Quantity';

  @override
  String get statusBreakdown => 'Status Breakdown';

  @override
  String get itemName => 'Item Name';

  @override
  String get status => 'Status';

  @override
  String get exportAs => 'Export as';

  @override
  String get exportExcel => 'Excel (.xlsx)';

  @override
  String get exportPdf => 'PDF (.pdf)';

  @override
  String exportPath(String path) {
    return 'Saved to: $path';
  }

  @override
  String get shareExport => 'Share';

  @override
  String get previousPage => 'Previous page';

  @override
  String get nextPage => 'Next page';

  @override
  String paginationPage(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String paginationRange(int from, int to, int total) {
    return '$from-$to of $total';
  }

  @override
  String get paginationItemsPerPage => 'Items per page';

  @override
  String get importParsing => 'Parsing Excel file...';

  @override
  String get importSaving => 'Saving items...';

  @override
  String get emptyWorkbook => 'The Excel file is empty or has no sheets.';

  @override
  String get noValidRows => 'No valid inventory rows were found in the file.';

  @override
  String duplicateRowsCount(int count) {
    return 'Replaced $count duplicate item codes';
  }

  @override
  String get syncSectionTitle => 'Synchronization';

  @override
  String get syncConnectionLabel => 'Connection';

  @override
  String get syncConnectionOnline => 'Online';

  @override
  String get syncConnectionOffline => 'Offline';

  @override
  String get syncLastSyncLabel => 'Last synchronization';

  @override
  String get syncLastSyncNever => 'Never';

  @override
  String get syncPendingChangesLabel => 'Pending changes';

  @override
  String get syncFailedChangesLabel => 'Failed changes';

  @override
  String get syncNowAction => 'Sync Now';

  @override
  String get syncOfflineMessage =>
      'You\'re offline. Changes will sync automatically when an internet connection is available.';

  @override
  String get syncStatusSynced => 'Synced';

  @override
  String get syncStatusSyncing => 'Syncing…';

  @override
  String get syncStatusPending => 'Pending';

  @override
  String get syncStatusFailed => 'Sync failed';

  @override
  String get syncStatusConflict => 'Conflict';

  @override
  String get syncStatusOffline => 'Offline';

  @override
  String get syncCompletedTitle => 'Synchronization completed';

  @override
  String get syncCompletedMessage => 'All changes have been synchronized.';

  @override
  String get syncPartialTitle => 'Some changes could not be synchronized';

  @override
  String get syncFailedTitle => 'Synchronization failed';

  @override
  String get syncFailedMessage => 'Please try again later.';

  @override
  String get loadingPleaseWait => 'Please wait…';

  @override
  String get loadingProcessing => 'Processing…';

  @override
  String get loadingSaving => 'Saving…';

  @override
  String get loadingDeleting => 'Deleting…';

  @override
  String get loadingImportingProducts => 'Importing products…';

  @override
  String get loadingImportingInventory => 'Importing inventory…';

  @override
  String get loadingSavingInventory => 'Saving inventory…';

  @override
  String get loadingSynchronizing => 'Synchronizing…';

  @override
  String get loadingExportingReport => 'Preparing report…';
}
