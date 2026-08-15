import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/sync/app_bar_sync_actions.dart';
import '../../../../app/theme/app_breakpoints.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/service_add_card.dart';
import '../models/inventory_service_definition.dart';
import '../providers/inventory_services_provider.dart';
import 'inventory_customize_sheet.dart';

/// Inventory module hub — customizable, reorderable service grid.
class InventoryHomePage extends ConsumerWidget {
  const InventoryHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final servicesAsync = ref.watch(inventoryServicesProvider);
    final controller = ref.read(inventoryServicesProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else {
          router.go(AppRoutes.services);
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: l10n.moduleInventory,
          showBackButton: true,
          actions: const [AppBarSyncActions()],
        ),
        body: servicesAsync.when(
          loading: () => const AppLoading(),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.somethingWentWrong),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(label: l10n.retry, onPressed: controller.reload),
                ],
              ),
            ),
          ),
          data: (_) {
            final services = controller.resolveServices();
            return ListView(
              padding: AppConstants.pageInsets(context),
              children: [
                Text(
                  l10n.servicesTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.moduleInventoryDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (services.isEmpty)
                  _EmptyPinnedServices(
                    onCustomize: () => _openCustomize(context, ref),
                  )
                else
                  _InventoryServiceGrid(
                    services: services,
                    onOpen: (service) => context.go(service.path),
                    onReorder: controller.reorder,
                    onCustomize: () => _openCustomize(context, ref),
                    customizeLabel: l10n.inventoryCustomizeServices,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openCustomize(BuildContext context, WidgetRef ref) async {
    final current =
        ref.read(inventoryServicesProvider).valueOrNull ??
        [for (final service in inventoryServiceCatalog()) service.id];

    final result = await showAppBottomSheet<List<String>>(
      context: context,
      child: InventoryCustomizeSheet(
        availableServices: inventoryServiceCatalog(),
        initiallySelectedIds: current,
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    await ref.read(inventoryServicesProvider.notifier).save(result);
  }
}

class _EmptyPinnedServices extends StatelessWidget {
  const _EmptyPinnedServices({required this.onCustomize});

  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Text(
            l10n.inventoryNoServicesTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.inventoryNoServicesMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l10n.inventoryCustomizeServices,
            onPressed: onCustomize,
          ),
        ],
      ),
    );
  }
}

class _InventoryServiceGrid extends StatelessWidget {
  const _InventoryServiceGrid({
    required this.services,
    required this.onOpen,
    required this.onReorder,
    required this.onCustomize,
    required this.customizeLabel,
  });

  final List<InventoryServiceDefinition> services;
  final ValueChanged<InventoryServiceDefinition> onOpen;
  final Future<void> Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onCustomize;
  final String customizeLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = AppBreakpoints.isDesktop(width)
            ? 4
            : AppBreakpoints.isTablet(width)
            ? 3
            : 2;
        final childAspectRatio = AppBreakpoints.isMobile(width) ? 0.82 : 0.95;
        final itemCount = services.length + 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            if (index == services.length) {
              return ServiceAddCard(onTap: onCustomize, label: customizeLabel);
            }

            final service = services[index];
            return _DraggableInventoryServiceCard(
              index: index,
              service: service,
              onOpen: () => onOpen(service),
              onAccept: (fromIndex) async {
                if (fromIndex == index) {
                  return;
                }
                final newIndex = fromIndex < index ? index + 1 : index;
                await onReorder(fromIndex, newIndex);
              },
            );
          },
        );
      },
    );
  }
}

class _DraggableInventoryServiceCard extends StatelessWidget {
  const _DraggableInventoryServiceCard({
    required this.index,
    required this.service,
    required this.onOpen,
    required this.onAccept,
  });

  final int index;
  final InventoryServiceDefinition service;
  final VoidCallback onOpen;
  final ValueChanged<int> onAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final card = _InventoryServiceCard(
      icon: service.icon,
      title: service.title(l10n),
      subtitle: service.subtitle(l10n),
      onTap: onOpen,
    );

    return LongPressDraggable<int>(
      data: index,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(width: 160, height: 180, child: card),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != index,
        onAcceptWithDetails: (details) => onAccept(details.data),
        builder: (context, candidate, rejected) {
          final highlighted = candidate.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: highlighted
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: card,
          );
        },
      ),
    );
  }
}

class _InventoryServiceCard extends StatelessWidget {
  const _InventoryServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
              boxShadow: AppShadows.card(brightness),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.16),
                          colorScheme.secondary.withValues(alpha: 0.10),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Icon(icon, color: colorScheme.primary, size: 32),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
