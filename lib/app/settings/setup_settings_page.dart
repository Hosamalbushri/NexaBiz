import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'company/app_currency.dart';
import 'company/company_profile.dart';
import 'company/company_profile_providers.dart';

/// Setup / company configuration settings page.
class SetupSettingsPage extends ConsumerStatefulWidget {
  const SetupSettingsPage({super.key});

  @override
  ConsumerState<SetupSettingsPage> createState() => _SetupSettingsPageState();
}

class _SetupSettingsPageState extends ConsumerState<SetupSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _taxController = TextEditingController();
  final _crController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _websiteController = TextEditingController();
  final _invoiceHeaderRightController = TextEditingController();
  final _invoiceHeaderLeftController = TextEditingController();

  var _hydrated = false;
  var _saving = false;
  var _logoBusy = false;
  var _currencyLocked = false;
  String _currencyCode = AppCurrencies.sar.code;
  int _fiscalMonth = 1;
  String? _logoPath;

  @override
  void dispose() {
    _nameController.dispose();
    _legalNameController.dispose();
    _taxController.dispose();
    _crController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _websiteController.dispose();
    _invoiceHeaderRightController.dispose();
    _invoiceHeaderLeftController.dispose();
    super.dispose();
  }

  void _hydrate(CompanyProfile profile) {
    if (_hydrated) {
      return;
    }
    _hydrated = true;
    _nameController.text = profile.name;
    _legalNameController.text = profile.legalName ?? '';
    _taxController.text = profile.taxNumber ?? '';
    _crController.text = profile.commercialRegister ?? '';
    _phoneController.text = profile.phone ?? '';
    _emailController.text = profile.email ?? '';
    _addressController.text = profile.address ?? '';
    _cityController.text = profile.city ?? '';
    _countryController.text = profile.country ?? '';
    _websiteController.text = profile.website ?? '';
    _invoiceHeaderRightController.text = profile.invoiceHeaderRight ?? '';
    _invoiceHeaderLeftController.text = profile.invoiceHeaderLeft ?? '';
    _currencyCode = profile.defaultCurrencyCode;
    _fiscalMonth = profile.fiscalYearStartMonth;
    _logoPath = profile.logoPath;
  }

  Future<void> _pickLogo() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _logoBusy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
      );
      final path = result?.files.single.path;
      if (path == null || path.isEmpty) {
        return;
      }
      final updated = await ref
          .read(companyProfileProvider.notifier)
          .setLogoFromPath(path);
      if (!mounted) {
        return;
      }
      setState(() => _logoPath = updated.logoPath);
      showAppSnackBar(context, message: l10n.setupLogoUpdated, isSuccess: true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, message: l10n.setupLogoFailed, isSuccess: false);
    } finally {
      if (mounted) {
        setState(() => _logoBusy = false);
      }
    }
  }

  Future<void> _clearLogo() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _logoBusy = true);
    try {
      await ref.read(companyProfileProvider.notifier).clearLogo();
      if (!mounted) {
        return;
      }
      setState(() => _logoPath = null);
      showAppSnackBar(context, message: l10n.setupLogoRemoved, isSuccess: true);
    } finally {
      if (mounted) {
        setState(() => _logoBusy = false);
      }
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saving = true);
    try {
      final profile = CompanyProfile(
        name: _nameController.text.trim(),
        legalName: _legalNameController.text.trim(),
        logoPath: _logoPath,
        defaultCurrencyCode: _currencyCode,
        taxNumber: _taxController.text.trim(),
        commercialRegister: _crController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        website: _websiteController.text.trim(),
        fiscalYearStartMonth: _fiscalMonth,
        invoiceHeaderRight: _invoiceHeaderRightController.text.trim(),
        invoiceHeaderLeft: _invoiceHeaderLeftController.text.trim(),
      );
      await ref.read(companyProfileProvider.notifier).save(profile);
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.setupSavedSuccess,
        isSuccess: true,
      );
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final asyncProfile = ref.watch(companyProfileProvider);

    return asyncProfile.when(
      loading: () => Scaffold(
        appBar: CustomAppBar(
          title: l10n.setupSettingsTitle,
          showBackButton: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: CustomAppBar(
          title: l10n.setupSettingsTitle,
          showBackButton: true,
        ),
        body: Center(child: Text(l10n.somethingWentWrong)),
      ),
      data: (profile) {
        _hydrate(profile);
        final currencyLocked =
            ref.watch(systemBaseCurrencyLockedProvider).valueOrNull ?? false;
        if (_currencyLocked != currencyLocked) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _currencyLocked = currencyLocked);
            }
          });
        }
        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainerLowest,
          appBar: CustomAppBar(
            title: l10n.setupSettingsTitle,
            showBackButton: true,
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: AppConstants.pageInsets(context),
              children: [
                Text(
                  l10n.setupSettingsSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.setupCompanyIdentitySection,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: _LogoPreview(path: _logoPath, busy: _logoBusy),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: l10n.setupPickLogo,
                              variant: AppButtonVariant.outlined,
                              expand: true,
                              icon: Icons.image_outlined,
                              onPressed: _logoBusy ? null : _pickLogo,
                              isLoading: _logoBusy,
                            ),
                          ),
                          if (_logoPath != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppButton(
                                label: l10n.setupRemoveLogo,
                                variant: AppButtonVariant.text,
                                expand: true,
                                onPressed: _logoBusy ? null : _clearLogo,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.setupCompanyName,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.setupCompanyNameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _legalNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.setupLegalName,
                          helperText: l10n.setupLegalNameHelper,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.setupInvoiceHeaderSection,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.setupInvoiceHeaderSectionSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _invoiceHeaderRightController,
                        maxLines: 4,
                        textAlign: TextAlign.start,
                        decoration: InputDecoration(
                          labelText: l10n.setupInvoiceHeaderRight,
                          helperText: l10n.setupInvoiceHeaderHelper,
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _invoiceHeaderLeftController,
                        maxLines: 4,
                        textAlign: TextAlign.start,
                        decoration: InputDecoration(
                          labelText: l10n.setupInvoiceHeaderLeft,
                          helperText: l10n.setupInvoiceHeaderHelper,
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.setupCurrencySection,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.setupCurrencySectionSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        value: _currencyCode,
                        decoration: InputDecoration(
                          labelText: l10n.setupDefaultCurrency,
                          helperText: _currencyLocked
                              ? l10n.systemSetupCurrencyLocked
                              : null,
                        ),
                        items: [
                          for (final currency in AppCurrencies.all)
                            DropdownMenuItem(
                              value: currency.code,
                              child: Text(
                                '${currency.code} — ${currency.localizedName(isArabic)} (${currency.symbol})',
                              ),
                            ),
                        ],
                        onChanged: _currencyLocked
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() => _currencyCode = value);
                              },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<int>(
                        value: _fiscalMonth,
                        decoration: InputDecoration(
                          labelText: l10n.setupFiscalYearStart,
                          helperText: l10n.setupFiscalYearStartHelper,
                        ),
                        items: [
                          for (var month = 1; month <= 12; month++)
                            DropdownMenuItem(
                              value: month,
                              child: Text(
                                DateFormat.MMMM(
                                  Localizations.localeOf(context).toString(),
                                ).format(DateTime(2024, month)),
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _fiscalMonth = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.setupLegalSection,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _taxController,
                        decoration: InputDecoration(
                          labelText: l10n.setupTaxNumber,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _crController,
                        decoration: InputDecoration(
                          labelText: l10n.setupCommercialRegister,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.setupContactSection,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(labelText: l10n.setupPhone),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(labelText: l10n.setupEmail),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _websiteController,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: l10n.setupWebsite,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: l10n.setupAddress,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(labelText: l10n.setupCity),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _countryController,
                        decoration: InputDecoration(
                          labelText: l10n.setupCountry,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: l10n.confirm,
                  expand: true,
                  icon: Icons.save_outlined,
                  onPressed: _saving ? null : _save,
                  isLoading: _saving,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.path, required this.busy});

  final String? path;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = 112.0;
    Widget child;
    if (busy) {
      child = const CircularProgressIndicator();
    } else if (path != null && File(path!).existsSync()) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Image.file(
          File(path!),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else {
      child = Icon(
        Icons.apartment_outlined,
        size: 48,
        color: theme.colorScheme.primary,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
