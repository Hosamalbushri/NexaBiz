import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/sync/sync_enabled_provider.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/presentation/scaffolds/module_list_scaffold.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/authentication/presentation/widgets/permission_gate.dart';
import 'package:stock_count/modules/administration/shared/data/admin_api_repository.dart';
import 'package:stock_count/modules/administration/shared/presentation/providers/admin_providers.dart';
import 'admin_role_editor_page.dart';

enum _RoleFilter { all, custom, system }

/// Roles list — searchable cards with clear custom vs system distinction.
class AdminRolesPage extends ConsumerStatefulWidget {
  const AdminRolesPage({super.key});

  @override
  ConsumerState<AdminRolesPage> createState() => _AdminRolesPageState();
}

class _AdminRolesPageState extends ConsumerState<AdminRolesPage> {
  String _searchQuery = '';
  _RoleFilter _filter = _RoleFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final syncOn = ref.watch(syncEnabledProvider);
    final auth = ref.watch(authStateProvider);
    final rolesAsync = ref.watch(adminRolesProvider);
    final canCreate = auth.hasAnyPermission(const [
      'roles.create',
      'roles.manage',
    ]);

    if (!syncOn || !auth.canUseRemoteSync) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.adminRolesTitle),
        ),
        body: AppEmptyState(
          icon: Icons.cloud_off_outlined,
          title: auth.needsSessionRenewal
              ? l10n.syncSessionExpired
              : l10n.adminRequiresOnlineTitle,
          subtitle: auth.needsSessionRenewal
              ? l10n.syncSessionExpired
              : l10n.adminRequiresOnlineMessage,
        ),
      );
    }

    final roles = rolesAsync.valueOrNull ?? const [];
    final filtered = roles.where((role) {
      switch (_filter) {
        case _RoleFilter.custom:
          if (role.systemRole) return false;
        case _RoleFilter.system:
          if (!role.systemRole) return false;
        case _RoleFilter.all:
          break;
      }
      if (_searchQuery.isEmpty) return true;
      return role.name.toLowerCase().contains(_searchQuery) ||
          (role.description?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    return ModuleListScaffold<AdminRoleSummary>(
      title: l10n.adminRolesTitle,
      searchQuery: _searchQuery,
      searchHint: l10n.adminRolesSearchHint,
      onSearchChanged: (val) {
        setState(() => _searchQuery = val.trim().toLowerCase());
      },
      activeFilterCount: _filter != _RoleFilter.all ? 1 : 0,
      activeFilterChips: [
        ChoiceChip(
          label: Text(l10n.adminRolesFilterAll),
          selected: _filter == _RoleFilter.all,
          onSelected: (_) => setState(() => _filter = _RoleFilter.all),
        ),
        ChoiceChip(
          label: Text(l10n.adminRolesFilterCustom),
          selected: _filter == _RoleFilter.custom,
          onSelected: (_) => setState(() => _filter = _RoleFilter.custom),
        ),
        ChoiceChip(
          label: Text(l10n.adminRolesFilterSystem),
          selected: _filter == _RoleFilter.system,
          onSelected: (_) => setState(() => _filter = _RoleFilter.system),
        ),
      ],
      isLoading: rolesAsync.isLoading && !rolesAsync.hasValue,
      error: rolesAsync.error,
      onRetry: () => ref.invalidate(adminRolesProvider),
      onRefresh: () async {
        ref.invalidate(adminRolesProvider);
        await ref.read(adminRolesProvider.future);
      },
      emptyTitle: l10n.adminRolesEmptyTitle,
      emptyMessage: l10n.adminRolesEmptyMessage,
      emptyIcon: Icons.badge_outlined,
      emptyActionLabel: canCreate ? l10n.adminCreateRole : null,
      onEmptyAction: canCreate ? () => _openEditor(context) : null,
      floatingActionButton: PermissionGate(
        anyOf: const ['roles.create', 'roles.manage'],
        child: FloatingActionButton.extended(
          onPressed: () => _openEditor(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.adminCreateRole),
        ),
      ),
      items: filtered,
      itemBuilder: (context, role) {
        return _RoleCard(
          role: role,
          onOpen: () => _openEditor(context, existing: role),
          onDelete: role.systemRole
              ? null
              : () => _confirmDelete(context, role),
        );
      },
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    AdminRoleSummary? existing,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminRoleEditorPage(existing: existing),
      ),
    );
    if (saved == true) {
      ref.invalidate(adminRolesProvider);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AdminRoleSummary role,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteRole),
        content: Text(l10n.adminDeleteRoleConfirm(role.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.adminDeleteRole),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(adminApiRepositoryProvider).deleteRole(role.id);
      ref.invalidate(adminRolesProvider);
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: l10n.adminRoleDeleted,
          isSuccess: true,
        );
      }
    } on AppFailure catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.message, isSuccess: false);
      }
    }
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.onOpen,
    this.onDelete,
  });

  final AdminRoleSummary role;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = role.effectivePermissionCount;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: role.systemRole
                        ? scheme.secondaryContainer
                        : scheme.primaryContainer,
                    foregroundColor: role.systemRole
                        ? scheme.onSecondaryContainer
                        : scheme.onPrimaryContainer,
                    child: Icon(
                      role.systemRole
                          ? Icons.verified_user_outlined
                          : Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role.description?.isNotEmpty == true
                              ? role.description!
                              : (role.systemRole
                                  ? l10n.adminSystemRoleHint
                                  : l10n.adminCustomRoleHint),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: l10n.adminDeleteRole,
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  Icon(
                    Icons.chevron_right,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _Tag(
                    label: role.systemRole
                        ? l10n.adminSystemRole
                        : l10n.adminCustomRole,
                    tone: role.systemRole
                        ? scheme.secondaryContainer
                        : scheme.primaryContainer,
                    onTone: role.systemRole
                        ? scheme.onSecondaryContainer
                        : scheme.onPrimaryContainer,
                  ),
                  _Tag(
                    label: l10n.adminPermissionCount(count),
                    tone: scheme.surfaceContainerHighest,
                    onTone: scheme.onSurface,
                  ),
                  _Tag(
                    label: l10n.adminTapToConfigure,
                    tone: scheme.surfaceContainerHighest,
                    onTone: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.tone,
    required this.onTone,
  });

  final String label;
  final Color tone;
  final Color onTone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: onTone,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
