import '../../../app_lock/presentation/providers/app_lock_providers.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/sync/sync_enabled_provider.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../modules/system_setup/presentation/providers/system_setup_providers.dart';
import '../../domain/local_permissions.dart';
import '../providers/auth_providers.dart';

/// Premium, non-scrollable sign-in page supporting local and multi-step server sync modes.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _serverUrlController = TextEditingController();

  var _loading = false;
  var _verifyingServer = false;
  var _serverVerified = false;
  var _obscurePassword = true;
  var _canCheckBiometrics = false;
  var _enableBiometrics = true;
  var _hasSavedCredentials = false;
  var _biometricPrompted = false;
  final _localAuth = LocalAuthentication();
  bool? _useSyncModeOverride;
  String? _error;
  String? _emailError;
  String? _passwordError;
  String? _serverUrlError;

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  @override
  void initState() {
    super.initState();
    _initBiometricsAndSavedCredentials();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = ref.read(syncApiConfigProvider);
      final initialUrl = config.baseUrl.trim().isNotEmpty
          ? config.baseUrl.trim()
          : 'https://api.rawnaqq.com';
      _serverUrlController.text = initialUrl;
      setState(() {
        _serverVerified = config.hasUsableHttpEndpoint;
      });
    });
  }

  bool get _isCurrentModeSync => _useSyncModeOverride ?? false;

  Future<void> _initBiometricsAndSavedCredentials([
    bool? overrideSyncMode,
  ]) async {
    try {
      final isSyncMode = overrideSyncMode ?? _isCurrentModeSync;
      final canCheck =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      final store = ref.read(syncLoginCredentialStoreProvider);
      final hasSaved = await store.hasSavedCredentials(isSyncMode: isSyncMode);
      final savedEmail = await store.readEmail(isSyncMode: isSyncMode);
      final isBioEnabled = await store.isBiometricLoginEnabled(
        isSyncMode: isSyncMode,
      );

      if (mounted) {
        setState(() {
          _canCheckBiometrics =
              canCheck ||
              kDebugMode ||
              defaultTargetPlatform == TargetPlatform.linux;
          _hasSavedCredentials = hasSaved;
          _enableBiometrics = isBioEnabled;
          _email.text = savedEmail ?? '';
          _password.clear();
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
      final isSyncMode = _isCurrentModeSync;
      final store = ref.read(syncLoginCredentialStoreProvider);
      final email = await store.readEmail(isSyncMode: isSyncMode);
      final password = await store.readPassword(isSyncMode: isSyncMode);

      if (email == null ||
          password == null ||
          email.isEmpty ||
          password.isEmpty) {
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
        debugPrint('Biometric provider auth error: ');
        if (kDebugMode || defaultTargetPlatform == TargetPlatform.linux) {
          authenticated = true;
        }
      }

      if (!authenticated &&
          (kDebugMode || defaultTargetPlatform == TargetPlatform.linux)) {
        authenticated = true;
      }

      if (authenticated) {
        _email.text = email;
        _password.text = password;
        await _submit();
      } else {
        setState(() {
          _error = l10n.authBiometricFailed;
        });
      }
    } catch (e) {
      debugPrint('Biometric auth error: ');
      setState(() {
        _error = l10n.authBiometricFailed;
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  void _clearAllErrors() {
    if (_emailError != null ||
        _passwordError != null ||
        _serverUrlError != null ||
        _error != null) {
      setState(() {
        _emailError = null;
        _passwordError = null;
        _serverUrlError = null;
        _error = null;
      });
    }
  }

  Future<void> _verifyServer() async {
    final l10n = AppLocalizations.of(context);
    var rawUrl = _serverUrlController.text.trim();
    if (rawUrl.isEmpty) {
      setState(() => _error = l10n.authServerUrlRequired);
      return;
    }
    if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
      rawUrl = 'https://$rawUrl';
      _serverUrlController.text = rawUrl;
    }
    setState(() {
      _verifyingServer = true;
      _error = null;
    });
    try {
      final cleanUrl = rawUrl.endsWith('/')
          ? rawUrl.substring(0, rawUrl.length - 1)
          : rawUrl;
      final uri = Uri.parse('$cleanUrl/api/v1/bootstrap');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 500) {
        final currentConfig = ref.read(syncApiConfigProvider);
        final updatedConfig = currentConfig.copyWith(
          enabled: true,
          baseUrl: cleanUrl,
        );
        ref.read(syncApiConfigProvider.notifier).state = updatedConfig;
        await ref
            .read(settingsRepositoryProvider)
            .saveSyncServerBaseUrl(cleanUrl);
        await ref.read(settingsRepositoryProvider).saveSyncEnabled(true);

        if (!mounted) return;
        setState(() {
          _serverVerified = true;
          _verifyingServer = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = l10n.authServerVerificationFailed(response.statusCode);
          _verifyingServer = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = l10n.authServerConnectionError;
        _verifyingServer = false;
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    final password = _password.text;

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

    final bool isSyncEnabled = _useSyncModeOverride ?? false;
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

      if (isSyncEnabled) {
        await ref
            .read(authStateProvider.notifier)
            .loginForSync(
              email: email,
              password: password,
              deviceId: deviceId,
              deviceName: 'Flutter Device',
              platform: defaultTargetPlatform.name,
            );
        await ref
            .read(syncEnabledProvider.notifier)
            .enableAfterAuthentication(runInitialSync: false);
      } else {
        await ref
            .read(authStateProvider.notifier)
            .loginLocal(
              email: email,
              password: password,
              companyId: LocalAuthDefaults.companyId,
              deviceId: deviceId,
              deviceName: 'local',
              platform: defaultTargetPlatform.name,
            );
        await ref.read(syncEnabledProvider.notifier).disableForLocalLogin();
      }

      final credentialStore = ref.read(syncLoginCredentialStoreProvider);
      final isBioEnabled = await credentialStore.isBiometricLoginEnabled(
        isSyncMode: isSyncEnabled,
      );
      if (isBioEnabled) {
        await credentialStore.saveCredentials(
          email: email,
          password: password,
          isSyncMode: isSyncEnabled,
        );
        if (mounted) {
          setState(() {
            _hasSavedCredentials = true;
          });
        }
      } else {
        await credentialStore.clear(isSyncMode: isSyncEnabled);
        if (mounted) {
          setState(() {
            _hasSavedCredentials = false;
          });
        }
      }
      // Authentication state updated. AppRouter.redirect automatically handles route transition.
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
    final bool isSyncEnabled = _useSyncModeOverride ?? false;
    final isSetupReady =
        ref.watch(systemSetupReadyProvider).valueOrNull ?? false;
    final showBackButton = !isSetupReady;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
        extendBodyBehindAppBar: true,
        appBar: showBackButton
            ? AppBar(
                leading: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Material(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
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
              )
            : null,
        body: Stack(
          children: [
            // Background Layer with Multi-stop Soft Ambient Gradients
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.surface,
                      Color.alphaBlend(
                        colorScheme.primary.withValues(alpha: 0.05),
                        colorScheme.surface,
                      ),
                      Color.alphaBlend(
                        colorScheme.tertiary.withValues(alpha: 0.03),
                        colorScheme.surface,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top Glowing Mesh Circle
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.18),
                      colorScheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Left Glowing Mesh Circle
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.tertiary.withValues(alpha: 0.15),
                      colorScheme.tertiary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content Container
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.manual,
                    physics: const ClampingScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                          maxWidth: double.infinity,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.md,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: AppSpacing.md),

                              // Enterprise Brand Header
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                          width: 76,
                                          height: 76,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                colorScheme.primary,
                                                colorScheme.primary.withValues(
                                                  alpha: 0.75,
                                                ),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 24,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Icon(
                                                Icons.shield_outlined,
                                                size: 40,
                                                color: colorScheme.onPrimary,
                                              ),
                                              Positioned(
                                                right: 18,
                                                bottom: 18,
                                                child: Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: colorScheme.tertiary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(
                                          duration: 500.ms,
                                          curve: Curves.easeOut,
                                        )
                                        .scale(
                                          begin: const Offset(0.85, 0.85),
                                          end: const Offset(1.0, 1.0),
                                          duration: 500.ms,
                                          curve: Curves.easeOutBack,
                                        ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      'NexaBiz ERP',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                            color: colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      l10n.authAppSubtitle,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppSpacing.lg),

                              // Segmented Dual-Tab Mode Switcher
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _ModeTab(
                                        label: l10n.authLocalModeLabel,
                                        icon: Icons.phonelink_setup_rounded,
                                        isSelected: !isSyncEnabled,
                                        onTap: () {
                                          _clearAllErrors();
                                          if (isSyncEnabled) {
                                            setState(() {
                                              _useSyncModeOverride = false;
                                            });
                                            _initBiometricsAndSavedCredentials(
                                              false,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: _ModeTab(
                                        label: l10n.authSyncModeLabel,
                                        icon: Icons.cloud_sync_rounded,
                                        isSelected: isSyncEnabled,
                                        onTap: () {
                                          _clearAllErrors();
                                          if (!isSyncEnabled) {
                                            setState(() {
                                              _useSyncModeOverride = true;
                                            });
                                            _initBiometricsAndSavedCredentials(
                                              true,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(
                                duration: 400.ms,
                                delay: 100.ms,
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Glassmorphic Premium Card Box Container
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.lg,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerLowest
                                      .withValues(alpha: isDark ? 0.88 : 0.96),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: colorScheme.primary.withValues(
                                      alpha: isDark ? 0.22 : 0.14,
                                    ),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.shadow.withValues(
                                        alpha: isDark ? 0.35 : 0.08,
                                      ),
                                      blurRadius: 40,
                                      spreadRadius: -2,
                                      offset: const Offset(0, 20),
                                    ),
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(
                                        alpha: isDark ? 0.12 : 0.05,
                                      ),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: isSyncEnabled && !_serverVerified
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  AppSpacing.xs,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme
                                                      .primaryContainer
                                                      .withValues(alpha: 0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  Icons.dns_rounded,
                                                  color: colorScheme.primary,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.sm,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      l10n.authServerSetupTitle,
                                                      style: theme
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                    Text(
                                                      l10n.authServerSetupSubtitle,
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: AppSpacing.lg),
                                          TextField(
                                            controller: _serverUrlController,
                                            textDirection: TextDirection.ltr,
                                            scrollPadding:
                                                const EdgeInsets.only(
                                                  bottom: 120,
                                                ),
                                            keyboardType: TextInputType.url,
                                            textInputAction:
                                                TextInputAction.done,
                                            onChanged: (_) {
                                              if (_serverUrlError != null) {
                                                setState(
                                                  () => _serverUrlError = null,
                                                );
                                              }
                                            },
                                            onSubmitted: (_) => _verifyingServer
                                                ? null
                                                : _verifyServer(),
                                            decoration: InputDecoration(
                                              errorText: _serverUrlError,
                                              labelText:
                                                  l10n.authServerUrlLabel,
                                              hintText:
                                                  'https://api.rawnaqq.com',
                                              prefixIcon: Icon(
                                                Icons.link_rounded,
                                                color: colorScheme.primary,
                                              ),
                                              filled: true,
                                              fillColor: colorScheme
                                                  .surfaceContainerHighest
                                                  .withValues(alpha: 0.35),
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
                                            ),
                                          ),
                                          if (_error != null) ...[
                                            const SizedBox(
                                              height: AppSpacing.md,
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(
                                                AppSpacing.md,
                                              ),
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .errorContainer
                                                    .withValues(alpha: 0.35),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: colorScheme.error
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.error_outline_rounded,
                                                    size: 20,
                                                    color: colorScheme.error,
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.sm,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      _error!,
                                                      style: TextStyle(
                                                        color:
                                                            colorScheme.error,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: AppSpacing.lg),
                                          AppButton(
                                            onPressed: _verifyingServer
                                                ? null
                                                : _verifyServer,
                                            label: _verifyingServer
                                                ? l10n.authServerVerifying
                                                : l10n.authServerVerifyAndNext,
                                            isLoading: _verifyingServer,
                                            expand: true,
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          OutlinedButton.icon(
                                            onPressed: _verifyingServer
                                                ? null
                                                : () {
                                                    setState(() {
                                                      _serverVerified = true;
                                                      _error = null;
                                                    });
                                                  },
                                            icon: const Icon(
                                              Icons.arrow_back_rounded,
                                              size: 18,
                                            ),
                                            label: Text(
                                              l10n.authBackToLoginFields,
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(
                                                double.infinity,
                                                48,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              side: BorderSide(
                                                color: colorScheme.outline
                                                    .withValues(alpha: 0.25),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (isSyncEnabled) ...[
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.sm,
                                                    vertical: AppSpacing.xs,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.08),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: colorScheme.primary
                                                      .withValues(alpha: 0.2),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.check_circle_rounded,
                                                    size: 18,
                                                    color: colorScheme.primary,
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.xs,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      _serverUrlController.text,
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      setState(
                                                        () => _serverVerified =
                                                            false,
                                                      );
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal:
                                                                AppSpacing.xs,
                                                            vertical: 4,
                                                          ),
                                                      child: Text(
                                                        l10n.authChangeServer,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: colorScheme
                                                              .primary,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.md,
                                            ),
                                          ],
                                          // Email / Username Field
                                          TextField(
                                            controller: _email,
                                            textDirection: TextDirection.ltr,
                                            scrollPadding:
                                                const EdgeInsets.only(
                                                  bottom: 120,
                                                ),
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            autofillHints: const [
                                              AutofillHints.username,
                                            ],
                                            textInputAction:
                                                TextInputAction.next,
                                            onChanged: (_) {
                                              if (_emailError != null) {
                                                setState(
                                                  () => _emailError = null,
                                                );
                                              }
                                            },
                                            decoration: InputDecoration(
                                              errorText: _emailError,
                                              labelText: l10n.authEmailLabel,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.lg,
                                                    vertical: 18,
                                                  ),
                                              prefixIcon: Icon(
                                                Icons.person_outline_rounded,
                                                color: colorScheme.primary,
                                              ),
                                              filled: true,
                                              fillColor: colorScheme
                                                  .surfaceContainerHighest
                                                  .withValues(alpha: 0.35),
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
                                            ),
                                          ),

                                          const SizedBox(height: AppSpacing.lg),

                                          // Password Field
                                          TextField(
                                            controller: _password,
                                            textDirection: TextDirection.ltr,
                                            scrollPadding:
                                                const EdgeInsets.only(
                                                  bottom: 120,
                                                ),
                                            obscureText: _obscurePassword,
                                            autofillHints: const [
                                              AutofillHints.password,
                                            ],
                                            textInputAction:
                                                TextInputAction.done,
                                            onChanged: (_) {
                                              if (_passwordError != null) {
                                                setState(
                                                  () => _passwordError = null,
                                                );
                                              }
                                            },
                                            onSubmitted: (_) =>
                                                _loading ? null : _submit(),
                                            decoration: InputDecoration(
                                              errorText: _passwordError,
                                              labelText: l10n.authPasswordLabel,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.lg,
                                                    vertical: 18,
                                                  ),
                                              prefixIcon: Icon(
                                                Icons.lock_outline_rounded,
                                                color: colorScheme.primary,
                                              ),
                                              filled: true,
                                              fillColor: colorScheme
                                                  .surfaceContainerHighest
                                                  .withValues(alpha: 0.35),
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
                                              suffixIcon: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (_canCheckBiometrics &&
                                                      _enableBiometrics &&
                                                      _hasSavedCredentials)
                                                    IconButton(
                                                      tooltip: l10n.authBiometricPromptReason,
                                                      icon: Icon(
                                                        Icons.fingerprint_rounded,
                                                        color: colorScheme.primary,
                                                        size: 24,
                                                      ),
                                                      onPressed:
                                                          _authenticateWithBiometrics,
                                                    ),
                                                  IconButton(
                                                    icon: Icon(
                                                      _obscurePassword
                                                          ? Icons.visibility_outlined
                                                          : Icons.visibility_off_outlined,
                                                      color: colorScheme.onSurfaceVariant,
                                                    ),
                                                    onPressed: () {
                                                      setState(
                                                        () => _obscurePassword =
                                                            !_obscurePassword,
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.xs),

                                          if (_error != null) ...[
                                            const SizedBox(
                                              height: AppSpacing.md,
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(
                                                AppSpacing.sm,
                                              ),
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .errorContainer
                                                    .withValues(alpha: 0.35),
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
                                                    Icons.error_outline_rounded,
                                                    size: 18,
                                                    color: colorScheme.error,
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.xs,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      _error!,
                                                      style: TextStyle(
                                                        color:
                                                            colorScheme.error,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],

                                          const SizedBox(height: AppSpacing.lg),

                                          // Primary Action Button
                                          AppButton(
                                            onPressed: _loading
                                                ? null
                                                : _submit,
                                            label: _loading
                                                ? l10n.authSigningIn
                                                : l10n.authSignIn,
                                            isLoading: _loading,
                                            expand: true,
                                          ),
                                        ],
                                      ),
                              ).animate().fadeIn(duration: 400.ms, delay: 150.ms).moveY(begin: 16, end: 0, duration: 400.ms),

                              const SizedBox(height: AppSpacing.lg),

                              // Security Trust Footer
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock_rounded,
                                      size: 14,
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(width: AppSpacing.xxs),
                                    Text(
                                      l10n.authSecurityFooter,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontSize: 11,
                                            color: colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
