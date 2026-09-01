import 'package:flutter/material.dart';

/// Reusable ERP Module List Page Scaffold.
///
/// Standardizes app bar, search bar, list items, empty states, and action buttons
/// across all business modules to prevent repetitive UI boilerplate.
class ModuleListScaffold<T> extends StatelessWidget {
  const ModuleListScaffold({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.isLoading = false,
    this.error,
    this.onRefresh,
    this.onSearchChanged,
    this.searchHint = 'بحث...',
    this.emptyMessage = 'لا توجد بيانات للعرض',
    this.floatingActionButton,
    this.actions,
  });

  final String title;
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool isLoading;
  final Object? error;
  final Future<void> Function()? onRefresh;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;
  final String emptyMessage;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          if (onSearchChanged != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: searchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
              ),
            ),
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(error.toString(), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
        ),
      );
    }

    Widget listWidget = ListView.separated(
      padding: const EdgeInsets.all(12.0),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8.0),
      itemBuilder: (ctx, index) => itemBuilder(ctx, items[index]),
    );

    if (onRefresh != null) {
      listWidget = RefreshIndicator(
        onRefresh: onRefresh!,
        child: listWidget,
      );
    }

    return listWidget;
  }
}
