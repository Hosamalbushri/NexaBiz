import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/modules/administration/shared/presentation/admin_localizations_extension.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/presentation/scaffolds/module_list_scaffold.dart';
import 'package:stock_count/core/auth/presentation/providers/auth_state_core.dart';
import 'package:stock_count/core/auth/presentation/widgets/permission_gate_core.dart';
import 'package:stock_count/modules/administration/shared/data/admin_api_repository.dart';
import 'package:stock_count/modules/administration/shared/presentation/providers/admin_providers.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

class AdminCompaniesPage extends ConsumerStatefulWidget {
  const AdminCompaniesPage({super.key});

  @override
  ConsumerState<AdminCompaniesPage> createState() => _AdminCompaniesPageState();
}

class _AdminCompaniesPageState extends ConsumerState<AdminCompaniesPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authStateProvider);
    final companiesAsync = ref.watch(adminCompaniesProvider);

    if (auth.needsSessionRenewal) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.adminCompaniesTitle)),
        body: AppEmptyState(
          icon: Icons.cloud_off_outlined,
          title: l10n.syncSessionExpired,
          subtitle: l10n.syncSessionExpired,
        ),
      );
    }

    final companiesList = companiesAsync.valueOrNull ?? const [];
    final filteredCompanies = companiesList.where((c) {
      if (_query.isEmpty) return true;
      return c.name.toLowerCase().contains(_query) ||
          (c.legalName?.toLowerCase().contains(_query) ?? false) ||
          (c.taxNumber?.toLowerCase().contains(_query) ?? false);
    }).toList();

    return ModuleListScaffold<AdminCompanySummary>(
      title: l10n.adminCompaniesTitle,
      searchQuery: _query,
      searchHint: l10n.adminCompaniesSearchHint,
      onSearchChanged: (val) {
        setState(() => _query = val.trim().toLowerCase());
      },
      isLoading: companiesAsync.isLoading && !companiesAsync.hasValue,
      error: companiesAsync.error,
      onRetry: () {
        ref.invalidate(adminCompaniesProvider);
      },
      onRefresh: () async {
        ref.invalidate(adminCompaniesProvider);
        await ref.read(adminCompaniesProvider.future);
      },
      emptyTitle: l10n.adminCompaniesEmptyTitle,
      emptyMessage: l10n.adminCompaniesEmptyMessage,
      emptyIcon: Icons.business_outlined,
      actions: [
        PermissionGate(
          anyOf: const [
            'companies.create',
            'companies.manage',
            'platform.companies.manage',
          ],
          child: IconButton(
            tooltip: l10n.adminCreateCompany,
            icon: const Icon(Icons.domain_add_outlined),
            onPressed: () => _openCreateSheet(context),
          ),
        ),
      ],
      items: filteredCompanies,
      itemBuilder: (context, company) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: company.isActive
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.business_rounded,
              color: company.isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  company.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              AppStatusBadge(
                label: company.isActive ? l10n.statusActive : l10n.statusInactive,
                tone: company.isActive
                    ? AppStatusTone.success
                    : AppStatusTone.error,
                animate: false,
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (company.legalName != null && company.legalName!.isNotEmpty)
                Text(company.legalName!),
              if (company.taxNumber != null && company.taxNumber!.isNotEmpty)
                Text(
                  '${l10n.taxNumberLabel}: ${company.taxNumber}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          trailing: PermissionGate(
            anyOf: const ['companies.manage', 'platform.companies.manage'],
            child: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') {
                  _openEditSheet(context, company);
                } else if (val == 'toggle_status') {
                  _toggleCompanyStatus(company);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.adminEditCompany),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_status',
                  child: Row(
                    children: [
                      Icon(
                        company.isActive
                            ? Icons.block_outlined
                            : Icons.check_circle_outline,
                        size: 20,
                        color: company.isActive ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        company.isActive
                            ? l10n.deactivateCompany
                            : l10n.activateCompany,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleCompanyStatus(AdminCompanySummary company) async {
    final newStatus = company.isActive ? 'inactive' : 'active';
    try {
      await ref
          .read(manageAdminCompaniesUseCaseProvider)
          .setCompanyStatus(companyId: company.id, status: newStatus);
      ref.invalidate(adminCompaniesProvider);
      if (mounted) {
        showAppSnackBar(
          context,
          message: newStatus == 'active'
              ? 'تم تفعيل الشركة بنجاح'
              : 'تم تعطيل الشركة بنجاح',
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CreateCompanySheet(
        onCreated: () {
          ref.invalidate(adminCompaniesProvider);
        },
      ),
    );
  }

  void _openEditSheet(BuildContext context, AdminCompanySummary company) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _EditCompanySheet(
        company: company,
        onUpdated: () {
          ref.invalidate(adminCompaniesProvider);
        },
      ),
    );
  }
}

class _CreateCompanySheet extends ConsumerStatefulWidget {
  const _CreateCompanySheet({required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<_CreateCompanySheet> createState() =>
      _CreateCompanySheetState();
}

class _CreateCompanySheetState extends ConsumerState<_CreateCompanySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _legalNameCtrl = TextEditingController();
  final _taxNumberCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _legalNameCtrl.dispose();
    _taxNumberCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(manageAdminCompaniesUseCaseProvider)
          .createCompany(
            name: _nameCtrl.text.trim(),
            legalName: _legalNameCtrl.text.trim(),
            taxNumber: _taxNumberCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
          );
      widget.onCreated();
      if (mounted) {
        Navigator.of(context).pop();
        showAppSnackBar(
          context,
          message: 'تم إنشاء الشركة بنجاح',
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.adminCreateCompany,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.companyNameLabel,
                  prefixIcon: const Icon(Icons.business),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? l10n.fieldRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _legalNameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.legalNameLabel,
                  prefixIcon: const Icon(Icons.gavel_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taxNumberCtrl,
                decoration: InputDecoration(
                  labelText: l10n.taxNumberLabel,
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: l10n.save,
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditCompanySheet extends ConsumerStatefulWidget {
  const _EditCompanySheet({required this.company, required this.onUpdated});
  final AdminCompanySummary company;
  final VoidCallback onUpdated;

  @override
  ConsumerState<_EditCompanySheet> createState() => _EditCompanySheetState();
}

class _EditCompanySheetState extends ConsumerState<_EditCompanySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _legalNameCtrl;
  late final TextEditingController _taxNumberCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.company.name);
    _legalNameCtrl = TextEditingController(
      text: widget.company.legalName ?? '',
    );
    _taxNumberCtrl = TextEditingController(
      text: widget.company.taxNumber ?? '',
    );
    _phoneCtrl = TextEditingController(text: widget.company.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.company.email ?? '');
    _addressCtrl = TextEditingController(text: widget.company.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _legalNameCtrl.dispose();
    _taxNumberCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(manageAdminCompaniesUseCaseProvider)
          .updateCompany(
            companyId: widget.company.id,
            name: _nameCtrl.text.trim(),
            legalName: _legalNameCtrl.text.trim(),
            taxNumber: _taxNumberCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
          );
      widget.onUpdated();
      if (mounted) {
        Navigator.of(context).pop();
        showAppSnackBar(
          context,
          message: 'تم تحديث بيانات الشركة بنجاح',
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.adminEditCompany,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.companyNameLabel,
                  prefixIcon: const Icon(Icons.business),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? l10n.fieldRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _legalNameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.legalNameLabel,
                  prefixIcon: const Icon(Icons.gavel_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taxNumberCtrl,
                decoration: InputDecoration(
                  labelText: l10n.taxNumberLabel,
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: l10n.save,
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
