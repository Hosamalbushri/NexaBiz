import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/widgets/settings_chrome.dart';
import 'package:stock_count/app/sync/sync_settings_section.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';

import 'package:stock_count/modules/sync/presentation/pages/admin_sync_conflict_page.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

/// Single authoritative Master Settings Hub for Sync Engine Module (`/sync/settings`).
///
/// Clean, unified, tabless professional configuration interface for Sync Engine.
class SyncMasterSettingsPage extends ConsumerWidget {
  const SyncMasterSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAr = l10n.localeName == 'ar';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isAr
            ? 'إعدادات وتهيئة محرك التزامن'
            : 'Sync Engine Master Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          // Hero Banner
          _buildHeroHeader(theme, isAr),
          const SizedBox(height: AppSpacing.md),

          // Section 1: Active Sync Engine Controls & Monitor
          SettingsGroupLabel(
            isAr
                ? 'حالة التزامن والاتصال بالخادم'
                : 'Live Sync Status & Engine Control',
          ),
          const SettingsGroup(
            children: [
              SyncSettingsSection(embedded: true, compactHeader: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 2: Sync Conflicts & Outbox Management List Menu
          SettingsGroupLabel(
            isAr
                ? 'إدارة التعارضات وصندوق الصادر'
                : 'Conflict Management & Inspection',
          ),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.sync_problem_rounded,
                iconColor: Colors.deepOrange,
                title: isAr
                    ? 'إدارة وسجل فك التعارضات'
                    : 'Sync Conflicts Management',
                subtitle: isAr
                    ? 'عرض وتصفية السجلات المتعادلة وإصلاح تعارض البيانات يدوياً'
                    : 'Review and resolve conflicting data records between local & cloud',
                showChevron: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminSyncConflictPage(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(ThemeData theme, bool isAr) {
    return AppCard(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.sync_rounded,
              color: theme.colorScheme.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr
                      ? 'مركز تهيئة وإعدادات المزامنة'
                      : 'Sync Engine Settings Center',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'مراقبة حالة الاتصال بالخادم، المزامنة الفورية، وفض تعارض السجلات'
                      : 'Monitor cloud connection, real-time sync, and resolve conflict records',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
