import 'package:flutter/material.dart';
import '../../core/modules/module_setup_definition.dart';

final salesSetupSteps = [
  ModuleSetupStepDefinition(
    id: 'sales_defaults_setup_step',
    moduleId: 'sales',
    titleAr: 'إعدادات وسياسات المبيعات',
    titleEn: 'Sales Defaults & Policies',
    descriptionAr: 'سياسات الأسعار، نسبة الضريبة الافتراضية، وخصومات الفواتير',
    descriptionEn: 'Default tax rate, pricing policies, and discount rules',
    icon: Icons.point_of_sale_outlined,
    sortOrder: 50,
    builder: (context, ref) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سياسات فواتير المبيعات:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'يتم ترحيل قيود المبيعات آلياً إلى الحسابات المحددة في دليل الحسابات.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    },
  ),
];
