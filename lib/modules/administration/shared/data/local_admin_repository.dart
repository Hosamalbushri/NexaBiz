import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/database/encrypted_hive_box.dart';
import '../../../../core/database/hive_boxes.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../authentication/data/local_auth_store.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_api_repository.dart';

/// Offline / Local implementation of [AdminRepository] backed by [LocalAuthStore] and Hive storage.
/// Allows Users, Companies, Roles, Branches, and Permissions to be managed locally without network dependencies.
class LocalAdminRepository implements AdminRepository {
  LocalAdminRepository(this._store);

  final LocalAuthStore _store;

  static const String _adminExtBoxName = HiveBoxes.localAuthEncrypted;
  static const String _rolesKey = 'admin_custom_roles';
  static const String _branchesKey = 'admin_branches';
  static const String _devicesKey = 'admin_devices';
  static const String _companySettingsKey = 'admin_company_settings';
  static const String _moduleSettingsKey = 'admin_module_settings';

  Future<Box<dynamic>> _box() async {
    if (Hive.isBoxOpen(_adminExtBoxName)) {
      return Hive.box<dynamic>(_adminExtBoxName);
    }
    return EncryptedHive.openMigrated<dynamic>(
      encryptedBoxName: _adminExtBoxName,
      legacyPlainBoxName: HiveBoxes.localAuth,
    );
  }

  // ==========================================
  // USERS & MEMBERSHIPS
  // ==========================================

  @override
  Future<List<AdminUserSummary>> listUsers() async {
    await _store.ensureSeeded();
    final box = await _box();
    final rawUsers = box.get('users');
    if (rawUsers is! List) return const [];

    final list = <AdminUserSummary>[];
    for (final item in rawUsers) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        list.add(
          AdminUserSummary(
            id: m['id'] as String? ?? '',
            name: m['name'] as String? ?? '',
            email: m['email'] as String? ?? '',
            phone: m['phone'] as String?,
            status: m['status'] as String? ?? 'active',
            isSuperAdmin: m['isSuperAdmin'] == true,
          ),
        );
      }
    }
    return list;
  }

  @override
  Future<AdminUserSummary> createUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    String status = 'active',
    String? roleId,
    String? companyId,
  }) async {
    final box = await _box();
    final rawUsers = box.get('users');
    final users = rawUsers is List ? List<dynamic>.from(rawUsers) : <dynamic>[];

    final userId = generateUuidV4();
    final salt = generateUuidV4();
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();

    final newUserMap = {
      'id': userId,
      'name': cleanName,
      'email': cleanEmail,
      'phone': phone?.trim(),
      'passwordSalt': salt,
      'passwordHash': LocalAuthStore.hashPassword(password, salt),
      'status': status,
      'isSuperAdmin': false,
      'mustChangePassword': false,
      'companyIds': companyId != null ? [companyId] : <String>[],
      'rolesByCompany': companyId != null && roleId != null
          ? {companyId: roleId}
          : <String, String>{},
      'permissionsByCompany': <String, List<String>>{},
    };

    users.add(newUserMap);
    await box.put('users', users);

    if (companyId != null && companyId.isNotEmpty) {
      await assignUserToCompany(
        userId: userId,
        companyId: companyId,
        roleId: roleId,
        status: status,
      );
    }

    return AdminUserSummary(
      id: userId,
      name: cleanName,
      email: cleanEmail,
      phone: phone,
      status: status,
      isSuperAdmin: false,
    );
  }

  @override
  Future<AdminUserSummary> updateUser({
    required String userId,
    String? name,
    String? phone,
    String? status,
    String? password,
  }) async {
    final box = await _box();
    final rawUsers = box.get('users');
    if (rawUsers is! List) throw Exception('المستخدم غير موجود محلياً');

    var foundIndex = -1;
    Map<String, dynamic>? targetUserMap;

    for (var i = 0; i < rawUsers.length; i++) {
      if (rawUsers[i] is Map) {
        final m = Map<String, dynamic>.from(rawUsers[i] as Map);
        if (m['id'] == userId) {
          foundIndex = i;
          targetUserMap = m;
          break;
        }
      }
    }

    if (foundIndex == -1 || targetUserMap == null) {
      throw Exception('المستخدم غير موجود محلياً');
    }

    if (name != null && name.trim().isNotEmpty) {
      targetUserMap['name'] = name.trim();
    }
    if (phone != null) {
      targetUserMap['phone'] = phone.trim();
    }
    if (status != null) {
      targetUserMap['status'] = status;
    }
    if (password != null && password.trim().isNotEmpty) {
      final salt = generateUuidV4();
      targetUserMap['passwordSalt'] = salt;
      targetUserMap['passwordHash'] = LocalAuthStore.hashPassword(
        password,
        salt,
      );
    }

    final updatedList = List<dynamic>.from(rawUsers);
    updatedList[foundIndex] = targetUserMap;
    await box.put('users', updatedList);

    return AdminUserSummary(
      id: userId,
      name: targetUserMap['name'] as String? ?? '',
      email: targetUserMap['email'] as String? ?? '',
      phone: targetUserMap['phone'] as String?,
      status: targetUserMap['status'] as String? ?? 'active',
      isSuperAdmin: targetUserMap['isSuperAdmin'] == true,
    );
  }

  @override
  Future<void> setUserStatus({
    required String userId,
    required String status,
  }) async {
    await updateUser(userId: userId, status: status);
  }

  @override
  Future<void> deactivateUser(String userId) async {
    await setUserStatus(userId: userId, status: 'inactive');
  }

  @override
  Future<List<UserCompanyMembership>> listUserCompanyMemberships(
    String userId,
  ) async {
    final box = await _box();
    final raw = box.get('memberships');
    if (raw is! List) return const [];

    final list = <UserCompanyMembership>[];
    for (final item in raw) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        if (m['user_id'] == userId || m['userId'] == userId) {
          list.add(
            UserCompanyMembership(
              id: m['id'] as String? ?? generateUuidV4(),
              userId: userId,
              companyId: (m['company_id'] ?? m['companyId']) as String? ?? '',
              companyName: m['company_name'] as String?,
              roleId: (m['role_id'] ?? m['role']) as String?,
              roleName: (m['role_name'] ?? m['role']) as String?,
              status: m['status'] as String? ?? 'active',
            ),
          );
        }
      }
    }
    return list;
  }

  @override
  Future<UserCompanyMembership> assignUserToCompany({
    required String userId,
    required String companyId,
    String? roleId,
    String status = 'active',
  }) async {
    final box = await _box();
    final raw = box.get('memberships');
    final memberships = raw is List ? List<dynamic>.from(raw) : <dynamic>[];

    final newMem = {
      'id': generateUuidV4(),
      'user_id': userId,
      'company_id': companyId,
      'role_id': roleId ?? 'Member',
      'role_name': roleId ?? 'Member',
      'status': status,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    memberships.add(newMem);
    await box.put('memberships', memberships);

    return UserCompanyMembership(
      id: newMem['id'] as String,
      userId: userId,
      companyId: companyId,
      roleId: roleId,
      roleName: roleId,
      status: status,
    );
  }

  @override
  Future<void> removeUserFromCompany({
    required String userId,
    required String companyId,
  }) async {
    final box = await _box();
    final raw = box.get('memberships');
    if (raw is! List) return;

    final updated = raw.where((item) {
      if (item is Map) {
        final uid = item['user_id'] ?? item['userId'];
        final cid = item['company_id'] ?? item['companyId'];
        return !(uid == userId && cid == companyId);
      }
      return true;
    }).toList();

    await box.put('memberships', updated);
  }

  @override
  Future<void> setUserCompanyMembershipStatus({
    required String userId,
    required String companyId,
    required String status,
  }) async {
    final box = await _box();
    final raw = box.get('memberships');
    if (raw is! List) return;

    final updated = raw.map((item) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        final uid = m['user_id'] ?? m['userId'];
        final cid = m['company_id'] ?? m['companyId'];
        if (uid == userId && cid == companyId) {
          m['status'] = status;
        }
        return m;
      }
      return item;
    }).toList();

    await box.put('memberships', updated);
  }

  // ==========================================
  // ROLES & PERMISSIONS
  // ==========================================

  static final List<String> kAllLocalPermissionsList = kAllLocalPermissions
      .toList();

  static final List<AdminRoleSummary> _defaultSystemRoles = [
    AdminRoleSummary(
      id: 'Owner',
      name: 'Owner',
      description: 'مالك الشركة - جميع الصلاحيات',
      systemRole: true,
      permissions: kAllLocalPermissionsList,
      permissionCount: kAllLocalPermissionsList.length,
    ),
    AdminRoleSummary(
      id: 'Admin',
      name: 'Admin',
      description: 'مدير النظام - صلاحيات إدارية وتنفيذية كاملة',
      systemRole: true,
      permissions: kAllLocalPermissionsList,
      permissionCount: kAllLocalPermissionsList.length,
    ),
    AdminRoleSummary(
      id: 'Manager',
      name: 'Manager',
      description: 'مدير عام - إشراف وتشغيل كامل للعمليات',
      systemRole: true,
      permissions: kAllLocalPermissionsList,
      permissionCount: kAllLocalPermissionsList.length,
    ),
    const AdminRoleSummary(
      id: 'Accountant',
      name: 'Accountant',
      description: 'محاسب - إدارة الحسابات والقيود والتقارير المالية',
      systemRole: true,
      permissions: [
        'accounting.view',
        'accounting.accounts.manage',
        'accounting.entries.create',
        'accounting.entries.post',
        'accounting.reports.view',
        'reports.view',
        'receipts_payments.view',
        'receipts_payments.create',
      ],
      permissionCount: 8,
    ),
    const AdminRoleSummary(
      id: 'SalesManager',
      name: 'SalesManager',
      description: 'مسؤول مبيعات - إدخال فواتير المبيعات والعملاء',
      systemRole: true,
      permissions: [
        'sales.view',
        'sales.invoices.create',
        'sales.invoices.edit',
        'customers.view',
        'customers.create',
        'reports.view',
      ],
      permissionCount: 6,
    ),
    const AdminRoleSummary(
      id: 'InventoryManager',
      name: 'InventoryManager',
      description:
          'مسؤول مخزن - متابعة المستودعات وتنسيق المنتجات وحركات الصنف',
      systemRole: true,
      permissions: [
        'inventory.view',
        'inventory.products.create',
        'inventory.products.edit',
        'inventory.movements.create',
        'inventory.stocktake.create',
        'reports.view',
      ],
      permissionCount: 6,
    ),
  ];

  @override
  Future<List<AdminRoleSummary>> listRoles() async {
    final box = await _box();
    final rawCustom = box.get(_rolesKey);
    final customRoles = <AdminRoleSummary>[];

    if (rawCustom is List) {
      for (final item in rawCustom) {
        if (item is Map) {
          customRoles.add(
            AdminRoleSummary.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return [..._defaultSystemRoles, ...customRoles];
  }

  @override
  Future<AdminRoleSummary> getRole(String roleId) async {
    final roles = await listRoles();
    for (final r in roles) {
      if (r.id == roleId || r.name.toLowerCase() == roleId.toLowerCase()) {
        return r;
      }
    }
    return AdminRoleSummary(
      id: roleId,
      name: roleId,
      description: 'دور مخصص',
      systemRole: false,
      permissions: kAllLocalPermissionsList,
      permissionCount: kAllLocalPermissionsList.length,
    );
  }

  @override
  Future<AdminRoleSummary> createRole({
    required String name,
    String? description,
    required List<String> permissionCodes,
  }) async {
    final box = await _box();
    final rawCustom = box.get(_rolesKey);
    final customList = rawCustom is List
        ? List<dynamic>.from(rawCustom)
        : <dynamic>[];

    final roleId = generateUuidV4();
    final newRoleMap = {
      'id': roleId,
      'name': name.trim(),
      'description': description?.trim(),
      'system_role': false,
      'permissions': permissionCodes,
      'permission_count': permissionCodes.length,
    };

    customList.add(newRoleMap);
    await box.put(_rolesKey, customList);

    return AdminRoleSummary.fromJson(newRoleMap);
  }

  @override
  Future<AdminRoleSummary> updateRole({
    required String roleId,
    String? name,
    String? description,
    List<String>? permissionCodes,
  }) async {
    final box = await _box();
    final rawCustom = box.get(_rolesKey);
    if (rawCustom is! List) throw Exception('الدور غير موجود محلياً');

    final customList = List<dynamic>.from(rawCustom);
    var targetIndex = -1;
    Map<String, dynamic>? targetMap;

    for (var i = 0; i < customList.length; i++) {
      if (customList[i] is Map) {
        final m = Map<String, dynamic>.from(customList[i] as Map);
        if (m['id'] == roleId) {
          targetIndex = i;
          targetMap = m;
          break;
        }
      }
    }

    if (targetIndex == -1 || targetMap == null) {
      throw Exception('لا يمكن تعديل أدوار النظام المحمية');
    }

    if (name != null) targetMap['name'] = name.trim();
    if (description != null) targetMap['description'] = description.trim();
    if (permissionCodes != null) {
      targetMap['permissions'] = permissionCodes;
      targetMap['permission_count'] = permissionCodes.length;
    }

    customList[targetIndex] = targetMap;
    await box.put(_rolesKey, customList);

    return AdminRoleSummary.fromJson(targetMap);
  }

  @override
  Future<void> deleteRole(String roleId) async {
    final box = await _box();
    final rawCustom = box.get(_rolesKey);
    if (rawCustom is! List) return;

    final updated = rawCustom.where((item) {
      if (item is Map) {
        return item['id'] != roleId;
      }
      return true;
    }).toList();

    await box.put(_rolesKey, updated);
  }

  @override
  Future<void> assignRoleToUser({
    required String userId,
    required String roleId,
  }) async {
    // Role assignments are bound per company in user record / memberships.
  }

  @override
  Future<void> removeRoleFromUser({
    required String userId,
    required String roleId,
  }) async {
    // Role removal bound per company.
  }

  @override
  Future<List<AdminPermissionInfo>> listPermissions() async {
    return [
      for (final code in kAllLocalPermissions)
        AdminPermissionInfo(
          code: code,
          description: _getPermissionArabicDescription(code),
        ),
    ];
  }

  @override
  Future<List<String>> listPermissionCodes() async {
    return kAllLocalPermissionsList;
  }

  String _getPermissionArabicDescription(String code) {
    return switch (code) {
      'sales.view' => 'عرض المبيعات وفواتير العملاء',
      'sales.invoices.create' => 'إنشاء فواتير مبيعات جديدة',
      'sales.invoices.edit' => 'تعديل فواتير المبيعات الحالية',
      'sales.invoices.delete' => 'حذف فواتير المبيعات',
      'inventory.view' => 'استعراض المستودعات والأصناف والمخزون',
      'inventory.products.create' => 'إضافة أصناف ومنتجات جديدة',
      'inventory.products.edit' => 'تعديل بيانات المنتجات',
      'inventory.movements.create' => 'إجراء حركات تحويل واستلام وصرف مخزني',
      'inventory.stocktake.create' => 'إجراء عمليات الجرد وتكلفة البضاعة',
      'accounting.view' => 'استعراض الحسابات والقيود والتقارير المالية',
      'accounting.accounts.manage' => 'إدارة وإنشاء شجرة الحسابات',
      'accounting.entries.create' => 'إدخال القيود اليومية',
      'accounting.entries.post' => 'ترحيل القيود اليومية والحسابات',
      'accounting.reports.view' => 'استعراض التقارير والقوائم المالية',
      'customers.view' => 'استعراض دليل العملاء والحسابات',
      'customers.create' => 'إضافة عملاء جدد',
      'customers.edit' => 'تعديل بيانات العملاء',
      'receipts_payments.view' => 'استعراض سندات القبض والصرف',
      'receipts_payments.create' => 'إنشاء سندات قبض وصرف',
      'administration.view' => 'استعراض لوحة الإدارة والإعدادات',
      'administration.users.manage' => 'إدارة المستخدمين والصلاحيات والشركات',
      'administration.companies.manage' => 'إدارة الشركات والفروع والتراخيص',
      'reports.view' => 'استعراض تقارير النظام العامة',
      _ => 'صلاحية $code',
    };
  }

  // ==========================================
  // COMPANIES & BRANCHES
  // ==========================================

  @override
  Future<List<AdminCompanySummary>> listCompanies() async {
    final box = await _box();
    final raw = box.get('companies');
    if (raw is! List) return const [];

    final list = <AdminCompanySummary>[];
    for (final item in raw) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        list.add(
          AdminCompanySummary(
            id: m['id'] as String? ?? '',
            name: m['name'] as String? ?? '',
            legalName: m['legal_name'] as String? ?? m['legalName'] as String?,
            taxNumber: m['tax_number'] as String? ?? m['taxNumber'] as String?,
            phone: m['phone'] as String?,
            email: m['email'] as String?,
            address: m['address'] as String?,
            status: m['status'] as String? ?? 'active',
            createdAt: DateTime.tryParse(m['created_at'] as String? ?? ''),
          ),
        );
      }
    }
    return list;
  }

  @override
  Future<AdminCompanySummary> getCompany(String companyId) async {
    final companies = await listCompanies();
    for (final c in companies) {
      if (c.id == companyId) return c;
    }
    throw Exception('الشركة غير موجودة محلياً');
  }

  @override
  Future<AdminCompanySummary> createCompany({
    required String name,
    String? legalName,
    String? taxNumber,
    String? phone,
    String? email,
    String? address,
    String status = 'active',
  }) async {
    final box = await _box();
    final raw = box.get('companies');
    final companies = raw is List ? List<dynamic>.from(raw) : <dynamic>[];

    final companyId = generateUuidV4();
    final companyCode = 'COMP_${companies.length + 1}';

    final newCompanyMap = {
      'id': companyId,
      'name': name.trim(),
      'code': companyCode,
      'legal_name': legalName?.trim(),
      'tax_number': taxNumber?.trim(),
      'phone': phone?.trim(),
      'email': email?.trim(),
      'address': address?.trim(),
      'status': status,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    companies.add(newCompanyMap);
    await box.put('companies', companies);

    return AdminCompanySummary(
      id: companyId,
      name: name.trim(),
      legalName: legalName,
      taxNumber: taxNumber,
      phone: phone,
      email: email,
      address: address,
      status: status,
      createdAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<AdminCompanySummary> updateCompany({
    required String companyId,
    String? name,
    String? legalName,
    String? taxNumber,
    String? phone,
    String? email,
    String? address,
    String? status,
  }) async {
    final box = await _box();
    final raw = box.get('companies');
    if (raw is! List) throw Exception('الشركة غير موجودة');

    final companies = List<dynamic>.from(raw);
    var index = -1;
    Map<String, dynamic>? target;

    for (var i = 0; i < companies.length; i++) {
      if (companies[i] is Map) {
        final m = Map<String, dynamic>.from(companies[i] as Map);
        if (m['id'] == companyId) {
          index = i;
          target = m;
          break;
        }
      }
    }

    if (index == -1 || target == null) throw Exception('الشركة غير موجودة');

    if (name != null) target['name'] = name.trim();
    if (legalName != null) target['legal_name'] = legalName.trim();
    if (taxNumber != null) target['tax_number'] = taxNumber.trim();
    if (phone != null) target['phone'] = phone.trim();
    if (email != null) target['email'] = email.trim();
    if (address != null) target['address'] = address.trim();
    if (status != null) target['status'] = status;

    companies[index] = target;
    await box.put('companies', companies);

    return AdminCompanySummary.fromJson(target);
  }

  @override
  Future<void> setCompanyStatus({
    required String companyId,
    required String status,
  }) async {
    await updateCompany(companyId: companyId, status: status);
  }

  @override
  Future<List<AdminBranchSummary>> listBranches() async {
    final box = await _box();
    final raw = box.get(_branchesKey);
    if (raw is! List) return const [];

    final list = <AdminBranchSummary>[];
    for (final item in raw) {
      if (item is Map) {
        list.add(AdminBranchSummary.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return list;
  }

  @override
  Future<AdminBranchSummary> getBranch(String branchId) async {
    final branches = await listBranches();
    for (final b in branches) {
      if (b.id == branchId) return b;
    }
    throw Exception('الفرع غير موجود محلياً');
  }

  @override
  Future<AdminBranchSummary> createBranch({
    required String name,
    String? parentBranchId,
    String? code,
    String? phone,
    String? email,
    String? address,
    String status = 'active',
    List<String> assignedUserIds = const [],
  }) async {
    final box = await _box();
    final raw = box.get(_branchesKey);
    final branches = raw is List ? List<dynamic>.from(raw) : <dynamic>[];

    final session = await _store.loadSession();
    final companyId = session?.currentCompanyId;
    if (companyId == null || companyId.trim().isEmpty) {
      throw StateError(
          'Active company scope context is required to create a branch.');
    }

    final branchId = generateUuidV4();
    final newBranchMap = {
      'id': branchId,
      'company_id': companyId,
      'name': name.trim(),
      'parent_branch_id': parentBranchId,
      'code': code?.trim(),
      'phone': phone?.trim(),
      'email': email?.trim(),
      'address': address?.trim(),
      'status': status,
      'assigned_user_ids': assignedUserIds,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    branches.add(newBranchMap);
    await box.put(_branchesKey, branches);

    return AdminBranchSummary.fromJson(newBranchMap);
  }

  @override
  Future<AdminBranchSummary> updateBranch({
    required String branchId,
    String? name,
    String? parentBranchId,
    String? code,
    String? phone,
    String? email,
    String? address,
    String? status,
    List<String>? assignedUserIds,
  }) async {
    final box = await _box();
    final raw = box.get(_branchesKey);
    if (raw is! List) throw Exception('الفرع غير موجود');

    final branches = List<dynamic>.from(raw);
    var index = -1;
    Map<String, dynamic>? target;

    for (var i = 0; i < branches.length; i++) {
      if (branches[i] is Map) {
        final m = Map<String, dynamic>.from(branches[i] as Map);
        if (m['id'] == branchId) {
          index = i;
          target = m;
          break;
        }
      }
    }

    if (index == -1 || target == null) throw Exception('الفرع غير موجود');

    if (name != null) target['name'] = name.trim();
    if (parentBranchId != null) target['parent_branch_id'] = parentBranchId;
    if (code != null) target['code'] = code.trim();
    if (phone != null) target['phone'] = phone.trim();
    if (email != null) target['email'] = email.trim();
    if (address != null) target['address'] = address.trim();
    if (status != null) target['status'] = status;
    if (assignedUserIds != null) target['assigned_user_ids'] = assignedUserIds;

    branches[index] = target;
    await box.put(_branchesKey, branches);

    return AdminBranchSummary.fromJson(target);
  }

  @override
  Future<void> setBranchStatus({
    required String branchId,
    required String status,
  }) async {
    await updateBranch(branchId: branchId, status: status);
  }

  @override
  Future<void> assignUserToBranch({
    required String branchId,
    required String userId,
  }) async {
    final branch = await getBranch(branchId);
    final users = Set<String>.from(branch.assignedUserIds)..add(userId);
    await updateBranch(branchId: branchId, assignedUserIds: users.toList());
  }

  @override
  Future<void> removeUserFromBranch({
    required String branchId,
    required String userId,
  }) async {
    final branch = await getBranch(branchId);
    final users = Set<String>.from(branch.assignedUserIds)..remove(userId);
    await updateBranch(branchId: branchId, assignedUserIds: users.toList());
  }

  // ==========================================
  // DEVICES & SETTINGS
  // ==========================================

  @override
  Future<List<AdminDeviceSummary>> listDevices() async {
    final box = await _box();
    final raw = box.get(_devicesKey);
    if (raw is! List) return const [];

    final list = <AdminDeviceSummary>[];
    for (final item in raw) {
      if (item is Map) {
        list.add(AdminDeviceSummary.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return list;
  }

  @override
  Future<void> revokeDevice(String deviceId) async {
    final box = await _box();
    final raw = box.get(_devicesKey);
    if (raw is! List) return;

    final updated = raw.map((item) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        if (m['id'] == deviceId) {
          m['status'] = 'revoked';
          m['revoked_at'] = DateTime.now().toUtc().toIso8601String();
        }
        return m;
      }
      return item;
    }).toList();

    await box.put(_devicesKey, updated);
  }

  @override
  Future<SyncDisableRequestSummary> requestSyncDisable() async {
    return const SyncDisableRequestSummary(
      id: 'local_req',
      deviceId: 'local_device',
      status: 'pending',
    );
  }

  @override
  Future<List<SyncDisableRequestSummary>> listSyncDisableRequests({
    String status = 'pending',
  }) async {
    return const [];
  }

  @override
  Future<void> approveSyncDisableRequest(String requestId) async {}

  @override
  Future<void> rejectSyncDisableRequest(String requestId) async {}

  @override
  Future<Map<String, dynamic>> getCompanySettings() async {
    final box = await _box();
    final raw = box.get(_companySettingsKey);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  @override
  Future<void> updateCompanySettings(Map<String, dynamic> settings) async {
    final box = await _box();
    final existing = await getCompanySettings();
    final merged = {...existing, ...settings};
    await box.put(_companySettingsKey, jsonEncode(merged));
  }

  @override
  Future<Map<String, dynamic>> getModuleSettings(String moduleId) async {
    final box = await _box();
    final raw = box.get('${_moduleSettingsKey}_$moduleId');
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  @override
  Future<void> updateModuleSettings(
    String moduleId,
    Map<String, dynamic> settings,
  ) async {
    final box = await _box();
    final existing = await getModuleSettings(moduleId);
    final merged = {...existing, ...settings};
    await box.put('${_moduleSettingsKey}_$moduleId', jsonEncode(merged));
  }
}
