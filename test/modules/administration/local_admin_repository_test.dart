import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/administration/shared/data/local_admin_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalAuthStore authStore;
  late LocalAdminRepository adminRepo;

  setUp(() async {
    Hive.init('./test_tmp_hive_admin');
    authStore = LocalAuthStore();
    await authStore.ensureSeeded();
    adminRepo = LocalAdminRepository(authStore);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  group('LocalAdminRepository - Unit Tests', () {
    test('1. List permissions returns offline catalog permissions with Arabic descriptions', () async {
      final perms = await adminRepo.listPermissions();
      expect(perms, isNotEmpty);
      expect(perms.any((p) => p.code == 'sales.view'), isTrue);
      expect(perms.firstWhere((p) => p.code == 'sales.view').description, contains('المبيعات'));
    });

    test('2. List default system roles and create a new custom role', () async {
      final initialRoles = await adminRepo.listRoles();
      expect(initialRoles.length, greaterThanOrEqualTo(6));
      expect(initialRoles.any((r) => r.name == 'Admin'), isTrue);

      final newRole = await adminRepo.createRole(
        name: 'Custom Auditor',
        description: 'مدقق مالي مخصص',
        permissionCodes: ['accounting.view', 'reports.view'],
      );

      expect(newRole.id, isNotEmpty);
      expect(newRole.name, equals('Custom Auditor'));
      expect(newRole.permissionCount, equals(2));

      final updatedRoles = await adminRepo.listRoles();
      expect(updatedRoles.any((r) => r.id == newRole.id), isTrue);
    });

    test('3. Create and update users locally without server dependencies', () async {
      final createdUser = await adminRepo.createUser(
        name: 'أحمد المحاسب',
        email: 'ahmed@nexabiz.local',
        password: 'Password123!',
        phone: '0500000000',
        roleId: 'Accountant',
      );

      expect(createdUser.id, isNotEmpty);
      expect(createdUser.name, equals('أحمد المحاسب'));
      expect(createdUser.email, equals('ahmed@nexabiz.local'));

      final users = await adminRepo.listUsers();
      expect(users.any((u) => u.id == createdUser.id), isTrue);

      final updatedUser = await adminRepo.updateUser(
        userId: createdUser.id,
        name: 'أحمد علي المحاسب',
        status: 'active',
      );
      expect(updatedUser.name, equals('أحمد علي المحاسب'));
    });

    test('4. Company management locally', () async {
      final company = await adminRepo.createCompany(
        name: 'شركة الأمل التجاري',
        taxNumber: '300123456700003',
        status: 'active',
      );

      expect(company.id, isNotEmpty);
      expect(company.name, equals('شركة الأمل التجاري'));

      final companies = await adminRepo.listCompanies();
      expect(companies.any((c) => c.id == company.id), isTrue);
    });
  });
}
