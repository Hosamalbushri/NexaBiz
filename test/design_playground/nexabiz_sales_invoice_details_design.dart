import 'package:flutter/material.dart' hide Card, Badge, Divider, TextField, Checkbox, Switch, AppBar, Scaffold, ListTile, Table, Dialog;
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Colors, Row, Column, Flexible, Expanded, Spacer;

/// NexaBiz ERP — Sales Invoice Details & ZATCA QR View Concept
/// Powered by shadcn_flutter design primitives
class NexaBizSalesInvoiceDetailsDesign extends StatelessWidget {
  const NexaBizSalesInvoiceDetailsDesign({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Action Toolbar
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
                            isAr ? 'فاتورة مبيعات ضريبية #INV-2026-0892' : 'Tax Sales Invoice #INV-2026-0892',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const SecondaryBadge(
                                child: Text('ZATCA Cleared (الطور الثاني)'),
                              ),
                              const SizedBox(width: 8),
                              const SecondaryBadge(
                                child: Text('مدفوعة / Paid'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlineButton(
                        onPressed: () {},
                        leading: const Icon(Icons.print_rounded, size: 16),
                        child: Text(isAr ? 'طباعة' : 'Print'),
                      ),
                      const SizedBox(width: 12),
                      PrimaryButton(
                        onPressed: () {},
                        leading: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                        child: Text(isAr ? 'تصدير PDF' : 'Export PDF'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Invoice Printable Container
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Company & ZATCA QR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'شركة نكسا بيز للحلول البرمجية' : 'NexaBiz Software Solutions Co.',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(isAr ? 'الرياض - طريق الملك فهد - المملكة العربية السعودية' : 'Riyadh, King Fahd Rd, Kingdom of Saudi Arabia', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              Text(isAr ? 'الرقم الضريبي: 310982341200003' : 'VAT Registration: 310982341200003', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(Icons.qr_code_2_rounded, size: 72),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Customer & Invoice Metadata Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isAr ? 'صادرة إلى (العميل):' : 'Billed To (Customer):', style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(isAr ? 'شركة الأمل للتجارة والمقاولات' : 'Al-Amal Trading Est.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(isAr ? 'كود الحساب: CUST-1092' : 'Customer Code: CUST-1092', style: const TextStyle(fontSize: 13)),
                              Text(isAr ? 'الرقم الضريبي: 300192837400003' : 'Customer VAT: 300192837400003', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(isAr ? 'تاريخ الإصدار: 09 سبتمبر 2026' : 'Issue Date: 09 Sep 2026', style: const TextStyle(fontSize: 13)),
                              Text(isAr ? 'تاريخ الاستحقاق: 09 أكتوبر 2026' : 'Due Date: 09 Oct 2026', style: const TextStyle(fontSize: 13)),
                              Text(isAr ? 'المستودع المصدر: الرئيسي (الرياض)' : 'Source Warehouse: Main (Riyadh)', style: const TextStyle(fontSize: 13)),
                              Text(isAr ? 'طريقة السداد: آجل (Net 30)' : 'Payment Terms: Credit (Net 30)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Items Table Header
                      _buildHeader(isAr),
                      const Divider(),
                      _buildRow('SKU-8019', 'طابعة ليزر صناعية متقدمة X1', '2', 'SAR 3,850.00', 'SAR 1,155.00', 'SAR 8,855.00'),
                      const Divider(),
                      _buildRow('SKU-8021', 'ورق طباعة A4 فاخر (5 ريم)', '10', 'SAR 130.00', 'SAR 195.00', 'SAR 1,495.00'),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Totals Summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('المبلغ الخاضع للضريبة (Subtotal): SAR 9,000.00', style: TextStyle(fontSize: 14)),
                              const SizedBox(height: 6),
                              const Text('إجمالي ضريبة القيمة المضافة (15% VAT): SAR 1,350.00', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              const SizedBox(height: 10),
                              Text(
                                isAr ? 'المبلغ الإجمالي المستحق: SAR 10,350.00' : 'Grand Total Due: SAR 10,350.00',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                              ),
                            ],
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

  Widget _buildHeader(bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(isAr ? 'الرمز' : 'SKU', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(child: Text(isAr ? 'الوصف' : 'Description', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          SizedBox(width: 60, child: Text(isAr ? 'الكمية' : 'Qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          SizedBox(width: 110, child: Text(isAr ? 'السعر' : 'Unit Price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          SizedBox(width: 110, child: Text(isAr ? 'الضريبة' : 'VAT (15%)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          SizedBox(width: 120, child: Text(isAr ? 'الإجمالي' : 'Total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildRow(String sku, String desc, String qty, String price, String vat, String total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(sku, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 14))),
          SizedBox(width: 60, child: Text(qty, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          SizedBox(width: 110, child: Text(price, style: const TextStyle(fontSize: 13))),
          SizedBox(width: 110, child: Text(vat, style: const TextStyle(fontSize: 13, color: Colors.grey))),
          SizedBox(width: 120, child: Text(total, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
        ],
      ),
    );
  }
}
