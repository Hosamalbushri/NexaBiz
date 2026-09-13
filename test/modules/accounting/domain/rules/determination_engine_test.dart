import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/modules/accounting/domain/rules/determination_condition.dart';
import 'package:stock_count/modules/accounting/domain/rules/determination_context.dart';
import 'package:stock_count/modules/accounting/domain/rules/determination_engine_impl.dart';
import 'package:stock_count/modules/accounting/domain/rules/determination_exceptions.dart';
import 'package:stock_count/modules/accounting/domain/rules/determination_rule.dart';
import 'package:stock_count/modules/accounting/domain/rules/specificity_vector.dart';

void main() {
  late DeterminationEngine engine;
  late DateTime now;
  late DeterminationContext context;

  setUp(() {
    engine = const DeterminationEngine();
    now = DateTime(2026, 9, 13);
    context = DeterminationContext(
      companyId: 'company_001',
      transactionDate: now,
      warehouseId: 'wh_main',
      productId: 'prod_99',
      customerId: 'cust_44',
    );
  });

  group('DeterminationEngine Specificity Hierarchy Tests', () {
    test('Product-level rule beats company-level default rule', () async {
      final rules = [
        DeterminationRule(
          uuid: 'rule_company_default',
          companyId: 'company_001',
          role: AccountRole.revenue,
          condition: const DeterminationCondition(companyId: 'company_001'),
          targetAccountUuid: 'acc_company_revenue',
          priority: 0,
        ),
        DeterminationRule(
          uuid: 'rule_product_specific',
          companyId: 'company_001',
          role: AccountRole.revenue,
          condition: const DeterminationCondition(
            companyId: 'company_001',
            productId: 'prod_99',
          ),
          targetAccountUuid: 'acc_product_revenue',
          priority: 0,
        ),
      ];

      final resolved = await engine.resolveAccountUuid(
        role: AccountRole.revenue,
        context: context,
        activeRules: rules,
      );

      expect(resolved, equals('acc_product_revenue'));
    });

    test('Higher explicit priority wins when specificity vectors match', () async {
      final rules = [
        DeterminationRule(
          uuid: 'rule_prio_10',
          companyId: 'company_001',
          role: AccountRole.revenue,
          condition: const DeterminationCondition(
            companyId: 'company_001',
            warehouseId: 'wh_main',
          ),
          targetAccountUuid: 'acc_wh_prio_10',
          priority: 10,
        ),
        DeterminationRule(
          uuid: 'rule_prio_20',
          companyId: 'company_001',
          role: AccountRole.revenue,
          condition: const DeterminationCondition(
            companyId: 'company_001',
            warehouseId: 'wh_main',
          ),
          targetAccountUuid: 'acc_wh_prio_20',
          priority: 20,
        ),
      ];

      final resolved = await engine.resolveAccountUuid(
        role: AccountRole.revenue,
        context: context,
        activeRules: rules,
      );

      expect(resolved, equals('acc_wh_prio_20'));
    });
  });

  group('DeterminationEngine Failure Case Tests', () {
    test('Throws UnmappedDeterminationException when 0 rules match', () async {
      final rules = <DeterminationRule>[];

      expect(
        () => engine.resolveAccountUuid(
          role: AccountRole.revenue,
          context: context,
          activeRules: rules,
        ),
        throwsA(isA<UnmappedDeterminationException>()),
      );
    });

    test('Throws AmbiguousDeterminationException when top candidates have equal specificity and priority', () async {
      final rules = [
        DeterminationRule(
          uuid: 'rule_ambig_a',
          companyId: 'company_001',
          role: AccountRole.revenue,
          condition: const DeterminationCondition(
            companyId: 'company_001',
            warehouseId: 'wh_main',
          ),
          targetAccountUuid: 'acc_revenue_a',
          priority: 5,
        ),
        DeterminationRule(
          uuid: 'rule_ambig_b',
          companyId: 'company_001',
          role: AccountRole.revenue,
          condition: const DeterminationCondition(
            companyId: 'company_001',
            warehouseId: 'wh_main',
          ),
          targetAccountUuid: 'acc_revenue_b',
          priority: 5,
        ),
      ];

      expect(
        () => engine.resolveAccountUuid(
          role: AccountRole.revenue,
          context: context,
          activeRules: rules,
        ),
        throwsA(isA<AmbiguousDeterminationException>()),
      );
    });

    test('Ignores disabled or out-of-date-range rules', () async {
      final rules = [
        DeterminationRule(
          uuid: 'rule_disabled',
          companyId: 'company_001',
          role: AccountRole.revenue,
          condition: const DeterminationCondition(
            companyId: 'company_001',
            productId: 'prod_99',
          ),
          targetAccountUuid: 'acc_disabled',
          isEnabled: false,
        ),
        DeterminationRule(
          uuid: 'rule_expired',
          companyId: 'company_001',
          role: AccountRole.revenue,
          condition: const DeterminationCondition(
            companyId: 'company_001',
            productId: 'prod_99',
          ),
          targetAccountUuid: 'acc_expired',
          effectiveTo: now.subtract(const Duration(days: 1)),
        ),
        DeterminationRule(
          uuid: 'rule_valid_fallback',
          companyId: 'company_001',
          role: AccountRole.revenue,
          condition: const DeterminationCondition(companyId: 'company_001'),
          targetAccountUuid: 'acc_valid_fallback',
        ),
      ];

      final resolved = await engine.resolveAccountUuid(
        role: AccountRole.revenue,
        context: context,
        activeRules: rules,
      );

      expect(resolved, equals('acc_valid_fallback'));
    });
  });
}
