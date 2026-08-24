import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../modules/system_setup/presentation/pages/system_setup_routes.dart';
import '../../../../modules/system_setup/presentation/providers/system_setup_providers.dart';
import '../../domain/models/password_change_exception.dart';
import '../providers/auth_providers.dart';

const _kBrandIcon = 'assets/branding/nexabiz_app_icon.png';

/// Password change page matching the LoginPage visual design & validation experience.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  final _currentFocus = FocusNode();
  final _nextFocus = FocusNode();
  final _confirmFocus = FocusNode();

  var _loading = false;
  var _obscureCurrent = true;
  var _obscureNext = true;
  var _obscureConfirm = true;

  String? _currentError;
  String? _nextError;
  String? _confirmError;
  String? _generalError;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    _currentFocus.dispose();
    _nextFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  bool _validateForm(AppLocalizations l10n) {
    final result = PasswordValidator.validateChangeForm(
      currentPassword: _current.text,
      newPassword: _next.text,
      confirmPassword: _confirm.text,
      l10n: l10n,
    );

    setState(() {
      _currentError = result.currentPasswordError;
      _nextError = result.newPasswordError;
      _confirmError = result.confirmPasswordError;
      _generalError = result.generalError;
    });

    return result.isValid;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_validateForm(l10n)) return;

    setState(() {
      _loading = true;
      _generalError = null;
    });

    try {
      await ref.read(authStateProvider.notifier).changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.authPasswordChangedSuccess),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      if (context.canPop()) {
        context.pop();
        return;
      }

      final ready = await ref
          .read(systemInitializationCoordinatorProvider)
          .isReady();
      if (!mounted) return;
      if (ready) {
        context.go(AppRoutes.dashboard);
        return;
      }

      final onboardingDone = await ref
          .read(settingsRepositoryProvider)
          .loadOnboardingCompleted();
      if (!mounted) return;
      context.go(
        onboardingDone ? SystemSetupRoutes.root : AppRoutes.onboarding,
      );
    } on PasswordChangeException catch (e) {
      final msg = PasswordValidator.mapExceptionCode(l10n, e.code);
      setState(() {
        if (e.code == PasswordChangeException.wrongCurrent) {
          _currentError = msg;
        } else if (e.code == PasswordChangeException.tooShort ||
            e.code == PasswordChangeException.sameAsDefault) {
          _nextError = msg;
        } else if (e.code == PasswordChangeException.mismatch) {
          _confirmError = msg;
        } else {
          _generalError = msg;
        }
      });
    } catch (_) {
      setState(() => _generalError = l10n.authLoginGenericError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapError(AppLocalizations l10n, String code) {
    return switch (code) {
      PasswordChangeException.tooShort => l10n.adminPasswordTooShort,
      PasswordChangeException.wrongCurrent => l10n.authPasswordWrongCurrent,
      PasswordChangeException.sameAsDefault => l10n.authPasswordSameAsDefault,
      PasswordChangeException.mismatch => l10n.authPasswordMismatch,
      _ => l10n.authLoginGenericError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: scheme.surfaceContainerLowest,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _Atmosphere(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xs,
                      AppSpacing.xs,
                      AppSpacing.md,
                      0,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          onPressed: _loading
                              ? null
                              : () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go(AppRoutes.setupChoice);
                                  }
                                },
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.manual,
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.xl + viewInsetsBottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _BrandHeader(
                                appName: l10n.appTitle,
                                title: l10n.authChangePasswordTitle,
                                subtitle: l10n.authChangePasswordHint,
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Local Account Notice
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.08),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color:
                                        scheme.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: scheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        l10n.authChangePasswordLocalAccountNotice,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 350.ms),

                              const SizedBox(height: AppSpacing.lg),

                              // Current Password
                              _PasswordField(
                                    controller: _current,
                                    focusNode: _currentFocus,
                                    enabled: !_loading,
                                    label: l10n.authCurrentPasswordLabel,
                                    icon: Icons.lock_clock_outlined,
                                    obscureText: _obscureCurrent,
                                    errorText: _currentError,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) =>
                                        _nextFocus.requestFocus(),
                                    onChanged: (_) {
                                      if (_currentError != null) {
                                        setState(() => _currentError = null);
                                      }
                                    },
                                    onToggleVisibility: () => setState(
                                      () => _obscureCurrent = !_obscureCurrent,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 120.ms, duration: 360.ms)
                                  .moveY(begin: 10, end: 0, duration: 360.ms),

                              const SizedBox(height: AppSpacing.md),

                              // New Password
                              _PasswordField(
                                    controller: _next,
                                    focusNode: _nextFocus,
                                    enabled: !_loading,
                                    label: l10n.authNewPasswordLabel,
                                    icon: Icons.key_outlined,
                                    obscureText: _obscureNext,
                                    errorText: _nextError,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) =>
                                        _confirmFocus.requestFocus(),
                                    onChanged: (_) {
                                      if (_nextError != null) {
                                        setState(() => _nextError = null);
                                      }
                                    },
                                    onToggleVisibility: () => setState(
                                      () => _obscureNext = !_obscureNext,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 180.ms, duration: 360.ms)
                                  .moveY(begin: 10, end: 0, duration: 360.ms),

                              const SizedBox(height: AppSpacing.md),

                              // Confirm Password
                              _PasswordField(
                                    controller: _confirm,
                                    focusNode: _confirmFocus,
                                    enabled: !_loading,
                                    label: l10n.authConfirmPasswordLabel,
                                    icon: Icons.check_circle_outline_rounded,
                                    obscureText: _obscureConfirm,
                                    errorText: _confirmError,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) {
                                      if (!_loading) _submit();
                                    },
                                    onChanged: (_) {
                                      if (_confirmError != null) {
                                        setState(() => _confirmError = null);
                                      }
                                    },
                                    onToggleVisibility: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 240.ms, duration: 360.ms)
                                  .moveY(begin: 10, end: 0, duration: 360.ms),

                              if (_generalError != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                _GeneralErrorBanner(message: _generalError!),
                              ],

                              const SizedBox(height: AppSpacing.lg),

                              // Save Button
                              SizedBox(
                                    height: 52,
                                    child: AppButton(
                                      onPressed: _loading ? null : _submit,
                                      label: _loading
                                          ? l10n.authChangingPassword
                                          : l10n.authChangePasswordAction,
                                      icon: _loading
                                          ? null
                                          : Icons.save_rounded,
                                      isLoading: _loading,
                                      expand: true,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 300.ms, duration: 360.ms)
                                  .moveY(begin: 8, end: 0, duration: 360.ms),

                              const SizedBox(height: AppSpacing.md),

                              // Logout Action Button
                              TextButton.icon(
                                onPressed: _loading
                                    ? null
                                    : () => ref
                                          .read(authStateProvider.notifier)
                                          .logout(),
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  size: 18,
                                ),
                                label: Text(l10n.authLogoutAction),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Atmosphere extends StatelessWidget {
  const _Atmosphere();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: isDark ? 0.16 : 0.08),
              scheme.surfaceContainerLowest,
              scheme.secondary.withValues(alpha: isDark ? 0.06 : 0.04),
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              left: -70,
              child: _Orb(
                size: 260,
                color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
              ),
            ),
            Positioned(
              top: 160,
              right: -90,
              child: _Orb(
                size: 200,
                color: scheme.secondary.withValues(alpha: isDark ? 0.12 : 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.appName,
    required this.title,
    required this.subtitle,
  });

  final String appName;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(
                      alpha: isDark ? 0.28 : 0.14,
                    ),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: Image.asset(
                  _kBrandIcon,
                  width: 84,
                  height: 84,
                  filterQuality: FilterQuality.high,
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 380.ms, curve: Curves.easeOut)
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1, 1),
              duration: 420.ms,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          appName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.05,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.primary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.label,
    required this.icon,
    required this.obscureText,
    required this.onToggleVisibility,
    this.errorText,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String label;
  final IconData icon;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          obscureText: obscureText,
          textDirection: TextDirection.ltr,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: scheme.surface.withValues(alpha: 0.92),
            prefixIcon: Icon(icon),
            suffixIcon: IconButton(
              onPressed: enabled ? onToggleVisibility : null,
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: errorText != null
                    ? scheme.error
                    : scheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: errorText != null ? scheme.error : scheme.primary,
                width: 1.6,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _GeneralErrorBanner extends StatelessWidget {
  const _GeneralErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
