---
trigger: always_on
---

# NEXABIZ TENANCY RULE

## 1. COMPANY SCOPE

NexaBiz is multi-company.

Every company-owned business operation must execute inside an authoritative active company context.

---

## 2. ACTIVE COMPANY CONTEXT

The application must maintain explicit:

- active company
- active user
- session scope
- device context where required

---

## 3. NO ARBITRARY COMPANY IDS

Presentation code must not be allowed to select arbitrary company IDs and thereby bypass scope.

Repositories must obtain or validate company scope through the approved tenant context.

---

## 4. REPOSITORY SCOPE

Every company-scoped query must enforce company ownership.

Forbidden:

```sql
SELECT * FROM customers WHERE id = ?
```

when the operation requires company scope.

Required conceptual condition:

```text
id = ?
AND company_id = activeCompanyId
```

---

## 5. CROSS-COMPANY REFERENCES

A company A entity must never reference a company B entity.

Validate:

- direct relationships
- imported records
- synchronization
- accounting mappings
- inventory
- customers
- suppliers
- cash registers

---

## 6. CACHE ISOLATION

Cached state must include company scope.

Switching companies must clear or reinitialize company-sensitive state.

---

## 7. ACCOUNTING ISOLATION

Accounting queries, journals, balances, reports and posting rules must preserve company scope.

---

## 8. SYNC ISOLATION

Synchronization identities and operations must be company-safe.

No operation from company A may be applied to company B.

---

## 9. PERMISSIONS

Permissions must be evaluated against:

```text
User
+
Company
+
Role/Permission
+
Resource
+
Operation
```

Do not use a global permission result for company-scoped authorization.

---

## 10. SYSTEM SCOPE

System administration may legitimately operate outside a company scope.

Such operations must be explicitly classified as system-scoped.

Never use missing company scope as an accidental bypass.

---

## 11. COMPANY SWITCH

Company switching must:

1. validate membership
2. change active context
3. invalidate company-sensitive caches
4. recreate/reload scoped state
5. prevent stale previous-company data from remaining authoritative


---