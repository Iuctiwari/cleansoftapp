# Phase 02 Plan — Scheduler and Job Foundation

## Scope

Provide tenant-safe BullMQ job envelopes, scheduling, idempotency, bounded retry, dead-letter visibility, and authorized recovery.

## Contracts

- **Consumes:** platform/event context, `SVC-AUDIT-001`.
- **Produces:** `SVC-JOB-001`, `SVC-JOB-002`.
- Supports typed work for notification, export, reconciliation, retention, subscription, reminder, and file cleanup without owning business decisions.

## Acceptance criteria

1. `FR-JOB-01`: typed owner/version/scope/idempotency job can be scheduled and correlated.
2. `FR-JOB-02`: duplicate processing has one effect; retry is bounded; poison work reaches observable dead letter.
3. `FR-JOB-03`: recovery is authorized, reasoned, scoped, and audited.
4. `FR-JOB-04`: scheduler triggers only domain-owned contracts and cannot read private collections.

## Out

Domain job payload decisions, provider dispatch behavior, production concurrency/retention values pending `OQ-25`/`OQ-28`.

