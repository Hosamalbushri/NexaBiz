import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/app_lock_state.dart';
import '../providers/app_lock_providers.dart';

/// Global PIN unlock screen — not a login page.
///
/// Navigation after unlock is owned by GoRouter redirect (not this page),
/// to avoid racing two navigators that share the same GlobalKeys.
class AppLockPage extends ConsumerStatefulWidget {
  const AppLockPage({super.key});

  @override
  ConsumerState<AppLockPage> createState() => _AppLockPageState();
}

class _AppLockPageState extends ConsumerState<AppLockPage>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  late final AnimationController _shake;
  var _obscure = true;
  var _submitting = false;
  var _pinLength = 0;
  var _biometricPrompted = false;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _controller.addListener(_onPinChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybePromptBiometrics();
    });
  }

  void _onPinChanged() {
    final next = _controller.text.length;
    if (next != _pinLength) {
      setState(() => _pinLength = next);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPinChanged);
    _controller.dispose();
    _focus.dispose();
    _shake.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final pin = _controller.text.trim();
    if (pin.isEmpty) return;

    setState(() => _submitting = true);
    _focus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    } catch (_) {
      // Platform may not expose TextInput; ignore.
    }
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final ok = await ref.read(appLockControllerProvider.notifier).unlock(pin);
    if (!mounted) return;

    _controller.clear();
    if (!ok) {
      setState(() => _submitting = false);
      await _shake.forward(from: 0);
      return;
    }
  }

  Future<void> _unlockWithBiometrics() async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context);
    final state = ref.read(appLockControllerProvider);
    if (!state.canUseBiometrics) return;

    setState(() => _submitting = true);
    final ok = await ref
        .read(appLockControllerProvider.notifier)
        .unlockWithBiometrics(localizedReason: l10n.appLockBiometricPrompt);
    if (!mounted) return;
    if (!ok) {
      setState(() => _submitting = false);
    }
  }

  void _maybePromptBiometrics() {
    if (!mounted || _biometricPrompted) return;
    final state = ref.read(appLockControllerProvider);
    if (!state.canUseBiometrics || state.busy) return;
    _biometricPrompted = true;
    _unlockWithBiometrics();
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
    final blocked = state.busy || state.isLockoutActive || _submitting;
    final hasError = error != null;

    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const _LockAtmosphere(),
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      child: Column(
                        children: [
                          const _BrandHeader(),
                          const SizedBox(height: AppSpacing.md),
                          AnimatedBuilder(
                            animation: _shake,
                            builder: (context, child) {
                              final t = Curves.elasticIn.transform(
                                _shake.value,
                              );
                              final dx = math.sin(t * math.pi * 6) * 7;
                              return Transform.translate(
                                offset: Offset(dx, 0),
                                child: child,
                              );
                            },
                            child: _UnlockCard(
                              title: l10n.appLockTitle,
                              subtitle: l10n.appLockSubtitle,
                              pinLabel: l10n.appLockPinLabel,
                              unlockLabel: l10n.appLockUnlockAction,
                              biometricLabel: l10n.appLockBiometricUnlockAction,
                              showPinTooltip: l10n.appLockShowPin,
                              hidePinTooltip: l10n.appLockHidePin,
                              controller: _controller,
                              focusNode: _focus,
                              obscure: _obscure,
                              pinLength: _pinLength,
                              blocked: blocked,
                              busy: state.busy || _submitting,
                              showBiometrics: state.canUseBiometrics,
                              error: error,
                              hasError: hasError,
                              onToggleObscure: () =>
                                  setState(() => _obscure = !_obscure),
                              onSubmit: _submit,
                              onBiometric: _unlockWithBiometrics,
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
      ),
    );
  }
}

class _LockAtmosphere extends StatelessWidget {
  const _LockAtmosphere();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.07),
                colorScheme.surface,
              ),
              colorScheme.surface,
              Color.alphaBlend(
                colorScheme.secondary.withValues(alpha: isDark ? 0.06 : 0.03),
                colorScheme.surface,
              ),
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -40,
              child: _GlowOrb(
                size: 280,
                color: colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              top: 120,
              right: -90,
              child: _GlowOrb(
                size: 220,
                color: colorScheme.tertiary.withValues(alpha: 0.08),
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
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.35),
                    colorScheme.secondary.withValues(alpha: 0.2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    'assets/branding/nexabiz_app_icon.png',
                    width: 68,
                    height: 68,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppLocalizations.of(context).appTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _UnlockCard extends StatelessWidget {
  const _UnlockCard({
    required this.title,
    required this.subtitle,
    required this.pinLabel,
    required this.unlockLabel,
    required this.biometricLabel,
    required this.showPinTooltip,
    required this.hidePinTooltip,
    required this.controller,
    required this.focusNode,
    required this.obscure,
    required this.pinLength,
    required this.blocked,
    required this.busy,
    required this.showBiometrics,
    required this.error,
    required this.hasError,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onBiometric,
  });

  final String title;
  final String subtitle;
  final String pinLabel;
  final String unlockLabel;
  final String biometricLabel;
  final String showPinTooltip;
  final String hidePinTooltip;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscure;
  final int pinLength;
  final bool blocked;
  final bool busy;
  final bool showBiometrics;
  final String? error;
  final bool hasError;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onBiometric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: hasError
              ? colorScheme.error.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                height: 1.15,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PinMeter(
              count: pinLength,
              hasError: hasError,
              onTap: blocked ? null : () => focusNode.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: false,
              obscureText: obscure,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              maxLength: AppLockController.maxPinLength,
              readOnly: blocked,
              style: theme.textTheme.titleMedium?.copyWith(
                letterSpacing: 10,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: pinLabel,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w500,
                ),
                counterText: '',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                suffixIcon: IconButton(
                  tooltip: obscure ? showPinTooltip : hidePinTooltip,
                  onPressed: blocked ? null : onToggleObscure,
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                ),
              ),
              onSubmitted: blocked ? null : (_) => onSubmit(),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: hasError
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: _ErrorBanner(message: error!),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: blocked ? null : onSubmit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.1,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.lock_open_rounded, size: 20),
              label: Text(
                unlockLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (showBiometrics) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: blocked ? null : onBiometric,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                icon: const Icon(Icons.fingerprint_rounded, size: 22),
                label: Text(biometricLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PinMeter extends StatelessWidget {
  const _PinMeter({
    required this.count,
    required this.hasError,
    this.onTap,
  });

  final int count;
  final bool hasError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = hasError ? colorScheme.error : colorScheme.primary;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: hasError
                  ? colorScheme.error.withValues(alpha: 0.35)
                  : colorScheme.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: count == 0
                ? Icon(
                    Icons.password_rounded,
                    key: const ValueKey('empty'),
                    size: 18,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                  )
                : Row(
                    key: ValueKey('dots-$count-$hasError'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < count; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active,
                            boxShadow: [
                              BoxShadow(
                                color: active.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
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
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: colorScheme.error,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
