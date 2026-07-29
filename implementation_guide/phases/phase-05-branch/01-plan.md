# Phase 05 Plan — Branch

## Scope

Branch creation/profile/contact/address/hours/configuration, manager/default selection, lifecycle, active branch context, scoped listing, and onboarding bootstrap.

## Contracts

- **Consumes:** `SVC-TENANT-002`, `SVC-TENANT-003`, `SVC-AUDIT-001`; manager eligibility uses `SVC-USER-004` when available.
- **Produces:** `SVC-BRANCH-001`–`SVC-BRANCH-003`, `EVT-BRANCH-CREATED-001`, `EVT-BRANCH-STATUS-001`, `EVT-BRANCH-CONFIG-001`.

## Acceptance criteria

1. `FR-BRANCH-01`: authorized create/update covers profile, contact, address, hours, manager, config.
2. `FR-BRANCH-02`: tenant/branch identity and tenant-scoped uniqueness are protected.
3. `FR-BRANCH-03`: list/get/write are branch/tenant authorized.
4. `FR-BRANCH-04`: selection never expands allowed branches.
5. `FR-BRANCH-05`: inactive branch remains historical and rejects new operations.

## Out

User profile/RBAC implementation, order/payment/expense data, invented entitlement limits, destructive branch deletion.

