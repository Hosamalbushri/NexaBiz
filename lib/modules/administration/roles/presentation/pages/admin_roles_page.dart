import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/sync/sync_enabled_provider.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
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
  final _search = TextEditingController();
  _RoleFilter _filter = _RoleFilter.all;

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
    final auth = ref.watch(authStateProvider);
    final rolesAsync = ref.watch(adminRolesProvider);
    final canCreate = auth.hasAnyPermission(const [
      'roles.create',
      'roles.manage',
    ]);

    if (!syncOn || !auth.canUseRemoteSync) {
      return Scaffold(
        appBar: CustomAppBar(
          title: l10n.adminRolesTitle,
          centerTitle: false,
          showBackButton: true,
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

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.adminRolesTitle,
        centerTitle: false,
        showBackButton: true,
      ),
      floatingActionButton: PermissionGate(
        anyOf: const ['roles.create', 'roles.manage'],
        child: FloatingActionButton.extended(
          onPressed: () => _openEditor(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.adminCreateRole),
        ),
      ),
      body: rolesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: l10n.adminRolesLoadError,
          subtitle: e is AppFailure ? e.message : e.toString(),
        ),
        data: (roles) {
          final query = _search.text.trim().toLowerCase();
          final filtered = roles.where((role) {
            switch (_filter) {
              case _RoleFilter.custom:
                if (role.systemRole) return false;
              case _RoleFilter.system:
                if (!role.systemRole) return false;
              case _RoleFilter.all:
                break;
            }
            if (query.isEmpty) return true;
            return role.name.toLowerCase().contains(query) ||
                (role.description?.toLowerCase().contains(query) ?? false);
          }).toList();

          final customCount = roles.where((r) => !r.systemRole).length;
          final systemCount = roles.length - customCount;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminRolesProvider);
              await ref.read(adminRolesProvider.future);
            },
            child: ListView(
              padding: AppConstants.pageInsets(context).copyWith(
                top: AppSpacing.sm,
                bottom: 100,
              ),
              children: [
                Text(
                  l10n.adminRolesPageIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _StatsRow(
                  total: roles.length,
                  custom: customCount,
                  system: systemCount,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.adminRolesSearchHint,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.adminRolesFilterAll),
                      selected: _filter == _RoleFilter.all,
                      onSelected: (_) =>
                          setState(() => _filter = _RoleFilter.all),
                    ),
                    ChoiceChip(
                      label: Text(l10n.adminRolesFilterCustom),
                      selected: _filter == _RoleFilter.custom,
                      onSelected: (_) =>
                          setState(() => _filter = _RoleFilter.custom),
                    ),
                    ChoiceChip(
                      label: Text(l10n.adminRolesFilterSystem),
                      selected: _filter == _RoleFilter.system,
                      onSelected: (_) =>
                          setState(() => _filter = _RoleFilter.system),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: AppEmptyState(
                      icon: Icons.badge_outlined,
                      title: l10n.adminRolesEmptyTitle,
                      subtitle: l10n.adminRolesEmptyMessage,
                      actionLabel: canCreate ? l10n.adminCreateRole : null,
                      onAction:
                          canCreate ? () => _openEditor(context) : null,
                    ),
                  )
                else
                  ...filtered.map(
                    (role) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _RoleCard(
                        role: role,
                        onOpen: () => _openEditor(context, existing: role),
                        onDelete: role.systemRole
                            ? null
                            : () => _confirmDelete(context, role),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.total,
    required this.custom,
    required this.system,
  });

  final int total;
  final int custom;
  final int system;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(child: _StatChip(label: l10n.adminRolesStatTotal, value: total)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _StatChip(label: l10n.adminRolesFilterCustom, value: custom),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _StatChip(label: l10n.adminRolesFilterSystem, value: system),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
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
