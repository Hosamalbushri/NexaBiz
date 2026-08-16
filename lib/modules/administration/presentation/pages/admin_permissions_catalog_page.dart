import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/sync/sync_enabled_provider.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/modules/module_providers.dart';
import '../../../../core/permissions/permission_defs.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';

/// Browse permissions as Package → Service → Operation.
///
/// Packages come from registered modules — add/remove a module in bootstrap
/// and this catalog updates automatically.
class AdminPermissionsCatalogPage extends ConsumerStatefulWidget {
  const AdminPermissionsCatalogPage({super.key});

  @override
  ConsumerState<AdminPermissionsCatalogPage> createState() =>
      _AdminPermissionsCatalogPageState();
}

class _AdminPermissionsCatalogPageState
    extends ConsumerState<AdminPermissionsCatalogPage> {
  final _search = TextEditingController();
  String? _packageFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final syncOn = ref.watch(syncEnabledProvider);
    final remote = ref.watch(authStateProvider).isRemoteSession;

    if (!syncOn || !remote) {
      return Scaffold(
        appBar: CustomAppBar(
          title: l10n.adminPermissionsCatalogTitle,
          centerTitle: false,
          showBackButton: true,
        ),
        body: AppEmptyState(
          icon: Icons.cloud_off_outlined,
          title: l10n.adminRequiresOnlineTitle,
          subtitle: l10n.adminRequiresOnlineMessage,
        ),
      );
    }

    final packages = ref.watch(moduleRegistryProvider).permissionPackages;
    final query = _search.text.trim().toLowerCase();

    final visible = packages.where((pkg) {
      if (_packageFilter != null && pkg.id != _packageFilter) return false;
      if (query.isEmpty) return true;
      if (pkg.title(context).toLowerCase().contains(query)) return true;
      for (final svc in pkg.services) {
        if (svc.title(context).toLowerCase().contains(query)) return true;
        for (final op in svc.operations) {
          if (op.label(context).toLowerCase().contains(query) ||
              op.code.toLowerCase().contains(query)) {
            return true;
          }
        }
      }
      return false;
    }).toList();

    final opCount = visible
        .expand((p) => p.services)
        .expand((s) => s.operations)
        .length;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.adminPermissionsCatalogTitle,
        centerTitle: false,
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context).copyWith(
          top: AppSpacing.sm,
          bottom: AppSpacing.lg,
        ),
        children: [
          Text(
            l10n.adminPermTreeCatalogIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.adminPermissionsSearchHint,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.adminRolesFilterAll),
                  selected: _packageFilter == null,
                  onSelected: (_) => setState(() => _packageFilter = null),
                ),
                for (final pkg in packages)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: AppSpacing.xs,
                    ),
                    child: FilterChip(
                      avatar: Icon(pkg.icon, size: 16),
                      label: Text(pkg.title(context)),
                      selected: _packageFilter == pkg.id,
                      onSelected: (_) => setState(
                        () => _packageFilter =
                            _packageFilter == pkg.id ? null : pkg.id,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.adminPermissionCount(opCount),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (visible.isEmpty)
            AppEmptyState(
              icon: Icons.search_off,
              title: l10n.adminPermissionsEmptyTitle,
              subtitle: l10n.adminPermissionsEmptyMessage,
            )
          else
            ...visible.map((pkg) => _PackageCard(package: pkg)),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package});

  final PermissionPackageDef package;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: false,
          leading: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Icon(package.icon),
          ),
          title: Text(
            package.title(context),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(package.subtitle(context)),
          children: [
            for (final svc in package.services)
              ExpansionTile(
                initiallyExpanded: false,
                tilePadding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.md,
                  end: AppSpacing.md,
                ),
                childrenPadding: EdgeInsets.zero,
                leading: Icon(svc.icon),
                title: Text(
                  svc.title(context),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(svc.subtitle(context)),
                children: [
                  for (final op in svc.operations)
                    ListTile(
                      contentPadding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.lg,
                        end: 16,
                      ),
                      leading: Icon(
                        op.icon,
                        size: 22,
                        color: scheme.primary,
                      ),
                      title: Text(op.label(context)),
                      dense: true,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
