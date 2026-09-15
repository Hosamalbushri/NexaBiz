// ignore_for_file: deprecated_member_use // Preserving standard Flutter RadioListTile parameters (groupValue/onChanged) to avoid UI tree refactoring risks.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/bootstrap/app_bootstrap_coordinator.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/di/app_providers.dart';
import '../../domain/services/first_run_setup_coordinator.dart';
import '../providers/system_setup_providers.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

class FirstRunSetupWizardPage extends ConsumerStatefulWidget {
  const FirstRunSetupWizardPage({super.key});

  static const routeName = '/setup/first-run';

  @override
  ConsumerState<FirstRunSetupWizardPage> createState() =>
      _FirstRunSetupWizardPageState();
}

class _FirstRunSetupWizardPageState
    extends ConsumerState<FirstRunSetupWizardPage> {
  int _currentStep = 0;
  bool _isCommitting = false;
  String? _errorMessage;

  final _adminFormKey = GlobalKey<FormState>();

  var _autoValidateAdmin = false;
  var _obscurePassword = true;
  var _obscureConfirmPassword = true;

  // Form State
  String? _selectedLanguage;
  bool _initializedLanguage = false;

  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminPasswordConfirmController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedLanguage) {
      final activeLocale =
          ref.read(localeProvider)?.languageCode ??
          Localizations.localeOf(context).languageCode;
      _selectedLanguage = activeLocale == 'en' ? 'en' : 'ar';
      _initializedLanguage = true;
    }
  }

  @override
  void dispose() {
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _adminPasswordConfirmController.dispose();
    super.dispose();
  }

  bool get _isArabic => _selectedLanguage == 'ar';

  void _onLanguageSelected(String langCode) {
    setState(() {
      _selectedLanguage = langCode;
    });
    ref.read(localeProvider.notifier).state = Locale(langCode);
  }

  void _nextStep() {
    setState(() => _errorMessage = null);

    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      setState(() => _autoValidateAdmin = true);
      if (_adminFormKey.currentState?.validate() ?? false) {
        setState(() => _currentStep = 2);
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0 && !_isCommitting) {
      setState(() {
        _errorMessage = null;
        _currentStep -= 1;
      });
    }
  }

  Future<void> _commitSetup() async {
    if (_isCommitting) return;
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isCommitting = true;
      _errorMessage = null;
    });

    final payload = FirstRunSetupPayload(
      language: _selectedLanguage ?? 'ar',
      adminName: _adminNameController.text.trim(),
      adminEmail: _adminEmailController.text.trim(),
      adminPassword: _adminPasswordController.text.trim(),
    );

    try {
      final coordinator = ref.read(firstRunSetupCoordinatorProvider);
      await coordinator.commitFirstRunSetup(payload);

      if (!mounted) return;
      await ref
          .read(appBootstrapCoordinatorProvider.notifier)
          .onFirstRunCompleted();
      ref.read(firstRunCompletedProvider.notifier).markCompleted();
      ref.read(systemSetupReadyProvider.notifier).markReady();

      if (!mounted) return;
      showAppSnackBar(
        context,
        message: l10n.setupAdminSuccess,
        isSuccess: true,
      );

      if (mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (!mounted) return;
      if (e is FirstRunAlreadyCompletedException) {
        await ref
            .read(appBootstrapCoordinatorProvider.notifier)
            .onFirstRunCompleted();
        ref.read(firstRunCompletedProvider.notifier).markCompleted();
        ref.read(systemSetupReadyProvider.notifier).markReady();
        if (!mounted) return;
        showAppSnackBar(
          context,
          message: l10n.setupAlreadyCompleted,
          isSuccess: true,
        );
        if (mounted) {
          context.go(AppRoutes.login);
        }
        return;
      }
      setState(() {
        _isCommitting = false;
        _errorMessage = e.toString();
      });
      showAppSnackBar(context, message: e.toString(), isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textDirection = _isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: colorScheme.surface,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
        ),
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              gradient: RadialGradient(
                center: const Alignment(0, -0.6),
                radius: 1.2,
                colors: [
                  colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.05),
                  colorScheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeaderNavBar(theme, colorScheme),
                  _buildProgressHeader(theme, colorScheme),
                  if (_errorMessage != null)
                    _buildErrorMessageBanner(colorScheme),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      physics: const BouncingScrollPhysics(),
                      child: AppContentConstraint(
                        maxWidth: 560,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: AppCard(
                            key: ValueKey<int>(_currentStep),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: _buildCurrentStepContent(
                                theme,
                                colorScheme,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildBottomFloatingBar(theme, colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderNavBar(ThemeData theme, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: AppContentConstraint(
        maxWidth: 560,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'NexaBiz ERP',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                l10n.setupAdminTitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader(ThemeData theme, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      l10n.setupStepLanguage,
      l10n.setupStepAdmin,
      l10n.setupStepConfirm,
    ];

    return Container(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      child: AppContentConstraint(
        maxWidth: 560,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(steps.length, (index) {
            final isCurrent = index == _currentStep;
            final isDone = index < _currentStep;
            final isLast = index == steps.length - 1;
            final isNextDone = index < _currentStep;

            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Left line segment (touching left edge of circle)
                      Expanded(
                        child: index == 0
                            ? const SizedBox.shrink()
                            : Container(
                                height: 3,
                                color: isDone
                                    ? AppColors.success
                                    : colorScheme.outlineVariant.withValues(
                                        alpha: 0.4,
                                      ),
                              ),
                      ),
                      // Circle Badge
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? AppColors.success
                              : isCurrent
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                        ),
                      ),
                      // Right line segment (touching right edge of circle)
                      Expanded(
                        child: isLast
                            ? const SizedBox.shrink()
                            : Container(
                                height: 3,
                                color: isNextDone
                                    ? const Color(0xFF10B981)
                                    : colorScheme.outlineVariant.withValues(
                                        alpha: 0.4,
                                      ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[index],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent
                          ? colorScheme.primary
                          : isDone
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildErrorMessageBanner(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      color: colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs + 2,
      ),
      child: AppContentConstraint(
        maxWidth: 560,
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(ThemeData theme, ColorScheme colorScheme) {
    switch (_currentStep) {
      case 0:
        return _buildStepLanguage(theme, colorScheme);
      case 1:
        return _buildStepAdminAccount(theme, colorScheme);
      case 2:
        return _buildStepReviewAndCommit(theme, colorScheme);
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 0: Language Selection
  Widget _buildStepLanguage(ThemeData theme, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.setupStepLanguage,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildLanguageCard(
          theme: theme,
          colorScheme: colorScheme,
          title: l10n.setupLanguageArabic,
          subtitle: l10n.setupLanguageArabicSubtitle,
          value: 'ar',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildLanguageCard(
          theme: theme,
          colorScheme: colorScheme,
          title: l10n.setupLanguageEnglish,
          subtitle: l10n.setupLanguageEnglishSubtitle,
          value: 'en',
        ),
      ],
    );
  }

  Widget _buildLanguageCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _selectedLanguage == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onLanguageSelected(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.language_rounded,
                  size: 20,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: _selectedLanguage,
                activeColor: colorScheme.primary,
                onChanged: (val) {
                  if (val != null) _onLanguageSelected(val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 1: Admin Credentials
  Widget _buildStepAdminAccount(ThemeData theme, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _adminFormKey,
      autovalidateMode: _autoValidateAdmin
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.setupAdminAccountTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.setupAdminAccountSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Admin Name
          TextFormField(
            controller: _adminNameController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            decoration: InputDecoration(
              labelText: l10n.setupAdminNameLabel,
              hintText: l10n.setupAdminNameHint,
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.setupAdminNameRequired;
              }
              return null;
            },
            onChanged: (_) {
              if (_autoValidateAdmin) _adminFormKey.currentState?.validate();
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Admin Email
          TextFormField(
            controller: _adminEmailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            decoration: InputDecoration(
              labelText: l10n.setupEmailLabel,
              hintText: 'admin@nexabiz.com',
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return l10n.setupEmailRequired;
              }
              final emailRegex = RegExp(
                r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$',
              );
              if (!emailRegex.hasMatch(trimmed)) {
                return l10n.setupEmailInvalid;
              }
              return null;
            },
            onChanged: (_) {
              if (_autoValidateAdmin) _adminFormKey.currentState?.validate();
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Admin Password
          TextFormField(
            controller: _adminPasswordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            decoration: InputDecoration(
              labelText: l10n.setupPasswordLabel,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return l10n.setupPasswordRequired;
              }
              if (trimmed.length < 8) {
                return l10n.setupPasswordMinLength;
              }
              return null;
            },
            onChanged: (_) {
              if (_autoValidateAdmin) _adminFormKey.currentState?.validate();
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Admin Password Confirm
          TextFormField(
            controller: _adminPasswordConfirmController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            decoration: InputDecoration(
              labelText: l10n.setupConfirmPasswordLabel,
              prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                ),
                onPressed: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return l10n.setupConfirmPasswordRequired;
              }
              if (trimmed != _adminPasswordController.text.trim()) {
                return l10n.setupPasswordsMismatch;
              }
              return null;
            },
            onChanged: (_) {
              if (_autoValidateAdmin) _adminFormKey.currentState?.validate();
            },
          ),
        ],
      ),
    );
  }

  // STEP 2: Review & Final Confirmation
  Widget _buildStepReviewAndCommit(ThemeData theme, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.setupConfirmTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Manifest Card
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        color: colorScheme.onPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _adminNameController.text.trim().isEmpty
                                ? l10n.setupTargetRoleValue
                                : _adminNameController.text.trim(),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            l10n.setupTargetRoleValue,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _buildManifestTile(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.language_rounded,
                label: l10n.setupStepLanguage,
                value: _selectedLanguage == 'ar'
                    ? l10n.setupLanguageArabic
                    : l10n.setupLanguageEnglish,
              ),
              const Divider(height: 1),
              _buildManifestTile(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.person_outline_rounded,
                label: l10n.setupAdminNameLabel.replaceAll(' *', ''),
                value: _adminNameController.text.trim(),
              ),
              const Divider(height: 1),
              _buildManifestTile(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.email_outlined,
                label: l10n.setupEmailLabel.replaceAll(' *', ''),
                value: _adminEmailController.text.trim(),
                isStacked: true,
                isLtr: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.setupConfirmNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        AppButton(
          label: l10n.setupInitializeButton,
          icon: Icons.check_circle_rounded,
          isLoading: _isCommitting,
          expand: true,
          onPressed: _isCommitting ? null : _commitSetup,
        ),
      ],
    );
  }

  Widget _buildManifestTile({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required String value,
    bool isStacked = false,
    bool isLtr = false,
  }) {
    if (isStacked) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md - 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 26, end: 26),
              child: Align(
                alignment: isLtr ? Alignment.centerLeft : Alignment.centerRight,
                child: Directionality(
                  textDirection: isLtr
                      ? TextDirection.ltr
                      : Directionality.of(context),
                  child: Text(
                    value,
                    softWrap: true,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md - 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: colorScheme.primary, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              softWrap: true,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomFloatingBar(ThemeData theme, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);

    const nextIcon = Icons.arrow_forward_rounded;
    const backIcon = Icons.arrow_back_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: AppContentConstraint(
        maxWidth: 560,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentStep > 0 && _currentStep < 2)
              AppButton(
                label: l10n.setupBackButton,
                icon: backIcon,
                variant: AppButtonVariant.outlined,
                onPressed: _isCommitting ? null : _prevStep,
              )
            else
              const SizedBox.shrink(),
            if (_currentStep < 2)
              AppButton(
                label: l10n.setupNextButton,
                icon: nextIcon,
                trailingIcon: true,
                isLoading: _isCommitting,
                variant: AppButtonVariant.filled,
                onPressed: _isCommitting ? null : _nextStep,
              ),
          ],
        ),
      ),
    );
  }
}
