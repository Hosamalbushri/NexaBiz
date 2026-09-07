import 'package:flutter/widgets.dart';
import 'package:stock_count/core/permissions/permission_defs.dart';

/// Permission codes for Cash Register management and operations.
abstract final class CashRegisterPermissions {
  static const view = ['cash_registers.view', 'accounting.journals.view'];
  static const create = ['cash_registers.create', 'accounting.accounts.create'];
  static const update = ['cash_registers.update', 'accounting.accounts.update'];
  static const delete = ['cash_registers.delete'];
  static const link = ['cash_registers.link', 'accounting.accounts.update'];
  static const transfer = [
    'cash_registers.transfer',
    'accounting.journals.create',
  ];
  static const configure = ['cash_registers.configure'];

  static const _icon = IconData(0xe49c, fontFamily: 'MaterialIcons');

  /// Package definition for system administration catalog integration.
  static final packageDef = PermissionPackageDef(
    id: 'cash_registers',
    icon: _icon,
    titleBuilder: (_) => 'صناديق النقدية',
    subtitleBuilder: (_) => 'إدارة وتحويلات الصناديق والمحاسبة',
    sortOrder: 25,
    services: [
      PermissionServiceDef(
        id: 'cash_registers',
        icon: _icon,
        titleBuilder: (_) => 'الصناديق النقدية',
        subtitleBuilder: (_) => 'ربط وتحويلات وتكوين الصناديق',
        operations: const [
          PermissionOperationDef(
            code: 'cash_registers.view',
            icon: _icon,
            labelBuilder: _viewLabel,
          ),
          PermissionOperationDef(
            code: 'cash_registers.create',
            icon: _icon,
            labelBuilder: _createLabel,
          ),
          PermissionOperationDef(
            code: 'cash_registers.update',
            icon: _icon,
            labelBuilder: _updateLabel,
          ),
          PermissionOperationDef(
            code: 'cash_registers.delete',
            icon: _icon,
            labelBuilder: _deleteLabel,
          ),
          PermissionOperationDef(
            code: 'cash_registers.link',
            icon: _icon,
            labelBuilder: _linkLabel,
          ),
          PermissionOperationDef(
            code: 'cash_registers.transfer',
            icon: _icon,
            labelBuilder: _transferLabel,
          ),
          PermissionOperationDef(
            code: 'cash_registers.configure',
            icon: _icon,
            labelBuilder: _configureLabel,
          ),
        ],
      ),
    ],
  );

  static String _viewLabel(BuildContext _) => 'عرض الصناديق';
  static String _createLabel(BuildContext _) => 'إنشاء صندوق جديد';
  static String _updateLabel(BuildContext _) => 'تعديل الصندوق';
  static String _deleteLabel(BuildContext _) => 'حذف الصندوق';
  static String _linkLabel(BuildContext _) => 'ربط/فك ربط الحساب المحاسبي';
  static String _transferLabel(BuildContext _) => 'تحويل بين الصناديق';
  static String _configureLabel(BuildContext _) => 'تحديد الصندوق الافتراضي';
}
