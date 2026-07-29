# Phase 18 Plan — Cross-System Testing and Security Hardening

## Scope

Independent verification of every implemented `FR-*`, `SVC-*`, `EVT-*`, public route, entity/index/transaction boundary, tenant/branch isolation path, financial continuity, resilience, mobile behavior, threat control, dependency/file/provider security, and performance objective.

## Contracts

- **Consumes:** all contracts and implementation evidence from Phases 00–17.
- **Produces:** test/security evidence, defect catalogue, accepted-risk links, release-gate result; no product contract.

## Acceptance criteria

1. `FR-QUALITY-01`: every implemented requirement/contract/data invariant maps to objective evidence or explicit blocked/failing status.
2. `FR-QUALITY-02`: every applicable contract, isolation, state, idempotency, financial, resilience, security, recovery, performance, and mobile scenario executes.
3. `FR-QUALITY-03`: unavailable, skipped, blocked, or failed checks remain factual.
4. `FR-QUALITY-04`: every defect has severity, traceability, ownership, disposition, retest, and residual risk.
5. `FR-QUALITY-05`: stubs do not satisfy completion; real behavior is required.

## Out

Feature expansion, production deployment, weakening controls to pass tests, premature completion claims.
