# Component Inventory & Usage Policy

## Component Classification

`shadcn_flutter` is the primary source of visual components in NexaBiz:

- **Foundation**: `shadcn.Theme`, `shadcn.ColorScheme`, `shadcn.Typography`
- **Buttons**: `AppButton` built on `shadcn.Button`, `AppIconButton`
- **Forms**: `AppForm`, `AppFormSection`, `AppTextField`, `AppSelectField`, `AppCheckbox`, `AppSwitch`, `AppDateField`
- **Overlays**: `AppDialog`, `AppConfirmationDialog`, `AppDrawerSheet`, `AppPinnedDockSheet`, `AppPopover`
- **Surfaces**: `shadcn.Card`, `AppSurface`
- **Data Display**: `AppDataTable`, `AppPaginationBar`, `AppStatusBadge`, `AppEmptyState`, `AppLoading`, `AppErrorState`

## Direct `shadcn_flutter` Usage Policy

Application screens may directly invoke native `shadcn_flutter` controls (such as `shadcn.Button`, `shadcn.Card`, `shadcn.TextField`) whenever no custom NexaBiz-specific accounting behavior is needed.
