# Theme & Color System Guidelines

## Single Theme Authority

All visual styling derives from `AppTheme.light()` or `AppTheme.dark()`, which produce native `shadcn.ThemeData` objects.

```dart
final theme = shadcn.Theme.of(context);
final colorScheme = theme.colorScheme;
```

## Color Mapping

- `colorScheme.background`: Main screen background.
- `colorScheme.card`: Surface container background.
- `colorScheme.primary`: Primary actions, links, active indicators.
- `colorScheme.destructive`: Errors, deletions, credit balances in accounting.
- `colorScheme.border`: Subtle borders and dividers.
- `colorScheme.mutedForeground`: Secondary text and labels.
