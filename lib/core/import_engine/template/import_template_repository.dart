import 'dart:convert';
import '../domain/exceptions/tenant_isolation_exception.dart';
import 'import_template.dart';

/// Repository port for persistent CRUD management of [ImportTemplate]s.
abstract class ImportTemplateRepository {
  /// Saves a new [ImportTemplate]. Throws if templateId already exists.
  Future<void> createTemplate(ImportTemplate template);

  /// Retrieves an [ImportTemplate] by [templateId] and [companyId].
  Future<ImportTemplate?> getTemplate(String templateId, {required String companyId});

  /// Updates an existing [ImportTemplate].
  Future<void> updateTemplate(ImportTemplate template);

  /// Deletes an [ImportTemplate] by [templateId] for [companyId].
  Future<void> deleteTemplate(String templateId, {required String companyId});

  /// Lists all templates for a specific [companyId] (tenant isolated).
  Future<List<ImportTemplate>> listTemplatesForCompany(String companyId);
}

/// In-memory & JSON-serializable persistent implementation of [ImportTemplateRepository].
/// Enforces strict multi-company tenant isolation on all operations.
class InMemoryImportTemplateRepository implements ImportTemplateRepository {
  InMemoryImportTemplateRepository([Map<String, String>? initialStorage]) {
    if (initialStorage != null) {
      _storage.addAll(initialStorage);
      for (final entry in _storage.entries) {
        try {
          final map = jsonDecode(entry.value) as Map<String, dynamic>;
          _templates[entry.key] = ImportTemplate.fromJson(map);
        } catch (_) {}
      }
    }
  }

  final Map<String, String> _storage = {};
  final Map<String, ImportTemplate> _templates = {};

  Map<String, String> exportStorage() => Map<String, String>.unmodifiable(_storage);

  @override
  Future<void> createTemplate(ImportTemplate template) async {
    if (template.companyId.trim().isEmpty) {
      throw ArgumentError('Cannot create ImportTemplate without a valid companyId');
    }
    if (_storage.containsKey(template.templateId)) {
      throw StateError('ImportTemplate with ID "${template.templateId}" already exists.');
    }
    await _persist(template);
  }

  @override
  Future<ImportTemplate?> getTemplate(String templateId, {required String companyId}) async {
    final template = _templates[templateId] ?? _loadFromStorage(templateId);
    if (template == null) return null;
    // Strict multi-company tenant isolation guard: return null on cross-company query
    if (template.companyId != companyId) {
      return null;
    }
    return template;
  }

  @override
  Future<void> updateTemplate(ImportTemplate template) async {
    final existing = _templates[template.templateId] ?? _loadFromStorage(template.templateId);
    if (existing == null) {
      throw StateError('ImportTemplate "${template.templateId}" not found for company "${template.companyId}".');
    }
    if (existing.companyId != template.companyId) {
      throw TenantIsolationException(
        'Cross-company template modification violation: Template "${template.templateId}" belongs to company "${existing.companyId}", but update was attempted under company "${template.companyId}"',
        expectedCompanyId: existing.companyId,
        attemptedCompanyId: template.companyId,
      );
    }
    final updated = template.copyWith(updatedAt: DateTime.now().toUtc());
    await _persist(updated);
  }

  @override
  Future<void> deleteTemplate(String templateId, {required String companyId}) async {
    final existing = _templates[templateId] ?? _loadFromStorage(templateId);
    if (existing != null && existing.companyId != companyId) {
      throw TenantIsolationException(
        'Cross-company template deletion violation: Template "$templateId" belongs to company "${existing.companyId}", but deletion was attempted under company "$companyId"',
        expectedCompanyId: companyId,
        attemptedCompanyId: existing.companyId,
      );
    }
    if (existing == null) {
      throw StateError('ImportTemplate "$templateId" not found for company "$companyId".');
    }
    _storage.remove(templateId);
    _templates.remove(templateId);
  }

  @override
  Future<List<ImportTemplate>> listTemplatesForCompany(String companyId) async {
    if (companyId.trim().isEmpty) return [];
    // Ensure storage is fully loaded
    for (final id in _storage.keys) {
      if (!_templates.containsKey(id)) {
        _loadFromStorage(id);
      }
    }
    return _templates.values
        .where((t) => t.companyId == companyId)
        .toList();
  }

  Future<void> _persist(ImportTemplate template) async {
    final jsonStr = jsonEncode(template.toJson());
    _storage[template.templateId] = jsonStr;
    _templates[template.templateId] = template;
  }

  ImportTemplate? _loadFromStorage(String templateId) {
    final raw = _storage[templateId];
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final template = ImportTemplate.fromJson(map);
    _templates[templateId] = template;
    return template;
  }
}
