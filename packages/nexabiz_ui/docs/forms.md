# Form Architecture & Guidelines

## Unified Form System

NexaBiz forms use native `shadcn_flutter` form capabilities integrated into `AppForm`:

```dart
AppForm(
  formKey: _formKey,
  title: 'إضافة عميل جديد',
  onSubmit: _handleSave,
  children: [
    AppFormSection(
      title: 'البيانات الأساسية',
      children: [
        AppTextField(
          label: 'اسم العميل',
          required: true,
        ),
        AppSelectField<String>(
          label: 'نوع الحساب',
          items: [
            SelectItem(value: 'corporate', label: 'شركات'),
            SelectItem(value: 'individual', label: 'أفراد'),
          ],
        ),
      ],
    ),
  ],
)
```

## Standard Form Field Structure

Every standard form field includes:
1. Label & Required Asterisk Indicator
2. Native `shadcn` input control
3. Helper text or description
4. Validation error state (red border + message)
5. Disabled & ReadOnly state handling
