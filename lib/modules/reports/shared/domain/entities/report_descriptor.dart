/// Catalog entry for a report available in the Reports module.
class ReportDescriptor {
  const ReportDescriptor({
    required this.id,
    required this.titleKey,
    required this.subtitleKey,
    required this.routePath,
  });

  final String id;

  /// Localization key resolved in UI (not stored English text).
  final String titleKey;
  final String subtitleKey;
  final String routePath;
}
