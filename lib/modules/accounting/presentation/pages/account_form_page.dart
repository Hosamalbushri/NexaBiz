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
import '../../domain/entities/account.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/models/account_exception.dart';
import '../../domain/services/account_labels.dart';
import '../providers/account_providers.dart';
import '../widgets/account_exception_messages.dart';
import 'accounting_routes.dart';

/// Create / edit Chart of Accounts node.
class AccountFormPage extends ConsumerStatefulWidget {
  const AccountFormPage({super.key, this.accountId, this.initialParentId});

  final int? accountId;
  final String? initialParentId;

  bool get isEditing => accountId != null;

  @override
  ConsumerState<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends ConsumerState<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  var _hydrated = false;
  var _saving = false;
  var _generatingCode = false;
  var _codeAutoFilled = false;
  var _isGroup = false;
  var _isActive = true;
  AccountType _accountType = AccountType.asset;
  String? _parentId;
  Account? _existing;

  @override
  void initState() {
    super.initState();
    _parentId = widget.initialParentId;
    if (!widget.isEditing && widget.initialParentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_assignCodeFromParent(force: true));
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _hydrate(Account account) {
    if (_hydrated) {
      return;
    }
    _existing = account;
    _codeController.text = account.accountCode;
    _nameController.text = account.name;
    _descriptionController.text = account.description ?? '';
    _accountType = account.accountType;
    _isGroup = account.isGroup;
    _isActive = account.isActive;
    _parentId = account.parentId;
    _hydrated = true;
  }

  Future<void> _applyParentSelection(String? parentUuid) async {
    setState(() => _parentId = parentUuid);
    if (parentUuid == null || widget.isEditing) {
      return;
    }
    final parent = await ref
        .read(getAccountByUuidUseCaseProvider)
        .call(parentUuid);
    if (!mounted || parent == null) {
      return;
    }
    setState(() => _accountType = parent.accountType);
    await _assignCodeFromParent(
      force: _codeController.text.trim().isEmpty || _codeAutoFilled,
    );
  }

  Future<void> _assignCodeFromParent({required bool force}) async {
    if (!mounted || widget.isEditing || _generatingCode) {
      return;
    }
    final parentUuid = _parentId;
    if (parentUuid == null || parentUuid.isEmpty) {
      return;
    }
    if (!force && _codeController.text.trim().isNotEmpty && !_codeAutoFilled) {
      return;
    }

    setState(() => _generatingCode = true);
    try {
      final parent = await ref
          .read(getAccountByUuidUseCaseProvider)
          .call(parentUuid);
      if (!mounted || parent == null || parent.accountCode.trim().isEmpty) {
        return;
      }
      final code = await ref
          .read(accountCodeGeneratorProvider)
          .generate(parentAccountCode: parent.accountCode);
      if (!mounted) {
        return;
      }
      _codeController.text = code;
      _codeAutoFilled = true;
    } on AccountException catch (e) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: accountExceptionMessage(AppLocalizations.of(context), e),
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _generatingCode = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parentsAsync = ref.watch(parentAccountOptionsProvider);

    if (widget.isEditing) {
      final async = ref.watch(accountByIdProvider(widget.accountId!));
      async.whenData((account) {
        if (account != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _hydrate(account));
            }
          });
        }
      });
    }

    final systemLocked = _existing?.isSystemAccount ?? false;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.isEditing
            ? l10n.accountingEditAccount
            : l10n.accountingAddAccount,
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            if (systemLocked)
              InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.accountingFieldName,
                  helperText: l10n.accountingSystemAccountHint,
                ),
                child: Text(
                  AccountLabels.displayName(l10n, _existing!),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            else
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.accountingFieldName,
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.accountingErrorNameRequired;
                  }
                  return null;
                },
              ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _codeController,
              enabled: !systemLocked,
              onChanged: (_) => _codeAutoFilled = false,
              decoration: InputDecoration(
                labelText: l10n.accountingFieldCode,
                helperText: systemLocked
                    ? l10n.accountingSystemAccountHint
                    : l10n.accountingFieldCodeHelper,
                suffixIcon: widget.isEditing || systemLocked
                    ? null
                    : IconButton(
                        tooltip: l10n.accountingGenerateCode,
                        onPressed: _generatingCode || _parentId == null
                            ? null
                            : () => _assignCodeFromParent(force: true),
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
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.accountingErrorCodeRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            parentsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(l10n.somethingWentWrong),
              data: (parents) {
                final options = [
                  for (final p in parents)
                    if (!widget.isEditing || p.uuid != _existing?.uuid) p,
                ];
                return DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: _parentId,
                  decoration: InputDecoration(
                    labelText: l10n.accountingFieldParent,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.accountingRootAccount),
                    ),
                    for (final parent in options)
                      DropdownMenuItem<String?>(
                        value: parent.uuid,
                        child: Text(
                          '${parent.accountCode} — ${AccountLabels.displayName(l10n, parent)}',
                        ),
                      ),
                  ],
                  onChanged: systemLocked
                      ? null
                      : (value) => _applyParentSelection(value),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<AccountType>(
              // ignore: deprecated_member_use
              value: _accountType,
              decoration: InputDecoration(
                labelText: l10n.accountingFieldType,
                helperText: _parentId == null
                    ? null
                    : l10n.accountingTypeInheritedHint,
              ),
              items: [
                for (final type in AccountType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Text(AccountLabels.typeLabel(l10n, type)),
                  ),
              ],
              onChanged: systemLocked || _parentId != null
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _accountType = value);
                      }
                    },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.accountingFieldDescription,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.accountingAccountGroup),
              subtitle: Text(l10n.accountingAccountGroupHint),
              value: _isGroup,
              onChanged: systemLocked
                  ? null
                  : (value) => setState(() => _isGroup = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.accountingAccountActive),
              value: _isActive,
              onChanged: systemLocked
                  ? null
                  : (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l10n.accountingSaveAccount,
              expand: true,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final draft = AccountDraft(
      parentId: _parentId,
      accountCode: _codeController.text,
      name: _nameController.text,
      description: _descriptionController.text,
      accountType: _accountType,
      isGroup: _isGroup,
      isActive: _isActive,
      isSystemAccount: _existing?.isSystemAccount ?? false,
    );

    try {
      if (widget.isEditing) {
        await ref
            .read(updateAccountUseCaseProvider)
            .call(widget.accountId!, draft);
        if (!mounted) {
          return;
        }
        showAppSnackBar(
          context,
          message: l10n.accountingSavedSuccess,
          isSuccess: true,
        );
        if (context.canPop()) {
          context.pop();
        } else {
          AccountingRoutes.goAccounts(context);
        }
      } else {
        final created = await ref
            .read(createAccountUseCaseProvider)
            .call(draft);
        if (!mounted) {
          return;
        }
        showAppSnackBar(
          context,
          message: l10n.accountingSavedSuccess,
          isSuccess: true,
        );
        context.go(AccountingRoutes.accountDetails(created.id));
      }
    } on AccountException catch (e) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: accountExceptionMessage(l10n, e),
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
