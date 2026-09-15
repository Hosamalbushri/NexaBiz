# Typography Guidelines

## Single Typography Authority

All typography must strictly derive from `shadcn.Theme.of(context).typography`:

- `theme.typography.h1` / `h2` / `h3` / `h4`: Page titles and section headings.
- `theme.typography.p`: Standard body text.
- `theme.typography.small`: Descriptions, labels, and captions.
- `theme.typography.muted`: Secondary and helper text.

## Accounting Semantic Roles

Accounting display text uses semantic aliases mapped to `shadcn.Theme`:
- **Currency & Amounts**: `theme.typography.p.copyWith(fontWeight: FontWeight.bold)`
- **Debit / Credit Lines**: `theme.typography.small` + `colorScheme.primary` or `colorScheme.destructive`
- **Account Codes**: Monospace formatting using `theme.typography.small`.
