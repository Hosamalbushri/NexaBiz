import 'package:flutter/material.dart';

import '../../theme/tokens/tokens.dart';
import '../../widgets/app_card.dart';

/// Canonical Responsive Master-Detail Layout Pattern for NexaBiz ERP.
///
/// Dual-pane split layout on Desktop/Tablet vs single-pane push layout on Mobile.
class AppResponsiveMasterDetailPattern<T> extends StatelessWidget {
  const AppResponsiveMasterDetailPattern({
    super.key,
    required this.masterBuilder,
    required this.detailBuilder,
    this.selectedItem,
    this.emptyDetailPlaceholder,
    this.masterFlex = 2,
    this.detailFlex = 3,
    this.breakpoint = 900.0,
  });

  final Widget Function(BuildContext context, T? selected) masterBuilder;
  final Widget Function(BuildContext context, T selected) detailBuilder;
  final T? selectedItem;
  final Widget? emptyDetailPlaceholder;
  final int masterFlex;
  final int detailFlex;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isDesktop = mediaWidth >= breakpoint;

    if (!isDesktop) {
      return masterBuilder(context, selectedItem);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: masterFlex, child: masterBuilder(context, selectedItem)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: detailFlex,
          child: selectedItem != null
              ? detailBuilder(context, selectedItem as T)
              : (emptyDetailPlaceholder ??
                    const AppCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            'Select an item from the list to view details',
                          ),
                        ),
                      ),
                    )),
        ),
      ],
    );
  }
}
