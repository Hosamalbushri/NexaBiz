import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/modules/module_providers.dart';
import '../../../../core/permissions/permission_defs.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/admin_api_repository.dart';
import '../providers/admin_providers.dart';

/// Role editor organized as Package → Service → Operation.
class AdminRoleEditorPage extends ConsumerStatefulWidget {
  const AdminRoleEditorPage({super.key, this.existing});

  final AdminRoleSummary? existing;

  @override
  ConsumerState<AdminRoleEditorPage> createState() =>
      _AdminRoleEditorPageState();
}

class _AdminRoleEditorPageState extends ConsumerState<AdminRoleEditorPage> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  final Set<String> _selected = {};
  final Set<String> _expandedPackages = {};
  final Set<String> _expandedServices = {};
  var _loading = true;
  var _saving = false;
  String? _error;
  String _filter = '';
  bool _readOnlySystem = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _readOnlySystem = existing?.systemRole == true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final packages = ref.read(moduleRegistryProvider).permissionPackages;
      if (packages.isNotEmpty) {
        setState(() {
          _expandedPackages.add(packages.first.id);
          if (packages.first.services.isNotEmpty) {
            _expandedServices.add(
              '${packages.first.id}.${packages.first.services.first.id}',
            );
          }
        });
      }
      _hydrate();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _hydrate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final existing = widget.existing;
      if (existing != null) {
        final full =
            await ref.read(adminApiRepositoryProvider).getRole(existing.id);
        _name.text = full.name;
        _description.text = full.description ?? '';
        _readOnlySystem = full.systemRole;
        _selected
          ..clear()
          ..addAll(_normalizeToPrimary(full.permissions));
      }
      await ref.read(adminPermissionsCatalogProvider.future);
    } on AppFailure catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Map any legacy codes onto primary service-operation codes for the UI.
  Set<String> _normalizeToPrimary(Iterable<String> codes) {
    final registry = ref.read(moduleRegistryProvider);
    final primary = <String>{};
    final known = registry.primaryPermissionCodes;
    for (final code in codes) {
      if (known.contains(code)) {
        primary.add(code);
        continue;
      }
      final op = registry.findPermissionOperation(code);
      if (op != null) primary.add(op.code);
    }
    return primary;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty) {
      setState(() => _error = l10n.adminRoleNameRequired);
      return;
    }
    if (_selected.isEmpty) {
      setState(() => _error = l10n.adminRolePermissionsRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminApiRepositoryProvider);
      // Persist primary codes; server aliases cover legacy checks.
      final codes = _selected.toList()..sort();
      if (widget.existing == null) {
        await repo.createRole(
          name: _name.text,
          description: _description.text,
          permissionCodes: codes,
        );
      } else {
        await repo.updateRole(
          roleId: widget.existing!.id,
          name: _name.text,
          description: _description.text,
          permissionCodes: codes,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleService(PermissionServiceDef service, bool select) {
    setState(() {
      for (final op in service.operations) {
        if (select) {
          _selected.add(op.code);
        } else {
          _selected.remove(op.code);
        }
      }
    });
  }

  void _togglePackage(PermissionPackageDef package, bool select) {
    setState(() {
      for (final service in package.services) {
        for (final op in service.operations) {
          if (select) {
            _selected.add(op.code);
          } else {
            _selected.remove(op.code);
          }
        }
      }
    });
  }

  bool _matchesFilter(BuildContext context, PermissionPackageDef pkg) {
    final q = _filter.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (pkg.title(context).toLowerCase().contains(q)) return true;
    for (final svc in pkg.services) {
      if (svc.title(context).toLowerCase().contains(q)) return true;
      for (final op in svc.operations) {
        if (op.label(context).toLowerCase().contains(q) ||
            op.code.toLowerCase().contains(q)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isCreate = widget.existing == null;
    final canEdit = !_readOnlySystem ||
        ref.watch(authStateProvider).session?.user.isSuperAdmin == true;
    final allPackages = ref.watch(moduleRegistryProvider).permissionPackages;
    final packages =
        allPackages.where((p) => _matchesFilter(context, p)).toList();
    final totalOps = allPackages
        .expand((p) => p.services)
        .expand((s) => s.operations)
        .length;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isCreate ? l10n.adminCreateRole : l10n.adminEditRole,
        centerTitle: false,
        showBackButton: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: AppConstants.pageInsets(context).copyWith(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                    ),
                    children: [
                      if (_readOnlySystem) ...[
                        _Banner(
                          text: l10n.adminSystemRoleReadOnly,
                          color: scheme.secondaryContainer,
                          onColor: scheme.onSecondaryContainer,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      Text(
                        l10n.adminRoleBasicsSection,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _name,
                        enabled: canEdit && !_saving,
                        decoration: InputDecoration(
                          labelText: l10n.adminRoleNameLabel,
                          hintText: l10n.adminRoleNameHint,
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: scheme.surface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _description,
                        enabled: canEdit && !_saving,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: l10n.adminRoleDescriptionLabel,
                          hintText: l10n.adminRoleDescriptionHint,
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: scheme.surface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.adminRolePermissionsSection,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.adminPermTreeHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _SummaryCard(
                        selected: _selected.length,
                        total: totalOps,
                        packages: packages,
                        selectedCodes: _selected,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        enabled: !_saving,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: l10n.adminPermissionsSearchHint,
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: scheme.surface,
                        ),
                        onChanged: (v) => setState(() => _filter = v),
                      ),
                      if (canEdit)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Wrap(
                            spacing: 4,
                            children: [
                              TextButton(
                                onPressed: _saving
                                    ? null
                                    : () => setState(() {
                                          for (final p in allPackages) {
                                            for (final s in p.services) {
                                              for (final o in s.operations) {
                                                _selected.add(o.code);
                                              }
                                            }
                                          }
                                        }),
                                child: Text(l10n.adminSelectAllPermissions),
                              ),
                              TextButton(
                                onPressed: _saving
                                    ? null
                                    : () => setState(_selected.clear),
                                child: Text(l10n.adminClearPermissions),
                              ),
                            ],
                          ),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Text(
                            _error!,
                            style: TextStyle(color: scheme.error),
                          ),
                        ),
                      ...packages.map((pkg) {
                        final pkgKey = pkg.id;
                        final pkgExpanded = _expandedPackages.contains(pkgKey);
                        final pkgOps = pkg.services
                            .expand((s) => s.operations)
                            .toList();
                        final pkgSelected = pkgOps
                            .where((o) => _selected.contains(o.code))
                            .length;
                        final pkgAll = pkgSelected == pkgOps.length &&
                            pkgOps.isNotEmpty;
                        final pkgNone = pkgSelected == 0;

                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Material(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () => setState(() {
                                    if (pkgExpanded) {
                                      _expandedPackages.remove(pkgKey);
                                    } else {
                                      _expandedPackages.add(pkgKey);
                                    }
                                  }),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.md),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              scheme.primaryContainer,
                                          foregroundColor:
                                              scheme.onPrimaryContainer,
                                          child: Icon(pkg.icon),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pkg.title(context),
                                                style: theme
                                                    .textTheme.titleSmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              Text(
                                                pkg.subtitle(context),
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: scheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                              Text(
                                                l10n.adminPermPackageSummary(
                                                  pkg.services.length,
                                                  pkgSelected,
                                                  pkgOps.length,
                                                ),
                                                style: theme
                                                    .textTheme.labelMedium
                                                    ?.copyWith(
                                                  color: scheme.primary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (canEdit)
                                          Checkbox(
                                            tristate: true,
                                            value: pkgAll
                                                ? true
                                                : (pkgNone ? false : null),
                                            onChanged: _saving
                                                ? null
                                                : (v) => _togglePackage(
                                                      pkg,
                                                      v ?? false,
                                                    ),
                                          ),
                                        Icon(
                                          pkgExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (pkgExpanded)
                                  ...pkg.services.map((svc) {
                                    final svcKey = '${pkg.id}.${svc.id}';
                                    final svcExpanded =
                                        _expandedServices.contains(svcKey);
                                    final svcSelected = svc.operations
                                        .where((o) => _selected.contains(o.code))
                                        .length;
                                    final svcAll = svcSelected ==
                                            svc.operations.length &&
                                        svc.operations.isNotEmpty;
                                    final svcNone = svcSelected == 0;

                                    return Column(
                                      children: [
                                        Divider(
                                          height: 1,
                                          color: scheme.outlineVariant
                                              .withValues(alpha: 0.45),
                                        ),
                                        InkWell(
                                          onTap: () => setState(() {
                                            if (svcExpanded) {
                                              _expandedServices.remove(svcKey);
                                            } else {
                                              _expandedServices.add(svcKey);
                                            }
                                          }),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              AppSpacing.lg,
                                              AppSpacing.sm,
                                              AppSpacing.md,
                                              AppSpacing.sm,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(svc.icon, size: 22),
                                                const SizedBox(
                                                  width: AppSpacing.sm,
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        svc.title(context),
                                                        style: theme
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      Text(
                                                        svc.subtitle(context),
                                                        style: theme
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                          color: scheme
                                                              .onSurfaceVariant,
                                                        ),
                                                      ),
                                                      Text(
                                                        l10n
                                                            .adminGroupPermissionSummary(
                                                          svcSelected,
                                                          svc.operations
                                                              .length,
                                                        ),
                                                        style: theme
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              scheme.primary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (canEdit)
                                                  Checkbox(
                                                    tristate: true,
                                                    value: svcAll
                                                        ? true
                                                        : (svcNone
                                                            ? false
                                                            : null),
                                                    onChanged: _saving
                                                        ? null
                                                        : (v) =>
                                                            _toggleService(
                                                              svc,
                                                              v ?? false,
                                                            ),
                                                  ),
                                                Icon(
                                                  svcExpanded
                                                      ? Icons.expand_less
                                                      : Icons.expand_more,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (svcExpanded)
                                          ...svc.operations.map((op) {
                                            return CheckboxListTile(
                                              contentPadding:
                                                  const EdgeInsetsDirectional
                                                      .only(
                                                start: AppSpacing.xxl,
                                                end: AppSpacing.md,
                                              ),
                                              value:
                                                  _selected.contains(op.code),
                                              onChanged: !canEdit || _saving
                                                  ? null
                                                  : (v) {
                                                      setState(() {
                                                        if (v == true) {
                                                          _selected
                                                              .add(op.code);
                                                        } else {
                                                          _selected
                                                              .remove(op.code);
                                                        }
                                                      });
                                                    },
                                              controlAffinity:
                                                  ListTileControlAffinity
                                                      .leading,
                                              title: Text(
                                                op.label(context),
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Text(
                                                op.code,
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: scheme
                                                      .onSurfaceVariant,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            );
                                          }),
                                      ],
                                    );
                                  }),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                if (canEdit)
                  Material(
                    elevation: 6,
                    color: scheme.surface,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.adminSelectedPermissionsCount(
                                  _selected.length,
                                ),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Flexible(
                              child: AppButton(
                                label: l10n.quickActionsSave,
                                expand: true,
                                isLoading: _saving,
                                onPressed: _saving ? null : _save,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.color,
    required this.onColor,
  });

  final String text;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: onColor),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.selected,
    required this.total,
    required this.packages,
    required this.selectedCodes,
  });

  final int selected;
  final int total;
  final List<PermissionPackageDef> packages;
  final Set<String> selectedCodes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabledPackages = packages.where((p) {
      return p.services.any(
        (s) => s.operations.any((o) => selectedCodes.contains(o.code)),
      );
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminSelectedPermissionsCount(selected),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : selected / total,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.adminRoleVisibleModules,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (enabledPackages.isEmpty)
            Text(
              l10n.adminRoleNoModulesYet,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final p in enabledPackages)
                  Chip(
                    avatar: Icon(p.icon, size: 16),
                    label: Text(p.title(context)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
