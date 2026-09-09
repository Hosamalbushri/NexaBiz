import 'package:flutter/material.dart' hide Card, Badge, Divider, TextField, Checkbox, Switch, AppBar, Scaffold, ListTile, Table, Dialog;
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Colors, Row, Column, Flexible, Expanded, Spacer;

/// NexaBiz ERP — Customer Creation & Edit Form Concept
/// Powered by shadcn_flutter design primitives
class NexaBizCustomerFormDesign extends StatefulWidget {
  const NexaBizCustomerFormDesign({super.key});

  @override
  State<NexaBizCustomerFormDesign> createState() => _NexaBizCustomerFormDesignState();
}

class _NexaBizCustomerFormDesignState extends State<NexaBizCustomerFormDesign> {
  final _codeCtrl = TextEditingController(text: 'CUST-1092');
  final _nameArCtrl = TextEditingController(text: 'شركة الأمل للتجارة والمقاولات');
  final _nameEnCtrl = TextEditingController(text: 'Al-Amal Trading Est.');
  final _taxNoCtrl = TextEditingController(text: '310982341200003');
  final _emailCtrl = TextEditingController(text: 'finance@alamal.com.sa');
  final _phoneCtrl = TextEditingController(text: '+966 50 123 4567');
  final _creditLimitCtrl = TextEditingController(text: '100000.00');

  String _customerGroup = 'corporate';
  bool _isActive = true;

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      OutlineButton(
                        onPressed: () {},
                        child: const Icon(Icons.arrow_back_rounded, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'بيانات حساب العميل' : 'Customer Master Data',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          const Text('CUST-1092 • Al-Amal Trading Est.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlineButton(
                        onPressed: () {},
                        child: Text(isAr ? 'إلغاء' : 'Cancel'),
                      ),
                      const SizedBox(width: 12),
                      PrimaryButton(
                        onPressed: () {},
                        leading: const Icon(Icons.save_rounded, size: 16),
                        child: Text(isAr ? 'حفظ العميل' : 'Save Customer'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Basic Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'البيانات الأساسية والتعريفية' : 'Basic Identity Information',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'رمز الحساب / الكود *' : 'Customer Code *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(controller: _codeCtrl),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'تصنيف العميل' : 'Customer Group', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                Select<String>(
                                  value: _customerGroup,
                                  onChanged: (val) {
                                    if (val != null) setState(() => _customerGroup = val);
                                  },
                                  itemBuilder: (context, item) => Text(
                                    item == 'corporate'
                                        ? (isAr ? 'شركات ومؤسسات' : 'Corporate')
                                        : item == 'retail'
                                            ? (isAr ? 'أفراد / تجزئة' : 'Retail')
                                            : (isAr ? 'كبار العملاء (VIP)' : 'VIP Key Account'),
                                  ),
                                  popup: SelectPopup.builder(
                                    builder: (context, searchQuery) => SelectItemList(
                                      children: [
                                        SelectItemButton(
                                          value: 'corporate',
                                          child: Text(isAr ? 'شركات ومؤسسات' : 'Corporate'),
                                        ),
                                        SelectItemButton(
                                          value: 'retail',
                                          child: Text(isAr ? 'أفراد / تجزئة' : 'Retail'),
                                        ),
                                        SelectItemButton(
                                          value: 'vip',
                                          child: Text(isAr ? 'كبار العملاء (VIP)' : 'VIP Key Account'),
                                        ),
                                      ],
                                    ),
                                  ).asBuilder,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'اسم العميل (بالعربية) *' : 'Customer Name (Arabic) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(controller: _nameArCtrl),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'اسم العميل (بالإنجليزية)' : 'Customer Name (English)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(controller: _nameEnCtrl),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tax & Financial Controls Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'البيانات الضريبية وضوابط الائتمان' : 'Tax & Financial Credit Controls',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'الرقم الضريبي (ZATCA VAT)' : 'ZATCA Tax ID', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(controller: _taxNoCtrl),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'الحد الائتماني المسموح (SAR)' : 'Credit Limit (SAR)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(controller: _creditLimitCtrl),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Contact Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'معلومات التواصل والعنوان' : 'Contact Details & Status',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'البريد الإلكتروني' : 'Email Address', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(controller: _emailCtrl),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'رقم الهاتف / الجوال' : 'Phone Number', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(controller: _phoneCtrl),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'حالة الحساب نشط' : 'Active Account Status',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                isAr ? 'السماح بإصدار الفواتير وسندات القبض لهذا الحساب' : 'Allow creating sales invoices and receipts',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (val) => setState(() => _isActive = val),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
