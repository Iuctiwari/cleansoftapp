# Phase 01 Plan — Audit Foundation

## Scope

Create the append-only audit owner and reliable obligation/query contracts before critical domain logic.

### In

- `SVC-AUDIT-001`, `SVC-AUDIT-002`, `EVT-AUDIT-RECORDED-001`.
- `auditRecords` schema/indexes and tenant/platform authorization separation.
- Idempotent record, safe summaries, query/export controls, retention tags, correlation.

### Out

- Operational logging, mutable audit records, unauthenticated audit writes, final retention/critical failure choices without `OQ-12`/`OQ-26`.

## Contracts

- **Consumes:** platform context/error/event primitives.
- **Produces:** `SVC-AUDIT-001`, `SVC-AUDIT-002`, `EVT-AUDIT-RECORDED-001`.

## Acceptance criteria

1. `FR-AUDIT-01`: critical obligation produces one append-only record.
2. `FR-AUDIT-02`: required context is stored and secrets/needless PII are rejected/redacted.
3. `FR-AUDIT-03`: platform and tenant queries cannot cross authorization boundaries.
4. `FR-AUDIT-04`: failure is explicit; no caller can silently ignore a required obligation.

