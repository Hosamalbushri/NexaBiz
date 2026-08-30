import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';

/// Data class representing a saved filter preset for a report.
class ReportFilterPreset {
  const ReportFilterPreset({
    required this.id,
    required this.reportId,
    required this.name,
    required this.filterValues,
    required this.createdAt,
  });

  final String id;
  final String reportId;
  final String name;
  final Map<String, dynamic> filterValues;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'reportId': reportId,
        'name': name,
        'filterValues': filterValues,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ReportFilterPreset.fromJson(Map<String, dynamic> json) =>
      ReportFilterPreset(
        id: json['id'] as String,
        reportId: json['reportId'] as String,
        name: json['name'] as String,
        filterValues: Map<String, dynamic>.from(json['filterValues'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Widget bar displaying saved filter presets for a report with save/delete controls.
class AppReportPresetBar extends StatefulWidget {
  const AppReportPresetBar({
    super.key,
    required this.reportId,
    required this.currentFilterValues,
    required this.onSelectPreset,
    required this.onClearPreset,
  });

  final String reportId;
  final Map<String, dynamic> currentFilterValues;
  final ValueChanged<ReportFilterPreset> onSelectPreset;
  final VoidCallback onClearPreset;

  @override
  State<AppReportPresetBar> createState() => _AppReportPresetBarState();
}

class _AppReportPresetBarState extends State<AppReportPresetBar> {
  static const String _boxName = 'report_filter_presets_box';
  List<ReportFilterPreset> _presets = [];
  String? _selectedPresetId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final rawList = box.get(widget.reportId);
      if (rawList != null) {
        final List decoded = jsonDecode(rawList) as List;
        setState(() {
          _presets = decoded
              .map((e) => ReportFilterPreset.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveCurrentAsPreset(String name) async {
    if (name.trim().isEmpty) return;
    final newPreset = ReportFilterPreset(
      id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
      reportId: widget.reportId,
      name: name.trim(),
      filterValues: Map<String, dynamic>.from(widget.currentFilterValues),
      createdAt: DateTime.now(),
    );

    final updated = [..._presets, newPreset];
    setState(() {
      _presets = updated;
      _selectedPresetId = newPreset.id;
    });

    final box = await Hive.openBox<String>(_boxName);
    await box.put(
      widget.reportId,
      jsonEncode(updated.map((p) => p.toJson()).toList()),
    );
    widget.onSelectPreset(newPreset);
  }

  Future<void> _deletePreset(String presetId) async {
    final updated = _presets.where((p) => p.id != presetId).toList();
    setState(() {
      _presets = updated;
      if (_selectedPresetId == presetId) _selectedPresetId = null;
    });

    final box = await Hive.openBox<String>(_boxName);
    await box.put(
      widget.reportId,
      jsonEncode(updated.map((p) => p.toJson()).toList()),
    );
    widget.onClearPreset();
  }

  void _showSavePresetDialog(BuildContext context) {
    final theme = Theme.of(context);
    final textController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Row(
          children: [
            Icon(Icons.bookmark_add_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'حفظ التصفية الحالية',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'اسم التصفية المحفوظة',
            hintText: 'مثال: حركة مستودع صنعاء الشهرية',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final name = textController.text;
              Navigator.of(ctx).pop();
              _saveCurrentAsPreset(name);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (_loading) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.bookmarks_outlined, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              isAr ? 'التصفيات المحفوظة:' : 'Presets:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final p in _presets) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.name,
                                style: TextStyle(
                                  fontWeight: _selectedPresetId == p.id
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                              if (_selectedPresetId == p.id) ...[
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _deletePreset(p.id),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: scheme.onPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          selected: _selectedPresetId == p.id,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedPresetId = p.id);
                              widget.onSelectPreset(p);
                            } else {
                              setState(() => _selectedPresetId = null);
                              widget.onClearPreset();
                            }
                          },
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _showSavePresetDialog(context),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 14, color: scheme.primary),
                    const SizedBox(width: 2),
                    Text(
                      isAr ? 'حفظ تصفية' : 'Save Preset',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
