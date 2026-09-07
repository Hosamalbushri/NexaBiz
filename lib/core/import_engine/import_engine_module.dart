import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../modules/app_module.dart';
import '../modules/module_registry.dart';
import '../modules/module_settings_definition.dart';
import 'presentation/pages/import_job_details_page.dart';
import 'presentation/pages/import_jobs_list_page.dart';
import 'presentation/pages/import_profiles_overview_page.dart';
import 'presentation/pages/universal_import_page.dart';
import 'presentation/providers/import_ui_providers.dart';
import 'presentation/routes/import_engine_routes.dart';

/// Import Engine Module definition — self-registers into NexaBiz ModuleRegistry.
class ImportEngineModule extends AppModule {
  const ImportEngineModule();

  static const String moduleId = 'import_engine';

  /// Self-registers ImportEngineModule into global ModuleRegistry.
  static void register() {
    ModuleRegistry.register(const ImportEngineModule());
  }

  /// Self-unregisters ImportEngineModule.
  static void unregister() {
    ModuleRegistry.unregister(moduleId);
  }

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleImportEngine';

  @override
  IconData get icon => Icons.system_update_alt_rounded;

  @override
  String get rootRoute => ImportEngineRoutes.root;

  @override
  int get sortOrder => 85;

  @override
  bool get isEnabled => true;

  @override
  bool get showInLauncher => false; // Accessed via Settings -> Unit Settings & direct route

  @override
  String label(BuildContext context) {
    return 'محرك الاستيراد العام | Import Engine';
  }

  @override
  String? description(BuildContext context) {
    return 'نظام الاستيراد العام الموحد للبيانات والمحاسبة والمنتجات';
  }

  @override
  List<ModuleSettingsCategoryDefinition> get settingsCategories => [
    ModuleSettingsCategoryDefinition(
      id: 'import_engine_settings_cat',
      moduleId: moduleId,
      icon: Icons.system_update_alt_rounded,
      titleBuilder: (l10n) => 'محرك الاستيراد العام | Import Engine',
      subtitleBuilder: (l10n) =>
          'إعدادات الاستيراد التكيفي وملفات البيانات وتتبع وظائف الخلفية',
      items: [
        ModuleSettingsItemDefinition(
          id: 'import_engine_universal_console',
          moduleId: moduleId,
          icon: Icons.upload_file_rounded,
          path: ImportEngineRoutes.universal,
          titleBuilder: (l10n) =>
              'منصة الاستيراد الموحدة | Universal Import Console',
          subtitleBuilder: (l10n) =>
              'استيراد دليل الحسابات والمنتجات والبيانات خطوة بخطوة',
        ),
        ModuleSettingsItemDefinition(
          id: 'import_engine_jobs_monitor',
          moduleId: moduleId,
          icon: Icons.history_rounded,
          path: ImportEngineRoutes.jobs,
          titleBuilder: (l10n) =>
              'سجل ومتابعة الوظائف | Background Jobs Monitor',
          subtitleBuilder: (l10n) =>
              'متابعة وظائف الاستيراد في الخلفية ونسب الإنجاز والأخطاء',
        ),
        ModuleSettingsItemDefinition(
          id: 'import_engine_profiles_registry',
          moduleId: moduleId,
          icon: Icons.manage_search_rounded,
          path: ImportProfilesOverviewPage.routePath,
          titleBuilder: (l10n) =>
              'ملفات الاستيراد المسجلة | Registered Profiles',
          subtitleBuilder: (l10n) =>
              'استعراض هيكل البيانات والمطابقة لكل نوع استيراد',
        ),
      ],
    ),
  ];

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: ImportEngineRoutes.universal,
      name: 'universalImport',
      builder: (context, state) {
        final initialProfileId = state.uri.queryParameters['profileId'];
        return UniversalImportPage(initialProfileId: initialProfileId);
      },
    ),
    GoRoute(
      path: ImportEngineRoutes.root,
      name: 'importEngineRoot',
      redirect: (context, state) => ImportEngineRoutes.universal,
      routes: [
        GoRoute(
          path: 'jobs',
          name: 'importEngineJobs',
          builder: (context, state) {
            return Consumer(
              builder: (context, ref, child) {
                final companyId = ref
                    .watch(importJobRepositoryProvider)
                    .toString();
                return ImportJobsListPage(companyId: companyId);
              },
            );
          },
          routes: [
            GoRoute(
              path: ':id',
              name: 'importEngineJobDetails',
              builder: (context, state) {
                final jobId = state.pathParameters['id'] ?? '';
                final repo = refReadJobRepo(context);
                return FutureBuilder(
                  future: repo.findById(jobId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final job = snapshot.data;
                    if (job == null) {
                      return const Scaffold(
                        body: Center(child: Text('الوظيفة غير موجودة')),
                      );
                    }
                    return ImportJobDetailsPage(job: job as dynamic);
                  },
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'profiles',
          name: 'importEngineProfiles',
          builder: (context, state) => const ImportProfilesOverviewPage(),
        ),
      ],
    ),
  ];

  static dynamic refReadJobRepo(BuildContext context) {
    return ProviderScope.containerOf(
      context,
      listen: false,
    ).read(importJobRepositoryProvider);
  }
}
