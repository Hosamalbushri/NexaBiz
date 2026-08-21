import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../modules/system_setup/presentation/pages/system_setup_routes.dart';
import '../../../../modules/system_setup/presentation/providers/system_setup_providers.dart';
import '../../domain/models/password_change_exception.dart';
import '../providers/auth_providers.dart';

/// Premium, state-of-the-art password change page.
/// Blocks the rest of the app until the seeded local password is replaced.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  var _loading = false;
  var _obscureCurrent = true;
  var _obscureNext = true;
  var _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_next.text != _confirm.text) {
      setState(() => _error = l10n.authPasswordMismatch);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authStateProvider.notifier).changeLocalPassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (!mounted) {
        return;
      }
      final ready =
          await ref.read(systemInitializationCoordinatorProvider).isReady();
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
      setState(() => _error = _mapError(l10n, e.code));
    } catch (_) {
      setState(() => _error = l10n.authLoginGenericError);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Material(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.setupChoice);
                  }
                },
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            // Background Layer with Gradient & Glows
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface,
                      colorScheme.surface,
                      Color.alphaBlend(
                        colorScheme.primary.withValues(alpha: 0.08),
                        colorScheme.surface,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top Decorative Glow Circle
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 90,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Decorative Glow Circle
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.secondary.withValues(alpha: 0.12),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Content Area
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: AppConstants.pageInsets(context),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Spacer(),

                                // Hero Icon Badge with Staggered Fade+Scale
                                Center(
                                  child: Container(
                                    width: 88,
                                    height: 88,
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          colorScheme.primaryContainer,
                                          colorScheme.primaryContainer
                                              .withValues(alpha: 0.6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.2),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.key_rounded,
                                      size: 44,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                                    .scale(
                                      begin: const Offset(0.8, 0.8),
                                      end: const Offset(1.0, 1.0),
                                      duration: 400.ms,
                                      curve: Curves.easeOutBack,
                                    ),

                                const SizedBox(height: AppSpacing.lg),

                                // Titles
                                Text(
                                  l10n.authChangePasswordTitle,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                                    .animate()
                                    .fadeIn(duration: 350.ms, delay: 100.ms)
                                    .moveY(begin: 10, end: 0, duration: 350.ms),

                                const SizedBox(height: AppSpacing.xs),

                                Text(
                                  l10n.authChangePasswordHint,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                                    .animate()
                                    .fadeIn(duration: 350.ms, delay: 150.ms)
                                    .moveY(begin: 10, end: 0, duration: 350.ms),

                                const SizedBox(height: AppSpacing.xl),

                                // Glassmorphic Card Container
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant
                                          .withValues(alpha: 0.4),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.3 : 0.06,
                                        ),
                                        blurRadius: 24,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Current Password Field
                                      TextField(
                                        controller: _current,
                                        obscureText: _obscureCurrent,
                                        textInputAction: TextInputAction.next,
                                        decoration: InputDecoration(
                                          labelText: l10n.authCurrentPasswordLabel,
                                          prefixIcon: Icon(
                                            Icons.lock_clock_outlined,
                                            color: colorScheme.primary,
                                          ),
                                          filled: true,
                                          fillColor: colorScheme.surfaceContainerHighest
                                              .withValues(alpha: 0.3),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: colorScheme.primary,
                                              width: 1.5,
                                            ),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureCurrent
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                            onPressed: () => setState(
                                              () => _obscureCurrent =
                                                  !_obscureCurrent,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: AppSpacing.md),

                                      // New Password Field
                                      TextField(
                                        controller: _next,
                                        obscureText: _obscureNext,
                                        textInputAction: TextInputAction.next,
                                        decoration: InputDecoration(
                                          labelText: l10n.authNewPasswordLabel,
                                          prefixIcon: Icon(
                                            Icons.key_outlined,
                                            color: colorScheme.primary,
                                          ),
                                          filled: true,
                                          fillColor: colorScheme.surfaceContainerHighest
                                              .withValues(alpha: 0.3),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: colorScheme.primary,
                                              width: 1.5,
                                            ),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureNext
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                            onPressed: () => setState(
                                              () => _obscureNext = !_obscureNext,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: AppSpacing.md),

                                      // Confirm Password Field
                                      TextField(
                                        controller: _confirm,
                                        obscureText: _obscureConfirm,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) =>
                                            _loading ? null : _submit(),
                                        decoration: InputDecoration(
                                          labelText: l10n.authConfirmPasswordLabel,
                                          prefixIcon: Icon(
                                            Icons.check_circle_outline,
                                            color: colorScheme.primary,
                                          ),
                                          filled: true,
                                          fillColor: colorScheme.surfaceContainerHighest
                                              .withValues(alpha: 0.3),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: colorScheme.primary,
                                              width: 1.5,
                                            ),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureConfirm
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                            onPressed: () => setState(
                                              () => _obscureConfirm =
                                                  !_obscureConfirm,
                                            ),
                                          ),
                                        ),
                                      ),

                                      if (_error != null) ...[
                                        const SizedBox(height: AppSpacing.md),
                                        Container(
                                          padding: const EdgeInsets.all(
                                            AppSpacing.md,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.errorContainer
                                                .withValues(alpha: 0.3),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: colorScheme.error
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                size: 20,
                                                color: colorScheme.error,
                                              ),
                                              const SizedBox(width: AppSpacing.sm),
                                              Expanded(
                                                child: Text(
                                                  _error!,
                                                  style: TextStyle(
                                                    color: colorScheme.error,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: AppSpacing.lg),

                                      // Save Button
                                      AppButton(
                                        onPressed: _loading ? null : _submit,
                                        label: _loading
                                            ? l10n.authChangingPassword
                                            : l10n.authChangePasswordAction,
                                        isLoading: _loading,
                                        expand: true,
                                      ),

                                      const SizedBox(height: AppSpacing.sm),

                                      // Logout Option Button
                                      TextButton(
                                        onPressed: _loading
                                            ? null
                                            : () => ref
                                                .read(authStateProvider.notifier)
                                                .logout(),
                                        child: Text(l10n.authLogoutAction),
                                      ),
                                    ],
                                  ),
                                )
                                    .animate()
                                    .fadeIn(duration: 400.ms, delay: 200.ms)
                                    .moveY(begin: 16, end: 0, duration: 400.ms),

                                const Spacer(flex: 2),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

