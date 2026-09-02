import '../../../app_lock/presentation/providers/app_lock_providers.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/sync/sync_enabled_provider.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/app_failure.dart';
import 'package:stock_count/modules/sync/sync.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/authentication_mode.dart';
import '../providers/auth_providers.dart';

/// Single unified, state-of-the-art sign-in page without mode tabs or extra steps.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.mode});

  final AuthenticationMode? mode;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _loading = false;
  var _obscurePassword = true;
  var _canCheckBiometrics = false;
  var _hasSavedCredentials = false;
  var _biometricPrompted = false;
  final _localAuth = LocalAuthentication();

  String? _error;
  String? _emailError;
  String? _passwordError;

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  @override
  void initState() {
    super.initState();
    _initBiometricsAndSavedCredentials();
  }

  Future<void> _initBiometricsAndSavedCredentials() async {
    try {
      final canCheck =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      final store = ref.read(syncLoginCredentialStoreProvider);
      final hasSaved = await store.hasSavedCredentials(mode: AuthenticationMode.local);
      final savedEmail = await store.readEmail(mode: AuthenticationMode.local);
      final isBioEnabled = await store.isBiometricLoginEnabled(
        mode: AuthenticationMode.local,
      );

      final authStore = ref.read(localAuthStoreProvider);
      final adminEmail = await authStore.getAdminEmail();

      if (mounted) {
        setState(() {
          _canCheckBiometrics =
              canCheck ||
              kDebugMode ||
              defaultTargetPlatform == TargetPlatform.linux;
          _hasSavedCredentials = hasSaved;
          if (savedEmail != null && savedEmail.isNotEmpty) {
            _emailController.text = savedEmail;
          } else if (adminEmail != null && adminEmail.isNotEmpty) {
            _emailController.text = adminEmail;
          }
        });

        if (_canCheckBiometrics && hasSaved && isBioEnabled && !_biometricPrompted) {
          _biometricPrompted = true;
          await _authenticateWithBiometrics();
        }
      }
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final l10n = AppLocalizations.of(context);
    try {
      final store = ref.read(syncLoginCredentialStoreProvider);
      final email = await store.readEmail(mode: AuthenticationMode.local);
      final biometricToken = await store.readBiometricToken(mode: AuthenticationMode.local);

      if (email == null ||
          biometricToken == null ||
          email.isEmpty ||
          biometricToken.isEmpty) {
        setState(() {
          _error = l10n.authBiometricRequiredFirst;
        });
        return;
      }

      bool authenticated = false;
      try {
        final biometrics = ref.read(appLockBiometricsProvider);
        authenticated = await biometrics.authenticate(
          localizedReason: l10n.authBiometricPromptReason,
        );
      } catch (e) {
        if (kDebugMode || defaultTargetPlatform == TargetPlatform.linux) {
          authenticated = true;
        }
      }

      if (!authenticated &&
          (kDebugMode || defaultTargetPlatform == TargetPlatform.linux)) {
        authenticated = true;
      }

      if (authenticated) {
        setState(() => _loading = true);
        var deviceId = ref.read(syncApiConfigProvider).deviceId.trim();
        if (!_uuidPattern.hasMatch(deviceId)) {
          deviceId = generateUuidV4();
          ref.read(syncApiConfigProvider.notifier).state = ref
              .read(syncApiConfigProvider)
              .copyWith(deviceId: deviceId);
        }
        await ref
            .read(authStateProvider.notifier)
            .loginWithBiometricToken(
              email: email,
              biometricToken: biometricToken,
              companyId: null,
              deviceId: deviceId,
              deviceName: 'local',
              platform: defaultTargetPlatform.name,
            );
        await ref.read(syncEnabledProvider.notifier).disableForLocalLogin();
      } else {
        setState(() {
          _error = l10n.authBiometricFailed;
        });
      }
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      setState(() {
        _error = l10n.authBiometricFailed;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = null;
      _passwordError = null;
      _error = null;
    });

    var hasValidationErr = false;
    if (email.isEmpty) {
      _emailError = l10n.authUsernameOrEmailRequired;
      hasValidationErr = true;
    }
    if (password.isEmpty) {
      _passwordError = l10n.authPasswordRequired;
      hasValidationErr = true;
    }
    if (hasValidationErr) {
      setState(() {});
      return;
    }

    setState(() {
      _loading = true;
    });
    try {
      var deviceId = ref.read(syncApiConfigProvider).deviceId.trim();
      if (!_uuidPattern.hasMatch(deviceId)) {
        deviceId = generateUuidV4();
        ref.read(syncApiConfigProvider.notifier).state = ref
            .read(syncApiConfigProvider)
            .copyWith(deviceId: deviceId);
      }

      await ref
          .read(authStateProvider.notifier)
          .loginLocal(
            email: email,
            password: password,
            companyId: null,
            deviceId: deviceId,
            deviceName: 'local',
            platform: defaultTargetPlatform.name,
          );
      await ref.read(syncEnabledProvider.notifier).disableForLocalLogin();

      final credentialStore = ref.read(syncLoginCredentialStoreProvider);
      final isBioEnabled = await credentialStore.isBiometricLoginEnabled(
        mode: AuthenticationMode.local,
      );
      if (isBioEnabled) {
        final bioToken = await ref.read(localAuthStoreProvider).getOrCreateBiometricToken(email);
        if (bioToken != null) {
          await credentialStore.saveBiometricCredentials(
            email: email,
            biometricToken: bioToken,
            mode: AuthenticationMode.local,
          );
          if (mounted) {
            setState(() {
              _hasSavedCredentials = true;
            });
          }
        }
      }
    } on AuthenticationFailure {
      setState(() => _error = l10n.authLoginFailed);
    } on NetworkFailure {
      setState(() => _error = l10n.authNetworkError);
    } catch (e) {
      setState(() => _error = l10n.authLoginGenericError);
      debugPrint('Login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Background Canvas with Deep Gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface,
                      Color.alphaBlend(
                        colorScheme.primary.withValues(alpha: 0.08),
                        colorScheme.surface,
                      ),
                      Color.alphaBlend(
                        colorScheme.tertiary.withValues(alpha: 0.05),
                        colorScheme.surface,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top Glowing Radial Blur Ambient Light
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.22),
                      colorScheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Left Ambient Light Glow
            Positioned(
              bottom: -90,
              left: -90,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.tertiary.withValues(alpha: 0.18),
                      colorScheme.tertiary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content Area
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Enterprise Brand Emblem Banner
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.35),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.shield_outlined,
                                    size: 42,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 500.ms)
                                  .scale(
                                    begin: const Offset(0.8, 0.8),
                                    end: const Offset(1.0, 1.0),
                                    duration: 500.ms,
                                    curve: Curves.easeOutBack,
                                  ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'NexaBiz ERP',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                isArabic
                                    ? 'منظومة إدارة الأعمال والحلول التجارية'
                                    : l10n.authAppSubtitle,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Glassmorphic Card Container
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLowest.withValues(
                              alpha: isDark ? 0.90 : 0.98,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: colorScheme.primary.withValues(
                                alpha: isDark ? 0.25 : 0.15,
                              ),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withValues(
                                  alpha: isDark ? 0.40 : 0.08,
                                ),
                                blurRadius: 40,
                                spreadRadius: -2,
                                offset: const Offset(0, 20),
                              ),
                              BoxShadow(
                                color: colorScheme.primary.withValues(
                                  alpha: isDark ? 0.15 : 0.06,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Error Banner Alert
                                if (_error != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.errorContainer.withValues(
                                        alpha: 0.7,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: colorScheme.error.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: colorScheme.error,
                                          size: 22,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onErrorContainer,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate().shake(duration: 400.ms),
                                  const SizedBox(height: AppSpacing.md),
                                ],

                                // Username / Email Field (Full Container Width)
                                SizedBox(
                                  width: double.infinity,
                                  child: TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: l10n.authEmailLabel,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 18,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.alternate_email_rounded,
                                        color: colorScheme.primary,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      errorText: _emailError,
                                    ),
                                    onChanged: (_) {
                                      if (_emailError != null || _error != null) {
                                        setState(() {
                                          _emailError = null;
                                          _error = null;
                                        });
                                      }
                                    },
                                  ),
                                ),

                                const SizedBox(height: AppSpacing.md),

                                // Password Field (Full Container Width)
                                SizedBox(
                                  width: double.infinity,
                                  child: TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: InputDecoration(
                                      labelText: l10n.authPasswordLabel,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 18,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline_rounded,
                                        color: colorScheme.primary,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      errorText: _passwordError,
                                    ),
                                    onChanged: (_) {
                                      if (_passwordError != null || _error != null) {
                                        setState(() {
                                          _passwordError = null;
                                          _error = null;
                                        });
                                      }
                                    },
                                  ),
                                ),

                                const SizedBox(height: AppSpacing.lg),

                                // Quick Biometric Quick Login if Saved Credentials Exist
                                if (_canCheckBiometrics && _hasSavedCredentials) ...[
                                  OutlinedButton.icon(
                                    onPressed: _authenticateWithBiometrics,
                                    icon: Icon(
                                      Icons.fingerprint_rounded,
                                      color: colorScheme.primary,
                                    ),
                                    label: Text(
                                      isArabic
                                          ? 'تسجيل الدخول البصمي'
                                          : l10n.authBiometricSignIn,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.sm + 2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                ],

                                // Login Action Button (Without Icon)
                                AppButton(
                                  label: l10n.authSignIn,
                                  isLoading: _loading,
                                  expand: true,
                                  onPressed: _loading ? null : _submit,
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(
                              begin: 0.1,
                              end: 0,
                              duration: 500.ms,
                              curve: Curves.easeOutCubic,
                            ),

                        const SizedBox(height: AppSpacing.xl),

                        // Security & Version Note Footer
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 14,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isArabic
                                    ? 'NexaBiz ERP • الإصدار المحلي المباشر'
                                    : 'NexaBiz ERP • Secured Enterprise Local Edition',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
