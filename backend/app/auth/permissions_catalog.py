"""Stable permission codes used by authorization checks."""

from __future__ import annotations

# Platform-level
PLATFORM_COMPANIES_MANAGE = "platform.companies.manage"
PLATFORM_USERS_MANAGE = "platform.users.manage"

# Identity
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

# Domain
PRODUCTS_VIEW = "products.view"
PRODUCTS_CREATE = "products.create"
PRODUCTS_UPDATE = "products.update"
PRODUCTS_DELETE = "products.delete"

INVENTORY_VIEW = "inventory.view"
INVENTORY_CREATE = "inventory.create"
INVENTORY_UPDATE = "inventory.update"
INVENTORY_DELETE = "inventory.delete"
INVENTORY_ADJUST = "inventory.adjust"

CUSTOMERS_VIEW = "customers.view"
CUSTOMERS_CREATE = "customers.create"
CUSTOMERS_UPDATE = "customers.update"
CUSTOMERS_DELETE = "customers.delete"

SALES_VIEW = "sales.view"
SALES_CREATE = "sales.create"
SALES_UPDATE = "sales.update"
SALES_DELETE = "sales.delete"
SALES_POST = "sales.post"
SALES_CANCEL = "sales.cancel"

ACCOUNTING_VIEW = "accounting.view"
ACCOUNTING_ACCOUNTS_VIEW = "accounting.accounts.view"
ACCOUNTING_ACCOUNTS_CREATE = "accounting.accounts.create"
ACCOUNTING_ACCOUNTS_UPDATE = "accounting.accounts.update"
ACCOUNTING_JOURNALS_VIEW = "accounting.journals.view"
ACCOUNTING_JOURNALS_CREATE = "accounting.journals.create"

REPORTS_VIEW = "reports.view"

SETTINGS_VIEW = "settings.view"
SETTINGS_UPDATE = "settings.update"

SYNC_VIEW = "sync.view"
SYNC_EXECUTE = "sync.execute"

DEVICES_VIEW = "devices.view"
DEVICES_REVOKE = "devices.revoke"

ALL_PERMISSIONS: tuple[tuple[str, str], ...] = (
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
    (PRODUCTS_VIEW, "View products"),
    (PRODUCTS_CREATE, "Create products"),
    (PRODUCTS_UPDATE, "Update products"),
    (PRODUCTS_DELETE, "Delete products"),
    (INVENTORY_VIEW, "View inventory"),
    (INVENTORY_CREATE, "Create inventory items"),
    (INVENTORY_UPDATE, "Update inventory items"),
    (INVENTORY_DELETE, "Delete inventory items"),
    (INVENTORY_ADJUST, "Adjust inventory quantities"),
    (CUSTOMERS_VIEW, "View customers"),
    (CUSTOMERS_CREATE, "Create customers"),
    (CUSTOMERS_UPDATE, "Update customers"),
    (CUSTOMERS_DELETE, "Delete customers"),
    (SALES_VIEW, "View sales"),
    (SALES_CREATE, "Create sales"),
    (SALES_UPDATE, "Update sales"),
    (SALES_DELETE, "Delete sales"),
    (SALES_POST, "Post sales"),
    (SALES_CANCEL, "Cancel sales"),
    (ACCOUNTING_VIEW, "View accounting"),
    (ACCOUNTING_ACCOUNTS_VIEW, "View accounts"),
    (ACCOUNTING_ACCOUNTS_CREATE, "Create accounts"),
    (ACCOUNTING_ACCOUNTS_UPDATE, "Update accounts"),
    (ACCOUNTING_JOURNALS_VIEW, "View journals"),
    (ACCOUNTING_JOURNALS_CREATE, "Create journals"),
    (REPORTS_VIEW, "View reports"),
    (SETTINGS_VIEW, "View settings"),
    (SETTINGS_UPDATE, "Update settings"),
    (SYNC_VIEW, "View sync status"),
    (SYNC_EXECUTE, "Execute synchronization"),
    (DEVICES_VIEW, "View devices"),
    (DEVICES_REVOKE, "Revoke devices"),
)

# entity_type + operation → required permission
SYNC_ENTITY_PERMISSIONS: dict[tuple[str, str], str] = {
    ("product", "create"): PRODUCTS_CREATE,
    ("product", "update"): PRODUCTS_UPDATE,
    ("product", "delete"): PRODUCTS_DELETE,
    ("inventory_item", "create"): INVENTORY_CREATE,
    ("inventory_item", "update"): INVENTORY_UPDATE,
    ("inventory_item", "delete"): INVENTORY_DELETE,
    ("customer", "create"): CUSTOMERS_CREATE,
    ("customer", "update"): CUSTOMERS_UPDATE,
    ("customer", "delete"): CUSTOMERS_DELETE,
    ("sale", "create"): SALES_CREATE,
    ("sale", "update"): SALES_UPDATE,
    ("sale", "delete"): SALES_DELETE,
    ("account", "create"): ACCOUNTING_ACCOUNTS_CREATE,
    ("account", "update"): ACCOUNTING_ACCOUNTS_UPDATE,
    ("account", "delete"): ACCOUNTING_ACCOUNTS_UPDATE,
}

# Default system role → permission codes
SYSTEM_ROLE_PERMISSIONS: dict[str, tuple[str, ...]] = {
    "Super Admin": tuple(code for code, _ in ALL_PERMISSIONS),
    "Company Admin": (
        USERS_VIEW,
        USERS_CREATE,
        USERS_UPDATE,
        USERS_DELETE,
        USERS_MANAGE,
        ROLES_VIEW,
        ROLES_CREATE,
        ROLES_UPDATE,
        ROLES_DELETE,
        ROLES_MANAGE,
        PERMISSIONS_MANAGE,
        COMPANIES_VIEW,
        COMPANIES_UPDATE,
        PRODUCTS_VIEW,
        PRODUCTS_CREATE,
        PRODUCTS_UPDATE,
        PRODUCTS_DELETE,
        INVENTORY_VIEW,
        INVENTORY_CREATE,
        INVENTORY_UPDATE,
        INVENTORY_DELETE,
        INVENTORY_ADJUST,
        CUSTOMERS_VIEW,
        CUSTOMERS_CREATE,
        CUSTOMERS_UPDATE,
        CUSTOMERS_DELETE,
        SALES_VIEW,
        SALES_CREATE,
        SALES_UPDATE,
        SALES_DELETE,
        SALES_POST,
        SALES_CANCEL,
        ACCOUNTING_VIEW,
        ACCOUNTING_ACCOUNTS_VIEW,
        ACCOUNTING_ACCOUNTS_CREATE,
        ACCOUNTING_ACCOUNTS_UPDATE,
        ACCOUNTING_JOURNALS_VIEW,
        ACCOUNTING_JOURNALS_CREATE,
        REPORTS_VIEW,
        SETTINGS_VIEW,
        SETTINGS_UPDATE,
        SYNC_VIEW,
        SYNC_EXECUTE,
        DEVICES_VIEW,
        DEVICES_REVOKE,
    ),
    "Accountant": (
        COMPANIES_VIEW,
        CUSTOMERS_VIEW,
        SALES_VIEW,
        ACCOUNTING_VIEW,
        ACCOUNTING_ACCOUNTS_VIEW,
        ACCOUNTING_ACCOUNTS_CREATE,
        ACCOUNTING_ACCOUNTS_UPDATE,
        ACCOUNTING_JOURNALS_VIEW,
        ACCOUNTING_JOURNALS_CREATE,
        REPORTS_VIEW,
        SETTINGS_VIEW,
        SYNC_VIEW,
        SYNC_EXECUTE,
        DEVICES_VIEW,
    ),
    "Sales Manager": (
        COMPANIES_VIEW,
        PRODUCTS_VIEW,
        CUSTOMERS_VIEW,
        CUSTOMERS_CREATE,
        CUSTOMERS_UPDATE,
        SALES_VIEW,
        SALES_CREATE,
        SALES_UPDATE,
        SALES_DELETE,
        SALES_POST,
        SALES_CANCEL,
        REPORTS_VIEW,
        SYNC_VIEW,
        SYNC_EXECUTE,
        DEVICES_VIEW,
    ),
    "Sales Employee": (
        COMPANIES_VIEW,
        PRODUCTS_VIEW,
        CUSTOMERS_VIEW,
        CUSTOMERS_CREATE,
        SALES_VIEW,
        SALES_CREATE,
        SYNC_VIEW,
        SYNC_EXECUTE,
        DEVICES_VIEW,
    ),
    "Inventory Manager": (
        COMPANIES_VIEW,
        PRODUCTS_VIEW,
        PRODUCTS_CREATE,
        PRODUCTS_UPDATE,
        PRODUCTS_DELETE,
        INVENTORY_VIEW,
        INVENTORY_CREATE,
        INVENTORY_UPDATE,
        INVENTORY_DELETE,
        INVENTORY_ADJUST,
        REPORTS_VIEW,
        SYNC_VIEW,
        SYNC_EXECUTE,
        DEVICES_VIEW,
    ),
    "Inventory Employee": (
        COMPANIES_VIEW,
        PRODUCTS_VIEW,
        INVENTORY_VIEW,
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
        INVENTORY_VIEW,
        CUSTOMERS_VIEW,
        SALES_VIEW,
        ACCOUNTING_VIEW,
        ACCOUNTING_ACCOUNTS_VIEW,
        ACCOUNTING_JOURNALS_VIEW,
        REPORTS_VIEW,
        SETTINGS_VIEW,
        SYNC_VIEW,
        DEVICES_VIEW,
    ),
}
