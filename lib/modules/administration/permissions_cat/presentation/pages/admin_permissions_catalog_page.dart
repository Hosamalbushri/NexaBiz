import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/modules/module_providers.dart';
import 'package:stock_count/core/permissions/permission_defs.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/core/auth/presentation/providers/auth_state_core.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

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
    final auth = ref.watch(authStateProvider);

    if (auth.needsSessionRenewal) {
      return Scaffold(
        appBar: CustomAppBar(
          title: l10n.adminPermissionsCatalogTitle,
          centerTitle: false,
          showBackButton: true,
        ),
        body: AppEmptyState(
          icon: Icons.cloud_off_outlined,
          title: l10n.syncSessionExpired,
          subtitle: l10n.syncSessionExpired,
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
        padding: AppConstants.pageInsets(
          context,
        ).copyWith(top: AppSpacing.sm, bottom: AppSpacing.lg),
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
                        () => _packageFilter = _packageFilter == pkg.id
                            ? null
                            : pkg.id,
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

class _PackageCard extends StatefulWidget {
  const _PackageCard({required this.package});

  final PermissionPackageDef package;

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
  bool _expanded = false;

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
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: shadcn.Collapsible(
            isExpanded: _expanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _expanded = !expanded;
              });
            },
            children: [
              shadcn.CollapsibleTrigger(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: Icon(widget.package.icon),
                  ),
                  title: Text(
                    widget.package.title(context),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(widget.package.subtitle(context)),
                  trailing: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ),
              ),
              shadcn.CollapsibleContent(
                child: Column(
                  children: [
                    for (final svc in widget.package.services)
                      _ServiceTile(service: svc),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatefulWidget {
  const _ServiceTile({required this.service});

  final PermissionServiceDef service;

  @override
  State<_ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<_ServiceTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return shadcn.Collapsible(
      isExpanded: _expanded,
      onExpansionChanged: (expanded) {
        setState(() {
          _expanded = !expanded;
        });
      },
      children: [
        shadcn.CollapsibleTrigger(
          child: ListTile(
            contentPadding: const EdgeInsetsDirectional.only(
              start: AppSpacing.md,
              end: AppSpacing.md,
            ),
            leading: Icon(widget.service.icon),
            title: Text(
              widget.service.title(context),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(widget.service.subtitle(context)),
            trailing: AnimatedRotation(
              turns: _expanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ),
        ),
        shadcn.CollapsibleContent(
          child: Column(
            children: [
              for (final op in widget.service.operations)
                ListTile(
                  contentPadding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.lg,
                    end: 16,
                  ),
                  leading: Icon(op.icon, size: 22, color: scheme.primary),
                  title: Text(op.label(context)),
                  dense: true,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

