import 'package:flutter/material.dart' hide Card, Badge, Divider, TextField, Checkbox, Switch, AppBar, Scaffold, ListTile, Table, Dialog;
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Colors, Row, Column, Flexible, Expanded, Spacer;

/// NexaBiz ERP — Product Master Catalog & Stock Status Concept
/// Powered by shadcn_flutter design primitives
class NexaBizProductListDesign extends StatefulWidget {
  const NexaBizProductListDesign({super.key});

  @override
  State<NexaBizProductListDesign> createState() => _NexaBizProductListDesignState();
}

class _NexaBizProductListDesignState extends State<NexaBizProductListDesign> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Toolbar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'دليل المنتجات والمخزون' : 'Product & Stock Catalog',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr ? 'إدارة الأصناف، فئات المنتجات، وأسعار التكلفة' : 'Manage items, product categories, and costing layers',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlineButton(
                    onPressed: () {},
                    leading: const Icon(Icons.download_rounded, size: 16),
                    child: Text(isAr ? 'تصدير اكسل' : 'Export Excel'),
                  ),
                  const SizedBox(width: 12),
                  PrimaryButton(
                    onPressed: () {},
                    leading: const Icon(Icons.add_box_rounded, size: 16),
                    child: Text(isAr ? 'إضافة صنف جديد' : 'Add New Item'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      placeholder: Text(isAr ? 'ابحث باسم الصنف، كود SKU، أو الباركوم...' : 'Search by name, SKU, or barcode...'),
                      features: const [
                        InputFeature.leading(Icon(Icons.search_rounded, size: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Select<String>(
                      value: _selectedCategory,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                      itemBuilder: (context, item) => Text(
                        item == 'all'
                            ? (isAr ? 'جميع الفئات' : 'All Categories')
                            : item == 'electronics'
                                ? (isAr ? 'إلكترونيات' : 'Electronics')
                                : (isAr ? 'مستلزمات مكتبية' : 'Office Supplies'),
                      ),
                      popup: SelectPopup.builder(
                        builder: (context, searchQuery) => SelectItemList(
                          children: [
                            SelectItemButton(
                              value: 'all',
                              child: Text(isAr ? 'جميع الفئات' : 'All Categories'),
                            ),
                            SelectItemButton(
                              value: 'electronics',
                              child: Text(isAr ? 'إلكترونيات' : 'Electronics'),
                            ),
                            SelectItemButton(
                              value: 'office',
                              child: Text(isAr ? 'مستلزمات مكتبية' : 'Office Supplies'),
                            ),
                          ],
                        ),
                      ).asBuilder,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Product List Data Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTableHeader(isAr),
                  const Divider(),
                  _buildProductRow(
                    sku: 'SKU-8019',
                    nameAr: 'طابعة ليزر صناعية متقدمة X1',
                    nameEn: 'Industrial Laser Printer X1',
                    category: isAr ? 'إلكترونيات' : 'Electronics',
                    buyPrice: 'SAR 3,200.00',
                    sellPrice: 'SAR 3,850.00',
                    stock: '14 ريم',
                    status: isAr ? 'متوفر' : 'In Stock',
                    isLowStock: false,
                  ),
                  const Divider(),
                  _buildProductRow(
                    sku: 'SKU-8021',
                    nameAr: 'ورق طباعة A4 فاخر (5 ريم)',
                    nameEn: 'Premium A4 Paper (5 Reams)',
                    category: isAr ? 'مستلزمات مكتبية' : 'Office Supplies',
                    buyPrice: 'SAR 95.00',
                    sellPrice: 'SAR 130.00',
                    stock: '2 ريم',
                    status: isAr ? 'مخزون منخفض' : 'Low Stock',
                    isLowStock: true,
                  ),
                  const Divider(),
                  _buildProductRow(
                    sku: 'SKU-8025',
                    nameAr: 'حبر طابعة أسود عالي السعة',
                    nameEn: 'High Capacity Black Ink Cartridge',
                    category: isAr ? 'إلكترونيات' : 'Electronics',
                    buyPrice: 'SAR 210.00',
                    sellPrice: 'SAR 290.00',
                    stock: '45 حبة',
                    status: isAr ? 'متوفر' : 'In Stock',
                    isLowStock: false,
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(isAr ? 'كود SKU' : 'SKU', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 3, child: Text(isAr ? 'اسم الصنف' : 'Item Name', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 2, child: Text(isAr ? 'الفئة' : 'Category', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          SizedBox(width: 120, child: Text(isAr ? 'سعر الشراء' : 'Cost Price', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          SizedBox(width: 120, child: Text(isAr ? 'سعر البيع' : 'Selling Price', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          SizedBox(width: 100, child: Text(isAr ? 'المخزون المتاح' : 'Stock Qty', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          SizedBox(width: 120, child: Text(isAr ? 'الحالة' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildProductRow({
    required String sku,
    required String nameAr,
    required String nameEn,
    required String category,
    required String buyPrice,
    required String sellPrice,
    required String stock,
    required String status,
    required bool isLowStock,
  }) {
    final isAr = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(sku, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isAr ? nameAr : nameEn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(isAr ? nameEn : nameAr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(category, style: const TextStyle(fontSize: 13))),
          SizedBox(width: 120, child: Text(buyPrice, style: const TextStyle(fontSize: 13))),
          SizedBox(width: 120, child: Text(sellPrice, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          SizedBox(width: 100, child: Text(stock, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          SizedBox(
            width: 120,
            child: isLowStock
                ? DestructiveBadge(child: Text(status))
                : SecondaryBadge(child: Text(status)),
          ),
        ],
      ),
    );
  }
}
