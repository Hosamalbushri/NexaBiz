import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/bootstrap/app_bootstrap_coordinator.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/services/first_run_setup_coordinator.dart';
import '../providers/system_setup_providers.dart';

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
  String _selectedLanguage = 'ar';

  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminPasswordConfirmController = TextEditingController();

  @override
  void dispose() {
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _adminPasswordConfirmController.dispose();
    super.dispose();
  }

  bool get _isArabic => _selectedLanguage == 'ar';

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
    setState(() {
      _isCommitting = true;
      _errorMessage = null;
    });

    final payload = FirstRunSetupPayload(
      language: _selectedLanguage,
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _isArabic
                      ? 'تم تهيئة مدير النظام بنجاح'
                      : 'System administrator set up successfully',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      if (e is FirstRunAlreadyCompletedException) {
        await ref
            .read(appBootstrapCoordinatorProvider.notifier)
            .onFirstRunCompleted();
        ref.read(firstRunCompletedProvider.notifier).markCompleted();
        ref.read(systemSetupReadyProvider.notifier).markReady();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic
                  ? 'التهيئة الأولى مكتملة بالفعل'
                  : 'Setup already completed.',
            ),
            backgroundColor: Colors.blue.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/login');
        return;
      }
      setState(() {
        _isCommitting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = _isArabic ? TextDirection.rtl : TextDirection.ltr;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: textDirection,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: colorScheme.surface,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              gradient: RadialGradient(
                center: const Alignment(0, -0.6),
                radius: 1.2,
                colors: [
                  colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.06),
                  colorScheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeaderNavBar(theme, colorScheme, isDark),
                  _buildProgressHeader(theme, colorScheme),
                  if (_errorMessage != null)
                    _buildErrorMessageBanner(colorScheme),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      physics: const BouncingScrollPhysics(),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 580),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.03, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Card(
                              key: ValueKey<int>(_currentStep),
                              elevation: isDark ? 6 : 3,
                              shadowColor: colorScheme.shadow.withValues(
                                alpha: isDark ? 0.4 : 0.08,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: BorderSide(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
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

  Widget _buildHeaderNavBar(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  _isArabic ? 'تهيئة مدير النظام' : 'System Admin Setup',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(ThemeData theme, ColorScheme colorScheme) {
    final steps = _isArabic
        ? ['اللغة', 'مدير النظام', 'تأكيد']
        : ['Language', 'System Admin', 'Confirm'];

    return Container(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm + 2,
        horizontal: AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Row(
            children: List.generate(steps.length, (index) {
              final isCurrent = index == _currentStep;
              final isDone = index < _currentStep;
              final isLast = index == steps.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? const Color(0xFF10B981)
                                  : isCurrent
                                      ? colorScheme.primary
                                      : colorScheme.surfaceContainerHighest,
                              border: Border.all(
                                color: isCurrent
                                    ? colorScheme.primary
                                    : isDone
                                        ? const Color(0xFF10B981)
                                        : colorScheme.outlineVariant,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrent
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            steps[index],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight:
                                  isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: isCurrent
                                  ? colorScheme.primary
                                  : isDone
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFF10B981)
                                : colorScheme.outlineVariant.withValues(
                                    alpha: 0.4,
                                  ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 20),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isArabic ? 'اللغة' : 'Language',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildLanguageCard(
          theme: theme,
          colorScheme: colorScheme,
          title: 'العربية',
          subtitle: 'Arabic (RTL)',
          value: 'ar',
          flagText: '🇸🇦',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildLanguageCard(
          theme: theme,
          colorScheme: colorScheme,
          title: 'English',
          subtitle: 'English (LTR)',
          value: 'en',
          flagText: '🇺🇸',
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
    required String flagText,
  }) {
    final isSelected = _selectedLanguage == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selectedLanguage = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(flagText, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLanguage = val);
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
    return Form(
      key: _adminFormKey,
      autovalidateMode: _autoValidateAdmin
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isArabic ? 'حساب مدير النظام' : 'System Administrator Account',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _isArabic
                ? 'قم بإنشاء حساب مدير النظام الرئيسي للتحكم الشامل في التطبيق'
                : 'Create the primary system administrator account for overall system control',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // System Scope Information Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _isArabic
                        ? 'تُنشئ هذه الخطوة حساب مدير النظام الرئيسي. يمكنك إنشاء الشركات وإدارة حسابات المستخدمين بعد تسجيل الدخول.'
                        : 'This step sets up the primary System Administrator. You can create companies and manage user accounts after signing in.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Admin Name
          TextFormField(
            controller: _adminNameController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: _isArabic ? 'اسم مدير النظام *' : 'Admin Name *',
              hintText: _isArabic ? 'مثال: عبد الله أحمد' : 'e.g. System Admin',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerLowest,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return _isArabic
                    ? 'يرجى إدخال اسم مدير النظام'
                    : 'Admin name is required';
              }
              return null;
            },
            onChanged: (_) {
              if (_autoValidateAdmin) _adminFormKey.currentState?.validate();
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Admin Email
          TextFormField(
            controller: _adminEmailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: _isArabic ? 'البريد الإلكتروني *' : 'Email *',
              hintText: 'admin@nexabiz.com',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerLowest,
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return _isArabic
                    ? 'يرجى إدخال البريد الإلكتروني'
                    : 'Email is required';
              }
              final emailRegex =
                  RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');
              if (!emailRegex.hasMatch(trimmed)) {
                return _isArabic
                    ? 'البريد الإلكتروني غير صحيح'
                    : 'Invalid email address';
              }
              return null;
            },
            onChanged: (_) {
              if (_autoValidateAdmin) _adminFormKey.currentState?.validate();
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Admin Password
          TextFormField(
            controller: _adminPasswordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: _isArabic
                  ? 'كلمة المرور * (8 أحرف فأكثر)'
                  : 'Password * (8+ chars)',
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerLowest,
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return _isArabic ? 'أدخل كلمة المرور' : 'Password is required';
              }
              if (trimmed.length < 8) {
                return _isArabic ? '8 أحرف على الأقل' : 'Min 8 characters';
              }
              return null;
            },
            onChanged: (_) {
              if (_autoValidateAdmin) _adminFormKey.currentState?.validate();
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Admin Password Confirm
          TextFormField(
            controller: _adminPasswordConfirmController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: _isArabic ? 'تأكيد كلمة المرور *' : 'Confirm Password *',
              prefixIcon: Icon(
                Icons.lock_reset_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerLowest,
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return _isArabic ? 'أدخل تأكيد كلمة المرور' : 'Confirm password';
              }
              if (trimmed != _adminPasswordController.text.trim()) {
                return _isArabic
                    ? 'كلمتا المرور غير متطابقتين'
                    : 'Passwords do not match';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_rounded,
          size: 48,
          color: colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _isArabic ? 'تأكيد تهيئة النظام' : 'Confirm System Setup',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Manifest Card
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              _buildManifestTile(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.language_rounded,
                label: _isArabic ? 'اللغة' : 'Language',
                value: _selectedLanguage == 'ar' ? 'العربية' : 'English',
              ),
              const Divider(height: 1),
              _buildManifestTile(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.person_rounded,
                label: _isArabic ? 'اسم مدير النظام' : 'Admin Name',
                value: _adminNameController.text.trim(),
              ),
              const Divider(height: 1),
              _buildManifestTile(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.email_rounded,
                label: _isArabic ? 'البريد الإلكتروني' : 'Email',
                value: _adminEmailController.text.trim(),
              ),
              const Divider(height: 1),
              _buildManifestTile(
                theme: theme,
                colorScheme: colorScheme,
                icon: Icons.security_rounded,
                label: _isArabic ? 'الدور المستهدف' : 'Target Role',
                value: _isArabic ? 'مدير النظام الرئيسي' : 'System Administrator',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Confirmation Note Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _isArabic
                      ? 'سيتم اعتماد تهيئة النظام وإنشاء مدير النظام. لا يتم إنشاء أي شركة أو انتماء في هذه الخطوة.'
                      : 'System setup will be initialized with the admin account. No company or membership is created during this step.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        if (_isCommitting)
          const CircularProgressIndicator()
        else
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _commitSetup,
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                _isArabic ? 'اعتماد تهيئة النظام' : 'Initialize System',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 18),
          const SizedBox(width: AppSpacing.sm),
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
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomFloatingBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0 && _currentStep < 2)
                OutlinedButton.icon(
                  onPressed: _prevStep,
                  icon: Icon(
                    _isArabic
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,
                    size: 16,
                  ),
                  label: Text(_isArabic ? 'السابق' : 'Back'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs + 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              if (_currentStep < 2)
                FilledButton.icon(
                  onPressed: _nextStep,
                  icon: Icon(
                    _isArabic
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded,
                    size: 16,
                  ),
                  label: Text(_isArabic ? 'التالي' : 'Next'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs + 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
