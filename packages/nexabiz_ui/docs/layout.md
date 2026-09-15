# Layout System Guidelines

## Core Layout Primitives

- `AppPage`: Central page container. Manages SafeAreas, header gap, max page constraints, and scrolling.
- `AppContent`: Constrained width container with directional padding.
- `AppSection`: Section wrapper using `shadcn.Card`.
- `AppGrid`: Adaptive grid layout using responsive breakpoint tiers.

## Semantic Page Layouts

1. `AppFormPage`: Form page layout with header and action bar.
2. `AppTablePage`: Dense table layout with header, filter bar, fixed height table, and pagination.
3. `AppDashboardPage`: ERP Dashboard layout with stat card grids.
4. `AppListPage`: Standard list view layout.
5. `AppDetailsPage`: Master detail view layout.
6. `AppSettingsPage`: Categorized settings page layout.
7. `AppMasterDetailPage`: Split pane desktop view with auto-collapsing mobile view.
