import '../../../../core/audit/domain/services/audit_trail_service.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../repositories/admin_repository.dart';

class ManageAdminSettingsUseCase {
  const ManageAdminSettingsUseCase(
    this._repository, {
    this.permissionGuard,
    this.auditTrailService,
  });

  final AdminRepository _repository;
  final PermissionGuard? permissionGuard;
  final AuditTrailService? auditTrailService;

  static const _viewPermissions = [
    'settings.view',
    'settings.manage',
    'platform.companies.manage',
  ];

  static const _managePermissions = [
    'settings.update',
    'settings.manage',
    'platform.companies.manage',
  ];

  static const List<String> supportedDomains = [
    'system_setup',
    'authentication',
    'accounting',
    'inventory',
    'cash_registers',
    'sales',
    'receipts_payments',
    'reports',
    'sync',
    'administration',
  ];

  static const List<String> supportedModules = [
    'accounting',
    'cash_registers',
    'customers',
    'inventory',
    'sales',
    'receipts_payments',
    'reports',
    'sync',
    'system_setup',
    'authentication',
    'app_lock',
  ];

  Future<Map<String, dynamic>> getCompanySettings() async {
    permissionGuard?.requireAny(_viewPermissions);
    return _repository.getCompanySettings();
  }

  Future<void> updateCompanySettings(Map<String, dynamic> settings) async {
    permissionGuard?.requireAny(_managePermissions);
    _validateCompanySettings(settings);

    await _repository.updateCompanySettings(settings);

    await auditTrailService?.recordEvent(
      documentId: 'company_settings',
      documentType: 'company_settings',
      eventType: 'company_settings.updated',
      notes: 'Updated company configuration settings',
      metadata: {'keys': settings.keys.toList()},
    );
  }

  Future<Map<String, dynamic>> getModuleSettings(String moduleId) async {
    permissionGuard?.requireAny(_viewPermissions);
    if (!supportedModules.contains(moduleId)) {
      throw ValidationFailure(
        'Unsupported module setting identifier: $moduleId',
      );
    }
    return _repository.getModuleSettings(moduleId);
  }

  Future<void> updateModuleSettings(
    String moduleId,
    Map<String, dynamic> settings,
  ) async {
    permissionGuard?.requireAny(_managePermissions);
    if (!supportedModules.contains(moduleId)) {
      throw ValidationFailure(
        'Unsupported module setting identifier: $moduleId',
      );
    }

    _validateModuleSettings(moduleId, settings);

    await _repository.updateModuleSettings(moduleId, settings);

    await auditTrailService?.recordEvent(
      documentId: moduleId,
      documentType: 'module_settings',
      eventType: 'module_settings.updated',
      notes: 'Updated module configuration settings for $moduleId',
      metadata: {'moduleId': moduleId, 'keys': settings.keys.toList()},
    );
  }

  void _validateCompanySettings(Map<String, dynamic> settings) {
    for (final entry in settings.entries) {
      if (entry.key == 'session_timeout_minutes' && entry.value is num) {
        if ((entry.value as num) < 1) {
          throw const ValidationFailure(
            'Session timeout must be at least 1 minute.',
          );
        }
      }
    }
  }

  void _validateModuleSettings(String moduleId, Map<String, dynamic> settings) {
    if (moduleId == 'inventory' && settings.containsKey('costing_method')) {
      final method = settings['costing_method'];
      if (method != 'fifo' && method != 'avco') {
        throw const ValidationFailure(
          'Inventory costing method must be fifo or avco.',
        );
      }
    }
  }
}
