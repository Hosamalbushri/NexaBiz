# Financial numeric input

Canonical system for amounts, quantities, rates, and other real numbers in the UI.

## Architecture

```
AppAmountField / FinancialNumberField  (presentation)
        │
GroupedDecimalInputFormatter           (as-you-type display)
        │
parseGroupedDecimal / formatGroupedDecimal
        │
raw double                             (domain / DB / sync)
```

**Never persist** strings like `1,250,000.75`. Domain layers receive `double` (or existing money helpers). Commas exist only in the presentation layer.

Entry points:

| Import | Purpose |
| --- | --- |
| `lib/core/widgets/app_amount_field.dart` | Widget + typedef `FinancialNumberField` |
| `lib/core/utils/grouped_decimal_input.dart` | Parse / format / `TextInputFormatter` |
| `lib/core/formatting/number/financial_number.dart` | Barrel re-export |

## Raw vs display

| Layer | Example |
| --- | --- |
| Display | `1,250,000.75` |
| `onChanged` / domain | `1250000.75` |

`,` and Arabic thousands `٬` are **grouping only**. Decimal point is always `.`.

## Usage

```dart
AppAmountField(
  value: amount,
  onChanged: (raw) => setState(() => amount = raw),
  decimalPlaces: 2,
  suffixText: 'SAR',
  emptyWhenZero: true,
)
```

Alias (same widget):

```dart
FinancialNumberField(
  value: rate,
  onChanged: setRate,
  decimalPlaces: 6,
  trimTrailingZeros: true,
)
```

### Variants

- `form` — labeled Material field
- `compact` — dense table cell
- `bare` — borderless embed (e.g. sales discount row)

### Common configs

| Use case | `decimalPlaces` | Notes |
| --- | --- | --- |
| Money / debit / credit | `2` | Default |
| Exchange rate | `4`–`6` | `trimTrailingZeros: true` |
| Quantity | `0`–`3` | Inventory counting uses formatter on `AppTextField` + `parseGroupedDecimal` |
| Integer money | `0` | No fractional input |

`allowNegative` defaults to `false`.

## Cursor / focus

- Formatter maps caret by significant characters (digits, `.`, `-`), not by raw string length.
- On focus, if the caret landed at offset `0` (typical tab-in), it moves to the **end** so Backspace removes the last digit. Mid-field taps keep their position.
- Prefer `TextEditingValue` / selection preservation; do not assign `controller.text = …` in listeners.

## When to use

Use for: amounts, prices, discounts, tax, quantities, balances, exchange rates, opening debit/credit.

**Do not use** for identifiers:

- Account codes, invoice / voucher numbers, barcodes, phone numbers, PINs, pack-size integers treated as codes

Those must stay plain text/`digitsOnly` fields without thousand separators.

## Adding a new numeric field

1. Prefer `AppAmountField` with a `double` in state (not a formatted string).
2. If you must keep an external `TextEditingController`, apply `WesternDigitsInputFormatter` + `GroupedDecimalInputFormatter`, and parse with `parseGroupedDecimal` only.
3. Do not call `replaceAll(',', '')` in feature modules.

## Import / Excel

Excel parsers should call `parseGroupedDecimal` so `1,250,000.75` imports correctly. Exported numeric cells should remain numeric (Excel) or unformatted plain numbers per existing exporters.

## Tests

- `test/grouped_decimal_input_test.dart` — parse, format, caret / backspace / paste
- `test/app_amount_field_test.dart` — widget focus, typing, RTL, disabled

## Localization

Labels come from ARB / `AppLocalizations`. Stored values stay locale-independent Western decimals. Arabic digits typed in the field are normalized to Western digits live.
