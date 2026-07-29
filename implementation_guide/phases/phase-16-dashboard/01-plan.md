# Phase 16 Plan — Dashboard

## Scope

Role-specific Owner/Manager/Staff/Cashier operational cards, tenant/branch/date filters, bounded refresh, freshness display, and report reconciliation.

## Contracts

- **Consumes:** `SVC-REPORT-001`, User/Branch context.
- **Produces:** `SVC-DASHBOARD-001`.

## Acceptance criteria

1. `FR-DASHBOARD-01`: cards/actions never exceed role and branch scope.
2. `FR-DASHBOARD-02`: freshness and bounded projection behavior are visible.
3. `FR-DASHBOARD-03`: KPI totals reconcile with governed reports.

## Out

Advanced analytics/forecasting, independent financial calculations, direct domain reads, Flutter widgets (Phase 17).

