import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/grouped_decimal_input.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class EditCountResult {
  const EditCountResult({required this.mainText, required this.secondaryText});

  final String mainText;
  final String secondaryText;
}

/// Popup dialog for editing an already saved inventory count.
Future<EditCountResult?> showEditCountDialog({
  required BuildContext context,
  required String initialMainText,
  required String initialSecondaryText,
}) {
  return showGeneralDialog<EditCountResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _EditCountDialog(
        initialMainText: initialMainText,
        initialSecondaryText: initialSecondaryText,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

class _EditCountDialog extends StatefulWidget {
  const _EditCountDialog({
    required this.initialMainText,
    required this.initialSecondaryText,
  });

  final String initialMainText;
  final String initialSecondaryText;

  @override
  State<_EditCountDialog> createState() => _EditCountDialogState();
}

class _EditCountDialogState extends State<_EditCountDialog> {
  late final TextEditingController _mainController;
  late final TextEditingController _secondaryController;
  late final FocusNode _mainFocusNode;
  late final FocusNode _secondaryFocusNode;

  @override
  void initState() {
    super.initState();
    _mainController = TextEditingController(text: widget.initialMainText);
    _secondaryController = TextEditingController(
      text: widget.initialSecondaryText,
    );
    _mainFocusNode = FocusNode();
    _secondaryFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _secondaryController.dispose();
    _mainFocusNode.dispose();
    _secondaryFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final maxWidth = media.size.width >= 520 ? 440.0 : media.size.width - 40;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: media.size.height * 0.86,
          ),
          child: Material(
            color: colorScheme.surface,
            elevation: 10,
            shadowColor: colorScheme.shadow.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DialogHeader(
                  title: localization.editCountTitle,
                  subtitle: localization.editCountSubtitle,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                              controller: _mainController,
                              focusNode: _mainFocusNode,
                              label: localization.mainQuantity,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: const [
                                WesternDigitsInputFormatter(),
                                GroupedDecimalInputFormatter(decimalPlaces: 3),
                              ],
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  _secondaryFocusNode.requestFocus(),
                            )
                            .animate()
                            .fadeIn(delay: 80.ms, duration: 220.ms)
                            .moveY(
                              begin: 10,
                              end: 0,
                              delay: 80.ms,
                              duration: 220.ms,
                              curve: Curves.easeOutCubic,
                            ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                              controller: _secondaryController,
                              focusNode: _secondaryFocusNode,
                              label: localization.subQuantity,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: const [
                                WesternDigitsInputFormatter(),
                                GroupedDecimalInputFormatter(decimalPlaces: 3),
                              ],
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                            )
                            .animate()
                            .fadeIn(delay: 140.ms, duration: 220.ms)
                            .moveY(
                              begin: 10,
                              end: 0,
                              delay: 140.ms,
                              duration: 220.ms,
                              curve: Curves.easeOutCubic,
                            ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child:
                      Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: localization.cancel,
                                  variant: AppButtonVariant.outlined,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: AppButton(
                                  label: localization.saveCount,
                                  icon: Icons.save_outlined,
                                  onPressed: _submit,
                                ),
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(delay: 180.ms, duration: 220.ms)
                          .moveY(
                            begin: 8,
                            end: 0,
                            delay: 180.ms,
                            duration: 220.ms,
                            curve: Curves.easeOutCubic,
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    Navigator.of(context).pop(
      EditCountResult(
        mainText: _mainController.text,
        secondaryText: _secondaryController.text,
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IconButton(
              onPressed: onClose,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.error,
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
