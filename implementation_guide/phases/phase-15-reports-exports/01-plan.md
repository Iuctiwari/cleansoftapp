# Phase 15 Plan — Reports and Exports

## Scope

Tenant/branch/date/role-safe core reports, immutable transaction facts/rollups, lineage, freshness, CSV export, asynchronous job/file retrieval, reconciliation, and rebuild.

## Contracts

- **Consumes:** Branch/Customer/Order/Payment/Expense events, `SVC-FILE-*`, `SVC-JOB-*`, User access, Audit.
- **Produces:** `SVC-REPORT-001`, `SVC-REPORT-002`, `SVC-REPORT-003`, `EVT-PROJECTION-LAG-001`.

## Acceptance criteria

1. `FR-REPORT-01`: every query/export enforces scope and permission.
2. `FR-REPORT-02`: figures derive from immutable snapshots/rebuildable facts and reconcile.
3. `FR-REPORT-03`: CSV export and async size/date behavior work.
4. `FR-REPORT-04`: lineage and freshness are visible.
5. `FR-REPORT-05`: rebuild/replay is monitored, idempotent, and source-safe.

## Out

PDF (post-MVP), advanced analytics/forecasting, source mutations, unlimited ranges, invented retention.
