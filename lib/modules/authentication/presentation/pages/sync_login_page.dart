import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/sync/sync_enabled_provider.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../app_lock/presentation/providers/app_lock_providers.dart';
import '../providers/auth_providers.dart';

const _kLoginBrandIcon = 'assets/branding/nexabiz_app_icon.png';

/// Authentication required to enable or renew remote synchronization.
///
/// First-time enable: sync preference stays off until login succeeds.
/// Session renewal: preference stays on; login resumes the sync engine.
/// Optional fingerprint unlock reuses securely stored credentials.
class SyncLoginPage extends ConsumerStatefulWidget {
  const SyncLoginPage({super.key});

  @override
  ConsumerState<SyncLoginPage> createState() => _SyncLoginPageState();
}

class _SyncLoginPageState extends ConsumerState<SyncLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  var _loading = false;
  var _obscure = true;
  var _biometricAvailable = false;
  var _biometricReady = false;
  var _biometricPrompted = false;
  String? _error;

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_prepareBiometricLogin());
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _prepareBiometricLogin() async {
    final biometrics = ref.read(appLockBiometricsProvider);
    final store = ref.read(syncLoginCredentialStoreProvider);
    final available = await biometrics.isAvailable();
    final isBioEnabled = await store.isBiometricLoginEnabled(isSyncMode: true);
    final hasSaved = await store.hasSavedCredentials(isSyncMode: true);
    final savedEmail = await store.readEmail(isSyncMode: true);

    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricReady = available && isBioEnabled && hasSaved;
      if (savedEmail != null && _email.text.trim().isEmpty) {
        _email.text = savedEmail;
      }
    });

    if (_biometricReady && !_biometricPrompted) {
      _biometricPrompted = true;
      await _signInWithBiometrics();
    }
  }

  Future<void> _signInWithBiometrics() async {
    if (_loading) return;
    final l10n = AppLocalizations.of(context);
    if (!_biometricAvailable) {
      setState(() => _error = l10n.authBiometricUnavailable);
      return;
    }

    final biometrics = ref.read(appLockBiometricsProvider);
    final ok = await biometrics.authenticate(
      localizedReason: l10n.authBiometricPrompt,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = l10n.authBiometricFailed);
      return;
    }

    final store = ref.read(syncLoginCredentialStoreProvider);
    final email = await store.readEmail();
    final password = await store.readPassword();
    if (email == null || password == null) {
      if (!mounted) return;
      setState(() {
        _biometricReady = false;
        _error = l10n.authBiometricFailed;
      });
      return;
    }

    _email.text = email;
    _password.text = password;
    await _submit(fromBiometric: true);
  }

  Future<void> _submit({bool fromBiometric = false}) async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = l10n.authLoginFailed);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = ref.read(syncApiConfigProvider);
      if (config.baseUrl.trim().isEmpty) {
        setState(() => _error = l10n.syncServerUrlRequired);
        return;
      }

      var deviceId = config.deviceId.trim();
      if (!_uuidPattern.hasMatch(deviceId)) {
        deviceId = generateUuidV4();
        ref.read(syncApiConfigProvider.notifier).state = config.copyWith(
          deviceId: deviceId,
        );
      }

      await ref
          .read(authStateProvider.notifier)
          .loginForSync(
            email: email,
            password: password,
            companyId: null,
            deviceId: deviceId,
            deviceName: 'Flutter',
            platform: defaultTargetPlatform.name,
          );

      final auth = ref.read(authStateProvider);
      final canSync =
          auth.session?.user.isSuperAdmin == true ||
          auth.hasAnyPermission(const ['sync.execute', 'sync.view']);
      if (!canSync) {
        await ref.read(authStateProvider.notifier).logoutRemote();
        await ref
            .read(authStateProvider.notifier)
            .bootstrap(preferRemote: false);
        if (!mounted) return;
        setState(() => _error = l10n.syncPermissionRequired);
        return;
      }

      final store = ref.read(syncLoginCredentialStoreProvider);
      final isBioEnabled =
          await store.isBiometricLoginEnabled(isSyncMode: true);
      if (isBioEnabled && _biometricAvailable) {
        await store.saveCredentials(
          email: email,
          password: password,
          isSyncMode: true,
        );
      } else if (!fromBiometric) {
        await store.clear(isSyncMode: true);
      }

      _password.clear();

      await ref
          .read(syncEnabledProvider.notifier)
          .enableAfterAuthentication(runInitialSync: false);

      if (!mounted) return;
      context.pop(true);
    } on AuthenticationFailure {
      if (fromBiometric) {
        await ref.read(syncLoginCredentialStoreProvider).clear();
        if (mounted) {
          setState(() {
            _biometricReady = false;
            _error = l10n.authLoginFailed;
          });
        }
      } else {
        setState(() => _error = l10n.authLoginFailed);
      }
    } on NetworkFailure {
      setState(() => _error = l10n.authNetworkError);
    } on AuthorizationFailure {
      setState(() => _error = l10n.authLoginGenericError);
    } catch (e) {
      setState(() => _error = l10n.authLoginGenericError);
      debugPrint('Sync login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final renewing = ref.watch(syncEnabledProvider);
    final hint = renewing ? l10n.syncSessionExpired : l10n.syncAuthRequiredHint;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _LoginAtmosphere(),
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
                          onPressed: _loading ? null : () => context.pop(false),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: scheme.primary.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                renewing
                                    ? Icons.lock_clock_outlined
                                    : Icons.cloud_sync_outlined,
                                size: 16,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                renewing
                                    ? l10n.authSignIn
                                    : l10n.syncEnabledTitle,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.xl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _BrandBlock(
                                appName: l10n.appTitle,
                                title: l10n.authLoginTitle,
                                subtitle: l10n.authLoginSubtitle,
                                hint: hint,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              if (_biometricReady) ...[
                                SizedBox(
                                      height: 52,
                                      child: FilledButton.tonalIcon(
                                        onPressed: _loading
                                            ? null
                                            : _signInWithBiometrics,
                                        icon: const Icon(
                                          Icons.fingerprint_rounded,
                                          size: 26,
                                        ),
                                        label: Text(l10n.authBiometricSignIn),
                                        style: FilledButton.styleFrom(
                                          textStyle: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(duration: 320.ms)
                                    .scale(
                                      begin: const Offset(0.96, 0.96),
                                      end: const Offset(1, 1),
                                      duration: 320.ms,
                                    ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: scheme.outlineVariant.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                      ),
                                      child: Text(
                                        l10n.authPasswordLabel,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: scheme.outlineVariant.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              _LoginField(
                                    controller: _email,
                                    focusNode: _emailFocus,
                                    enabled: !_loading,
                                    label: l10n.authEmailLabel,
                                    icon: Icons.mail_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [
                                      AutofillHints.username,
                                      AutofillHints.email,
                                    ],
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) =>
                                        _passwordFocus.requestFocus(),
                                  )
                                  .animate()
                                  .fadeIn(delay: 120.ms, duration: 360.ms)
                                  .moveY(
                                    begin: 10,
                                    end: 0,
                                    delay: 120.ms,
                                    duration: 360.ms,
                                    curve: Curves.easeOutCubic,
                                  ),
                              const SizedBox(height: AppSpacing.md),
                              _LoginField(
                                    controller: _password,
                                    focusNode: _passwordFocus,
                                    enabled: !_loading,
                                    label: l10n.authPasswordLabel,
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscure,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) {
                                      if (!_loading) _submit();
                                    },
                                    suffix: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_biometricReady)
                                          IconButton(
                                            tooltip: l10n.authBiometricPromptReason,
                                            onPressed: _loading ? null : _signInWithBiometrics,
                                            icon: Icon(
                                              Icons.fingerprint_rounded,
                                              color: scheme.primary,
                                              size: 24,
                                            ),
                                          ),
                                        IconButton(
                                          onPressed: _loading
                                              ? null
                                              : () => setState(
                                                  () => _obscure = !_obscure,
                                                ),
                                          icon: Icon(
                                            _obscure
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 180.ms, duration: 360.ms)
                                  .moveY(
                                    begin: 10,
                                    end: 0,
                                    delay: 180.ms,
                                    duration: 360.ms,
                                    curve: Curves.easeOutCubic,
                                  ),
                               if (_error != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                _ErrorBanner(message: _error!),
                              ],
                              const SizedBox(height: AppSpacing.lg),
                              SizedBox(
                                    height: 52,
                                    child: AppButton(
                                      onPressed: _loading
                                          ? null
                                          : () => _submit(),
                                      label: _loading
                                          ? l10n.authSigningIn
                                          : l10n.authSignIn,
                                      icon: _loading
                                          ? null
                                          : Icons.login_rounded,
                                      isLoading: _loading,
                                      expand: true,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 240.ms, duration: 360.ms)
                                  .moveY(
                                    begin: 8,
                                    end: 0,
                                    delay: 240.ms,
                                    duration: 360.ms,
                                    curve: Curves.easeOutCubic,
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

class _LoginAtmosphere extends StatelessWidget {
  const _LoginAtmosphere();

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
              child: _GlowOrb(
                size: 260,
                color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
              ),
            ),
            Positioned(
              top: 160,
              right: -90,
              child: _GlowOrb(
                size: 200,
                color: scheme.secondary.withValues(alpha: isDark ? 0.12 : 0.08),
              ),
            ),
            Positioned(
              bottom: -40,
              left: 40,
              child: _GlowOrb(
                size: 160,
                color: scheme.tertiary.withValues(alpha: isDark ? 0.08 : 0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

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

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({
    required this.appName,
    required this.title,
    required this.subtitle,
    required this.hint,
  });

  final String appName;
  final String title;
  final String subtitle;
  final String hint;

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
                  _kLoginBrandIcon,
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
            )
            .animate()
            .fadeIn(delay: 60.ms, duration: 400.ms)
            .moveY(
              begin: 10,
              end: 0,
              delay: 60.ms,
              duration: 400.ms,
              curve: Curves.easeOutCubic,
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
        ).animate().fadeIn(delay: 100.ms, duration: 380.ms),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ).animate().fadeIn(delay: 140.ms, duration: 380.ms),
        const SizedBox(height: AppSpacing.md),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
            height: 1.35,
          ),
        ).animate().fadeIn(delay: 160.ms, duration: 360.ms),
      ],
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: scheme.surface.withValues(alpha: 0.92),
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
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
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

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
    ).animate().fadeIn(duration: 220.ms).shake(hz: 2.5, duration: 280.ms);
  }
}
