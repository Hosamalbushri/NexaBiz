import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/settings/company/company_profile.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/auth_user.dart';
import '../providers/auth_providers.dart';

/// Modal bottom sheet to view detailed company profile and ownership data.
class CompanyDetailsSheet extends ConsumerStatefulWidget {
  const CompanyDetailsSheet({
    super.key,
    required this.company,
  });

  final AuthCompany company;

  static Future<void> show(BuildContext context, AuthCompany company) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompanyDetailsSheet(company: company),
    );
  }

  @override
  ConsumerState<CompanyDetailsSheet> createState() =>
      _CompanyDetailsSheetState();
}

class _CompanyDetailsSheetState extends ConsumerState<CompanyDetailsSheet> {
  late Future<CompanyProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ref
        .read(settingsRepositoryProvider)
        .loadCompanyProfile(widget.company.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final company = widget.company;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header with Avatar and Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  company.code.isNotEmpty ? company.code.substring(0, 1) : 'C',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs + 2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            'كود: ${company.code}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (company.role != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs + 2,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              'الدور: ${company.role}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
          const SizedBox(height: AppSpacing.sm),

          // Scrollable Profile Async Loader & Card Details
          Flexible(
            child: SingleChildScrollView(
              child: FutureBuilder<CompanyProfile>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final profile = snapshot.data ?? const CompanyProfile();
                  final session = ref.watch(authStateProvider).session;
                  final isCurrentlyActive = session?.currentCompanyId == company.id;
                  final activeContext = session?.activeCompanyContext;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tenancy Context Card
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isCurrentlyActive
                              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isCurrentlyActive
                                ? colorScheme.primary.withValues(alpha: 0.4)
                                : colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isCurrentlyActive
                                      ? Icons.check_circle_rounded
                                      : Icons.tag_rounded,
                                  size: 18,
                                  color: isCurrentlyActive
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'سياق التشغيل والعزل (Tenancy Context)',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentlyActive
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs + 2),
                            _buildContextText(
                              context,
                              label: 'حالة السياق النشط:',
                              value: isCurrentlyActive
                                  ? 'نشط حالياً في الجلسة (Active Context)'
                                  : 'غير نشط حالياً (Inactive Context)',
                            ),
                            _buildContextText(
                              context,
                              label: 'معرّف الشركة (Company ID):',
                              value: company.id,
                            ),
                            _buildContextText(
                              context,
                              label: 'رمز الشركة (Code):',
                              value: company.code.isNotEmpty ? company.code : 'غير محدد',
                            ),
                            _buildContextText(
                              context,
                              label: 'الدور في السياق (Role):',
                              value: company.role ??
                                  (session?.user.isSuperAdmin == true
                                      ? 'Owner (SuperAdmin)'
                                      : 'Member'),
                            ),
                            if (activeContext != null && isCurrentlyActive)
                              _buildContextText(
                                context,
                                label: 'معرّف السياق المعزول (Context ID):',
                                value: activeContext.companyId,
                              ),
                            if (session?.sessionId != null)
                              _buildContextText(
                                context,
                                label: 'معرّف الجلسة (Session ID):',
                                value: session!.sessionId!,
                              ),
                          ],
                        ),
                      ),

                      _buildDetailTile(
                        context,
                        icon: Icons.fingerprint_rounded,
                        title: 'معرّف الشركة (Company ID)',
                        subtitle: company.id,
                      ),
                      _buildDetailTile(
                        context,
                        icon: Icons.business_center_rounded,
                        title: 'الاسم التجاري / الرسمية',
                        subtitle: profile.name.isNotEmpty
                            ? profile.name
                            : company.name,
                      ),
                      if (profile.legalName != null &&
                          profile.legalName!.isNotEmpty)
                        _buildDetailTile(
                          context,
                          icon: Icons.gavel_rounded,
                          title: 'الاسم القانوني للشركة',
                          subtitle: profile.legalName!,
                        ),
                      _buildDetailTile(
                        context,
                        icon: Icons.attach_money_rounded,
                        title: 'العملة الافتراضية',
                        subtitle:
                            '${profile.defaultCurrency.nameAr} (${profile.defaultCurrencyCode})',
                      ),
                      _buildDetailTile(
                        context,
                        icon: Icons.receipt_long_rounded,
                        title: 'الرقم الضريبي',
                        subtitle: profile.taxNumber ?? 'غير محدد',
                      ),
                      _buildDetailTile(
                        context,
                        icon: Icons.badge_rounded,
                        title: 'السجل التجاري',
                        subtitle: profile.commercialRegister ?? 'غير محدد',
                      ),
                      if (profile.email != null && profile.email!.isNotEmpty)
                        _buildDetailTile(
                          context,
                          icon: Icons.email_rounded,
                          title: 'البريد الإلكتروني للتواصل',
                          subtitle: profile.email!,
                        ),
                      if (profile.phone != null && profile.phone!.isNotEmpty)
                        _buildDetailTile(
                          context,
                          icon: Icons.phone_rounded,
                          title: 'رقم الهاتف',
                          subtitle: profile.phone!,
                        ),
                      if (profile.address != null &&
                          profile.address!.isNotEmpty)
                        _buildDetailTile(
                          context,
                          icon: Icons.location_on_rounded,
                          title: 'العنوان والمعلومات المكانية',
                          subtitle: [
                            profile.address,
                            if (profile.city != null) profile.city,
                            if (profile.country != null) profile.country,
                          ].join(', '),
                        ),
                      _buildDetailTile(
                        context,
                        icon: Icons.calendar_month_rounded,
                        title: 'بداية السنة المالية',
                        subtitle: 'شهر ${profile.fiscalYearStartMonth}',
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق التفاصيل'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextText(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
