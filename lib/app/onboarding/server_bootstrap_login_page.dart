import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/server_bootstrap_auth_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../bootstrap/app_initialization.dart';
import '../localization/app_localizations.dart';
import '../router/app_routes.dart';
import '../theme/app_spacing.dart';

/// Dedicated Server Bootstrap Login Screen.
///
/// Used exclusively during first-launch server setup to authenticate against the server
/// and retrieve the authorized bootstrap token for company snapshot download.
/// Disconnected from normal Application User Authentication and RBAC.
class ServerBootstrapLoginPage extends ConsumerStatefulWidget {
  const ServerBootstrapLoginPage({super.key, this.initialBaseUrl = ''});

  final String initialBaseUrl;

  @override
  ConsumerState<ServerBootstrapLoginPage> createState() =>
      _ServerBootstrapLoginPageState();
}

class _ServerBootstrapLoginPageState
    extends ConsumerState<ServerBootstrapLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isLoading = false;
  var _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleBootstrapLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final initState = ref.read(appInitializationControllerProvider);
    final baseUrl = widget.initialBaseUrl.isNotEmpty
        ? widget.initialBaseUrl
        : (initState.stageDetails.startsWith('http')
            ? initState.stageDetails
            : '');

    try {
      final authService = ref.read(serverBootstrapAuthServiceProvider);
      final token = await authService.authenticate(
        baseUrl: baseUrl,
        email: email,
        password: password,
      );

      if (!mounted) return;

      showAppSnackBar(
        context,
        message: l10n.syncSessionAuthenticated,
        isSuccess: true,
      );

      // Trigger server initialization pipeline with the isolated bootstrap token
      unawaited(
        ref
            .read(appInitializationControllerProvider.notifier)
            .runServerInitialization(
              baseUrl: baseUrl,
              token: token,
            ),
      );

      context.go(AppRoutes.serverBootstrapProgress);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: e.toString(),
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Bootstrap Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.serverSetup),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                Icon(
                  Icons.cloud_sync_outlined,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Authorize Company Initialization',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Sign in with an authorized server administrator account to retrieve company initialization data.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Server Admin Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!val.contains('@')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Server Admin Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Submit button
                AppButton(
                  label: 'Authorize & Download Data',
                  expand: true,
                  isLoading: _isLoading,
                  onPressed: _handleBootstrapLogin,
                ),

                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.go(AppRoutes.serverSetup),
                  child: const Text('Change Server Address'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
