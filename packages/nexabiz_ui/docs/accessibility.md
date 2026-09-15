# Accessibility & RTL Guidelines

## Right-To-Left (RTL) Compliance

Every layout component must support Arabic and English bi-directional rendering seamlessly:
- Use `EdgeInsetsDirectional` instead of physical `EdgeInsets.only(left/right)`.
- Use `AlignmentDirectional` instead of physical `Alignment.centerLeft/centerRight`.
- Use `TextDirection` aware primitives from `shadcn_flutter`.

## Focus & Screen Reader Support

- Interactive controls (`AppButton`, `AppTextField`, `AppSelectField`) preserve native Flutter `FocusNode` and `Semantics` tags.
- Minimum touch target size of 44x44 points is maintained across all interactive buttons and icons.
