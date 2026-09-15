# Accounting UI Controls & Semantic Mapping

## Accounting Form Fields

Accounting forms require domain-specific field semantics without creating separate visual widget frameworks:

| Accounting Role | Native Control | Formatting & Behavior |
| :--- | :--- | :--- |
| **Debit / Credit** | `AppNumberField` / `AppTextField` | Numeric keyboard, 2-decimal formatting, right-aligned |
| **Amount / Balance** | `AppNumberField` | Fixed-point integer or double formatting, right-aligned |
| **Currency** | `AppSelectField` / `AppSearchableSelect` | Currency code picker (SAR, USD, EUR, etc.) |
| **Account Code** | `AppSearchableSelect` | Monospace code + account name search |
| **Document Date** | `AppDateField` | Calendar popover with localized date format |
| **Description** | `AppMultilineField` | Multi-line text area built on `shadcn.TextField` |

Accounting semantics modulate validation and layout without introducing competing visual primitives.
