import 'package:flutter/material.dart' hide Card, Badge, Divider, TextField, Checkbox, Switch, AppBar, Scaffold, Table, Dialog, ThemeData;
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Colors, Row, Column, Flexible, Expanded, Spacer;

import 'nexabiz_customer_form_design.dart';
import 'nexabiz_customer_list_design.dart';
import 'nexabiz_dashboard_design.dart';
import 'nexabiz_product_form_design.dart';
import 'nexabiz_product_list_design.dart';
import 'nexabiz_sales_invoice_design.dart';
import 'nexabiz_sales_invoice_details_design.dart';

void main() {
  runApp(const NexaBizDesignPlaygroundApp());
}

class NexaBizDesignPlaygroundApp extends StatelessWidget {
  const NexaBizDesignPlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: 'NexaBiz ERP — UI Design Playground (shadcn_flutter_genui)',
      theme: ThemeData(
        colorScheme: LegacyColorSchemes.darkZinc(),
        radius: 0.5,
      ),
      home: const NexaBizPlaygroundShell(),
    );
  }
}

class NexaBizPlaygroundShell extends StatefulWidget {
  const NexaBizPlaygroundShell({super.key});

  @override
  State<NexaBizPlaygroundShell> createState() => _NexaBizPlaygroundShellState();
}

class _NexaBizPlaygroundShellState extends State<NexaBizPlaygroundShell> {
  int _selectedScreenIndex = 0;
  bool _isRtl = true;

  final List<Map<String, dynamic>> _screens = [
    {
      'titleAr': 'لوحة التحكم القيادية',
      'titleEn': 'Executive Dashboard',
      'icon': Icons.dashboard_rounded,
      'widget': const NexaBizMobileDashboardDesign(),
    },
    {
      'titleAr': 'قائمة العملاء',
      'titleEn': 'Customer List',
      'icon': Icons.people_alt_rounded,
      'widget': const NexaBizCustomerListDesign(),
    },
    {
      'titleAr': 'نموذج إدخال العميل',
      'titleEn': 'Customer Form',
      'icon': Icons.person_add_rounded,
      'widget': const NexaBizCustomerFormDesign(),
    },
    {
      'titleAr': 'دليل المنتجات والمخزون',
      'titleEn': 'Product Catalog',
      'icon': Icons.inventory_2_rounded,
      'widget': const NexaBizProductListDesign(),
    },
    {
      'titleAr': 'نموذج الصنف',
      'titleEn': 'Product Form',
      'icon': Icons.add_box_rounded,
      'widget': const NexaBizProductFormDesign(),
    },
    {
      'titleAr': 'إنشاء فاتورة مبيعات',
      'titleEn': 'Sales Invoice Form',
      'icon': Icons.receipt_long_rounded,
      'widget': const NexaBizSalesInvoiceDesign(),
    },
    {
      'titleAr': 'تفاصيل الفاتورة والقيد',
      'titleEn': 'Sales Invoice Details',
      'icon': Icons.description_rounded,
      'widget': const NexaBizSalesInvoiceDetailsDesign(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeScreen = _screens[_selectedScreenIndex];

    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        headers: [
          AppBar(
            title: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                Text(
                  _isRtl ? 'NexaBiz ERP — معرض التصاميم المبتكرة (GenUI)' : 'NexaBiz ERP — GenUI Design Playground',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 16),
                const SecondaryBadge(
                  child: Text('DESIGN ONLY • Isolated Playground'),
                ),
              ],
            ),
            trailing: [
              OutlineButton(
                onPressed: () => setState(() => _isRtl = !_isRtl),
                child: Text(_isRtl ? 'LTR / English' : 'RTL / العربية'),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
        child: Row(
          children: [
            // Sidebar Navigation
            Container(
              width: 260,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey.shade800)),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                itemCount: _screens.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 4),
                itemBuilder: (ctx, i) {
                  final sc = _screens[i];
                  final isSelected = i == _selectedScreenIndex;

                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: Icon(sc['icon'] as IconData, size: 18, color: isSelected ? Colors.amber : Colors.grey),
                        title: Text(
                          _isRtl ? sc['titleAr'] : sc['titleEn'],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        onTap: () => setState(() => _selectedScreenIndex = i),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Active Screen Viewing Stage
            Expanded(
              child: activeScreen['widget'] as Widget,
            ),
          ],
        ),
      ),
    );
  }
}
