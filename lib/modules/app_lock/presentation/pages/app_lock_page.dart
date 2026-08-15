import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/app_lock_state.dart';
import '../providers/app_lock_providers.dart';
import 'app_lock_routes.dart';

/// Global PIN unlock screen — not a login page.
class AppLockPage extends ConsumerStatefulWidget {
  const AppLockPage({super.key});

  @override
  ConsumerState<AppLockPage> createState() => _AppLockPageState();
}

class _AppLockPageState extends ConsumerState<AppLockPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  var _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _controller.text.trim();
    if (pin.isEmpty) return;
    final ok = await ref.read(appLockControllerProvider.notifier).unlock(pin);
    if (!mounted) return;
    _controller.clear();
    if (ok) {
      final returnTo =
          ref.read(appLockControllerProvider.notifier).returnToLocation;
      ref.read(appLockControllerProvider.notifier).returnToLocation = null;
      final target = (returnTo != null &&
              returnTo.isNotEmpty &&
              returnTo != AppLockRoutes.root)
          ? returnTo
          : AppRoutes.dashboard;
      context.go(target);
    } else {
      _focus.requestFocus();
    }
  }

  String? _errorText(AppLockState state, AppLocalizations l10n) {
    if (state.isLockoutActive) {
      return l10n.appLockErrorLockout;
    }
    return switch (state.errorMessage) {
      'invalid' => l10n.appLockErrorInvalid,
      'lockout' => l10n.appLockErrorLockout,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(appLockControllerProvider);
    final error = _errorText(state, l10n);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.surface,
                  Color.alphaBlend(
                    colorScheme.primary.withValues(alpha: 0.06),
                    colorScheme.surface,
                  ),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          child: Image.asset(
                            'assets/branding/nexabiz_app_icon.png',
                            width: 72,
                            height: 72,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 36,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.appLockTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.appLockSubtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        TextField(
                          controller: _controller,
                          focusNode: _focus,
                          autofocus: true,
                          obscureText: _obscure,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          maxLength: AppLockController.maxPinLength,
                          enabled: !state.busy && !state.isLockoutActive,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: l10n.appLockPinLabel,
                            counterText: '',
                            border: const OutlineInputBorder(),
                            errorText: error,
                            suffixIcon: IconButton(
                              tooltip: _obscure
                                  ? l10n.appLockShowPin
                                  : l10n.appLockHidePin,
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: state.busy || state.isLockoutActive
                                ? null
                                : _submit,
                            child: state.busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : Text(l10n.appLockUnlockAction),
                          ),
                        ),
                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
