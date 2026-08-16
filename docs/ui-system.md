# UI System

## Philosophy

Consistent Material 3 business UI across the platform. Modules consume shared tokens and widgets; they must not invent a second visual language.

## Libraries in use

| Library | Role |
| --- | --- |
| Material 3 | Foundation |
| FlexColorScheme | Theme construction (`AppTheme`) |
| Google Fonts / Cairo | Typography for EN/AR |
| Flutter Animate | Subtle motion |
| Skeletonizer | Skeleton loading |
| Syncfusion Charts | Inventory status chart |
| Syncfusion DataGrid | Inventory report table |

### Not used

- **GetWidget** — not in `pubspec.yaml`. Do not add without approval.
- **Syncfusion PDF** — not used; PDF export uses package `pdf` due to `xml` conflict with `excel`.

## Tokens

Located under `lib/app/theme/`:

| Token file | Purpose |
| --- | --- |
| `app_colors.dart` | Brand + semantic colors |
| `app_typography.dart` | Cairo text theme |
| `app_spacing.dart` | 8-point scale |
| `app_radius.dart` | Corner radii |
| `app_shadows.dart` | Elevation shadows |
| `app_breakpoints.dart` | Responsive breakpoints |
| `components/*` | Button/card/input/dialog/nav/chip themes |

Prefer `Theme.of(context).colorScheme` in screens. Use `AppColors` semantic tokens for status accents when needed.

## Spacing scale

`xxs=4`, `xs=8`, `sm=12`, `md=16`, `lg=24`, `xl=32`, `xxl=40`, `xxxl=48`

## Breakpoints

- Mobile: width `< 600`
- Tablet: `600 ≤ width < 900`
- Desktop: `width ≥ 900`

## Preferred reusable widgets

From `lib/core/widgets/` (also exported via `app_widgets.dart` for the App* set):

- `AppButton`
- `AppCard`
- `AppTextField`
- `AppAmountField` / `FinancialNumberField` — financial & quantity numeric input (see [financial-numeric-input.md](financial-numeric-input.md))
- `AppSearchBar`
- `AppDialog` / `showAppDialog`
- `AppBottomSheet` / `showAppBottomSheet`
- `AppStatusBadge`
- `AppLoading` (circular / linear / skeleton list)
- `AppEmptyState`
- `AppErrorState`
- `CustomAppBar`
- `StatCard`
- `showAppSnackBar`

### Legacy widgets still in tree

Prefer migrating away over time:

- `EmptyStateWidget` → `AppEmptyState`
- `ConfirmationDialog` → `showAppDialog`
- `AppTopBar` → `CustomAppBar`
- `CustomBottomNav` (platform now uses shell navigation)

### Not present

- `AppDataTable` — use Syncfusion DataGrid inside Inventory reports (or Material tables for simple cases)

## UI rules for contributors

1. Search Core widgets before creating a new shared control.
2. Do not hardcode colors/spacing when tokens exist.
3. Keep Syncfusion usage inside the feature that needs it (currently Inventory reports).
4. Verify RTL with Arabic.
5. Provide loading / empty / error states for async screens.
