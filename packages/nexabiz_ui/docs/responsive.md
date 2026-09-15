# Responsive Design Policy

## Centralized Breakpoints

NexaBiz UI defines 4 central responsive breakpoints in `AppBreakpoints`:

| Breakpoint Tier | Width Range | Form Columns | Table Mode |
| :--- | :--- | :--- | :--- |
| `compact` (Mobile) | `< 600px` | 1 Column | Card list / Horizontal scroll |
| `medium` (Tablet) | `600px - 999px` | 2 Columns | Compact table |
| `expanded` (Laptop) | `1000px - 1439px` | 2-3 Columns | Full table |
| `wide` (Desktop) | `>= 1440px` | 3-4 Columns | Split master-detail pane |

All pages must consume `AppResponsive` or `ResponsiveBuilder` instead of defining custom inline `MediaQuery` logic.
