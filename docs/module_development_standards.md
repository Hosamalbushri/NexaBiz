# معايير تطوير الموديولات والتقارير — NexaBiz Module Development Standards

هذا المستند يحدد القواعد والمعايير الصارمة الواجب اتباعها عند إنشاء **موديول جديد**، أو **إضافة تقرير جديد**، أو **إضافة إعدادات موديول** في نظام **NexaBiz**.

---

## 1. نمط التسجيل والإلغاء الذاتي للموديولات (Module Self-Registration & Self-Unregistration Pattern)

كل موديول جديد يجب أن يتبع نمط التسجيل الذاتي والإلغاء الذاتي عبر الخطوات التالية:

### الخطوات:
1. **إنشاء كلاس الموديول**: يرث من `AppModule` (`lib/core/modules/app_module.dart`).
2. **إضافة دوال التسجيل والإلغاء الذاتي**:
   ```dart
   class MyNewModule extends AppModule {
     const MyNewModule();

     static const String moduleId = 'my_new_module';

     /// Self-registers into ModuleRegistry via static injection
     static void register() {
       ModuleRegistry.register(const MyNewModule());
     }

     /// Self-unregisters from ModuleRegistry
     static void unregister() {
       ModuleRegistry.unregister(moduleId);
     }

     @override
     String get id => moduleId;
     
     @override
     String get nameKey => 'moduleMyNewModule'; // مفتاح الترجمة
     
     @override
     IconData get icon => Icons.extension_outlined;
     
     @override
     int get sortOrder => 60; // الترتيب في العرض

     @override
     List<Override> get providerOverrides => [
       myModuleProviderPort.overrideWith((ref) => MyModuleAdapter()),
     ];
   }
   ```
3. **التسجيل في المانفيست `module_bootstrap_manifest.dart`**:
   ملف `lib/app/bootstrap/module_bootstrap.dart` هو **ملف للقراءة فقط ولا يحتوي على أي تعريفات أو Overrides للموديولات**.
   لإدراج الموديول الجديد في التسجيل الذاتي عند بدء التطبيق، افتح `lib/app/bootstrap/module_bootstrap_manifest.dart` وأضف:
   ```dart
   MyNewModule.register();
   ```

---

## 2. معمارية التقارير المركزية (Centralized Reports Architecture)

> [!IMPORTANT]
> **قاعدة صارمة**: لا يجوز لأي موديول تجاري تعريف تقاريره الخاصة داخل كلاس الموديول `MyModule.reportCategories`. موديول التقارير `ReportsModule` هو **المصدر الوحيد والمركز** لجميع تعريفات التقارير.

### خطوات إضافة تقرير جديد:
1. **إنشاء واجهة التقرير ومساره**:
   - أنشئ صفحة التقرير أو عارض PDF في الموديول المعني أو داخل `lib/modules/reports/`.
   - أضف مسار التقرير في `ReportsRoutes` (`lib/modules/reports/shared/presentation/pages/reports_routes.dart`).
2. **تسجيل التقرير مركزياً في `ReportsModule`**:
   - افتح `lib/modules/reports/reports_module.dart`.
   - في دالة `reportCategories` المعرفة داخل `ReportsModule`، تحقق من وجود الموديول التجاري عبر `ModuleRegistry.isModuleRegistered('my_module')`.
   - أضف فئة التقرير وعناصره:
   ```dart
   if (ModuleRegistry.isModuleRegistered('my_module')) {
     categories.add(
       ReportCategoryDefinition(
         id: 'my_module_reports',
         moduleId: 'my_module',
         icon: Icons.analytics_outlined,
         titleBuilder: (l10n) => l10n.moduleMyModule,
         subtitleBuilder: (l10n) => l10n.moduleMyModuleDescription,
         reports: [
           ReportItemDefinition(
             id: 'reports_my_feature',
             moduleId: 'my_module',
             icon: Icons.summarize_outlined,
             path: ReportsRoutes.myFeatureReport,
             titleBuilder: (l10n) => l10n.reportsMyFeatureTitle,
             subtitleBuilder: (l10n) => l10n.reportsMyFeatureSubtitle,
           ),
         ],
       ),
     );
   }
   ```

### القواعد:
- إذا لم يكن `ReportsModule` مسجلاً أو مفعلاً → لا تظهر أي تقارير في النظام.
- إذا تم إيقاف موديول تجاري معين → تكتشف `ReportsModule` ذلك تلقائياً وتخفي تقارير ذلك الموديول فقط.
- **ترتيب عرض الموديولات وفئاتها**: يتم فرز بطاقات الموديولات وفئات التقارير تلقائياً وبشكل صارم حسب ترتيب الفرز المعرف في الموديول (`AppModule.sortOrder`).

---

## 3. معمارية إعدادات الموديولات (Module Settings Architecture)

لكل موديول الحق في تعريف فئات إعداداته الخاصة التي تظهر في شاشة إعدادات الموديولات الهرمية.

### الخطوات:
1. **تعريف فئات الإعدادات**:
   داخل ملف `my_module_settings.dart`:
   ```dart
   List<ModuleSettingsCategoryDefinition> buildMyModuleSettingsCategories(String moduleId) {
     return [
       ModuleSettingsCategoryDefinition(
         id: 'my_module_unit_settings',
         moduleId: moduleId,
         icon: Icons.settings_applications_outlined,
         titleBuilder: (l10n) => l10n.myModuleSettingsTitle,
         subtitleBuilder: (l10n) => l10n.myModuleSettingsSubtitle,
         routePath: '/my-module/settings/unit',
       ),
     ];
   }
   ```
2. **ربط الإعدادات بكلاس الموديول**:
   ```dart
   @override
   List<ModuleSettingsCategoryDefinition> get settingsCategories =>
       buildMyModuleSettingsCategories(moduleId);
   ```

---

## 4. الإجراءات السريعة والصلاحيات (Quick Actions & RBAC)

1. **الإجراءات السريعة (Quick Actions)**:
   - يتم تعريفها عبر `quickActions` وتظهر في لوحة التحكم الرئيسية تلقائياً.
2. **حزمة الصلاحيات (Permission Package)**:
   - يتم تعريف الصلاحيات في `permissionPackage` وإسناد أدوار الوصول `routeAccessRules` للتحكم بحماية المسارات.

---

## 5. قائمة التحقق قبل الاعتماد (Pre-Commit Checklist)

- [ ] الموديول يتبع نمط `Self-Registration` ويتم تسجيله في `module_bootstrap.dart`.
- [ ] لا توجد أي تعريفات تقارير داخل الموديول التجاري (`reportCategories` ترجع `[]` افتراضياً من `AppModule`).
- [ ] جميع التقارير معرّفة حصرية داخل `ReportsModule` ومربوطة بـ `ReportsRoutes`.
- [ ] جميع النصوص الثابتة معرّفة في ملفات الترجمة `app_ar.arb` و `app_en.arb`.
- [ ] تم فحص الكود باستخدام `flutter analyze lib/` وتأكيد خلوه من الأخطاء (0 Errors).
