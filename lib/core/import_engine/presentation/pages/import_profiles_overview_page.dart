import 'package:flutter/material.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/import_profile.dart';
import '../../registry/import_profile_registry.dart';

/// Settings page displaying all registered Import profiles and their field schemas.
class ImportProfilesOverviewPage extends StatelessWidget {
  const ImportProfilesOverviewPage({super.key});

  static const String routePath = '/import-engine/profiles';

  @override
  Widget build(BuildContext context) {
    final profiles = ImportProfileRegistry.allProfiles;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'ملفات الاستيراد المسجلة | Import Profiles',
        showBackButton: true,
      ),
      body: profiles.isEmpty
          ? const Center(
              child: Text('لا توجد ملفات استيراد مسجلة حالياً.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: profiles.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return _ProfileDetailCard(profile: profile);
              },
            ),
    );
  }
}

class _ProfileDetailCard extends StatelessWidget {
  const _ProfileDetailCard({required this.profile});

  final ImportProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.insert_drive_file_outlined,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ID: ${profile.profileId} | Entity: ${profile.entityType}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppStatusBadge(
                label: '${profile.fields.length} حقول',
                tone: AppStatusTone.info,
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),

          // Fields List Header
          Text(
            'حقول البيانات (Data Fields):',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: profile.fields.map((field) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: field.isRequired
                        ? colorScheme.error.withValues(alpha: 0.4)
                        : colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      field.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: field.isRequired ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (field.isRequired) ...[
                      const SizedBox(width: 2),
                      Text('*', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(width: 4),
                    Text(
                      '(${field.dataType.name})',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          if (profile.relations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'العلاقات والربط (Relations):',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: profile.relations.map((rel) {
                return Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.link_rounded, size: 14),
                  label: Text('${rel.relationKey} ➔ ${rel.targetEntityType} (${rel.lookupFieldKey})'),
                  backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
