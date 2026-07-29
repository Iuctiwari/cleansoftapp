# Phase 18 Build Brief — Testing and Security Hardening

## Objective

Execute the existing Testing Strategy against real running code. This phase re-homes the substantive legacy Security Hardening and Comprehensive Testing prompts that were stored under conflicting filenames.

## Required suites

- Unit: calculations, permissions, lifecycle, validation, retry.
- Contract: all 58 `SVC-*`, 28 `EVT-*`, gateway/mobile compatibility.
- Persistence: every `DATA-MODEL.md` index, transaction, concurrency, idempotency, immutable/deletion rule.
- API: every route/method/gate/request/response/error in `API-CONTRACTS.md`.
- Isolation: two tenants, multiple branches across CRUD/search/cache/events/jobs/files/exports/recovery/errors.
- Financial: snapshots, rounding policy, duplicate/partial/refund/reconcile/register/report.
- Security: auth replay/lockout/reset, RBAC escalation, injection/IDOR/mass assignment, rate limit, secret/redaction, file/callback/dependencies.
- Resilience/recovery/performance/mobile/accessibility exactly as `TESTING-STRATEGY.md`.

## Workflow

1. Verify real prerequisites and environments.
2. Build trace matrix from phase acceptance criteria.
3. Run exact commands; retain outputs/evidence.
4. Classify defects by severity/owner.
5. Remediate only explicitly authorized in-scope defects; otherwise report.
6. Re-run affected suites and record residual risk.
7. Create `03-audit.md` for each phase only when its real business logic exists, plus this phase's audit after testing logic/evidence exists.

## What not to build

No new feature, schema/contract change without ADR and upstream update, test bypass, synthetic success report, deployment, or acceptance of missing evidence as pass.

