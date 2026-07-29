# Phase 09 Plan — Catalog

## Scope

Service/item categories, services, codes, descriptions, duration, lifecycle, branch availability, price types, currency, tax/discount inputs, effective pricing, pickers/search, and historical quote snapshots.

## Contracts

- **Consumes:** Tenant settings/entitlement, Branch/User access, `SVC-AUDIT-001`.
- **Produces:** `SVC-CATALOG-001`, `SVC-CATALOG-002`, `SVC-CATALOG-003`, `EVT-CATALOG-CHANGED-001`.

## Acceptance criteria

1. `FR-CATALOG-01`: authorized catalog lifecycle and branch availability work.
2. `FR-CATALOG-02`: pricing/tax/discount inputs are server validated under approved policy.
3. `FR-CATALOG-03`: order picker returns only active branch-available entries.
4. `FR-CATALOG-04`: quote snapshots do not change with later catalog updates.
5. `FR-CATALOG-05`: bounded tenant-scoped search uses approved indexes.

## Out

Order totals/history, inventory, appointments, loyalty/promotions, invented tax/discount policy.
