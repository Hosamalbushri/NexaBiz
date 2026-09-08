import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/custom_app_bar.dart';

/// Purchases Management Dashboard & Home Page
class PurchasesHomePage extends ConsumerWidget {
  const PurchasesHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'إدارة المشتريات والموردين',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'إعدادات المشتريات',
            onPressed: () => context.push('/purchases/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.people_alt_outlined, color: Colors.indigo),
                title: const Text('دليل الموردين (Suppliers)'),
                subtitle: const Text('إدارة بيانات الموردين وأرصدتهم والحسابات المربوطة'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to suppliers catalog
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.receipt_long_outlined, color: Colors.teal),
                title: const Text('فواتير المشتريات (Purchase Invoices)'),
                subtitle: const Text('إنشاء واستعراض فواتير المشتريات وترحيل قيود المخزون'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to purchase invoices list
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined, color: Colors.orange),
                title: const Text('إشعارات الاستلام والمخزون (Goods Receipts)'),
                subtitle: const Text('متابعة الشحنات المستلمة ومطابقة أوامر الشراء'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to receiving notes
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.tune_outlined, color: Colors.blueGrey),
                title: const Text('إعدادات المشتريات (Purchases Settings)'),
                subtitle: const Text('ربط الحسابات المحاسبية وإعدادات موديول المشتريات'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push('/purchases/settings'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Open create purchase invoice form
        },
        icon: const Icon(Icons.add),
        label: const Text('فاتورة مشتريات جديدة'),
      ),
    );
  }
}

