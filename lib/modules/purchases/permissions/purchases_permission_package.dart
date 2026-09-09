import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/permissions/permission_defs.dart';
import '../../../shared/permissions/standard_permission_ops.dart';

/// Purchases document permission codes.
abstract final class PurchasesPermissions {
  static const view = ['purchases.documents.view', 'purchases.view'];
  static const create = ['purchases.documents.create', 'purchases.create'];
  static const update = ['purchases.documents.update', 'purchases.update'];
  static const delete = ['purchases.documents.delete', 'purchases.delete'];
  static const post = ['purchases.documents.post', 'purchases.post'];
}

PermissionPackageDef purchasesPermissionPackage() {
  return PermissionPackageDef(
    id: 'purchases',
    icon: Icons.shopping_bag_outlined,
    sortOrder: 35,
    titleBuilder: (context) => AppLocalizations.of(context).localeName == 'ar'
        ? 'إعدادات وصلاحيات المشتريات'
        : 'Purchases & Suppliers Permissions',
    subtitleBuilder: (context) =>
        AppLocalizations.of(context).localeName == 'ar'
        ? 'إدارة صلاحيات فواتير واستلام المشتريات والموردين'
        : 'Manage purchase invoices, receiving, and supplier controls',
    services: [
      PermissionServiceDef(
        id: 'documents',
        icon: Icons.receipt_long_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).localeName == 'ar'
            ? 'فواتير وإشعارات المشتريات'
            : 'Purchase Documents',
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).localeName == 'ar'
            ? 'صلاحيات إنشاء واستعراض وترحيل فواتير المشتريات'
            : 'Permissions to create, view, and post purchase invoices',
        operations: [
          StandardPermissionOps.view(
            'purchases.documents.view',
            legacyCodes: const ['purchases.view'],
          ),
          StandardPermissionOps.create(
            'purchases.documents.create',
            legacyCodes: const ['purchases.create'],
          ),
          StandardPermissionOps.update(
            'purchases.documents.update',
            legacyCodes: const ['purchases.update'],
          ),
          StandardPermissionOps.delete(
            'purchases.documents.delete',
            legacyCodes: const ['purchases.delete'],
          ),
          StandardPermissionOps.custom(
            code: 'purchases.documents.post',
            icon: Icons.check_circle_outline,
            legacyCodes: const ['purchases.post'],
            label: (l10n) =>
                l10n.localeName == 'ar' ? 'ترحيل المشتريات' : 'Post Purchases',
          ),
        ],
      ),
    ],
  );
}
