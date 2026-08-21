import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/server_validator.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../modules/authentication/presentation/providers/auth_providers.dart';
import '../bootstrap/app_initialization.dart';
import '../localization/app_localizations.dart';
import '../router/app_routes.dart';
import '../sync/sync_enabled_provider.dart';
import '../theme/app_spacing.dart';
import '../constants/app_constants.dart';

/// First-launch server setup: enter server address, validate, then sign in.
///
/// Shown when the user chooses "Connect to Server" from [SetupChoicePage].
/// After validation the user is sent to the sync login page, then an initial
/// sync runs before entering the dashboard.
class ServerSetupPage extends ConsumerStatefulWidget {
  const ServerSetupPage({super.key});

  @override
  ConsumerState<ServerSetupPage> createState() => _ServerSetupPageState();
}

class _ServerSetupPageState extends ConsumerState<ServerSetupPage> {
  final _urlController = TextEditingController();
  var _validating = false;
  String? _error;
  bool _validated = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    final l10n = AppLocalizations.of(context);
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = l10n.syncServerUrlRequired);
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      setState(() => _error = l10n.syncServerUrlInvalid);
      return;
    }

    setState(() {
      _validating = true;
      _error = null;
      _validated = false;
    });

    final result = await ServerValidator.validate(url);

    if (!mounted) return;

    if (result.healthy) {
      // Persist server URL for the sync subsystem.
      await ref
          .read(syncEnabledProvider.notifier)
          .saveServer(baseUrl: result.baseUrl ?? url, apiToken: '');
      setState(() {
        _validating = false;
        _validated = true;
        _error = null;
      });
    } else {
      setState(() {
        _validating = false;
        _error = result.error ?? l10n.serverSetupValidFailed;
      });
    }
  }

  Future<void> _continueToSignIn() async {
    final baseUrl = _urlController.text.trim();
    // Navigate to dedicated Server Bootstrap Login screen
    context.go(AppRoutes.serverBootstrapLogin, extra: baseUrl);
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
      child: PopScope(
        canPop: true,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(AppRoutes.setupChoice),
            ),
            title: Text(l10n.serverSetupTitle),
          ),
          body: ListView(
            padding: AppConstants.pageInsets(context),
            children: [
              const SizedBox(height: AppSpacing.lg),
              Icon(
                Icons.dns_outlined,
                size: 56,
                color: colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.serverSetupSubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                enabled: !_validated,
                decoration: InputDecoration(
                  labelText: l10n.serverSetupUrlLabel,
                  hintText: l10n.serverSetupUrlHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.link),
                  errorText: _error,
                  suffixIcon: _validated
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
                onSubmitted: (_) => _validate(),
              ),
              if (_validated) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.serverSetupValidSuccess,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (!_validated)
                AppButton(
                  label: l10n.serverSetupValidate,
                  isLoading: _validating,
                  expand: true,
                  onPressed: _validating ? null : _validate,
                )
              else
                AppButton(
                  label: l10n.serverSetupContinueToSignIn,
                  expand: true,
                  icon: Icons.login_outlined,
                  onPressed: _continueToSignIn,
                ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => context.go(AppRoutes.setupChoice),
                child: Text(l10n.serverSetupBackToChoice),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
