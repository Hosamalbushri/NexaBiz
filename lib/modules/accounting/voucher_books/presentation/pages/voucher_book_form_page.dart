import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_form_section.dart';
import 'package:stock_count/core/widgets/app_responsive.dart';
import 'package:stock_count/core/widgets/app_responsive_scaffold.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import '../../domain/entities/voucher_book.dart';
import '../../domain/entities/voucher_book_type.dart';
import '../../domain/models/voucher_book_exception.dart';
import '../providers/voucher_book_providers.dart';
import '../widgets/voucher_book_labels.dart';

/// Create / edit a leaf voucher numbering book under a section.
class VoucherBookFormPage extends ConsumerStatefulWidget {
  const VoucherBookFormPage({
    super.key,
    this.bookId,
    this.initialParentId,
    this.initialBookType,
  });

  final int? bookId;
  final String? initialParentId;
  final VoucherBookType? initialBookType;

  bool get isEditing => bookId != null;

  @override
  ConsumerState<VoucherBookFormPage> createState() =>
      _VoucherBookFormPageState();
}

class _VoucherBookFormPageState extends ConsumerState<VoucherBookFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentNumberController = TextEditingController(text: '1');
  final _endNumberController = TextEditingController(text: '9999');
  final _notesController = TextEditingController();

  var _hydrated = false;
  var _saving = false;
  var _isActive = true;
  String? _parentId;
  late VoucherBookType _bookType;
  var _lockBookType = false;

  @override
  void initState() {
    super.initState();
    _parentId = widget.initialParentId;
    _bookType = widget.initialBookType ?? VoucherBookType.sales;
    _lockBookType = widget.initialBookType != null && !widget.isEditing;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentNumberController.dispose();
    _endNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _hydrate(VoucherBook book) {
    if (_hydrated) {
      return;
    }
    _hydrated = true;
    _nameController.text = book.name;
    _currentNumberController.text = '${book.currentNumber}';
    _endNumberController.text = '${book.endNumber}';
    _notesController.text = book.notes ?? '';
    _isActive = book.isActive;
    _bookType = book.bookType;
    _parentId = book.parentId;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_parentId == null || _parentId!.isEmpty) {
      showAppSnackBar(
        context,
        message: l10n.accountingVoucherBooksErrorParent,
        isSuccess: false,
      );
      return;
    }

    final currentNumber = int.tryParse(_currentNumberController.text.trim());
    final endNumber = int.tryParse(_endNumberController.text.trim());
    if (currentNumber == null || currentNumber < 1) {
      showAppSnackBar(
        context,
        message: l10n.accountingVoucherBooksErrorCurrentNumber,
        isSuccess: false,
      );
      return;
    }
    if (endNumber == null || endNumber < 1) {
      showAppSnackBar(
        context,
        message: l10n.accountingVoucherBooksErrorEndNumber,
        isSuccess: false,
      );
      return;
    }
    if (endNumber < currentNumber) {
      showAppSnackBar(
        context,
        message: l10n.accountingVoucherBooksErrorEndBeforeCurrent,
        isSuccess: false,
      );
      return;
    }

    setState(() => _saving = true);
    final draft = VoucherBookDraft(
      name: _nameController.text.trim(),
      bookType: _bookType,
      parentId: _parentId,
      isGroup: false,
      currentNumber: currentNumber,
      endNumber: endNumber,
      isActive: _isActive,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      final repo = ref.read(voucherBookRepositoryProvider);
      if (widget.isEditing) {
        await repo.update(widget.bookId!, draft);
      } else {
        await repo.create(draft);
      }
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.accountingVoucherBooksSaved,
        isSuccess: true,
      );
      Navigator.of(context).pop();
    } on VoucherBookException catch (e) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, message: e.toString(), isSuccess: false);
    } catch (e) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, message: e.toString(), isSuccess: false);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sectionsAsync = ref.watch(voucherBookSectionsProvider);

    if (widget.isEditing) {
      final asyncBook = ref.watch(voucherBookByIdProvider(widget.bookId!));
      return asyncBook.when(
        loading: () => Scaffold(
          appBar: CustomAppBar(
            title: l10n.accountingVoucherBooksEdit,
            showBackButton: true,
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: CustomAppBar(
            title: l10n.accountingVoucherBooksEdit,
            showBackButton: true,
          ),
          body: Center(child: Text(e.toString())),
        ),
        data: (book) {
          if (book == null || book.isGroup) {
            return Scaffold(
              appBar: CustomAppBar(
                title: l10n.accountingVoucherBooksEdit,
                showBackButton: true,
              ),
              body: Center(child: Text(l10n.accountingVoucherBooksEmptyTitle)),
            );
          }
          _hydrate(book);
          return sectionsAsync.when(
            loading: () => Scaffold(
              appBar: CustomAppBar(
                title: l10n.accountingVoucherBooksEdit,
                showBackButton: true,
              ),
              body: const Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Scaffold(
              appBar: CustomAppBar(
                title: l10n.accountingVoucherBooksEdit,
                showBackButton: true,
              ),
              body: Center(child: Text(e.toString())),
            ),
            data: (sections) =>
                _buildForm(l10n, theme, sections, effectiveParentId: _parentId),
          );
        },
      );
    }

    return sectionsAsync.when(
      loading: () => Scaffold(
        appBar: CustomAppBar(
          title: l10n.accountingVoucherBooksAdd,
          showBackButton: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: CustomAppBar(
          title: l10n.accountingVoucherBooksAdd,
          showBackButton: true,
        ),
        body: Center(child: Text(e.toString())),
      ),
      data: (sections) {
        final effectiveParentId =
            _parentId ?? (sections.isEmpty ? null : sections.first.group.uuid);
        return _buildForm(
          l10n,
          theme,
          sections,
          effectiveParentId: effectiveParentId,
        );
      },
    );
  }

  Widget _buildForm(
    AppLocalizations l10n,
    ThemeData theme,
    List<VoucherBookSectionNode> sections, {
    required String? effectiveParentId,
  }) {
    VoucherBookSectionNode? selectedParent;
    for (final node in sections) {
      if (node.group.uuid == effectiveParentId) {
        selectedParent = node;
        break;
      }
    }
    selectedParent ??= sections.isEmpty ? null : sections.first;
    final parentUuid = selectedParent?.group.uuid;
    final sectionType =
        selectedParent?.group.bookType.section ?? VoucherBookType.sales;
    final leafKinds = VoucherBookType.leafKindsFor(sectionType);
    final effectiveType = _lockBookType
        ? _bookType
        : (leafKinds.contains(_bookType) ? _bookType : leafKinds.first);

    return AppResponsiveScaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: widget.isEditing
            ? l10n.accountingVoucherBooksEdit
            : l10n.accountingVoucherBooksAdd,
        showBackButton: true,
      ),
      bottomActions: AppBottomActions(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving
                ? null
                : () {
                    _parentId = parentUuid;
                    _bookType = effectiveType;
                    _save();
                  },
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(l10n.accountingVoucherBooksSave),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            AppFormSection(
              title: l10n.localeName == 'ar' ? 'تصنيف الدفتر' : 'Book Classification',
              icon: Icons.category_outlined,
              topSpacing: 0,
            ),
            AppResponsiveForm(
              maxColumns: 2,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('parent-$parentUuid'),
                  initialValue: parentUuid,
                  decoration: InputDecoration(
                    labelText: l10n.accountingVoucherBooksParentSection,
                  ),
                  items: [
                    for (final node in sections)
                      DropdownMenuItem(
                        value: node.group.uuid,
                        child: Text(
                          voucherBookSectionLabel(l10n, node.group.bookType),
                        ),
                      ),
                  ],
                  onChanged: (widget.isEditing || widget.initialParentId != null)
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _parentId = value;
                            final parent = sections
                                .firstWhere((s) => s.group.uuid == value)
                                .group;
                            final kinds = VoucherBookType.leafKindsFor(
                              parent.bookType,
                            );
                            if (!_lockBookType && !kinds.contains(_bookType)) {
                              _bookType = kinds.first;
                            }
                          });
                        },
                ),
                DropdownButtonFormField<VoucherBookType>(
                  key: ValueKey('type-$effectiveType-$parentUuid'),
                  initialValue: effectiveType,
                  decoration: InputDecoration(
                    labelText: l10n.accountingVoucherBooksType,
                  ),
                  items: [
                    for (final type in leafKinds)
                      DropdownMenuItem(
                        value: type,
                        child: Text(voucherBookTypeLabel(l10n, type)),
                      ),
                  ],
                  onChanged: (_lockBookType || widget.isEditing)
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _bookType = value);
                        },
                ),
              ],
            ),
            AppFormSection(
              title: l10n.localeName == 'ar' ? 'بيانات الترقيم والاسم' : 'Name & Numbering',
              icon: Icons.format_list_numbered_outlined,
            ),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.accountingVoucherBooksName,
                hintText: l10n.accountingVoucherBooksNameHint,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.accountingVoucherBooksErrorName;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppResponsiveForm(
              maxColumns: 2,
              children: [
                TextFormField(
                  controller: _currentNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.accountingVoucherBooksCurrentNumber,
                    helperText: l10n.accountingVoucherBooksCurrentNumberHelper,
                  ),
                  validator: (value) {
                    final n = int.tryParse(value?.trim() ?? '');
                    if (n == null || n < 1) {
                      return l10n.accountingVoucherBooksErrorCurrentNumber;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _endNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.accountingVoucherBooksEndNumber,
                    helperText: l10n.accountingVoucherBooksEndNumberHelper,
                  ),
                  validator: (value) {
                    final end = int.tryParse(value?.trim() ?? '');
                    final current = int.tryParse(
                      _currentNumberController.text.trim(),
                    );
                    if (end == null || end < 1) {
                      return l10n.accountingVoucherBooksErrorEndNumber;
                    }
                    if (current != null && end < current) {
                      return l10n.accountingVoucherBooksErrorEndBeforeCurrent;
                    }
                    return null;
                  },
                ),
              ],
            ),
            AppFormSection(
              title: l10n.localeName == 'ar' ? 'ملاحظات وحالة الدفتر' : 'Notes & Status',
              icon: Icons.notes_outlined,
            ),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.accountingVoucherBooksNotes,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.accountingVoucherBooksActive),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
