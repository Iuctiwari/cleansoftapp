# Phase 08 Plan — Customers

## Scope

Tenant customer registration/search/profile/contact/address/preferences/notes, walk-in snapshot support, archive/restore, history view, and derived outstanding balance.

## Contracts

- **Consumes:** Branch/User access, `SVC-FILE-001/002`, `SVC-AUDIT-001`, Order/Payment events for balance.
- **Produces:** `SVC-CUSTOMER-001`, `SVC-CUSTOMER-002`, `SVC-CUSTOMER-003`, `SVC-CUSTOMER-004`, `EVT-CUSTOMER-CREATED-001`, `EVT-CUSTOMER-CHANGED-001`.

## Acceptance criteria

1. `FR-CUSTOMER-01`: tenant-scoped duplicate search occurs before create.
2. `FR-CUSTOMER-02`: persistent and lightweight walk-in paths are supported.
3. `FR-CUSTOMER-03`: authorized profile/address/preferences/note lifecycle works.
4. `FR-CUSTOMER-04`: balance is derived/reconcilable and not client editable.
5. `FR-CUSTOMER-05`: all paths are privacy and tenant scoped.
6. `FR-CUSTOMER-06`: order snapshot contract remains historically stable.

## Out

Loyalty/rewards (future), orders/payments ownership, notification dispatch, unresolved consent/deletion policy.
