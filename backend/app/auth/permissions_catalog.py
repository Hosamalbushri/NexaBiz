"""Stable permission codes used by authorization checks.

Hierarchy (product model):
  package/module → service → operation

Examples:
  inventory.stock_count.adjust
  inventory.products.import
  sales.documents.post
  customers.master.create

Legacy flat codes (products.view, sales.create, …) remain for sync entity
maps and older role templates. Prefer service-level codes for new UI gates.
"""

from __future__ import annotations

# Platform-level
PLATFORM_COMPANIES_MANAGE = "platform.companies.manage"
PLATFORM_USERS_MANAGE = "platform.users.manage"

# Identity / administration
USERS_VIEW = "users.view"
USERS_CREATE = "users.create"
USERS_UPDATE = "users.update"
USERS_DELETE = "users.delete"
USERS_MANAGE = "users.manage"

ROLES_VIEW = "roles.view"
ROLES_CREATE = "roles.create"
ROLES_UPDATE = "roles.update"
ROLES_DELETE = "roles.delete"
ROLES_MANAGE = "roles.manage"

PERMISSIONS_MANAGE = "permissions.manage"

COMPANIES_VIEW = "companies.view"
COMPANIES_UPDATE = "companies.update"

# ---------------------------------------------------------------------------
# Inventory package
# ---------------------------------------------------------------------------
# Legacy (kept for sync + older roles)
PRODUCTS_VIEW = "products.view"
PRODUCTS_CREATE = "products.create"
PRODUCTS_UPDATE = "products.update"
PRODUCTS_DELETE = "products.delete"

INVENTORY_VIEW = "inventory.view"
INVENTORY_CREATE = "inventory.create"
INVENTORY_UPDATE = "inventory.update"
INVENTORY_DELETE = "inventory.delete"
INVENTORY_ADJUST = "inventory.adjust"

# Service: Stock count (الجرد)
INVENTORY_STOCK_COUNT_VIEW = "inventory.stock_count.view"
INVENTORY_STOCK_COUNT_ADJUST = "inventory.stock_count.adjust"
INVENTORY_STOCK_COUNT_IMPORT = "inventory.stock_count.import"
INVENTORY_STOCK_COUNT_EXPORT = "inventory.stock_count.export"
INVENTORY_STOCK_COUNT_CLEAR = "inventory.stock_count.clear"

# Service: Products (المنتجات)
INVENTORY_PRODUCTS_VIEW = "inventory.products.view"
INVENTORY_PRODUCTS_CREATE = "inventory.products.create"
INVENTORY_PRODUCTS_UPDATE = "inventory.products.update"
INVENTORY_PRODUCTS_DELETE = "inventory.products.delete"
INVENTORY_PRODUCTS_IMPORT = "inventory.products.import"
INVENTORY_PRODUCTS_BARCODE = "inventory.products.barcode"

# ---------------------------------------------------------------------------
# Sales package — service: documents
# ---------------------------------------------------------------------------
SALES_VIEW = "sales.view"
SALES_CREATE = "sales.create"
SALES_UPDATE = "sales.update"
SALES_DELETE = "sales.delete"
SALES_POST = "sales.post"
SALES_CANCEL = "sales.cancel"

SALES_DOCUMENTS_VIEW = "sales.documents.view"
SALES_DOCUMENTS_CREATE = "sales.documents.create"
SALES_DOCUMENTS_UPDATE = "sales.documents.update"
SALES_DOCUMENTS_DELETE = "sales.documents.delete"
SALES_DOCUMENTS_POST = "sales.documents.post"
SALES_DOCUMENTS_CANCEL = "sales.documents.cancel"
SALES_DOCUMENTS_DUPLICATE = "sales.documents.duplicate"
SALES_DOCUMENTS_EXPORT = "sales.documents.export"

# ---------------------------------------------------------------------------
# Customers package
# ---------------------------------------------------------------------------
CUSTOMERS_VIEW = "customers.view"
CUSTOMERS_CREATE = "customers.create"
CUSTOMERS_UPDATE = "customers.update"
CUSTOMERS_DELETE = "customers.delete"

CUSTOMERS_MASTER_VIEW = "customers.master.view"
CUSTOMERS_MASTER_CREATE = "customers.master.create"
CUSTOMERS_MASTER_UPDATE = "customers.master.update"
CUSTOMERS_MASTER_DELETE = "customers.master.delete"
CUSTOMERS_MASTER_IMPORT = "customers.master.import"
CUSTOMERS_ACCOUNTS_VIEW = "customers.accounts.view"
CUSTOMERS_SETTINGS_VIEW = "customers.settings.view"
CUSTOMERS_SETTINGS_UPDATE = "customers.settings.update"

# ---------------------------------------------------------------------------
# Accounting package
# ---------------------------------------------------------------------------
ACCOUNTING_VIEW = "accounting.view"
ACCOUNTING_ACCOUNTS_VIEW = "accounting.accounts.view"
ACCOUNTING_ACCOUNTS_CREATE = "accounting.accounts.create"
ACCOUNTING_ACCOUNTS_UPDATE = "accounting.accounts.update"
ACCOUNTING_ACCOUNTS_DELETE = "accounting.accounts.delete"
ACCOUNTING_JOURNALS_VIEW = "accounting.journals.view"
ACCOUNTING_JOURNALS_CREATE = "accounting.journals.create"
ACCOUNTING_JOURNALS_UPDATE = "accounting.journals.update"
ACCOUNTING_JOURNALS_DELETE = "accounting.journals.delete"
ACCOUNTING_CURRENCY_RATES_VIEW = "accounting.currency_rates.view"
ACCOUNTING_CURRENCY_RATES_CREATE = "accounting.currency_rates.create"
ACCOUNTING_CURRENCY_RATES_UPDATE = "accounting.currency_rates.update"
ACCOUNTING_CURRENCY_RATES_DELETE = "accounting.currency_rates.delete"
ACCOUNTING_FISCAL_YEARS_VIEW = "accounting.fiscal_years.view"
ACCOUNTING_FISCAL_YEARS_CREATE = "accounting.fiscal_years.create"
ACCOUNTING_FISCAL_YEARS_UPDATE = "accounting.fiscal_years.update"
ACCOUNTING_FISCAL_YEARS_OPEN_PERIOD = "accounting.fiscal_years.open_period"
ACCOUNTING_FISCAL_YEARS_CLOSE_PERIOD = "accounting.fiscal_years.close_period"
ACCOUNTING_FISCAL_YEARS_REOPEN_PERIOD = "accounting.fiscal_years.reopen_period"
ACCOUNTING_VOUCHER_BOOKS_VIEW = "accounting.voucher_books.view"
ACCOUNTING_VOUCHER_BOOKS_CREATE = "accounting.voucher_books.create"
ACCOUNTING_VOUCHER_BOOKS_UPDATE = "accounting.voucher_books.update"
ACCOUNTING_VOUCHER_BOOKS_DELETE = "accounting.voucher_books.delete"
ACCOUNTING_REPORTS_VIEW = "accounting.reports.view"

# ---------------------------------------------------------------------------
# Receipts & Payments package
# ---------------------------------------------------------------------------
RECEIPTS_VIEW = "receipts.view"
RECEIPTS_CREATE = "receipts.create"
RECEIPTS_UPDATE = "receipts.update"
RECEIPTS_POST = "receipts.post"
RECEIPTS_CANCEL = "receipts.cancel"
PAYMENTS_VIEW = "payments.view"
PAYMENTS_CREATE = "payments.create"
PAYMENTS_UPDATE = "payments.update"
PAYMENTS_POST = "payments.post"
PAYMENTS_CANCEL = "payments.cancel"
RECEIPTS_PAYMENTS_REPORTS_VIEW = "receipts_payments.reports.view"
RECEIPTS_PAYMENTS_REPORTS_EXPORT = "receipts_payments.reports.export"
RECEIPTS_PAYMENTS_SYNC = "receipts_payments.sync"

# ---------------------------------------------------------------------------
# Reports package
# ---------------------------------------------------------------------------
REPORTS_VIEW = "reports.view"
REPORTS_SALES_PERIOD_VIEW = "reports.sales_period.view"
REPORTS_SALES_PERIOD_EXPORT = "reports.sales_period.export"
REPORTS_ACCOUNT_STATEMENT_VIEW = "reports.account_statement.view"
REPORTS_ACCOUNT_STATEMENT_EXPORT = "reports.account_statement.export"
REPORTS_TRIAL_BALANCE_VIEW = "reports.trial_balance.view"
REPORTS_TRIAL_BALANCE_EXPORT = "reports.trial_balance.export"
REPORTS_JOURNAL_BOOK_VIEW = "reports.journal_book.view"
REPORTS_JOURNAL_BOOK_EXPORT = "reports.journal_book.export"

# Settings / sync / devices
SETTINGS_VIEW = "settings.view"
SETTINGS_UPDATE = "settings.update"
SYNC_VIEW = "sync.view"
SYNC_EXECUTE = "sync.execute"
DEVICES_VIEW = "devices.view"
DEVICES_REVOKE = "devices.revoke"

ALL_PERMISSIONS: tuple[tuple[str, str], ...] = (
    # Platform / admin
    (PLATFORM_COMPANIES_MANAGE, "Manage companies at platform level"),
    (PLATFORM_USERS_MANAGE, "Manage users across companies"),
    (USERS_VIEW, "View users"),
    (USERS_CREATE, "Create users"),
    (USERS_UPDATE, "Update users"),
    (USERS_DELETE, "Delete users"),
    (USERS_MANAGE, "Manage users"),
    (ROLES_VIEW, "View roles"),
    (ROLES_CREATE, "Create roles"),
    (ROLES_UPDATE, "Update roles"),
    (ROLES_DELETE, "Delete roles"),
    (ROLES_MANAGE, "Manage roles"),
    (PERMISSIONS_MANAGE, "Manage permissions"),
    (COMPANIES_VIEW, "View company"),
    (COMPANIES_UPDATE, "Update company"),
    # Inventory — legacy
    (PRODUCTS_VIEW, "View products (legacy)"),
    (PRODUCTS_CREATE, "Create products (legacy)"),
    (PRODUCTS_UPDATE, "Update products (legacy)"),
    (PRODUCTS_DELETE, "Delete products (legacy)"),
    (INVENTORY_VIEW, "View inventory (legacy)"),
    (INVENTORY_CREATE, "Create inventory items (legacy)"),
    (INVENTORY_UPDATE, "Update inventory items (legacy)"),
    (INVENTORY_DELETE, "Delete inventory items (legacy)"),
    (INVENTORY_ADJUST, "Adjust inventory quantities (legacy)"),
    # Inventory — stock count service
    (INVENTORY_STOCK_COUNT_VIEW, "View stock count service"),
    (INVENTORY_STOCK_COUNT_ADJUST, "Perform stock count adjustments"),
    (INVENTORY_STOCK_COUNT_IMPORT, "Import stock count data"),
    (INVENTORY_STOCK_COUNT_EXPORT, "Export / print stock count reports"),
    (INVENTORY_STOCK_COUNT_CLEAR, "Clear stock count data"),
    # Inventory — products service
    (INVENTORY_PRODUCTS_VIEW, "View products service"),
    (INVENTORY_PRODUCTS_CREATE, "Create products"),
    (INVENTORY_PRODUCTS_UPDATE, "Update products"),
    (INVENTORY_PRODUCTS_DELETE, "Delete products"),
    (INVENTORY_PRODUCTS_IMPORT, "Import products from Excel"),
    (INVENTORY_PRODUCTS_BARCODE, "Generate and print barcodes"),
    # Sales — legacy
    (SALES_VIEW, "View sales (legacy)"),
    (SALES_CREATE, "Create sales (legacy)"),
    (SALES_UPDATE, "Update sales (legacy)"),
    (SALES_DELETE, "Delete sales (legacy)"),
    (SALES_POST, "Post sales (legacy)"),
    (SALES_CANCEL, "Cancel sales (legacy)"),
    # Sales — documents service
    (SALES_DOCUMENTS_VIEW, "View sales documents"),
    (SALES_DOCUMENTS_CREATE, "Create sales documents"),
    (SALES_DOCUMENTS_UPDATE, "Update sales documents"),
    (SALES_DOCUMENTS_DELETE, "Delete sales documents"),
    (SALES_DOCUMENTS_POST, "Post / confirm sales"),
    (SALES_DOCUMENTS_CANCEL, "Cancel sales documents"),
    (SALES_DOCUMENTS_DUPLICATE, "Duplicate sales documents"),
    (SALES_DOCUMENTS_EXPORT, "Export / print sales invoices"),
    # Customers — legacy
    (CUSTOMERS_VIEW, "View customers (legacy)"),
    (CUSTOMERS_CREATE, "Create customers (legacy)"),
    (CUSTOMERS_UPDATE, "Update customers (legacy)"),
    (CUSTOMERS_DELETE, "Delete customers (legacy)"),
    # Customers — services
    (CUSTOMERS_MASTER_VIEW, "View customer master list"),
    (CUSTOMERS_MASTER_CREATE, "Create customers"),
    (CUSTOMERS_MASTER_UPDATE, "Update customers"),
    (CUSTOMERS_MASTER_DELETE, "Delete customers"),
    (CUSTOMERS_MASTER_IMPORT, "Import customers from Excel"),
    (CUSTOMERS_ACCOUNTS_VIEW, "View customer accounts"),
    (CUSTOMERS_SETTINGS_VIEW, "View customer settings"),
    (CUSTOMERS_SETTINGS_UPDATE, "Update customer settings"),
    # Accounting
    (ACCOUNTING_VIEW, "View accounting package"),
    (ACCOUNTING_ACCOUNTS_VIEW, "View chart of accounts"),
    (ACCOUNTING_ACCOUNTS_CREATE, "Create accounts"),
    (ACCOUNTING_ACCOUNTS_UPDATE, "Update accounts"),
    (ACCOUNTING_ACCOUNTS_DELETE, "Delete / deactivate accounts"),
    (ACCOUNTING_JOURNALS_VIEW, "View journal entries"),
    (ACCOUNTING_JOURNALS_CREATE, "Create journal entries"),
    (ACCOUNTING_JOURNALS_UPDATE, "Update journal entries"),
    (ACCOUNTING_JOURNALS_DELETE, "Delete journal entries"),
    (ACCOUNTING_CURRENCY_RATES_VIEW, "View currency rates"),
    (ACCOUNTING_CURRENCY_RATES_CREATE, "Create currency rates"),
    (ACCOUNTING_CURRENCY_RATES_UPDATE, "Update currency rates"),
    (ACCOUNTING_CURRENCY_RATES_DELETE, "Delete currency rates"),
    (ACCOUNTING_FISCAL_YEARS_VIEW, "View fiscal years"),
    (ACCOUNTING_FISCAL_YEARS_CREATE, "Create fiscal years"),
    (ACCOUNTING_FISCAL_YEARS_UPDATE, "Update fiscal years"),
    (ACCOUNTING_FISCAL_YEARS_OPEN_PERIOD, "Open accounting periods"),
    (ACCOUNTING_FISCAL_YEARS_CLOSE_PERIOD, "Close accounting periods"),
    (ACCOUNTING_FISCAL_YEARS_REOPEN_PERIOD, "Reopen accounting periods"),
    (ACCOUNTING_VOUCHER_BOOKS_VIEW, "View voucher books"),
    (ACCOUNTING_VOUCHER_BOOKS_CREATE, "Create voucher books"),
    (ACCOUNTING_VOUCHER_BOOKS_UPDATE, "Update voucher books"),
    (ACCOUNTING_VOUCHER_BOOKS_DELETE, "Delete voucher books"),
    (ACCOUNTING_REPORTS_VIEW, "View accounting reports"),
    # Receipts & Payments
    (RECEIPTS_VIEW, "View receipts"),
    (RECEIPTS_CREATE, "Create receipts"),
    (RECEIPTS_UPDATE, "Update receipts"),
    (RECEIPTS_POST, "Post receipts"),
    (RECEIPTS_CANCEL, "Cancel receipts"),
    (PAYMENTS_VIEW, "View payments"),
    (PAYMENTS_CREATE, "Create payments"),
    (PAYMENTS_UPDATE, "Update payments"),
    (PAYMENTS_POST, "Post payments"),
    (PAYMENTS_CANCEL, "Cancel payments"),
    (RECEIPTS_PAYMENTS_REPORTS_VIEW, "View receipts & payments reports"),
    (RECEIPTS_PAYMENTS_REPORTS_EXPORT, "Export receipts & payments reports"),
    (RECEIPTS_PAYMENTS_SYNC, "Sync receipts & payments"),
    # Reports
    (REPORTS_VIEW, "View reports package (legacy)"),
    (REPORTS_SALES_PERIOD_VIEW, "View sales period report"),
    (REPORTS_SALES_PERIOD_EXPORT, "Export sales period report"),
    (REPORTS_ACCOUNT_STATEMENT_VIEW, "View account statement report"),
    (REPORTS_ACCOUNT_STATEMENT_EXPORT, "Export account statement report"),
    (REPORTS_TRIAL_BALANCE_VIEW, "View trial balance report"),
    (REPORTS_TRIAL_BALANCE_EXPORT, "Export trial balance report"),
    (REPORTS_JOURNAL_BOOK_VIEW, "View journal book report"),
    (REPORTS_JOURNAL_BOOK_EXPORT, "Export journal book report"),
    # Settings / sync / devices
    (SETTINGS_VIEW, "View settings"),
    (SETTINGS_UPDATE, "Update settings"),
    (SYNC_VIEW, "View sync status"),
    (SYNC_EXECUTE, "Execute synchronization"),
    (DEVICES_VIEW, "View devices"),
    (DEVICES_REVOKE, "Revoke devices"),
)

# entity_type + operation → required permission (sync push)
# Prefer service-level codes; legacy codes remain accepted via aliases in authz.
SYNC_ENTITY_PERMISSIONS: dict[tuple[str, str], str] = {
    ("product", "create"): INVENTORY_PRODUCTS_CREATE,
    ("product", "update"): INVENTORY_PRODUCTS_UPDATE,
    ("product", "delete"): INVENTORY_PRODUCTS_DELETE,
    ("inventory_item", "create"): INVENTORY_STOCK_COUNT_ADJUST,
    ("inventory_item", "update"): INVENTORY_STOCK_COUNT_ADJUST,
    ("inventory_item", "delete"): INVENTORY_STOCK_COUNT_CLEAR,
    ("customer", "create"): CUSTOMERS_MASTER_CREATE,
    ("customer", "update"): CUSTOMERS_MASTER_UPDATE,
    ("customer", "delete"): CUSTOMERS_MASTER_DELETE,
    ("sale", "create"): SALES_DOCUMENTS_CREATE,
    ("sale", "update"): SALES_DOCUMENTS_UPDATE,
    ("sale", "delete"): SALES_DOCUMENTS_DELETE,
    ("account", "create"): ACCOUNTING_ACCOUNTS_CREATE,
    ("account", "update"): ACCOUNTING_ACCOUNTS_UPDATE,
    ("account", "delete"): ACCOUNTING_ACCOUNTS_DELETE,
    ("journal_entry", "create"): ACCOUNTING_JOURNALS_CREATE,
    ("journal_entry", "update"): ACCOUNTING_JOURNALS_UPDATE,
    ("journal_entry", "delete"): ACCOUNTING_JOURNALS_DELETE,
    ("currency_rate", "create"): ACCOUNTING_CURRENCY_RATES_CREATE,
    ("currency_rate", "update"): ACCOUNTING_CURRENCY_RATES_UPDATE,
    ("currency_rate", "delete"): ACCOUNTING_CURRENCY_RATES_DELETE,
    ("fiscal_year", "create"): ACCOUNTING_FISCAL_YEARS_CREATE,
    ("fiscal_year", "update"): ACCOUNTING_FISCAL_YEARS_UPDATE,
    ("fiscal_year", "delete"): ACCOUNTING_FISCAL_YEARS_UPDATE,
    ("financial_transaction", "create"): RECEIPTS_CREATE,
    ("financial_transaction", "update"): RECEIPTS_UPDATE,
    ("financial_transaction", "delete"): RECEIPTS_CANCEL,
}

# Legacy codes that satisfy a newer service-level requirement (and vice versa).
PERMISSION_ALIASES: dict[str, tuple[str, ...]] = {
    INVENTORY_STOCK_COUNT_VIEW: (INVENTORY_VIEW,),
    INVENTORY_STOCK_COUNT_ADJUST: (INVENTORY_ADJUST, INVENTORY_UPDATE),
    INVENTORY_STOCK_COUNT_IMPORT: (INVENTORY_CREATE, INVENTORY_UPDATE),
    INVENTORY_STOCK_COUNT_CLEAR: (INVENTORY_DELETE,),
    INVENTORY_PRODUCTS_VIEW: (PRODUCTS_VIEW,),
    INVENTORY_PRODUCTS_CREATE: (PRODUCTS_CREATE,),
    INVENTORY_PRODUCTS_UPDATE: (PRODUCTS_UPDATE,),
    INVENTORY_PRODUCTS_DELETE: (PRODUCTS_DELETE,),
    INVENTORY_PRODUCTS_IMPORT: (PRODUCTS_CREATE, PRODUCTS_UPDATE),
    SALES_DOCUMENTS_VIEW: (SALES_VIEW,),
    SALES_DOCUMENTS_CREATE: (SALES_CREATE,),
    SALES_DOCUMENTS_UPDATE: (SALES_UPDATE,),
    SALES_DOCUMENTS_DELETE: (SALES_DELETE,),
    SALES_DOCUMENTS_POST: (SALES_POST,),
    SALES_DOCUMENTS_CANCEL: (SALES_CANCEL,),
    CUSTOMERS_MASTER_VIEW: (CUSTOMERS_VIEW,),
    CUSTOMERS_MASTER_CREATE: (CUSTOMERS_CREATE,),
    CUSTOMERS_MASTER_UPDATE: (CUSTOMERS_UPDATE,),
    CUSTOMERS_MASTER_DELETE: (CUSTOMERS_DELETE,),
    REPORTS_SALES_PERIOD_VIEW: (REPORTS_VIEW,),
    REPORTS_ACCOUNT_STATEMENT_VIEW: (REPORTS_VIEW,),
    REPORTS_TRIAL_BALANCE_VIEW: (REPORTS_VIEW,),
    REPORTS_JOURNAL_BOOK_VIEW: (REPORTS_VIEW,),
    # Reverse: holding a service code also satisfies legacy checks.
    INVENTORY_VIEW: (INVENTORY_STOCK_COUNT_VIEW,),
    INVENTORY_ADJUST: (INVENTORY_STOCK_COUNT_ADJUST,),
    PRODUCTS_VIEW: (INVENTORY_PRODUCTS_VIEW,),
    PRODUCTS_CREATE: (INVENTORY_PRODUCTS_CREATE,),
    PRODUCTS_UPDATE: (INVENTORY_PRODUCTS_UPDATE,),
    PRODUCTS_DELETE: (INVENTORY_PRODUCTS_DELETE,),
    SALES_VIEW: (SALES_DOCUMENTS_VIEW,),
    SALES_CREATE: (SALES_DOCUMENTS_CREATE,),
    SALES_UPDATE: (SALES_DOCUMENTS_UPDATE,),
    SALES_DELETE: (SALES_DOCUMENTS_DELETE,),
    SALES_POST: (SALES_DOCUMENTS_POST,),
    SALES_CANCEL: (SALES_DOCUMENTS_CANCEL,),
    CUSTOMERS_VIEW: (CUSTOMERS_MASTER_VIEW,),
    CUSTOMERS_CREATE: (CUSTOMERS_MASTER_CREATE,),
    CUSTOMERS_UPDATE: (CUSTOMERS_MASTER_UPDATE,),
    CUSTOMERS_DELETE: (CUSTOMERS_MASTER_DELETE,),
    REPORTS_VIEW: (
        REPORTS_SALES_PERIOD_VIEW,
        REPORTS_ACCOUNT_STATEMENT_VIEW,
        REPORTS_TRIAL_BALANCE_VIEW,
        REPORTS_JOURNAL_BOOK_VIEW,
    ),
}


def expand_permission_codes(codes: set[str]) -> set[str]:
    """Expand a permission set with bidirectional aliases."""
    expanded = set(codes)
    changed = True
    while changed:
        changed = False
        for code in list(expanded):
            for alias in PERMISSION_ALIASES.get(code, ()):
                if alias not in expanded:
                    expanded.add(alias)
                    changed = True
    return expanded


_INVENTORY_FULL = (
    INVENTORY_VIEW,
    INVENTORY_CREATE,
    INVENTORY_UPDATE,
    INVENTORY_DELETE,
    INVENTORY_ADJUST,
    PRODUCTS_VIEW,
    PRODUCTS_CREATE,
    PRODUCTS_UPDATE,
    PRODUCTS_DELETE,
    INVENTORY_STOCK_COUNT_VIEW,
    INVENTORY_STOCK_COUNT_ADJUST,
    INVENTORY_STOCK_COUNT_IMPORT,
    INVENTORY_STOCK_COUNT_EXPORT,
    INVENTORY_STOCK_COUNT_CLEAR,
    INVENTORY_PRODUCTS_VIEW,
    INVENTORY_PRODUCTS_CREATE,
    INVENTORY_PRODUCTS_UPDATE,
    INVENTORY_PRODUCTS_DELETE,
    INVENTORY_PRODUCTS_IMPORT,
    INVENTORY_PRODUCTS_BARCODE,
)

_SALES_FULL = (
    SALES_VIEW,
    SALES_CREATE,
    SALES_UPDATE,
    SALES_DELETE,
    SALES_POST,
    SALES_CANCEL,
    SALES_DOCUMENTS_VIEW,
    SALES_DOCUMENTS_CREATE,
    SALES_DOCUMENTS_UPDATE,
    SALES_DOCUMENTS_DELETE,
    SALES_DOCUMENTS_POST,
    SALES_DOCUMENTS_CANCEL,
    SALES_DOCUMENTS_DUPLICATE,
    SALES_DOCUMENTS_EXPORT,
)

_CUSTOMERS_FULL = (
    CUSTOMERS_VIEW,
    CUSTOMERS_CREATE,
    CUSTOMERS_UPDATE,
    CUSTOMERS_DELETE,
    CUSTOMERS_MASTER_VIEW,
    CUSTOMERS_MASTER_CREATE,
    CUSTOMERS_MASTER_UPDATE,
    CUSTOMERS_MASTER_DELETE,
    CUSTOMERS_MASTER_IMPORT,
    CUSTOMERS_ACCOUNTS_VIEW,
    CUSTOMERS_SETTINGS_VIEW,
    CUSTOMERS_SETTINGS_UPDATE,
)

_ACCOUNTING_FULL = (
    ACCOUNTING_VIEW,
    ACCOUNTING_ACCOUNTS_VIEW,
    ACCOUNTING_ACCOUNTS_CREATE,
    ACCOUNTING_ACCOUNTS_UPDATE,
    ACCOUNTING_ACCOUNTS_DELETE,
    ACCOUNTING_JOURNALS_VIEW,
    ACCOUNTING_JOURNALS_CREATE,
    ACCOUNTING_JOURNALS_UPDATE,
    ACCOUNTING_JOURNALS_DELETE,
    ACCOUNTING_CURRENCY_RATES_VIEW,
    ACCOUNTING_CURRENCY_RATES_CREATE,
    ACCOUNTING_CURRENCY_RATES_UPDATE,
    ACCOUNTING_CURRENCY_RATES_DELETE,
    ACCOUNTING_FISCAL_YEARS_VIEW,
    ACCOUNTING_FISCAL_YEARS_CREATE,
    ACCOUNTING_FISCAL_YEARS_UPDATE,
    ACCOUNTING_FISCAL_YEARS_OPEN_PERIOD,
    ACCOUNTING_FISCAL_YEARS_CLOSE_PERIOD,
    ACCOUNTING_FISCAL_YEARS_REOPEN_PERIOD,
    ACCOUNTING_VOUCHER_BOOKS_VIEW,
    ACCOUNTING_VOUCHER_BOOKS_CREATE,
    ACCOUNTING_VOUCHER_BOOKS_UPDATE,
    ACCOUNTING_VOUCHER_BOOKS_DELETE,
    ACCOUNTING_REPORTS_VIEW,
)

_REPORTS_FULL = (
    REPORTS_VIEW,
    REPORTS_SALES_PERIOD_VIEW,
    REPORTS_SALES_PERIOD_EXPORT,
    REPORTS_ACCOUNT_STATEMENT_VIEW,
    REPORTS_ACCOUNT_STATEMENT_EXPORT,
    REPORTS_TRIAL_BALANCE_VIEW,
    REPORTS_TRIAL_BALANCE_EXPORT,
    REPORTS_JOURNAL_BOOK_VIEW,
    REPORTS_JOURNAL_BOOK_EXPORT,
)

_RECEIPTS_PAYMENTS_FULL = (
    RECEIPTS_VIEW,
    RECEIPTS_CREATE,
    RECEIPTS_UPDATE,
    RECEIPTS_POST,
    RECEIPTS_CANCEL,
    PAYMENTS_VIEW,
    PAYMENTS_CREATE,
    PAYMENTS_UPDATE,
    PAYMENTS_POST,
    PAYMENTS_CANCEL,
    RECEIPTS_PAYMENTS_REPORTS_VIEW,
    RECEIPTS_PAYMENTS_REPORTS_EXPORT,
    RECEIPTS_PAYMENTS_SYNC,
)

# Default system role → permission codes
SYSTEM_ROLE_PERMISSIONS: dict[str, tuple[str, ...]] = {
    "Super Admin": tuple(code for code, _ in ALL_PERMISSIONS),
    "Company Admin": tuple(code for code, _ in ALL_PERMISSIONS if not code.startswith("platform.")),
    "Accountant": (
        COMPANIES_VIEW,
        CUSTOMERS_VIEW,
        CUSTOMERS_MASTER_VIEW,
        CUSTOMERS_ACCOUNTS_VIEW,
        SALES_VIEW,
        SALES_DOCUMENTS_VIEW,
        *_ACCOUNTING_FULL,
        *_RECEIPTS_PAYMENTS_FULL,
        *_REPORTS_FULL,
        SETTINGS_VIEW,
        SYNC_VIEW,
        SYNC_EXECUTE,
        DEVICES_VIEW,
    ),
    "Sales Manager": (
        COMPANIES_VIEW,
        PRODUCTS_VIEW,
        INVENTORY_PRODUCTS_VIEW,
        *_CUSTOMERS_FULL,
        *_SALES_FULL,
        # Sale-originated journals must push/pull with the invoice.
        ACCOUNTING_JOURNALS_CREATE,
        ACCOUNTING_JOURNALS_UPDATE,
        ACCOUNTING_JOURNALS_DELETE,
        RECEIPTS_VIEW,
        RECEIPTS_CREATE,
        RECEIPTS_UPDATE,
        RECEIPTS_POST,
        RECEIPTS_CANCEL,
        RECEIPTS_PAYMENTS_REPORTS_VIEW,
        REPORTS_VIEW,
        REPORTS_SALES_PERIOD_VIEW,
        REPORTS_SALES_PERIOD_EXPORT,
        SYNC_VIEW,
        SYNC_EXECUTE,
        DEVICES_VIEW,
    ),
    "Sales Employee": (
        COMPANIES_VIEW,
        PRODUCTS_VIEW,
        INVENTORY_PRODUCTS_VIEW,
        CUSTOMERS_VIEW,
        CUSTOMERS_MASTER_VIEW,
        CUSTOMERS_MASTER_CREATE,
        CUSTOMERS_CREATE,
        SALES_VIEW,
        SALES_CREATE,
        SALES_DOCUMENTS_VIEW,
        SALES_DOCUMENTS_CREATE,
        # Sale-originated journals must push/pull with the invoice.
        ACCOUNTING_JOURNALS_CREATE,
        ACCOUNTING_JOURNALS_UPDATE,
        ACCOUNTING_JOURNALS_DELETE,
        RECEIPTS_VIEW,
        RECEIPTS_CREATE,
        SYNC_VIEW,
        SYNC_EXECUTE,
        DEVICES_VIEW,
    ),
    "Inventory Manager": (
        COMPANIES_VIEW,
        *_INVENTORY_FULL,
        REPORTS_VIEW,
        SYNC_VIEW,
        SYNC_EXECUTE,
        DEVICES_VIEW,
    ),
    "Inventory Employee": (
        COMPANIES_VIEW,
        PRODUCTS_VIEW,
        INVENTORY_PRODUCTS_VIEW,
        INVENTORY_VIEW,
        INVENTORY_STOCK_COUNT_VIEW,
        INVENTORY_STOCK_COUNT_ADJUST,
        INVENTORY_CREATE,
        INVENTORY_UPDATE,
        INVENTORY_ADJUST,
        SYNC_VIEW,
        SYNC_EXECUTE,
        DEVICES_VIEW,
    ),
    "Viewer": (
        COMPANIES_VIEW,
        PRODUCTS_VIEW,
        INVENTORY_PRODUCTS_VIEW,
        INVENTORY_VIEW,
        INVENTORY_STOCK_COUNT_VIEW,
        CUSTOMERS_VIEW,
        CUSTOMERS_MASTER_VIEW,
        SALES_VIEW,
        SALES_DOCUMENTS_VIEW,
        ACCOUNTING_VIEW,
        ACCOUNTING_ACCOUNTS_VIEW,
        ACCOUNTING_JOURNALS_VIEW,
        ACCOUNTING_REPORTS_VIEW,
        RECEIPTS_VIEW,
        PAYMENTS_VIEW,
        RECEIPTS_PAYMENTS_REPORTS_VIEW,
        *_REPORTS_FULL,
        SETTINGS_VIEW,
        SYNC_VIEW,
        DEVICES_VIEW,
    ),
}
