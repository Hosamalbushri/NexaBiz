import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/permissions/permission_defs.dart';
import '../../../shared/permissions/standard_permission_ops.dart';

/// Sales document permission codes (primary + legacy).
abstract final class SalesPermissions {
  static const view = ['sales.documents.view', 'sales.view'];
  static const create = ['sales.documents.create', 'sales.create'];
  static const update = ['sales.documents.update', 'sales.update'];
  static const delete = ['sales.documents.delete', 'sales.delete'];
  static const post = ['sales.documents.post', 'sales.post'];
  static const cancel = ['sales.documents.cancel', 'sales.cancel'];
  static const duplicate = ['sales.documents.duplicate'];
  static const export = ['sales.documents.export'];
}

PermissionPackageDef salesPermissionPackage() {
  return PermissionPackageDef(
    id: 'sales',
    icon: Icons.point_of_sale_outlined,
    sortOrder: 20,
    titleBuilder: (context) => AppLocalizations.of(context).moduleSales,
    subtitleBuilder: (context) =>
        AppLocalizations.of(context).adminPermPackageSalesHint,
    services: [
      PermissionServiceDef(
        id: 'documents',
        icon: Icons.receipt_long_outlined,
        titleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceSalesDocuments,
        subtitleBuilder: (context) =>
            AppLocalizations.of(context).adminPermServiceSalesDocumentsHint,
        operations: [
          StandardPermissionOps.view(
            'sales.documents.view',
            legacyCodes: const ['sales.view'],
          ),
          StandardPermissionOps.create(
            'sales.documents.create',
            legacyCodes: const ['sales.create'],
          ),
          StandardPermissionOps.update(
            'sales.documents.update',
            legacyCodes: const ['sales.update'],
          ),
          StandardPermissionOps.delete(
            'sales.documents.delete',
            legacyCodes: const ['sales.delete'],
          ),
          StandardPermissionOps.custom(
            code: 'sales.documents.post',
            icon: Icons.check_circle_outline,
            legacyCodes: const ['sales.post'],
            label: (l10n) => l10n.adminPermActionPost,
          ),
          StandardPermissionOps.custom(
            code: 'sales.documents.cancel',
            icon: Icons.cancel_outlined,
            legacyCodes: const ['sales.cancel'],
            label: (l10n) => l10n.adminPermActionCancel,
          ),
          StandardPermissionOps.custom(
            code: 'sales.documents.duplicate',
            icon: Icons.copy_outlined,
            label: (l10n) => l10n.adminPermOpDuplicate,
          ),
          StandardPermissionOps.custom(
            code: 'sales.documents.export',
            icon: Icons.download_outlined,
            label: (l10n) => l10n.adminPermOpInvoiceExport,
          ),
        ],
      ),
    ],
  );
}
