# Phase 10 Plan — Orders and Delivery

## Scope

Order creation/items/customer/catalog snapshots, authoritative totals, scoped numbering, assignment, expected completion, lifecycle/history, concurrency, cancellation, archive, pickup/home delivery, receiver/proof, and settlement projection.

## Contracts

- **Consumes:** `SVC-CUSTOMER-002`, `SVC-CATALOG-002`, `SVC-USER-002/005`, `SVC-BRANCH-002`, `SVC-TENANT-005`, `SVC-FILE-001/002`, `SVC-AUDIT-001`.
- **Produces:** `SVC-ORDER-001`, `SVC-ORDER-002`, `SVC-ORDER-003`, `SVC-ORDER-004`, `SVC-ORDER-005`, `SVC-ORDER-006`, `SVC-ORDER-007`, `EVT-ORDER-CREATED-001`, `EVT-ORDER-STATUS-001`, `EVT-ORDER-CANCELLED-001`, `EVT-DELIVERY-COMPLETED-001`.

## Acceptance criteria

1. `FR-ORDER-01`: authorized complete order input and assignment are persisted.
2. `FR-ORDER-02`: server calculations and immutable snapshots are authoritative.
3. `FR-ORDER-03`: scoped numbers remain unique under concurrency.
4. `FR-ORDER-04`: only allowed transitions occur with full history.
5. `FR-ORDER-05`: stale edits fail and cancellation produces corrections.
6. `FR-ORDER-06`: list/search/actions remain scoped.
7. `FR-ORDER-07`: later source changes cannot rewrite history.
8. `FR-DELIVERY-01`–`04`: governed pickup/delivery, policy check, proof, and assigned access work.

## Out

Payment ownership, route optimization, inventory, client totals, unresolved financial/delivery policy.
