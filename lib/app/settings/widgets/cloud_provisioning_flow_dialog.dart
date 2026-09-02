import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../company/company_cloud_providers.dart';
import '../company/company_cloud_state.dart';
import '../company/company_profile_providers.dart';
import '../../theme/app_spacing.dart';

enum ProvisioningMode { linkExisting, createNew }

class CloudProvisioningFlowDialog extends ConsumerStatefulWidget {
  const CloudProvisioningFlowDialog({
    super.key,
    this.initialMode = ProvisioningMode.linkExisting,
  });

  final ProvisioningMode initialMode;

  static Future<void> show(
    BuildContext context, {
    ProvisioningMode initialMode = ProvisioningMode.linkExisting,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CloudProvisioningFlowDialog(initialMode: initialMode),
    );
  }

  @override
  ConsumerState<CloudProvisioningFlowDialog> createState() =>
      _CloudProvisioningFlowDialogState();
}

class _CloudProvisioningFlowDialogState
    extends ConsumerState<CloudProvisioningFlowDialog> {
  late ProvisioningMode _mode;
  String _selectedPlanId = 'plan_starter';
  final _paymentRefController =
      TextEditingController(text: 'PAY-ONBOARDING-VERIFIED');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _paymentRefController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyProfileAsync = ref.watch(companyProfileProvider);
    final companyName = companyProfileAsync.valueOrNull?.name ?? '';
    final provisioningAsync = ref.watch(companyProvisioningControllerProvider);

    final currentStep = provisioningAsync.value;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: currentStep != null && currentStep.isProcessing
            ? _buildProgressView(context, currentStep)
            : currentStep != null && currentStep.isSuccess
                ? _buildSuccessView(context, currentStep)
                : currentStep != null && currentStep.isFailed
                    ? _buildErrorView(context, currentStep)
                    : _buildMainView(context, companyName),
      ),
    );
  }

  Widget _buildMainView(BuildContext context, String companyName) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_upload_outlined,
                  color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cloud Linking & Setup',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    companyName.isEmpty ? 'Local Business' : companyName,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<ProvisioningMode>(
          segments: const [
            ButtonSegment(
              value: ProvisioningMode.linkExisting,
              label: Text('Link Existing Account'),
              icon: Icon(Icons.link),
            ),
            ButtonSegment(
              value: ProvisioningMode.createNew,
              label: Text('Create New Cloud Co.'),
              icon: Icon(Icons.add_business),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (set) {
            setState(() {
              _mode = set.first;
            });
          },
        ),
        const Divider(height: 24),
        Expanded(
          child: _mode == ProvisioningMode.linkExisting
              ? _buildLinkExistingForm(context)
              : _buildPlanSelectionView(context, companyName),
        ),
      ],
    );
  }

  Widget _buildLinkExistingForm(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Admin Credentials for Server Company',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Authenticate with an existing cloud company administrator account to link this local workspace.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Admin Email *',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter admin email address';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Admin Password *',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Please enter admin password';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _companyCodeController,
              decoration: const InputDecoration(
                labelText: 'Server Company Code (Optional)',
                hintText: 'e.g. COMP-101 (Leave empty to auto-detect)',
                prefixIcon: Icon(Icons.business_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: _isConfirming ? null : _submitLinkExisting,
                  icon: const Icon(Icons.link),
                  label: const Text('Link Account & Sync'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSelectionView(BuildContext context, String companyName) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildPlanCard(
                  id: 'plan_starter',
                  title: 'Starter Plan',
                  price: '\$49 / month',
                  features: const [
                    'Cloud Synchronization',
                    'Multi-device access (Up to 5 devices)',
                    'Automatic Cloud Backup',
                    '5 Team Accounts',
                  ],
                  badge: 'Popular',
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildPlanCard(
                  id: 'plan_business',
                  title: 'Business Plan',
                  price: '\$99 / month',
                  features: const [
                    'All Starter capabilities',
                    'Multi-branch management',
                    'Advanced Financial Reports',
                    'Up to 20 Devices & 20 Users',
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildPlanCard(
                  id: 'plan_enterprise',
                  title: 'Enterprise Plan',
                  price: '\$199 / month',
                  features: const [
                    'Unlimited Devices & Users',
                    'Dedicated Cloud Instance',
                    '24/7 Priority Support',
                    'Custom ERP Integration',
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: _isConfirming ? null : _submitProvisioning,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Confirm & Provision Cloud'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String price,
    required List<String> features,
    String? badge,
  }) {
    final isSelected = _selectedPlanId == id;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => setState(() => _selectedPlanId = id),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Radio<String>(
                  value: id,
                  groupValue: _selectedPlanId,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPlanId = val);
                  },
                ),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: colorScheme.onPrimary),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.check, size: 14, color: Colors.green),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(f, style: theme.textTheme.bodySmall)),
                        ],
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

  Widget _buildProgressView(
      BuildContext context, ProvisioningStepProgress progress) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.lg),
        const CircularProgressIndicator(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          progress.status == CompanyCloudStatus.initialSyncing
              ? 'Migrating Local Data to Cloud...'
              : 'Provisioning Cloud Workspace...',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          progress.stepMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        if (progress.migrationProgress != null) ...[
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: progress.migrationProgress!.totalCount == 0
                ? 0
                : progress.migrationProgress!.processedCount /
                    progress.migrationProgress!.totalCount,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildSuccessView(
      BuildContext context, ProvisioningStepProgress progress) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Workspace Successfully Linked!',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your local company is now fully connected to the cloud instance. Real-time background sync is active.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildErrorView(
      BuildContext context, ProvisioningStepProgress progress) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 64, color: colorScheme.error),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Cloud setup could not be completed',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          progress.errorMessage ?? 'An unexpected network error occurred.',
          textAlign: TextAlign.center,
          style:
              theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue Offline'),
            ),
            ElevatedButton(
              onPressed: _mode == ProvisioningMode.linkExisting
                  ? _submitLinkExisting
                  : _submitProvisioning,
              child: const Text('Retry'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submitLinkExisting() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isConfirming = true);

    await ref
        .read(companyProvisioningControllerProvider.notifier)
        .linkExistingServerCompany(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          companyCode: _companyCodeController.text.trim(),
        );

    if (mounted) {
      setState(() => _isConfirming = false);
    }
  }

  Future<void> _submitProvisioning() async {
    setState(() => _isConfirming = true);
    final companyProfileAsync = ref.read(companyProfileProvider);
    final profile = companyProfileAsync.valueOrNull;
    final companyName =
        profile == null || profile.name.isEmpty ? 'My Business' : profile.name;

    await ref
        .read(companyProvisioningControllerProvider.notifier)
        .runProvisioningAndActivation(
          companyName: companyName,
          planId: _selectedPlanId,
          packageCodes: const ['cloud_sync'],
          paymentReference: _paymentRefController.text.trim(),
        );

    if (mounted) {
      setState(() => _isConfirming = false);
    }
  }
}
