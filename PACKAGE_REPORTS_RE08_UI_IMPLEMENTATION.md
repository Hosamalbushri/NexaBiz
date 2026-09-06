# RE-08 — REPORT UI / UX CONSOLIDATION

## 1. UI Architecture & Design System Integration

All report pages in `lib/modules/reports/` have been consolidated to conform to canonical NexaBiz ERP UI/UX patterns:

### Canonical Components Used
- **App Bar**: `CustomAppBar` with centralized title, subtitle, and back navigation.
- **Filter Panel**: `AppReportQueryFilterPanel` with date pickers (`showDatePicker`), clear buttons, posting scope toggles (`Posted Only`), and generation trigger buttons.
- **Page Layout**: `Scaffold` with responsive padding `AppConstants.pageInsets(context)` supporting Mobile, Tablet, and Desktop screen widths.
- **State Handling**:
  - `LoadingController`: Centrally managed loading indicator (`ref.read(loadingControllerProvider).run(...)`) blocking double submissions.
  - `AppSnackBar`: Standardized error and success notifications (`showAppSnackBar`).
  - `Empty State`: Localized empty state card when zero rows match filter.
- **PDF Preview**: `PdfDocumentPreviewPage` providing zoom, printing, and file export options.

---

## 2. Localization, RTL & Number Formatting

- **Text Direction**: Native RTL text rendering via Flutter's `Directionality` and PDF `ReportPdfContext.create(isRtl: locale.languageCode == 'ar')`.
- **Arabic Strings**: 100% Arabic report headers and titles extracted to localization context.
- **Financial Formatting**: Clean, consistent currency formatting using `NumberFormat('#,##0.00', 'en')` for figures and localized dates (`yyyy-MM-dd` / `dd-MM-yyyy`).
- **Zero Business Logic in UI**: UI widgets act strictly as presentation views receiving pre-calculated payload data models.
