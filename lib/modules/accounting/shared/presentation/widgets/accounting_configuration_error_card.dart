import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/accounting_configuration_error.dart';


class AccountingConfigurationErrorCard extends StatelessWidget {
  final AccountingConfigurationException error;
  final VoidCallback? onConfigurePressed;

  const AccountingConfigurationErrorCard({
    super.key,
    required this.error,
    this.onConfigurePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final roleLabel = error.accountingRole?.name ?? error.module;
    final expectedTypeLabel =
        error.expectedAccountType?.name ?? l10n.accountingUnspecified;
    final actualTypeLabel = error.actualAccountType?.name;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.error,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  error.userMessage,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (error.userExplanation != null) ...[
            Text(
              error.userExplanation!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  context,
                  l10n.accountingModuleRuleLabel,
                  roleLabel,
                ),
                _buildDetailRow(
                  context,
                  l10n.accountingRequiredAccountType,
                  expectedTypeLabel,
                ),
                if (actualTypeLabel != null)
                  _buildDetailRow(
                    context,
                    l10n.accountingCurrentAccountType,
                    actualTypeLabel,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppButton(
              onPressed:
                  onConfigurePressed ?? () => _defaultNavigate(context),
              icon: Icons.settings,
              label: _getActionLabel(l10n, error.errorCode),
              variant: AppButtonVariant.destructive,
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getActionLabel(
    AppLocalizations l10n,
    AccountingConfigurationErrorCode code,
  ) {
    switch (code) {
      case AccountingConfigurationErrorCode.accountTypeMismatch:
      case AccountingConfigurationErrorCode.accountScopeInvalid:
        return l10n.accountingFixSetupAction;
      case AccountingConfigurationErrorCode.entityAccountNotConfigured:
        return l10n.accountingBindEntityAccountAction;
      case AccountingConfigurationErrorCode.accountInactive:
      case AccountingConfigurationErrorCode.accountDeleted:
        return l10n.accountingReviewSettingsAction;
      default:
        return l10n.accountingSetupAction;
    }
  }

  void _defaultNavigate(BuildContext context) {
    if (error.configurationRoute != null) {
      context.push(error.configurationRoute!);
    }
  }
}
