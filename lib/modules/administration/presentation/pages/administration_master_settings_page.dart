import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/widgets/settings_chrome.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_card.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';

import 'package:stock_count/modules/administration/branches/presentation/pages/admin_branches_page.dart';
import 'package:stock_count/modules/administration/companies/presentation/pages/admin_companies_page.dart';
import 'package:stock_count/modules/administration/devices/presentation/pages/admin_devices_page.dart';
import 'package:stock_count/modules/administration/roles/presentation/pages/admin_roles_page.dart';
import 'package:stock_count/modules/administration/users/presentation/pages/admin_users_page.dart';

/// Single authoritative Master Settings Hub for Administration Module (`/administration/settings`).
///
/// Clean, unified, tabless professional configuration interface for Administration.
class AdministrationMasterSettingsPage extends ConsumerWidget {
  const AdministrationMasterSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAr = l10n.localeName == 'ar';

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isAr ? 'إعدادات وتهيئة الإدارة والنظام' : 'Administration Master Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          // Hero Banner
          _buildHeroHeader(theme, isAr),
          const SizedBox(height: AppSpacing.md),

          // Section 1: Access & Identity Management List Menu
          SettingsGroupLabel(
            isAr ? 'إدارة المستخدمين والأدوار' : 'Users & Roles Management',
          ),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.people_alt_rounded,
                iconColor: colorScheme.primary,
                title: isAr ? 'إدارة المستخدمين والحسابات' : 'User Accounts Management',
                subtitle: isAr
                    ? 'إضافة وحظر وتعديل بيانات وحسابات مستخدمي النظام'
                    : 'Manage system user accounts, credentials, and access',
                showChevron: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminUsersPage()),
                ),
              ),
              SettingsTile(
                icon: Icons.security_rounded,
                iconColor: Colors.teal,
                title: isAr ? 'إدارة أدوار النظام والصلاحيات' : 'Roles & Permissions Matrix',
                subtitle: isAr
                    ? 'تعريف الأدوار (مدير، محاسب، بائع) وتحديد مصفوفة الصلاحيات'
                    : 'Define custom user roles and assign permission capabilities',
                showChevron: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminRolesPage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 2: Structure & Environment Setup List Menu
          SettingsGroupLabel(
            isAr ? 'الفروع، الشركات والأجهزة' : 'Branches, Companies & Devices',
          ),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.store_mall_directory_outlined,
                iconColor: Colors.indigo,
                title: isAr ? 'إدارة الفروع والمواقع' : 'Branches & Outlets',
                subtitle: isAr
                    ? 'إضافة وتعديل بيانات أفرع المؤسسة وتخصيص مستودعاتها'
                    : 'Configure multi-branch infrastructure and outlets',
                showChevron: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminBranchesPage()),
                ),
              ),
              SettingsTile(
                icon: Icons.business_rounded,
                iconColor: Colors.purple,
                title: isAr ? 'إدارة الشركات والمستأجرين' : 'Companies & Tenants',
                subtitle: isAr
                    ? 'إدارة بيانات الشركات المسجلة بالنظام ومؤسسات العميل'
                    : 'Manage corporate entities and system tenants',
                showChevron: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminCompaniesPage()),
                ),
              ),
              SettingsTile(
                icon: Icons.devices_rounded,
                iconColor: Colors.amber.shade800,
                title: isAr ? 'إدارة الأجهزة والطرفيات' : 'Registered Devices & Terminals',
                subtitle: isAr
                    ? 'التحكم بالأجهزة المرخصة ونقاط البيع المعتمدة'
                    : 'Manage authorized POS terminals and mobile devices',
                showChevron: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminDevicesPage()),
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
              Icons.admin_panel_settings_rounded,
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
                  isAr ? 'مركز تهيئة وإعدادات الإدارة' : 'Administration Settings Center',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'إدارة كاملة للمستخدمين، الأدوار والصلاحيات، الفروع، الشركات والأجهزة'
                      : 'Full administrative control over users, roles, branches, companies, and devices',
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
