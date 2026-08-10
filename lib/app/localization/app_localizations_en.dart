// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Business Platform';

  @override
  String get servicesTitle => 'Services';

  @override
  String get servicesSubtitle => 'Choose a business module to get started.';

  @override
  String get moduleInventory => 'Inventory';

  @override
  String get moduleInventoryDescription =>
      'Counting, import, and stock reports.';

  @override
  String get modulePlaceholderMessage =>
      'This module is registered and ready. Business features will be added in the next stages.';

  @override
  String get inventoryOverview => 'Overview';

  @override
  String get inventoryCountTitle => 'Inventory Count';

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
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get exitAppTitle => 'Exit the app?';

  @override
  String get exitAppMessage => 'Do you want to close the application now?';

  @override
  String get exitAppConfirm => 'Exit';

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
}
