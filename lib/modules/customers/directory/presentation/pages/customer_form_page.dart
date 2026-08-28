import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/exit/app_exit_scope.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';

import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_expandable_form_section.dart';
import 'package:stock_count/core/widgets/app_form_section.dart';
import 'package:stock_count/core/widgets/app_responsive.dart';
import 'package:stock_count/core/widgets/app_responsive_scaffold.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_data_source.dart';
import '../../domain/models/customer_exception.dart';
import 'package:stock_count/modules/customers/accounts/domain/services/customer_account_link_port.dart';
import '../providers/customer_providers.dart';

class CustomerFormPage extends ConsumerStatefulWidget {
  const CustomerFormPage({super.key, this.customerId});

  final int? customerId;

  bool get isEditing => customerId != null;

  @override
  ConsumerState<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends ConsumerState<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _accountController = TextEditingController();
  final _externalIdController = TextEditingController();

  var _hydrated = false;
  var _saving = false;
  var _generatingCode = false;
  var _isActive = true;
  var _dataSource = CustomerDataSource.local;
  LinkedAccountRef? _linkedAccount;

  // Snapshot of initial values for dirty detection.
  String _initialCode = '';
  String _initialName = '';
  String _initialPhone = '';
  String _initialEmail = '';
  String _initialAddress = '';
  String _initialNotes = '';
  String _initialAccount = '';
  String _initialExternalId = '';
  bool _initialIsActive = true;
  CustomerDataSource _initialDataSource = CustomerDataSource.local;

  @override
  void initState() {
    super.initState();
    if (!widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_assignAutoCode());
      });
    }
  }

  Future<void> _assignAutoCode() async {
    if (!mounted || widget.isEditing || _codeController.text.isNotEmpty) {
      return;
    }
    setState(() => _generatingCode = true);
    try {
      final code = await _generateCodeFromParent();
      if (!mounted || code == null) {
        return;
      }
      _codeController.text = code;
    } finally {
      if (mounted) {
        setState(() => _generatingCode = false);
      }
    }
  }

  Future<String?> _generateCodeFromParent() async {
    final l10n = AppLocalizations.of(context);
    var parent = ref.read(customersParentAccountProvider).valueOrNull;
    if (parent == null) {
      await ref.read(customersParentAccountProvider.notifier).refresh();
      if (!mounted) {
        return null;
      }
      parent = ref.read(customersParentAccountProvider).valueOrNull;
    }
    if (parent == null || parent.code.trim().isEmpty) {
      showAppSnackBar(
        context,
        message: l10n.customersParentAccountNotSet,
        isSuccess: false,
      );
      return null;
    }
    return ref
        .read(customerCodeGeneratorProvider)
        .generate(
          parentAccountCode: parent.code,
          parentAccountId: parent.accountId,
        );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _accountController.dispose();
    _externalIdController.dispose();
    super.dispose();
  }

  Future<void> _hydrate(Customer customer) async {
    if (_hydrated) {
      return;
    }
    _hydrated = true;
    _codeController.text = customer.customerCode;
    _nameController.text = customer.name;
    _phoneController.text = customer.phone ?? '';
    _emailController.text = customer.email ?? '';
    _addressController.text = customer.address ?? '';
    _notesController.text = customer.notes ?? '';
    _externalIdController.text = customer.externalId ?? '';
    _isActive = customer.isActive;
    _dataSource = customer.dataSource;

    // Save initial snapshot for dirty detection.
    _initialCode = _codeController.text;
    _initialName = _nameController.text;
    _initialPhone = _phoneController.text;
    _initialEmail = _emailController.text;
    _initialAddress = _addressController.text;
    _initialNotes = _notesController.text;
    _initialExternalId = _externalIdController.text;
    _initialIsActive = _isActive;
    _initialDataSource = _dataSource;

    final accountId = customer.accountId;
    if (accountId != null) {
      final linked = await ref
          .read(customerAccountLinkPortProvider)
          .findById(accountId);
      if (linked != null) {
        _linkedAccount = linked;
        _accountController.text = linked.code;
      } else {
        _accountController.text = accountId;
      }
    }
    _initialAccount = _accountController.text;
    if (mounted) {
      setState(() {});
    }
  }

  bool _hasUnsavedChanges() {
    if (!widget.isEditing && !_hydrated) {
      // New form — any non-empty field means dirty.
      return _codeController.text.trim().isNotEmpty ||
          _nameController.text.trim().isNotEmpty ||
          _phoneController.text.trim().isNotEmpty ||
          _emailController.text.trim().isNotEmpty ||
          _addressController.text.trim().isNotEmpty ||
          _notesController.text.trim().isNotEmpty ||
          _externalIdController.text.trim().isNotEmpty ||
          _accountController.text.trim().isNotEmpty ||
          !_isActive ||
          _dataSource != CustomerDataSource.local;
    }
    return _codeController.text != _initialCode ||
        _nameController.text != _initialName ||
        _phoneController.text != _initialPhone ||
        _emailController.text != _initialEmail ||
        _addressController.text != _initialAddress ||
        _notesController.text != _initialNotes ||
        _externalIdController.text != _initialExternalId ||
        _accountController.text != _initialAccount ||
        _isActive != _initialIsActive ||
        _dataSource != _initialDataSource;
  }

  Future<void> _resolveAccountField() async {
    final input = _accountController.text.trim();
    if (input.isEmpty) {
      setState(() => _linkedAccount = null);
      return;
    }
    final linked = await ref
        .read(customerAccountLinkPortProvider)
        .resolve(input);
    if (!mounted) {
      return;
    }
    setState(() => _linkedAccount = linked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _saving = true);
    try {
      final accountInput = _accountController.text.trim();
      String? accountId;
      if (accountInput.isNotEmpty) {
        final linked =
            _linkedAccount ??
            await ref
                .read(customerAccountLinkPortProvider)
                .resolve(accountInput);
        if (linked == null) {
          if (!mounted) {
            return;
          }
          showAppSnackBar(
            context,
            message: l10n.customersAccountLinkInvalid,
            isSuccess: false,
          );
          return;
        }
        accountId = linked.accountId;
        final parent = ref.read(customersParentAccountProvider).valueOrNull;
        if (parent != null) {
          final underParent = await ref
              .read(customerAccountLinkPortProvider)
              .isUnderParent(accountId: accountId, parentId: parent.accountId);
          if (!underParent) {
            if (!mounted) {
              return;
            }
            showAppSnackBar(
              context,
              message: l10n.customersAccountMustBeUnderParent(
                parent.code,
                parent.name,
              ),
              isSuccess: false,
            );
            return;
          }
        }
      } else {
        final autoLink =
            ref.read(customersAutoLinkAccountProvider).valueOrNull ?? true;
        if (autoLink) {
          var parent = ref.read(customersParentAccountProvider).valueOrNull;
          if (parent == null) {
            await ref.read(customersParentAccountProvider.notifier).refresh();
            if (!mounted) {
              return;
            }
            parent = ref.read(customersParentAccountProvider).valueOrNull;
          }
          if (parent == null) {
            if (!mounted) {
              return;
            }
            showAppSnackBar(
              context,
              message: l10n.customersParentAccountNotSet,
              isSuccess: false,
            );
            return;
          }
          final created = await ref
              .read(customerAccountLinkPortProvider)
              .ensurePostingUnderParent(
                parentId: parent.accountId,
                accountCode: _codeController.text.trim(),
                name: _nameController.text.trim(),
              );
          if (created == null) {
            if (!mounted) {
              return;
            }
            showAppSnackBar(
              context,
              message: l10n.customersAccountAutoLinkFailed,
              isSuccess: false,
            );
            return;
          }
          accountId = created.accountId;
          _linkedAccount = created;
          _accountController.text = created.code;
        }
      }

      final draft = CustomerDraft(
        customerCode: _codeController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        notes: _notesController.text.trim(),
        isActive: _isActive,
        accountId: accountId,
        externalId: _externalIdController.text.trim(),
        dataSource: _dataSource,
      );

      if (widget.isEditing) {
        await ref
            .read(updateCustomerUseCaseProvider)
            .call(widget.customerId!, draft);
      } else {
        await ref.read(createCustomerUseCaseProvider).call(draft);
      }
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: widget.isEditing
            ? l10n.customersUpdated
            : l10n.customersCreated,
        isSuccess: true,
      );
      context.pop();
    } on CustomerException catch (e) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: _localizeException(l10n, e),
        isSuccess: false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.customersAccountAutoLinkFailed,
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _localizeException(AppLocalizations l10n, CustomerException e) {
    return switch (e.code) {
      CustomerException.duplicateCustomerCode =>
        l10n.customersErrorDuplicateCode,
      CustomerException.duplicateExternalId =>
        l10n.customersErrorDuplicateExternalId,
      CustomerException.invalidCustomerCode => l10n.customersErrorInvalidCode,
      CustomerException.invalidName => l10n.customersErrorInvalidName,
      CustomerException.invalidEmail => l10n.customersErrorInvalidEmail,
      CustomerException.externalIdRequired =>
        l10n.customersErrorExternalIdRequired,
      CustomerException.invalidAccountLink => l10n.customersAccountLinkInvalid,
      _ => e.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (widget.isEditing) {
      final asyncCustomer = ref.watch(customerByIdProvider(widget.customerId!));
      return asyncCustomer.when(
        loading: () => Scaffold(
          appBar: CustomAppBar(
            title: l10n.customersEditTitle,
            showBackButton: true,
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Scaffold(
          appBar: CustomAppBar(
            title: l10n.customersEditTitle,
            showBackButton: true,
          ),
          body: Center(child: Text(l10n.somethingWentWrong)),
        ),
        data: (customer) {
          if (customer == null) {
            return Scaffold(
              appBar: CustomAppBar(
                title: l10n.customersEditTitle,
                showBackButton: true,
              ),
              body: Center(child: Text(l10n.emptyStateTitle)),
            );
          }
          unawaited(_hydrate(customer));
          return _buildForm(context, l10n);
        },
      );
    }

    return _buildForm(context, l10n);
  }

  Widget _buildForm(BuildContext context, AppLocalizations l10n) {
    return UnsavedChangesScope(
      hasUnsavedChanges: _hasUnsavedChanges,
      child: AppResponsiveScaffold(
        appBar: CustomAppBar(
          title: widget.isEditing
              ? l10n.customersEditTitle
              : l10n.customersCreateTitle,
          showBackButton: true,
        ),
        bottomActions: AppBottomActions(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(l10n.confirm),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: AppConstants.pageInsets(context),
            children: [
              AppFormSection(
                title: l10n.localeName == 'ar' ? 'البيانات الأساسية' : 'Basic Details',
                icon: Icons.person_outline,
                topSpacing: 0,
              ),
              AppResponsiveForm(
                maxColumns: 2,
                children: [
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: l10n.customersFieldCode,
                      helperText: l10n.customersFieldCodeHelper,
                      prefixIcon: const Icon(Icons.badge_outlined),
                      suffixIcon: widget.isEditing
                          ? null
                          : IconButton(
                              tooltip: l10n.customersGenerateCode,
                              onPressed: _generatingCode
                                  ? null
                                  : () async {
                                      setState(() => _generatingCode = true);
                                      try {
                                        final code = await _generateCodeFromParent();
                                        if (!mounted || code == null) {
                                          return;
                                        }
                                        _codeController.text = code;
                                      } finally {
                                        if (mounted) {
                                          setState(() => _generatingCode = false);
                                        }
                                      }
                                    },
                              icon: _generatingCode
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.auto_awesome),
                            ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.customersErrorInvalidCode;
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.customersFieldName,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.customersErrorInvalidName;
                      }
                      return null;
                    },
                  ),
                ],
              ),
              AppFormSection(
                title: l10n.localeName == 'ar' ? 'معلومات التواصل والعنوان' : 'Contact & Address',
                icon: Icons.contact_phone_outlined,
              ),
              AppResponsiveForm(
                maxColumns: 2,
                children: [
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.customersFieldPhone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                  ),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.customersFieldEmail,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.customersFieldAddress,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.customersFieldNotes,
                  prefixIcon: const Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              AppFormSection(
                title: l10n.localeName == 'ar' ? 'الربط المحاسبي' : 'Accounting Link',
                icon: Icons.account_balance_outlined,
              ),
              TextFormField(
                controller: _accountController,
                onEditingComplete: () => unawaited(_resolveAccountField()),
                onChanged: (_) {
                  if (_linkedAccount != null) {
                    setState(() => _linkedAccount = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: l10n.customersFieldAccount,
                  prefixIcon: const Icon(Icons.link_outlined),
                  helperText: _linkedAccount == null
                      ? l10n.customersFieldAccountHelperAuto
                      : l10n.customersAccountLinked(
                          _linkedAccount!.code,
                          _linkedAccount!.name,
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppExpandableFormSection(
                title: l10n.localeName == 'ar' ? 'الإعدادات ومصدر البيانات' : 'Settings & Data Source',
                icon: Icons.tune_outlined,
                initiallyExpanded: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.customersFieldActive,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, top: AppSpacing.md, bottom: AppSpacing.xs),
                            child: Text(
                              l10n.customersFieldDataSource,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          RadioListTile<CustomerDataSource>(
                            title: Text(l10n.customersDataSourceLocal),
                            subtitle: Text(l10n.customersDataSourceLocalHint),
                            value: CustomerDataSource.local,
                            groupValue: _dataSource,
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() => _dataSource = value);
                            },
                          ),
                          RadioListTile<CustomerDataSource>(
                            title: Text(l10n.customersDataSourceExternal),
                            subtitle: Text(l10n.customersDataSourceExternalHint),
                            value: CustomerDataSource.external,
                            groupValue: _dataSource,
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() => _dataSource = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_dataSource == CustomerDataSource.external) ...[
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _externalIdController,
                        decoration: InputDecoration(
                          labelText: l10n.customersFieldExternalId,
                          helperText: l10n.customersFieldExternalIdHelper,
                          prefixIcon: const Icon(Icons.hub_outlined),
                        ),
                        validator: (value) {
                          if (_dataSource == CustomerDataSource.external &&
                              (value == null || value.trim().isEmpty)) {
                            return l10n.customersErrorExternalIdRequired;
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
