/// Drift file names scoped by company so local books do not mix on switch.
///
/// The bootstrap / default local company keeps the historical file name so
/// existing installs are not orphaned after this change.
String tenantDbName(
  String baseName, {
  String? companyId,
  String? legacyCompanyId,
}) {
  final id = companyId?.trim() ?? '';
  if (id.isEmpty) {
    return baseName;
  }
  if (legacyCompanyId != null && id == legacyCompanyId) {
    return baseName;
  }
  final safe = id.toLowerCase().replaceAll(RegExp(r'[^0-9a-f]'), '');
  if (safe.length < 8) {
    return baseName;
  }
  return '${baseName}_$safe';
}
