import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

import 'package:stock_count/app/exit/app_exit_scope.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/models/account_exception.dart';
import '../../domain/services/account_labels.dart';
import '../providers/account_providers.dart';
import '../widgets/account_exception_messages.dart';
import 'package:stock_count/modules/accounting/shared/presentation/pages/accounting_routes.dart';

/// Create / edit Chart of Accounts node.
class AccountFormPage extends ConsumerStatefulWidget {
  const AccountFormPage({super.key, this.accountId, this.initialParentId});

  final String? accountId;
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

  String _initialCode = '';
  String _initialName = '';
  String _initialDescription = '';
  bool _initialIsGroup = false;
  bool _initialIsActive = true;
  AccountType _initialAccountType = AccountType.asset;
  String? _initialParentId;

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

  bool _hasUnsavedChanges() {
    if (!widget.isEditing) {
      return _nameController.text.trim().isNotEmpty ||
          _codeController.text.trim().isNotEmpty ||
          _descriptionController.text.trim().isNotEmpty ||
          _isGroup ||
          !_isActive ||
          _accountType != AccountType.asset ||
          _parentId != null;
    }
    return _codeController.text != _initialCode ||
        _nameController.text != _initialName ||
        _descriptionController.text != _initialDescription ||
        _isGroup != _initialIsGroup ||
        _isActive != _initialIsActive ||
        _accountType != _initialAccountType ||
        _parentId != _initialParentId;
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

    _initialCode = _codeController.text;
    _initialName = _nameController.text;
    _initialDescription = _descriptionController.text;
    _initialIsGroup = _isGroup;
    _initialIsActive = _isActive;
    _initialAccountType = _accountType;
    _initialParentId = _parentId;
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
          .generate(
            parentAccountCode: parent.accountCode,
            parentAccountId: parent.id,
          );
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

    return UnsavedChangesScope(
      hasUnsavedChanges: _hasUnsavedChanges,
      child: AppFormPage(
        title: widget.isEditing
            ? l10n.accountingEditAccount
            : l10n.accountingAddAccount,
        formKey: _formKey,
        onSubmit: _saving ? null : _save,
        submitLabel: l10n.accountingSaveAccount,
        isLoading: _saving,
        showBackButton: true,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFormSection(
              title: l10n.localeName == 'ar'
                  ? 'البيانات الأساسية'
                  : 'Basic Details',
              icon: Icons.account_tree_outlined,
              topSpacing: 0,
            ),
            AppResponsiveForm(
              maxColumns: 2,
              children: [
                if (systemLocked)
                  AppTextField(
                    controller: TextEditingController(
                      text: AccountLabels.displayName(l10n, _existing!),
                    ),
                    label: l10n.accountingFieldName,
                    enabled: false,
                    readOnly: true,
                    helperText: l10n.accountingSystemAccountHint,
                  )
                else
                  AppTextField(
                    controller: _nameController,
                    label: l10n.accountingFieldName,
                    required: true,
                    textInputAction: TextInputAction.next,
                  ),
                AppTextField(
                  controller: _codeController,
                  enabled: !systemLocked,
                  label: l10n.accountingFieldCode,
                  required: true,
                  helperText: systemLocked
                      ? l10n.accountingSystemAccountHint
                      : l10n.accountingFieldCodeHelper,
                  onChanged: (_) => _codeAutoFilled = false,
                  suffixIcon: widget.isEditing || systemLocked
                      ? null
                      : AppIconButton(
                          icon: _generatingCode
                              ? Icons.hourglass_empty
                              : Icons.auto_awesome,
                          tooltip: l10n.accountingGenerateCode,
                          onPressed: _generatingCode || _parentId == null
                              ? null
                              : () => _assignCodeFromParent(force: true),
                        ),
                  textInputAction: TextInputAction.next,
                ),
              ],
            ),
            AppFormSection(
              title: l10n.localeName == 'ar'
                  ? 'التسلسل الهيكلي والنوع'
                  : 'Hierarchy & Type',
              icon: Icons.account_balance_outlined,
            ),
            AppResponsiveForm(
              maxColumns: 2,
              children: [
                parentsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => Text(l10n.somethingWentWrong),
                  data: (parents) {
                    final options = [
                      for (final p in parents)
                        if (!widget.isEditing || p.id != _existing?.id) p,
                    ];
                    return AppSelectField<String?>(
                      value: _parentId,
                      label: l10n.accountingFieldParent,
                      enabled: !systemLocked,
                      items: [
                        AppSelectItem<String?>(
                          value: null,
                          label: l10n.accountingRootAccount,
                        ),
                        for (final parent in options)
                          AppSelectItem<String?>(
                            value: parent.id,
                            label:
                                '${parent.accountCode} — ${AccountLabels.displayName(l10n, parent)}',
                          ),
                      ],
                      onChanged: systemLocked
                          ? null
                          : (value) => _applyParentSelection(value),
                    );
                  },
                ),
                AppSelectField<AccountType>(
                  value: _accountType,
                  label: l10n.accountingFieldType,
                  helperText: _parentId == null
                      ? null
                      : l10n.accountingTypeInheritedHint,
                  enabled: !systemLocked && _parentId == null,
                  items: [
                    for (final type in AccountType.values)
                      AppSelectItem(
                        value: type,
                        label: AccountLabels.typeLabel(l10n, type),
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
              ],
            ),
            AppFormSection(
              title: l10n.localeName == 'ar'
                  ? 'الوصف والإعدادات'
                  : 'Description & Options',
              icon: Icons.tune_outlined,
            ),
            AppTextField(
              controller: _descriptionController,
              label: l10n.accountingFieldDescription,
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
            const SizedBox(height: AppSpacing.lg),
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
        context.replace(AccountingRoutes.accountDetails(created.id));
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
