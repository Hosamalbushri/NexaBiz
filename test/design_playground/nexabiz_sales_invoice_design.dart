import 'package:flutter/material.dart' hide Card, Badge, Divider, TextField, Checkbox, Switch, AppBar, Scaffold, ListTile, Table, Dialog;
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Colors, Row, Column, Flexible, Expanded, Spacer;

/// NexaBiz ERP — Sales Invoice Entry & Line Item Calculation Concept
/// Powered by shadcn_flutter design primitives
class NexaBizSalesInvoiceDesign extends StatefulWidget {
  const NexaBizSalesInvoiceDesign({super.key});

  @override
  State<NexaBizSalesInvoiceDesign> createState() => _NexaBizSalesInvoiceDesignState();
}

class _NexaBizSalesInvoiceDesignState extends State<NexaBizSalesInvoiceDesign> {
  final _invNoCtrl = TextEditingController(text: 'INV-2026-0892');
  final _dateCtrl = TextEditingController(text: '2026-09-09');
  final _poNoCtrl = TextEditingController(text: 'PO-99120');

  String _customer = 'alamal';
  String _warehouse = 'main_wh';
  String _paymentTerms = 'net30';

  final List<Map<String, dynamic>> _lineItems = [
    {
      'sku': 'SKU-8019',
      'name': 'طابعة ليزر صناعية متقدمة X1',
      'qty': 2,
      'price': 3850.00,
      'vatRate': 0.15,
    },
    {
      'sku': 'SKU-8021',
      'name': 'ورق طباعة A4 فاخر (5 ريم)',
      'qty': 10,
      'price': 130.00,
      'vatRate': 0.15,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;

    double subtotal = 0.0;
    for (var item in _lineItems) {
      subtotal += (item['qty'] as int) * (item['price'] as double);
    }
    double vatTotal = subtotal * 0.15;
    double grandTotal = subtotal + vatTotal;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
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
                            isAr ? 'إنشاء فاتورة مبيعات ضريبية' : 'Create Tax Sales Invoice',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          const Text('ZATCA Phase 2 E-Invoicing Compliant', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlineButton(
                        onPressed: () {},
                        child: Text(isAr ? 'حفظ مسودة' : 'Save Draft'),
                      ),
                      const SizedBox(width: 12),
                      PrimaryButton(
                        onPressed: () {},
                        leading: const Icon(Icons.send_rounded, size: 16),
                        child: Text(isAr ? 'ترحيل واعتماد الفاتورة' : 'Post & Issue Invoice'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Invoice Metadata Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'بيانات الفاتورة والعميل' : 'Invoice Metadata & Customer',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'العميل *' : 'Customer Account *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                Select<String>(
                                  value: _customer,
                                  onChanged: (val) {
                                    if (val != null) setState(() => _customer = val);
                                  },
                                  itemBuilder: (context, item) => Text(
                                    item == 'alamal'
                                        ? (isAr ? 'شركة الأمل للتجارة (CUST-1092)' : 'Al-Amal Trading Est.')
                                        : (isAr ? 'مؤسسة التقنية الحديثة (CUST-1091)' : 'Modern Tech Est.'),
                                  ),
                                  popup: SelectPopup.builder(
                                    builder: (context, searchQuery) => SelectItemList(
                                      children: [
                                        SelectItemButton(
                                          value: 'alamal',
                                          child: Text(isAr ? 'شركة الأمل للتجارة (CUST-1092)' : 'Al-Amal Trading Est.'),
                                        ),
                                        SelectItemButton(
                                          value: 'modern_tech',
                                          child: Text(isAr ? 'مؤسسة التقنية الحديثة (CUST-1091)' : 'Modern Tech Est.'),
                                        ),
                                      ],
                                    ),
                                  ).asBuilder,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'المستودع المصدر *' : 'Source Warehouse *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                Select<String>(
                                  value: _warehouse,
                                  onChanged: (val) {
                                    if (val != null) setState(() => _warehouse = val);
                                  },
                                  itemBuilder: (context, item) => Text(
                                    item == 'main_wh'
                                        ? (isAr ? 'المستودع الرئيسي - الرياض' : 'Main Wh - Riyadh')
                                        : (isAr ? 'مستودع جدة' : 'Jeddah Branch Wh'),
                                  ),
                                  popup: SelectPopup.builder(
                                    builder: (context, searchQuery) => SelectItemList(
                                      children: [
                                        SelectItemButton(
                                          value: 'main_wh',
                                          child: Text(isAr ? 'المستودع الرئيسي - الرياض' : 'Main Wh - Riyadh'),
                                        ),
                                        SelectItemButton(
                                          value: 'jeddah_wh',
                                          child: Text(isAr ? 'مستودع جدة' : 'Jeddah Branch Wh'),
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
                                Text(isAr ? 'رقم الفاتورة' : 'Invoice No.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(controller: _invNoCtrl),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'تاريخ الإصدار' : 'Issue Date', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(controller: _dateCtrl),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'أمر الشراء Reference' : 'PO Reference', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(controller: _poNoCtrl),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'شروط السداد' : 'Payment Terms', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                Select<String>(
                                  value: _paymentTerms,
                                  onChanged: (val) {
                                    if (val != null) setState(() => _paymentTerms = val);
                                  },
                                  itemBuilder: (context, item) => Text(
                                    item == 'cash'
                                        ? (isAr ? 'نقداً / كاش' : 'Cash')
                                        : item == 'net30'
                                            ? (isAr ? 'آجل 30 يوم' : 'Net 30 Days')
                                            : (isAr ? 'آجل 60 يوم' : 'Net 60 Days'),
                                  ),
                                  popup: SelectPopup.builder(
                                    builder: (context, searchQuery) => SelectItemList(
                                      children: [
                                        SelectItemButton(
                                          value: 'cash',
                                          child: Text(isAr ? 'نقداً / كاش' : 'Cash'),
                                        ),
                                        SelectItemButton(
                                          value: 'net30',
                                          child: Text(isAr ? 'آجل 30 يوم' : 'Net 30 Days'),
                                        ),
                                        SelectItemButton(
                                          value: 'net60',
                                          child: Text(isAr ? 'آجل 60 يوم' : 'Net 60 Days'),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Line Items Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAr ? 'بنود الفاتورة والكميات' : 'Invoice Line Items',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          OutlineButton(
                            onPressed: () {},
                            leading: const Icon(Icons.add_rounded, size: 16),
                            child: Text(isAr ? 'إضافة بند' : 'Add Line Item'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLineItemsHeader(isAr),
                      const Divider(),
                      for (int i = 0; i < _lineItems.length; i++) ...[
                        _buildLineItemRow(_lineItems[i], isAr),
                        const Divider(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SecondaryBadge(
                            child: Text('ZATCA Tax Invoice Rules Applied'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAr ? 'ضريبة القيمة المضافة 15% محتسبة تلقائياً' : 'Standard 15% VAT calculated automatically',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildSummaryRow(isAr ? 'المبلغ الخاضع للضريبة:' : 'Subtotal Excl. VAT:', 'SAR ${subtotal.toStringAsFixed(2)}'),
                          const SizedBox(height: 6),
                          _buildSummaryRow(isAr ? 'ضريبة القيمة المضافة (15%):' : 'VAT Amount (15%):', 'SAR ${vatTotal.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            isAr ? 'إجمالي الفاتورة المستحق:' : 'Grand Total Payable:',
                            'SAR ${grandTotal.toStringAsFixed(2)}',
                            isBold: true,
                            color: const Color(0xFF10B981),
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

  Widget _buildLineItemsHeader(bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(isAr ? 'رمز الصنف' : 'SKU', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 3, child: Text(isAr ? 'وصف الصنف' : 'Product Description', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          SizedBox(width: 80, child: Text(isAr ? 'الكمية' : 'Qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          SizedBox(width: 120, child: Text(isAr ? 'السعر الفردي' : 'Unit Price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          SizedBox(width: 100, child: Text(isAr ? 'الضريبة (15%)' : 'VAT (15%)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          SizedBox(width: 130, child: Text(isAr ? 'الإجمالي الشامل' : 'Total Incl. VAT', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildLineItemRow(Map<String, dynamic> item, bool isAr) {
    int qty = item['qty'] as int;
    double price = item['price'] as double;
    double sub = qty * price;
    double vat = sub * 0.15;
    double total = sub + vat;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(item['sku'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 3, child: Text(item['name'] as String, style: const TextStyle(fontSize: 14))),
          SizedBox(width: 80, child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          SizedBox(width: 120, child: Text('SAR ${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13))),
          SizedBox(width: 100, child: Text('SAR ${vat.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Colors.grey))),
          SizedBox(width: 130, child: Text('SAR ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          SizedBox(
            width: 40,
            child: GhostButton(
              onPressed: () {},
              child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 15 : 13)),
        const SizedBox(width: 16),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
            color: color,
          ),
        ),
      ],
    );
  }
}
