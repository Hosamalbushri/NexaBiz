import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/inventory_item.dart';

final selectedItemProvider = StateProvider<InventoryItem?>((ref) => null);
