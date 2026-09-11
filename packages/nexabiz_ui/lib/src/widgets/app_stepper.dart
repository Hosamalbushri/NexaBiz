import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Data model for an individual step in [AppStepper].
class AppStepItem {
  /// The title widget for this step.
  final Widget title;

  /// Content builder called when this step is active.
  final WidgetBuilder contentBuilder;

  /// Optional custom icon.
  final Widget? icon;

  /// Optional validation callback before advancing past this step.
  final bool Function()? validate;

  /// Creates an [AppStepItem].
  const AppStepItem({
    required this.title,
    required this.contentBuilder,
    this.icon,
    this.validate,
  });
}

/// A canonical NexaBiz multi-step wizard component.
///
/// Built on top of [shadcn.Stepper], [shadcn.StepperController], and [shadcn.StepContainer].
/// Manages step navigation lifecycle, validation callback checks, and localized navigation actions.
class AppStepper extends StatefulWidget {
  /// The list of step items.
  final List<AppStepItem> steps;

  /// Optional external controller. If null, an internal controller is managed automatically.
  final shadcn.StepperController? controller;

  /// Active step index (default: 0).
  final int currentStep;

  /// Callback when active step changes.
  final ValueChanged<int>? onStepChanged;

  /// Callback when advancing to the next step.
  final VoidCallback? onNext;

  /// Callback when returning to the previous step.
  final VoidCallback? onPrevious;

  /// Callback when finishing the final step.
  final VoidCallback? onComplete;

  /// Custom label for the Next button.
  final String nextLabel;

  /// Custom label for the Previous button.
  final String previousLabel;

  /// Custom label for the Complete button.
  final String completeLabel;

  /// Whether the complete action is currently submitting/loading.
  final bool isSubmitting;

  /// Stepper direction (horizontal or vertical).
  final Axis direction;

  /// Stepper visual variant.
  final shadcn.StepVariant variant;

  /// Stepper size.
  final shadcn.StepSize size;

  /// Creates an [AppStepper].
  const AppStepper({
    super.key,
    required this.steps,
    this.controller,
    this.currentStep = 0,
    this.onStepChanged,
    this.onNext,
    this.onPrevious,
    this.onComplete,
    this.nextLabel = 'Next',
    this.previousLabel = 'Back',
    this.completeLabel = 'Complete',
    this.isSubmitting = false,
    this.direction = Axis.horizontal,
    this.variant = shadcn.StepVariant.circle,
    this.size = shadcn.StepSize.medium,
  });

  @override
  State<AppStepper> createState() => _AppStepperState();
}

class _AppStepperState extends State<AppStepper> {
  late shadcn.StepperController _controller;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = shadcn.StepperController(currentStep: widget.currentStep);
      _internalController = true;
    }
  }

  @override
  void didUpdateWidget(covariant AppStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_internalController) {
        _controller.dispose();
      }
      if (widget.controller != null) {
        _controller = widget.controller!;
        _internalController = false;
      } else {
        _controller = shadcn.StepperController(currentStep: widget.currentStep);
        _internalController = true;
      }
    } else if (widget.currentStep != oldWidget.currentStep) {
      if (_controller.value.currentStep != widget.currentStep) {
        _controller.jumpToStep(widget.currentStep);
      }
    }
  }

  @override
  void dispose() {
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleNext() {
    final currentIdx = _controller.value.currentStep;
    if (currentIdx >= 0 && currentIdx < widget.steps.length) {
      final currentItem = widget.steps[currentIdx];
      if (currentItem.validate != null) {
        final isValid = currentItem.validate!();
        if (!isValid) return;
      }
    }

    if (currentIdx < widget.steps.length - 1) {
      _controller.nextStep();
      widget.onStepChanged?.call(_controller.value.currentStep);
      widget.onNext?.call();
    } else {
      widget.onComplete?.call();
    }
  }

  void _handlePrevious() {
    if (_controller.value.currentStep > 0) {
      _controller.previousStep();
      widget.onStepChanged?.call(_controller.value.currentStep);
      widget.onPrevious?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shadcnSteps = <shadcn.Step>[];

    for (int i = 0; i < widget.steps.length; i++) {
      final item = widget.steps[i];
      final isLast = i == widget.steps.length - 1;

      shadcnSteps.add(
        shadcn.Step(
          title: item.title,
          icon: item.icon,
          contentBuilder: (ctx) {
            final content = item.contentBuilder(ctx);
            return shadcn.StepContainer(
              actions: [
                if (i > 0)
                  shadcn.OutlineButton(
                    onPressed: _handlePrevious,
                    child: Text(widget.previousLabel),
                  ),
                if (!isLast)
                  shadcn.PrimaryButton(
                    onPressed: _handleNext,
                    child: Text(widget.nextLabel),
                  )
                else
                  shadcn.PrimaryButton(
                    onPressed: widget.isSubmitting ? null : _handleNext,
                    child: widget.isSubmitting
                        ? const shadcn.CircularProgressIndicator()
                        : Text(widget.completeLabel),
                  ),
              ],
              child: content,
            );
          },
        ),
      );
    }

    return shadcn.Stepper(
      controller: _controller,
      steps: shadcnSteps,
      direction: widget.direction,
      variant: widget.variant,
      size: widget.size,
    );
  }
}
