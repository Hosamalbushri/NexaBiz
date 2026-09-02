import 'package:flutter/material.dart';
import '../../core/modules/module_setup_definition.dart';

final inventorySetupSteps = [
  ModuleSetupStepDefinition(
    id: 'inventory_base_currency_warehouse_step',
    moduleId: 'inventory',
    titleAr: 'عملة المخزون والمستودع الافتراضي',
    titleEn: 'Inventory Base Currency & Warehouse',
    descriptionAr: 'تحديد عملة وحيدة لاحتساب تكلفة الأصناف والمستودع الرئيسي',
    descriptionEn: 'Select single base currency for inventory costing and default warehouse',
    icon: Icons.warehouse_outlined,
    sortOrder: 30,
    builder: (context, ref) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'عملة المخزون الأساسية (Single-Choice):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'تعتمد جميع حركات تقييم المخزون وتكلفة الأصناف (WAC / FIFO) على عملة وحيدة ثابتة.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    },
  ),
  ModuleSetupStepDefinition(
    id: 'inventory_costing_policy_step',
    moduleId: 'inventory',
    titleAr: 'سياسات تقييم المخزون',
    titleEn: 'Inventory Valuation Policies',
    descriptionAr: 'طريقة احتساب التكلفة وسياسة المنع عند نفاذ الرصيد',
    descriptionEn: 'Costing method (FIFO / WAC) and negative stock prevention',
    icon: Icons.inventory_2_outlined,
    sortOrder: 40,
    builder: (context, ref) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سياسة تقييم التكلفة: المتوسط المرجح (WAC)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      );
    },
  ),
];
