import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/password_change_exception.dart';
import '../providers/auth_providers.dart';

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
      context.go(AppRoutes.dashboard);
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.authChangePasswordTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.authChangePasswordHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _current,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.authCurrentPasswordLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _next,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.authNewPasswordLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirm,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _loading ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: l10n.authConfirmPasswordLabel,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: scheme.error)),
                  ],
                  const SizedBox(height: 24),
                  AppButton(
                    onPressed: _loading ? null : _submit,
                    label: _loading
                        ? l10n.authChangingPassword
                        : l10n.authChangePasswordAction,
                    isLoading: _loading,
                    expand: true,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => ref.read(authStateProvider.notifier).logout(),
                    child: Text(l10n.authLogoutAction),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
