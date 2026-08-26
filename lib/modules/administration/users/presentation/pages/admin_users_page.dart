import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/sync/sync_enabled_provider.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/authentication/presentation/widgets/permission_gate.dart';
import 'package:stock_count/modules/administration/shared/data/admin_api_repository.dart';
import 'package:stock_count/modules/administration/shared/presentation/providers/admin_providers.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final syncOn = ref.watch(syncEnabledProvider);
    final auth = ref.watch(authStateProvider);
    final usersAsync = ref.watch(adminUsersProvider);

    if (!syncOn || !auth.canUseRemoteSync) {
      return Scaffold(
        appBar: CustomAppBar(
          title: l10n.adminUsersTitle,
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
      appBar: CustomAppBar(
        title: l10n.adminUsersTitle,
        centerTitle: false,
        showBackButton: true,
        actions: [
          PermissionGate(
            anyOf: const [
              'users.create',
              'users.manage',
              'platform.users.manage',
            ],
            child: IconButton(
              tooltip: l10n.adminCreateUser,
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () => _openCreateSheet(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.adminUsersSearchHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppEmptyState(
                icon: Icons.error_outline,
                title: l10n.adminUsersLoadError,
                subtitle: e is AppFailure ? e.message : e.toString(),
              ),
              data: (users) {
                final filtered = users.where((u) {
                  if (_query.isEmpty) return true;
                  return u.name.toLowerCase().contains(_query) ||
                      u.email.toLowerCase().contains(_query);
                }).toList();
                if (filtered.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.people_outline,
                    title: l10n.adminUsersEmptyTitle,
                    subtitle: l10n.adminUsersEmptyMessage,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminUsersProvider);
                    await ref.read(adminUsersProvider.future);
                  },
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name.characters.first.toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(user.name),
                        subtitle: Text(
                          '${user.email} · ${user.status}'
                          '${user.isSuperAdmin ? ' · admin' : ''}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) =>
                              _onUserAction(context, user, value),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(l10n.adminEditUser),
                            ),
                            if (user.status == 'active')
                              PopupMenuItem(
                                value: 'suspend',
                                child: Text(l10n.adminSuspendUser),
                              )
                            else
                              PopupMenuItem(
                                value: 'activate',
                                child: Text(l10n.adminActivateUser),
                              ),
                            PopupMenuItem(
                              value: 'deactivate',
                              child: Text(l10n.adminDeactivateUser),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onUserAction(
    BuildContext context,
    AdminUserSummary user,
    String action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(adminApiRepositoryProvider);
    try {
      switch (action) {
        case 'edit':
          await _openEditSheet(context, user);
          return;
        case 'suspend':
          await repo.setUserStatus(userId: user.id, status: 'suspended');
          break;
        case 'activate':
          await repo.setUserStatus(userId: user.id, status: 'active');
          break;
        case 'deactivate':
          await repo.deactivateUser(user.id);
          break;
      }
      ref.invalidate(adminUsersProvider);
      if (context.mounted) {
        showAppSnackBar(context, message: l10n.adminUserUpdated, isSuccess: true);
      }
    } on AppFailure catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.message, isSuccess: false);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isSuccess: false);
      }
    }
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _UserFormSheet(),
    );
    if (created == true) {
      ref.invalidate(adminUsersProvider);
    }
  }

  Future<void> _openEditSheet(
    BuildContext context,
    AdminUserSummary user,
  ) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _UserFormSheet(existing: user),
    );
    if (updated == true) {
      ref.invalidate(adminUsersProvider);
    }
  }
}

class _UserFormSheet extends ConsumerStatefulWidget {
  const _UserFormSheet({this.existing});

  final AdminUserSummary? existing;

  @override
  ConsumerState<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends ConsumerState<_UserFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  late final TextEditingController _confirm;
  String _status = 'active';
  String? _roleId;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = widget.existing;
    _name = TextEditingController(text: u?.name ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _password = TextEditingController();
    _confirm = TextEditingController();
    _status = u?.status ?? 'active';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final isCreate = widget.existing == null;
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) {
      setState(() => _error = l10n.adminUserValidationError);
      return;
    }
    if (isCreate) {
      if (_password.text.length < 8) {
        setState(() => _error = l10n.adminPasswordTooShort);
        return;
      }
      if (_password.text != _confirm.text) {
        setState(() => _error = l10n.adminPasswordMismatch);
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminApiRepositoryProvider);
      final companyId =
          ref.read(authStateProvider).session?.currentCompanyId;
      if (isCreate) {
        await repo.createUser(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          phone: _phone.text,
          status: _status,
          roleId: _roleId,
          companyId: companyId,
        );
        _password.clear();
        _confirm.clear();
      } else {
        await repo.updateUser(
          userId: widget.existing!.id,
          name: _name.text,
          phone: _phone.text,
          status: _status,
          password: _password.text.isEmpty ? null : _password.text,
        );
        _password.clear();
        _confirm.clear();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rolesAsync = ref.watch(adminRolesProvider);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isCreate = widget.existing == null;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCreate ? l10n.adminCreateUser : l10n.adminEditUser,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.adminUserNameLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _email,
              enabled: isCreate,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.authEmailLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.adminUserPhoneLabel),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(labelText: l10n.adminUserStatusLabel),
              items: [
                DropdownMenuItem(value: 'active', child: Text(l10n.adminStatusActive)),
                DropdownMenuItem(
                  value: 'inactive',
                  child: Text(l10n.adminStatusInactive),
                ),
                DropdownMenuItem(
                  value: 'suspended',
                  child: Text(l10n.adminStatusSuspended),
                ),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'active'),
            ),
            if (isCreate) ...[
              const SizedBox(height: 8),
              rolesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (roles) => DropdownButtonFormField<String>(
                  value: _roleId,
                  decoration:
                      InputDecoration(labelText: l10n.adminUserRoleLabel),
                  items: [
                    for (final role in roles)
                      DropdownMenuItem(
                        value: role.id,
                        child: Text(role.name),
                      ),
                  ],
                  onChanged: (v) => setState(() => _roleId = v),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: isCreate
                    ? l10n.authPasswordLabel
                    : l10n.adminNewPasswordOptional,
              ),
            ),
            if (isCreate) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _confirm,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.adminConfirmPasswordLabel,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: l10n.quickActionsSave,
              expand: true,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
