import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/modules/administration/shared/presentation/admin_localizations_extension.dart';
import 'package:stock_count/app/sync/sync_enabled_provider.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/presentation/scaffolds/module_list_scaffold.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/auth/presentation/providers/auth_state_core.dart';
import 'package:stock_count/core/auth/presentation/widgets/permission_gate_core.dart';
import 'package:stock_count/modules/administration/shared/data/admin_api_repository.dart';
import 'package:stock_count/modules/administration/shared/presentation/providers/admin_providers.dart';

class AdminBranchesPage extends ConsumerStatefulWidget {
  const AdminBranchesPage({super.key});

  @override
  ConsumerState<AdminBranchesPage> createState() => _AdminBranchesPageState();
}

class _AdminBranchesPageState extends ConsumerState<AdminBranchesPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authStateProvider);
    final branchesAsync = ref.watch(adminBranchesProvider);

    if (auth.needsSessionRenewal) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.adminBranchesTitle)),
        body: AppEmptyState(
          icon: Icons.cloud_off_outlined,
          title: l10n.syncSessionExpired,
          subtitle: l10n.syncSessionExpired,
        ),
      );
    }

    final branchesList = branchesAsync.valueOrNull ?? const [];
    final filteredBranches = branchesList.where((b) {
      if (_query.isEmpty) return true;
      return b.name.toLowerCase().contains(_query) ||
          (b.code?.toLowerCase().contains(_query) ?? false) ||
          (b.phone?.toLowerCase().contains(_query) ?? false) ||
          (b.email?.toLowerCase().contains(_query) ?? false);
    }).toList();

    return ModuleListScaffold<AdminBranchSummary>(
      title: l10n.adminBranchesTitle,
      searchQuery: _query,
      searchHint: l10n.adminBranchesSearchHint,
      onSearchChanged: (val) {
        setState(() => _query = val.trim().toLowerCase());
      },
      isLoading: branchesAsync.isLoading && !branchesAsync.hasValue,
      error: branchesAsync.error,
      onRetry: () {
        ref.invalidate(adminBranchesProvider);
      },
      onRefresh: () async {
        ref.invalidate(adminBranchesProvider);
        await ref.read(adminBranchesProvider.future);
      },
      emptyTitle: l10n.adminBranchesEmptyTitle,
      emptyMessage: l10n.adminBranchesEmptyMessage,
      emptyIcon: Icons.account_tree_outlined,
      actions: [
        PermissionGate(
          anyOf: const [
            'branches.create',
            'branches.manage',
            'platform.companies.manage',
          ],
          child: IconButton(
            tooltip: l10n.adminCreateBranch,
            icon: const Icon(Icons.add_business_outlined),
            onPressed: () => _openCreateSheet(context),
          ),
        ),
      ],
      items: filteredBranches,
      itemBuilder: (context, branch) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: branch.isActive
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(
              Icons.account_tree_rounded,
              color: branch.isActive
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          title: Row(
            children: [
              Text(
                branch.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (branch.code != null && branch.code!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    branch.code!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            [
              if (branch.phone != null && branch.phone!.isNotEmpty)
                branch.phone,
              if (branch.email != null && branch.email!.isNotEmpty)
                branch.email,
              if (branch.address != null && branch.address!.isNotEmpty)
                branch.address,
            ].whereType<String>().join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Chip(
                label: Text(
                  branch.isActive ? l10n.statusActive : l10n.statusInactive,
                  style: TextStyle(
                    fontSize: 12,
                    color: branch.isActive
                        ? Colors.green.shade800
                        : Colors.grey.shade700,
                  ),
                ),
                backgroundColor: branch.isActive
                    ? Colors.green.shade50
                    : Colors.grey.shade200,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
              PopupMenuButton<String>(
                onSelected: (val) async {
                  if (val == 'edit') {
                    _openEditSheet(context, branch);
                  } else if (val == 'toggle_status') {
                    await _toggleBranchStatus(context, branch);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n.adminEditBranch),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(
                          branch.isActive
                              ? Icons.block_outlined
                              : Icons.check_circle_outline,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          branch.isActive
                              ? l10n.deactivateBranch
                              : l10n.activateBranch,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleBranchStatus(
    BuildContext context,
    AdminBranchSummary branch,
  ) async {
    final newStatus = branch.isActive ? 'inactive' : 'active';
    try {
      final useCase = ref.read(manageAdminBranchesUseCaseProvider);
      await useCase.setBranchStatus(branchId: branch.id, status: newStatus);
      ref.invalidate(adminBranchesProvider);
      if (mounted) {
        showAppSnackBar(
          context,
          message: newStatus == 'active'
              ? 'Branch activated'
              : 'Branch deactivated',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          message: e is AppFailure ? e.message : e.toString(),
          isSuccess: false,
        );
      }
    }
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BranchEditorSheet(
        onSaved: () {
          ref.invalidate(adminBranchesProvider);
        },
      ),
    );
  }

  void _openEditSheet(BuildContext context, AdminBranchSummary branch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BranchEditorSheet(
        branch: branch,
        onSaved: () {
          ref.invalidate(adminBranchesProvider);
        },
      ),
    );
  }
}

class _BranchEditorSheet extends ConsumerStatefulWidget {
  const _BranchEditorSheet({this.branch, required this.onSaved});

  final AdminBranchSummary? branch;
  final VoidCallback onSaved;

  @override
  ConsumerState<_BranchEditorSheet> createState() => _BranchEditorSheetState();
}

class _BranchEditorSheetState extends ConsumerState<_BranchEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.branch?.name ?? '');
    _codeCtrl = TextEditingController(text: widget.branch?.code ?? '');
    _phoneCtrl = TextEditingController(text: widget.branch?.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.branch?.email ?? '');
    _addressCtrl = TextEditingController(text: widget.branch?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.branch != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 24,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? l10n.adminEditBranch : l10n.adminCreateBranch,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.branchNameLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? l10n.fieldRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeCtrl,
                decoration: InputDecoration(
                  labelText: l10n.branchCodeLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: l10n.save,
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final useCase = ref.read(manageAdminBranchesUseCaseProvider);
      if (widget.branch == null) {
        await useCase.createBranch(
          name: _nameCtrl.text.trim(),
          code: _codeCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
        );
      } else {
        await useCase.updateBranch(
          branchId: widget.branch!.id,
          name: _nameCtrl.text.trim(),
          code: _codeCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
        );
      }
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          message: e is AppFailure ? e.message : e.toString(),
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
