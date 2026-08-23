import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/sync/conflict_strategy.dart';
import 'package:stock_count/core/sync/three_way_merger.dart';

void main() {
  group('ThreeWayMerger Master Data Tests', () {
    const merger = ThreeWayMerger();

    test('non-overlapping fields auto-merge cleanly for customer', () {
      final base = {
        'uuid': 'cust-1',
        'name': 'Original Name',
        'phone': '111111111',
        'email': 'old@test.com',
      };

      // Device A changed name
      final local = {
        'uuid': 'cust-1',
        'name': 'Updated Name A',
        'phone': '111111111',
        'email': 'old@test.com',
      };

      // Device B changed phone and email
      final remote = {
        'uuid': 'cust-1',
        'name': 'Original Name',
        'phone': '999999999',
        'email': 'new@test.com',
      };

      final policy = EntityConflictPolicy.getForEntity('customer');
      final result = merger.merge(
        basePayload: base,
        localPayload: local,
        remotePayload: remote,
        policy: policy,
      );

      expect(result.isSuccess, isTrue);
      expect(result.mergeStatus, 'auto_merged');
      expect(result.mergedPayload?['name'], 'Updated Name A');
      expect(result.mergedPayload?['phone'], '999999999');
      expect(result.mergedPayload?['email'], 'new@test.com');
      expect(result.conflictingFields, isEmpty);
    });

    test('overlapping field edits produce explicit conflict with conflictingFields', () {
      final base = {
        'uuid': 'cust-1',
        'name': 'Original Name',
        'phone': '111111111',
      };

      final local = {
        'uuid': 'cust-1',
        'name': 'Name From Device A',
        'phone': '111111111',
      };

      final remote = {
        'uuid': 'cust-1',
        'name': 'Name From Device B',
        'phone': '111111111',
      };

      final policy = EntityConflictPolicy.getForEntity('customer');
      final result = merger.merge(
        basePayload: base,
        localPayload: local,
        remotePayload: remote,
        policy: policy,
      );

      expect(result.isSuccess, isFalse);
      expect(result.mergeStatus, 'requires_user_resolution');
      expect(result.conflictingFields, contains('name'));
    });

    test('never-merge fields (e.g. balance) flag conflict when differing', () {
      final base = {
        'uuid': 'cust-1',
        'name': 'Original Name',
        'balance': 100.0,
      };

      final local = {
        'uuid': 'cust-1',
        'name': 'Original Name',
        'balance': 150.0,
      };

      final remote = {
        'uuid': 'cust-1',
        'name': 'Original Name',
        'balance': 200.0,
      };

      final policy = EntityConflictPolicy.getForEntity('customer');
      final result = merger.merge(
        basePayload: base,
        localPayload: local,
        remotePayload: remote,
        policy: policy,
      );

      expect(result.isSuccess, isFalse);
      expect(result.conflictingFields, contains('balance'));
    });

    test('immutable entity strategy (journal_entry) immediately rejects merge', () {
      final base = {'uuid': 'j-1', 'isPosted': true};
      final local = {'uuid': 'j-1', 'isPosted': true, 'voucherNumber': 'J-1'};
      final remote = {'uuid': 'j-1', 'isPosted': true, 'voucherNumber': 'J-2'};

      final policy = EntityConflictPolicy.getForEntity('journal_entry');
      final result = merger.merge(
        basePayload: base,
        localPayload: local,
        remotePayload: remote,
        policy: policy,
      );

      expect(result.isSuccess, isFalse);
      expect(result.mergeStatus, 'rejected');
    });
  });
}
