import 'package:flutter/material.dart';
import '../../import_engine.dart';

/// Reusable dynamic assignments & relation fallback configuration widget.
///
/// Dynamically generates UI form controls (Category, Warehouse, Accounts, Brand, etc.)
/// directly from the provided [ImportProfile] without hardcoding entity screens.
class StepDynamicAssignments extends StatelessWidget {
  const StepDynamicAssignments({
    super.key,
    required this.profile,
    required this.assignments,
    required this.onAssignmentChanged,
  });

  final ImportProfile profile;
  final Map<String, dynamic> assignments;
  final void Function(String key, dynamic value) onAssignmentChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final relations = profile.relations;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(Icons.tune_rounded, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dynamic Assignments & Fallbacks',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Set fixed default values or fallbacks for "${profile.label}".',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),

          if (relations.isNotEmpty) ...[
            Text(
              'Entity Relations',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12.0),
            ...relations.map((rel) => _buildRelationAssignmentCard(context, rel)),
            const SizedBox(height: 24.0),
          ],

          Text(
            'Default Field Attributes',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12.0),
          ...profile.fields.map((field) => _buildFieldAssignmentInput(context, field)),
        ],
      ),
    );
  }

  Widget _buildRelationAssignmentCard(BuildContext context, ImportRelation rel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentVal = assignments[rel.relationKey]?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree_outlined, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    '${rel.relationKey}${rel.isRequired ? ' *' : ''}',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    rel.targetEntityType,
                    style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              'Lookup Field: ${rel.lookupFieldKey}',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12.0),
            TextFormField(
              key: Key('assignment_relation_${rel.relationKey}'),
              initialValue: currentVal,
              decoration: InputDecoration(
                labelText: 'Fixed / Default ${rel.relationKey}',
                hintText: 'e.g. Main ${rel.relationKey} or Code',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                isDense: true,
              ),
              onChanged: (val) => onAssignmentChanged(rel.relationKey, val.trim().isEmpty ? null : val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldAssignmentInput(BuildContext context, ImportField field) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentVal = assignments[field.key]?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        key: Key('assignment_field_${field.key}'),
        initialValue: currentVal,
        decoration: InputDecoration(
          labelText: 'Default ${field.label} (${field.key})',
          hintText: 'Optional default value if unmapped or empty',
          helperText: field.description,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
          isDense: true,
          prefixIcon: Icon(
            _getFieldTypeIcon(field.dataType),
            color: colorScheme.primary,
          ),
        ),
        onChanged: (val) => onAssignmentChanged(field.key, val.trim().isEmpty ? null : val),
      ),
    );
  }

  IconData _getFieldTypeIcon(ImportDataType dataType) {
    switch (dataType) {
      case ImportDataType.number:
      case ImportDataType.integer:
        return Icons.pin_outlined;
      case ImportDataType.boolean:
        return Icons.check_circle_outline;
      case ImportDataType.date:
      case ImportDataType.dateTime:
        return Icons.calendar_today_outlined;
      default:
        return Icons.short_text;
    }
  }
}
