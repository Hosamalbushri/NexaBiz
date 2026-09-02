import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/inventory/products/presentation/providers/product_providers.dart';

import '../../domain/entities/stock_transfer.dart';
import '../providers/stock_transfer_providers.dart';
import '../providers/warehouse_providers.dart';

class _TransferItemRow {
  _TransferItemRow({
    required this.itemCode,
    required this.itemName,
    required this.quantity,
    required this.unitCost,
  });

  String itemCode;
  String itemName;
  double quantity;
  double unitCost;

  double get totalCost => quantity * unitCost;
}

class StockTransferFormPage extends ConsumerStatefulWidget {
  const StockTransferFormPage({super.key});

  @override
  ConsumerState<StockTransferFormPage> createState() => _StockTransferFormPageState();
}

class _StockTransferFormPageState extends ConsumerState<StockTransferFormPage> {
  late String _transferNumber;
  final DateTime _transferDate = DateTime.now();
  String? _fromWarehouseId;
  String? _toWarehouseId;
  final _notesCtrl = TextEditingController();

  final List<_TransferItemRow> _lines = [];

  @override
  void initState() {
    super.initState();
    _transferNumber = 'TRF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final warehousesAsync = ref.watch(warehousesListStreamProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.localeName == 'ar' ? 'إنشاء أمر تحويل مخزني' : 'Create Stock Transfer',
        showBackButton: true,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.localeName == 'ar' ? 'إجمالي التكلفة المحولة' : 'Total Transferred Cost',
                    style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    _totalTransferredCost().toStringAsFixed(2),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: _saveTransfer,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(l10n.localeName == 'ar' ? 'حفظ أمر التحويل' : 'Save Transfer'),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.localeName == 'ar' ? 'رقم أمر التحويل' : 'Transfer No'}: $_transferNumber',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  warehousesAsync.when(
                    data: (warehouses) {
                      return Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _fromWarehouseId,
                            decoration: InputDecoration(
                              labelText: l10n.localeName == 'ar' ? 'المستودع المصدر (من)' : 'Source Warehouse (From)',
                              prefixIcon: const Icon(Icons.outbox_rounded),
                            ),
                            items: warehouses.map((wh) {
                              return DropdownMenuItem(
                                value: wh.id,
                                child: Text('${wh.name} (${wh.code})'),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _fromWarehouseId = val),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DropdownButtonFormField<String>(
                            initialValue: _toWarehouseId,
                            decoration: InputDecoration(
                              labelText: l10n.localeName == 'ar' ? 'المستودع الهدف (إلى)' : 'Target Warehouse (To)',
                              prefixIcon: const Icon(Icons.move_to_inbox_rounded),
                            ),
                            items: warehouses.map((wh) {
                              return DropdownMenuItem(
                                value: wh.id,
                                child: Text('${wh.name} (${wh.code})'),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _toWarehouseId = val),
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, _) => Text(l10n.localeName == 'ar' ? 'خطأ في تحميل المستودعات' : 'Error loading warehouses'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.localeName == 'ar' ? 'الأصناف المحولة' : 'Transferred Items',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              OutlinedButton.icon(
                onPressed: () => _openAddItemDialog(context, productsAsync),
                icon: const Icon(Icons.add),
                label: Text(l10n.localeName == 'ar' ? 'إضافة صنف' : 'Add Item'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_lines.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.localeName == 'ar' ? 'لم يتم إضافة أي أصناف بعد. انقر على إضافة صنف.' : 'No items added yet. Click Add Item.',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            ..._lines.asMap().entries.map((entry) {
              final idx = entry.key;
              final line = entry.value;
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                color: colorScheme.surfaceContainerLow,
                child: ListTile(
                  title: Text(line.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${l10n.localeName == 'ar' ? 'الكود' : 'Code'}: ${line.itemCode} • ${l10n.localeName == 'ar' ? 'الكمية' : 'Qty'}: ${line.quantity}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        line.totalCost.toStringAsFixed(2),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => setState(() => _lines.removeAt(idx)),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  double _totalTransferredCost() {
    return _lines.fold(0.0, (sum, line) => sum + line.totalCost);
  }

  void _openAddItemDialog(BuildContext context, AsyncValue productsAsync) {
    productsAsync.whenData((productsList) {
      final l10n = AppLocalizations.of(context);
      dynamic selectedProduct;
      final qtyCtrl = TextEditingController(text: '1.0');

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(l10n.localeName == 'ar' ? 'إضافة صنف للتحويل' : 'Add Item to Transfer'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField(
                    hint: Text(l10n.localeName == 'ar' ? 'اختر المنتج' : 'Select Product'),
                    items: (productsList as List).map<DropdownMenuItem>((prod) {
                      return DropdownMenuItem(
                        value: prod,
                        child: Text('${prod.name} (${prod.itemCode})'),
                      );
                    }).toList(),
                    onChanged: (val) => setStateDialog(() => selectedProduct = val),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.localeName == 'ar' ? 'الكمية المحولة' : 'Quantity',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.localeName == 'ar' ? 'إلغاء' : 'Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (selectedProduct == null) return;
                    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
                    if (qty <= 0) return;

                    setState(() {
                      _lines.add(
                        _TransferItemRow(
                          itemCode: selectedProduct.itemCode,
                          itemName: selectedProduct.name,
                          quantity: qty,
                          unitCost: selectedProduct.unitCost ?? 0.0,
                        ),
                      );
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: Text(l10n.localeName == 'ar' ? 'إضافة' : 'Add'),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  void _saveTransfer() async {
    final l10n = AppLocalizations.of(context);
    if (_fromWarehouseId == null || _toWarehouseId == null) {
      showAppSnackBar(context, message: l10n.localeName == 'ar' ? 'يرجى تحديد المستودع المصدر والهدف' : 'Please select source and target warehouses', isSuccess: false);
      return;
    }
    if (_fromWarehouseId == _toWarehouseId) {
      showAppSnackBar(context, message: l10n.localeName == 'ar' ? 'لا يمكن التحويل لنفس المستودع' : 'Cannot transfer to the same warehouse', isSuccess: false);
      return;
    }
    if (_lines.isEmpty) {
      showAppSnackBar(context, message: l10n.localeName == 'ar' ? 'يرجى إضافة صنف واحد على الأقل' : 'Please add at least one item', isSuccess: false);
      return;
    }

    final transferUuid = generateUuidV4();
    final transfer = StockTransfer(
      id: transferUuid,
      transferNumber: _transferNumber,
      fromWarehouseId: _fromWarehouseId!,
      toWarehouseId: _toWarehouseId!,
      transferDate: _transferDate,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      lines: _lines.map((l) {
        return StockTransferLine(
          id: generateUuidV4(),
          transferUuid: transferUuid,
          itemCode: l.itemCode,
          itemName: l.itemName,
          quantity: l.quantity,
          unitCost: l.unitCost,
          totalCost: l.totalCost,
        );
      }).toList(),
    );

    final success = await ref.read(stockTransferControllerProvider.notifier).saveTransfer(transfer);
    if (mounted && success) {
      showAppSnackBar(context, message: l10n.localeName == 'ar' ? 'تم حفظ أمر التحويل بنجاح' : 'Transfer saved successfully', isSuccess: true);
      Navigator.of(context).pop();
    }
  }
}
