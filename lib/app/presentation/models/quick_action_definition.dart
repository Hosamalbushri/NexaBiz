export '../../../core/modules/quick_action_definition.dart';

/// Default pinned shortcuts until the user customizes.
List<String> defaultQuickActionIds() => const [
  'scan_barcode',
  'create_sale',
  'create_customer',
  'create_receipt',
  'create_product',
];
