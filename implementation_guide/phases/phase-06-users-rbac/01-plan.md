# Phase 06 Plan — Users and RBAC

## Scope

Staff profiles/membership, default/custom roles, permissions/overrides, invitation lifecycle, branch assignments, departments/designations, grant ceilings, access invalidation, and final-Owner protection.

## Contracts

- **Consumes:** `SVC-AUTH-004`, `SVC-AUTH-006`, `SVC-TENANT-002`, `SVC-TENANT-003`, `SVC-BRANCH-003`, `SVC-AUDIT-001`, `SVC-NOTIFY-001`.
- **Produces:** `SVC-USER-001`, `SVC-USER-002`, `SVC-USER-003`, `SVC-USER-004`, `SVC-USER-005`, `EVT-USER-CREATED-001`, `EVT-USER-ACCESS-CHANGED-001`, `EVT-USER-INVITED-001`.

## Acceptance criteria

1. `FR-USER-01`: authorized profile/role/permission/branch management works within scope.
2. `FR-USER-02`: invitation is scoped, expiring, single-use, rotated on resend, and credential-initialized.
3. `FR-USER-03`: deny default and grant ceiling block escalation.
4. `FR-USER-04`: access changes invalidate session/cache state.
5. `FR-USER-05`: final active Owner invariant survives concurrency.
6. `FR-USER-06`: searches exclude secret/unauthorized fields.

## Out

Unapproved MFA/custom-role plans/approval thresholds, customer/staff work modules, global user directory, plaintext invitation tokens.
