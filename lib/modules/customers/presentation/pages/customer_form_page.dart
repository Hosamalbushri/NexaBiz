import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_data_source.dart';
import '../../domain/models/customer_exception.dart';
import '../../domain/services/customer_account_link_port.dart';
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
        .generate(parentAccountCode: parent.code);
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
    if (mounted) {
      setState(() {});
    }
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
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.isEditing
            ? l10n.customersEditTitle
            : l10n.customersCreateTitle,
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            TextFormField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.customersFieldCode,
                helperText: l10n.customersFieldCodeHelper,
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
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.customersFieldName),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.customersErrorInvalidName;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.customersFieldPhone),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.customersFieldEmail),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.customersFieldAddress,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.customersFieldNotes),
            ),
            const SizedBox(height: AppSpacing.md),
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
                helperText: _linkedAccount == null
                    ? l10n.customersFieldAccountHelperAuto
                    : l10n.customersAccountLinked(
                        _linkedAccount!.code,
                        _linkedAccount!.name,
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.customersFieldActive),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.customersFieldDataSource,
              style: Theme.of(context).textTheme.titleSmall,
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
            if (_dataSource == CustomerDataSource.external) ...[
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _externalIdController,
                decoration: InputDecoration(
                  labelText: l10n.customersFieldExternalId,
                  helperText: l10n.customersFieldExternalIdHelper,
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
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l10n.confirm,
              expand: true,
              onPressed: _saving ? null : _save,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
