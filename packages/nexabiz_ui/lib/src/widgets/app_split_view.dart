import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// A canonical NexaBiz resizable split-view container (Master/Detail or Side-Panel layout).
///
/// Built on top of [shadcn.ResizablePanel.horizontal] and [shadcn.ResizablePane].
class AppSplitView extends StatelessWidget {
  /// The master/primary pane widget (left/start).
  final Widget master;

  /// The detail/secondary pane widget (right/end).
  final Widget detail;

  /// Initial size of the master pane in pixels.
  final double initialMasterWidth;

  /// Minimum width constraint for the master pane.
  final double? minMasterWidth;

  /// Maximum width constraint for the master pane.
  final double? maxMasterWidth;

  /// Creates an [AppSplitView].
  const AppSplitView({
    super.key,
    required this.master,
    required this.detail,
    this.initialMasterWidth = 300,
    this.minMasterWidth = 200,
    this.maxMasterWidth = 600,
  });

  @override
  Widget build(BuildContext context) {
    return shadcn.ResizablePanel.horizontal(
      children: [
        shadcn.ResizablePane(
          initialSize: initialMasterWidth,
          minSize: minMasterWidth,
          maxSize: maxMasterWidth,
          child: master,
        ),
        shadcn.ResizablePane.flex(
          initialFlex: 1,
          child: detail,
        ),
      ],
    );
  }
}
