# Getting Started with NexaBiz UI

## Architectural Principle

NexaBiz UI (`packages/nexabiz_ui`) is the canonical application integration layer built natively on top of `shadcn_flutter`.

```text
Flutter Primitives
       ↓
shadcn_flutter (Theme, Card, Typography, Form, Components)
       ↓
nexabiz_ui (AppPage, AppForm, AppTablePage, AppSection, AppLayoutTokens)
       ↓
NexaBiz Application Screens
       ↓
Business / Accounting Logic
```

## Public API Usage

Import all canonical primitives from a single entry point:

```dart
import 'package:nexabiz_ui/nexabiz_ui.dart';
```

## Decision Rule for Components

When building any UI feature in NexaBiz:

1. **Does `shadcn_flutter` provide it natively?** → Use `shadcn_flutter` directly or via native theme.
2. **Can Flutter primitives solve it cleanly?** → Use Flutter layout primitives (`Row`, `Column`, `Expanded`, `Flex`).
3. **Is there a NexaBiz-specific accounting/semantic requirement?** → Use the thin `nexabiz_ui` semantic wrapper.
