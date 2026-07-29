# Phase 14 Plan — Search Projection

## Scope

Tenant/branch-safe event-fed search for approved Branch, User, Customer, Catalog, and Order fields; freshness, authorization facets, anti-existence leakage, rebuild/reconcile.

## Contracts

- **Consumes:** corresponding producer events, User/Branch access, `SVC-JOB-001/002`, `SVC-AUDIT-001` for recovery.
- **Produces:** `SVC-SEARCH-001`, `SVC-SEARCH-002`, `EVT-PROJECTION-LAG-001`.

## Acceptance criteria

1. `FR-SEARCH-01`: query/index is mandatory tenant scoped and branch aware.
2. `FR-SEARCH-02`: unauthorized fields/existence never leak.
3. `FR-SEARCH-03`: projection is rebuildable with observable freshness/checkpoint.

## Out

Authoritative domain writes, unbounded global search, future public search, silent stale results.

