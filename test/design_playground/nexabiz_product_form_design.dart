import 'package:flutter/material.dart' hide Card, Badge, Divider, TextField, Checkbox, Switch, AppBar, Scaffold, ListTile, Table, Dialog;
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Colors, Row, Column, Flexible, Expanded, Spacer;

/// NexaBiz ERP — Product Item Creation & Edit Form Concept
/// Powered by shadcn_flutter design primitives
class NexaBizProductFormDesign extends StatefulWidget {
  const NexaBizProductFormDesign({super.key});

  @override
  State<NexaBizProductFormDesign> createState() => _NexaBizProductFormDesignState();
}

class _NexaBizProductFormDesignState extends State<NexaBizProductFormDesign> {
  final _skuCtrl = TextEditingController(text: 'SKU-8019');
  final _barcodeCtrl = TextEditingController(text: '628110098123');
  final _nameArCtrl = TextEditingController(text: 'طابعة ليزر صناعية متقدمة X1');
  final _nameEnCtrl = TextEditingController(text: 'Industrial Laser Printer X1');
  final _costCtrl = TextEditingController(text: '2400.00');
  final _priceCtrl = TextEditingController(text: '3850.00');
  final _minStockCtrl = TextEditingController(text: '5');

  String _category = 'electronics';
  String _unit = 'pcs';
  bool _trackInventory = true;

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
                            isAr ? 'تعديل بيانات الصنف' : 'Edit Product Master',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          const Text('SKU-8019 • Industrial Laser Printer X1', style: TextStyle(color: Colors.grey)),
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
                        leading: const Icon(Icons.check_circle_rounded, size: 16),
                        child: Text(isAr ? 'حفظ الصنف' : 'Save Product'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Item Basics Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'أكواد وبيانات الصنف الرئيسية' : 'Primary Product Identifiers',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'رمز الصنف (SKU) *' : 'Stock SKU Code *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(controller: _skuCtrl),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'الباركود الدولي' : 'Barcode / EAN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(controller: _barcodeCtrl),
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
                                Text(isAr ? 'اسم الصنف (بالعربية) *' : 'Product Name (Arabic) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                                Text(isAr ? 'اسم الصنف (بالإنجليزية)' : 'Product Name (English)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

              // Pricing & Category Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'التصنيفات وهيكلة الأسعار' : 'Category & Cost Structure',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'التصنيف الرئيسي' : 'Category', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                Select<String>(
                                  value: _category,
                                  onChanged: (val) {
                                    if (val != null) setState(() => _category = val);
                                  },
                                  itemBuilder: (context, item) => Text(
                                    item == 'electronics'
                                        ? (isAr ? 'إلكترونيات' : 'Electronics')
                                        : item == 'supplies'
                                            ? (isAr ? 'مستلزمات مكتبية' : 'Office Supplies')
                                            : (isAr ? 'مواد استهلاكية' : 'Consumables'),
                                  ),
                                  popup: SelectPopup.builder(
                                    builder: (context, searchQuery) => SelectItemList(
                                      children: [
                                        SelectItemButton(
                                          value: 'electronics',
                                          child: Text(isAr ? 'إلكترونيات' : 'Electronics'),
                                        ),
                                        SelectItemButton(
                                          value: 'supplies',
                                          child: Text(isAr ? 'مستلزمات مكتبية' : 'Office Supplies'),
                                        ),
                                        SelectItemButton(
                                          value: 'consumables',
                                          child: Text(isAr ? 'مواد استهلاكية' : 'Consumables'),
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
                                Text(isAr ? 'وحدة القياس الرئيسية' : 'Unit of Measurement', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                Select<String>(
                                  value: _unit,
                                  onChanged: (val) {
                                    if (val != null) setState(() => _unit = val);
                                  },
                                  itemBuilder: (context, item) => Text(
                                    item == 'pcs' ? 'Pieces (حبة)' : item == 'box' ? 'Box (كرتون)' : 'Kilogram (كجم)',
                                  ),
                                  popup: SelectPopup.builder(
                                    builder: (context, searchQuery) => SelectItemList(
                                      children: const [
                                        SelectItemButton(
                                          value: 'pcs',
                                          child: Text('Pieces (حبة)'),
                                        ),
                                        SelectItemButton(
                                          value: 'box',
                                          child: Text('Box (كرتون)'),
                                        ),
                                        SelectItemButton(
                                          value: 'kg',
                                          child: Text('Kilogram (كجم)'),
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
                                Text(isAr ? 'تكلفة الشراء (SAR)' : 'Cost Price (SAR)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(controller: _costCtrl),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'سعر البيع الأساسي (SAR)' : 'Selling Price (SAR)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(controller: _priceCtrl),
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

              // Inventory Controls Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'إعدادات التحكم بالحركة والمخزون' : 'Inventory Tracking Policy',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'تتبع الكميات وحركة المخزن' : 'Enable Stock Tracking',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                isAr ? 'يحتسب الرصيد وحركات التوريد والصرف تلقائياً' : 'Automatically track stock receipts & issues',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          Switch(
                            value: _trackInventory,
                            onChanged: (val) => setState(() => _trackInventory = val),
                          ),
                        ],
                      ),
                      if (_trackInventory) ...[
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isAr ? 'حد إعادة الطلب الأدنى' : 'Minimum Reorder Threshold', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(controller: _minStockCtrl),
                          ],
                        ),
                      ],
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
