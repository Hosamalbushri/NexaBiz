import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/bootstrap/app_bootstrap.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/auth_user.dart';
import '../providers/auth_providers.dart';

/// Shows a 2-step confirmation and re-authentication dialog flow for switching companies.
/// Returns true if company switch succeeded, false otherwise.
Future<bool> showCompanySwitchConfirmationFlow(
  BuildContext context,
  WidgetRef ref,
  AuthCompany targetCompany,
) async {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  // Step 1: Confirmation Dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Row(
        children: [
          Icon(Icons.swap_horiz_rounded, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(l10n.authSelectCompanyTitle),
        ],
      ),
      content: Text(
        'هل أنت تأكد من الانتقال إلى شركة "${targetCompany.name}"؟',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          child: const Text('تأكيد الانتقال'),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;
  if (!context.mounted) return false;

  // Step 2: Email & Password Re-Authentication Dialog
  final authSuccess = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => _CompanySwitchAuthDialog(
      targetCompany: targetCompany,
      initialEmail: '',
      ref: ref,
    ),
  );

  return authSuccess ?? false;
}

class _CompanySwitchAuthDialog extends StatefulWidget {
  final AuthCompany targetCompany;
  final String initialEmail;
  final WidgetRef ref;

  const _CompanySwitchAuthDialog({
    required this.targetCompany,
    required this.initialEmail,
    required this.ref,
  });

  @override
  State<_CompanySwitchAuthDialog> createState() => _CompanySwitchAuthDialogState();
}

class _CompanySwitchAuthDialogState extends State<_CompanySwitchAuthDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await AppBootstrap.stopSync(widget.ref);

      final result = await widget.ref
          .read(authStateProvider.notifier)
          .switchCompanyWithCredentials(
            companyId: widget.targetCompany.id,
            email: email,
            password: password,
          );

      if (!mounted) return;

      if (result.isSuccess) {
        await AppBootstrap.bootstrapSync(widget.ref);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              result.failureReason ?? 'فشل تسجيل الدخول أو بيانات غير صحيحة';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ غير متوقع: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.lock_person_rounded, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'المصادقة للانتقال',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'شركة: ${widget.targetCompany.name}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'يرجى إدخال البريد الإلكتروني وكلمة المرور لتأكيد الدخول إلى الشركة:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني / اسم المستخدم *',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'يرجى إدخال البريد الإلكتروني'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور *',
                  prefixIcon: const Icon(Icons.lock_outline),
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
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'يرجى إدخال كلمة المرور'
                    : null,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: colorScheme.error),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('تأكيد ودخول'),
        ),
      ],
    );
  }
}
