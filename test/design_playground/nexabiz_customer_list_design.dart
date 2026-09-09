import 'package:flutter/material.dart' hide Card, Badge, Divider, TextField, Checkbox, Switch, AppBar, Scaffold, ListTile, Table, Dialog;
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Colors, Row, Column, Flexible, Expanded, Spacer;

/// NexaBiz ERP — Customer Directory & Management Concept
/// Powered by shadcn_flutter design primitives
class NexaBizCustomerListDesign extends StatefulWidget {
  const NexaBizCustomerListDesign({super.key});

  @override
  State<NexaBizCustomerListDesign> createState() => _NexaBizCustomerListDesignState();
}

class _NexaBizCustomerListDesignState extends State<NexaBizCustomerListDesign> {
  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'دليل العملاء والشركاء' : 'Customer Directory',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr
                        ? 'إدارة حسابات العملاء، الأرصدة، والحدود الائتمانية'
                        : 'Manage customer master records, balances, and credit policies',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              PrimaryButton(
                onPressed: () {},
                leading: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                child: Text(isAr ? 'إضافة عميل جديد' : 'Add New Customer'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters and Search Bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      placeholder: Text(
                        isAr
                            ? 'ابحث باسم العميل، الكود، الرقم الضريبي، أو رقم الهاتف...'
                            : 'Search customer name, code, tax ID, or phone...',
                      ),
                      features: const [
                        InputFeature.leading(
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(Icons.search_rounded, size: 18, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlineButton(
                    onPressed: () {},
                    leading: const Icon(Icons.filter_list_rounded, size: 16),
                    child: Text(isAr ? 'تصفية حسب التصنيف' : 'Filter'),
                  ),
                  const SizedBox(width: 12),
                  OutlineButton(
                    onPressed: () {},
                    leading: const Icon(Icons.file_download_rounded, size: 16),
                    child: Text(isAr ? 'تصدير' : 'Export'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Customer Table Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildTableHeader(isAr),
                  const Divider(),
                  _buildCustomerRow(
                    code: 'CUST-1092',
                    name: isAr ? 'شركة الأمل للتجارة والمقاولات' : 'Al-Amal Trading Est.',
                    group: isAr ? 'شركات ومؤسسات' : 'Corporate',
                    balance: 'SAR 42,500.00',
                    creditLimit: 'SAR 100,000.00',
                    phone: '+966 50 123 4567',
                    isActive: true,
                    isAr: isAr,
                  ),
                  const Divider(),
                  _buildCustomerRow(
                    code: 'CUST-1091',
                    name: isAr ? 'مؤسسة التقنية الحديثة' : 'Modern Tech Est.',
                    group: isAr ? 'شركات ومؤسسات' : 'Corporate',
                    balance: 'SAR 0.00',
                    creditLimit: 'SAR 50,000.00',
                    phone: '+966 55 987 6543',
                    isActive: true,
                    isAr: isAr,
                  ),
                  const Divider(),
                  _buildCustomerRow(
                    code: 'CUST-1090',
                    name: isAr ? 'شركة الرياد المتقدمة المحدودة' : 'Riyad Advanced Ltd.',
                    group: isAr ? 'كبار العملاء (VIP)' : 'VIP Key Account',
                    balance: 'SAR 128,400.00',
                    creditLimit: 'SAR 150,000.00',
                    phone: '+966 54 111 2233',
                    isActive: true,
                    isAr: isAr,
                  ),
                  const Divider(),
                  _buildCustomerRow(
                    code: 'CUST-1089',
                    name: isAr ? 'مستودع الشرق الأوسط اللوجستي' : 'Middle East Logistics',
                    group: isAr ? 'شركات ومؤسسات' : 'Corporate',
                    balance: 'SAR 8,920.00',
                    creditLimit: 'SAR 30,000.00',
                    phone: '+966 56 444 5566',
                    isActive: false,
                    isAr: isAr,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(isAr ? 'كود الحساب' : 'Code', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 3, child: Text(isAr ? 'اسم العميل' : 'Customer Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text(isAr ? 'التصنيف' : 'Group', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text(isAr ? 'الرصيد الحالي' : 'Current Balance', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text(isAr ? 'الحد الائتماني' : 'Credit Limit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          SizedBox(width: 100, child: Text(isAr ? 'الحالة' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildCustomerRow({
    required String code,
    required String name,
    required String group,
    required String balance,
    required String creditLimit,
    required String phone,
    required bool isActive,
    required bool isAr,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(group, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(balance, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(creditLimit, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          SizedBox(
            width: 100,
            child: isActive
                ? SecondaryBadge(child: Text(isAr ? 'نشط' : 'Active'))
                : DestructiveBadge(child: Text(isAr ? 'موقوف' : 'Inactive')),
          ),
          SizedBox(
            width: 60,
            child: GhostButton(
              onPressed: () {},
              child: const Icon(Icons.more_horiz_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
