// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/database/hive_boxes.dart';
import '../../domain/entities/account_binding.dart';
import '../../domain/repositories/account_binding_repository.dart';

/// Durable, Hive-backed implementation of [AccountBindingRepository].
///
/// Guarantees:
/// 1. Cold Restart Preservation: Account bindings survive application restarts.
/// 2. Multi-Tenant Scoping: Keys are strictly scoped by [companyId].
/// 3. Idempotency: Overwrites existing bindings without duplicating keys.
class HiveAccountBindingRepository implements AccountBindingRepository {
  HiveAccountBindingRepository({
    Box<dynamic>? box,
  }) : _box = box;

  Box<dynamic>? _box;

  Future<Box<dynamic>> get _initBox async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox<dynamic>(HiveBoxes.settings);
    return _box!;
  }

  String _buildKey(String companyId, String packageId, String requirementKey) {
    return 'account_binding_${companyId.trim()}_${packageId.trim()}_${requirementKey.trim()}';
  }

  @override
  Future<AccountBinding?> getBinding({
    required String companyId,
    required String packageId,
    required String requirementKey,
  }) async {
    final key = _buildKey(companyId, packageId, requirementKey);
    final box = await _initBox;
    final raw = box.get(key);

    if (raw == null) return null;

    if (raw is Map) {
      return AccountBinding.fromJson(Map<String, dynamic>.from(raw));
    }

    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return AccountBinding.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }

    return null;
  }

  @override
  Future<List<AccountBinding>> getBindingsForPackage({
    required String companyId,
    required String packageId,
  }) async {
    final box = await _initBox;
    final prefix = 'account_binding_${companyId.trim()}_${packageId.trim()}_';

    final result = <AccountBinding>[];
    for (final key in box.keys) {
      if (key is String && key.startsWith(prefix)) {
        final raw = box.get(key);
        if (raw is Map) {
          result.add(AccountBinding.fromJson(Map<String, dynamic>.from(raw)));
        } else if (raw is String && raw.isNotEmpty) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is Map) {
              result.add(AccountBinding.fromJson(Map<String, dynamic>.from(decoded)));
            }
          } catch (_) {}
        }
      }
    }

    return List.unmodifiable(result);
  }

  @override
  Future<void> saveBinding(AccountBinding binding) async {
    final key = _buildKey(binding.companyId, binding.packageId, binding.requirementKey);
    final box = await _initBox;
    await box.put(key, binding.toJson());
  }

  @override
  Future<void> removeBinding({
    required String companyId,
    required String packageId,
    required String requirementKey,
  }) async {
    final key = _buildKey(companyId, packageId, requirementKey);
    final box = await _initBox;
    await box.delete(key);
  }

  @override
  Future<void> clear() async {
    final box = await _initBox;
    final keysToRemove = box.keys
        .whereType<String>()
        .where((k) => k.startsWith('account_binding_'))
        .toList();
    for (final key in keysToRemove) {
      await box.delete(key);
    }
  }
}
