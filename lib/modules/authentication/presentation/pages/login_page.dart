import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/local_permissions.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController(text: LocalAuthDefaults.adminEmail);
  final _password = TextEditingController(text: LocalAuthDefaults.adminPassword);
  var _loading = false;
  String? _error;

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var deviceId = ref.read(syncApiConfigProvider).deviceId.trim();
      if (!_uuidPattern.hasMatch(deviceId)) {
        deviceId = generateUuidV4();
        ref.read(syncApiConfigProvider.notifier).state = ref
            .read(syncApiConfigProvider)
            .copyWith(deviceId: deviceId);
      }
      await ref.read(authStateProvider.notifier).login(
            email: _email.text.trim(),
            password: _password.text.trim(),
            companyId: LocalAuthDefaults.companyId,
            deviceId: deviceId,
            deviceName: 'local',
            platform: defaultTargetPlatform.name,
          );
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
                    l10n.authLoginTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.authLoginLocalHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l10n.authEmailLabel),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _loading ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: l10n.authPasswordLabel,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: scheme.error)),
                  ],
                  const SizedBox(height: 24),
                  AppButton(
                    onPressed: _loading ? null : _submit,
                    label: _loading ? l10n.authSigningIn : l10n.authSignIn,
                    isLoading: _loading,
                    expand: true,
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
