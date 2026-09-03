import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/setup/presentation/widgets/central_setup_center_widget.dart';

/// Comprehensive setup hub for configuring package default accounts & operational defaults.
///
/// Refactored in Phase 7 to wrap the central dynamic [CentralSetupCenterWidget].
class PackageInitializationSettingsHub extends ConsumerWidget {
  const PackageInitializationSettingsHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CentralSetupCenterWidget();
  }
}
