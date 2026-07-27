# Phase 15 — Background Jobs

## Phase Number

15

## Phase Name

Background Jobs

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 15. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_15_ORDERS.md`; its canonical identity is Phase 15 — Background Jobs. Implement only this canonical phase.

## Objective

Harden scheduler-service and BullMQ into a shared, observable, idempotent background-job platform for notifications, storage, search, reporting, and maintenance.

## Scope

- Queue naming/versioning, job envelopes, scheduling, retries/backoff, idempotency, deduplication, timeouts, cancellation, dead-letter handling, replay, and graceful shutdown.
- Tenant-aware fairness, concurrency, rate limits, job health, metrics, structured logs, tracing, and operator controls.
- Migration of existing phase jobs onto the common conventions.
- Recurring cleanup/reconciliation/reindex/report jobs already required by prior phases.

## Out of Scope

- New ERP business workflows, arbitrary user-supplied code execution, and replacing domain-service ownership.
- A full external workflow engine unless approved requirements demand it.
- Unbounded retry or silent dead-letter deletion.

## Mandatory Reading

Read all of the following completely before implementation:

- ERP-PLANNING/PROJECT_BIBLE.md
- ERP-PLANNING/SOFTWARE_IDEA.md
- ERP-PLANNING/BUSINESS_REQUIREMENTS.md
- ERP-PLANNING/BUSINESS_GOALS.md
- ERP-PLANNING/TARGET_USERS.md
- ERP-PLANNING/FEATURE_LIST.md
- ERP-PLANNING/SYSTEM_ARCHITECTURE.md
- ERP-PLANNING/TECH_STACK.md
- ERP-PLANNING/MICROSERVICES.md
- ERP-PLANNING/MODULE_BREAKDOWN.md
- ERP-PLANNING/DATABASE_DESIGN.md
- ERP-PLANNING/DOMAIN_MODEL.md
- ERP-PLANNING/ENTITY_RELATIONSHIP.md
- ERP-PLANNING/API_DESIGN.md
- ERP-PLANNING/EVENT_ARCHITECTURE.md
- ERP-PLANNING/MULTI_TENANCY.md
- ERP-PLANNING/RBAC.md
- ERP-PLANNING/SECURITY_ARCHITECTURE.md
- ERP-PLANNING/CODING_GUIDELINES.md
- ERP-PLANNING/NAMING_CONVENTIONS.md
- ERP-PLANNING/DIRECTORY_GUIDE.md
- README.md, docs/README.md, apps/README.md, packages/README.md, and every README in a directory touched by this phase
- All earlier phase prompts, completion reports, ADRs, schemas, and tests that define dependencies for this phase
- The current git status and actual repository tree; current implementation and executable tests outrank stale prose

Also read the relevant application/package source, manifests, environment examples, Docker/infra assets, API/event/job schemas, and tests for every component named in this prompt.

## Dependencies

Verify all earlier completion reports, especially the direct dependencies listed below, before implementation. Do not assume a report is true when the repository or tests disagree.

- Phase 00 Redis/BullMQ foundation.
- Phase 10 notification jobs, Phase 11 storage jobs, Phase 12 indexing jobs, and Phase 13 export/reconciliation jobs.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- scheduler-service coordinates scheduling and shared operations; domain policy and handler ownership remain in the relevant service.
- Every job uses a versioned envelope with job ID, type, tenant context where applicable, correlation/causation IDs, attempt metadata, and bounded payload.
- Exactly-once delivery is not assumed. Handlers must be idempotent and side effects protected by inbox/idempotency records.
- Dead-letter and replay are first-class operational states with authorization and audit-ready records.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Define queue topology, naming, ownership, job envelope, compatibility/versioning, retry classes, timeout/cancellation, DLQ, replay, and retention standards.
5. Implement scheduler-service bootstrap, recurring schedule registry, leader-safe scheduling, health/readiness, and graceful worker shutdown.
6. Create shared producer/consumer libraries with schema validation, tenant context, correlation, telemetry, idempotency, and error classification.
7. Migrate notification, storage cleanup/scan, search rebuild/indexing, and report export/reconciliation jobs to the standard.
8. Implement safe operator APIs/CLI for inspection, retry, replay, cancellation, and pausing with explicit RBAC; do not expose raw secrets/payloads.
9. Implement metrics and alerts for depth, age, throughput, duration, failures, retries, DLQ, scheduler drift, and tenant fairness.
10. Run fault-injection tests for worker crashes, Redis interruptions, duplicate delivery, poison jobs, timeouts, shutdown, and clock drift.
11. Update scheduler-service, job catalog, runbooks, service integration, security, and monitoring documentation.
12. Run every required validation, inspect the diff for scope/security/data-isolation regressions, and remove generated junk or secrets.
13. Replace the instructional content in the matching completion report with factual evidence from this implementation.

Do not implement anything listed as out of scope. Do not leave simulated success paths, dormant insecure fallbacks, undocumented breaking changes, or unowned data.

## Coding Standards

- Preserve the monorepo boundaries: deployable applications remain in apps/*, reusable infrastructure in packages/*, planning in ERP-PLANNING/*, documentation in docs/*, and deployment assets in docker/* or infra/*.
- Use Node.js 22+, pnpm 10, strict TypeScript with no implicit any, NestJS dependency injection, class-validator/class-transformer DTO boundaries, and Mongoose repositories with explicit tenant-aware indexes.
- Keep controllers and transport handlers thin; place invariants in testable application/domain services and persistence details behind repositories/adapters.
- Use structured redacted logs, correlation/causation IDs, typed configuration validated at startup, stable machine-readable errors, UTC timestamps, opaque IDs, optimistic concurrency, and integer minor units for money.
- Use versioned API, event, job, and stored-data contracts. Producers and consumers must tolerate documented compatible evolution; breaking changes require migration and ADR.
- Use outbox/inbox and idempotency patterns for cross-service effects. Never reach into another service's private MongoDB collections.
- For Flutter, follow analyzer rules, feature-oriented modules, immutable typed models, accessible Material 3 components, go_router, centralized API/error handling, and no secrets in client assets.
- Format, lint, type-check, test, and build every touched workspace. Do not disable rules, skip tests, weaken types, or catch and ignore errors to obtain a green result.
- Preserve unrelated user changes. Make the smallest coherent changes for this phase and do not rename top-level repository directories.

## Backend Requirements

- Validate job schemas at producer and consumer boundaries and reject unknown versions safely.
- Use deterministic job/idempotency keys for repeatable operations and persist side-effect state where queue deduplication alone is insufficient.
- Classify errors as retryable, non-retryable, or operator-actionable with bounded exponential backoff and jitter.
- Do not place large files, credentials, or excessive personal data in Redis job payloads; pass secure references.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- No end-user feature UI is required.
- If operator controls are added to the web admin shell, they must expose redacted metadata, explicit confirmation, permission checks, and accessible state; detailed administration is completed in Phase 17.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Authenticate/encrypt Redis connections in non-local environments and isolate queue namespaces by environment.
- Treat job payloads as untrusted input, validate tenant context, prevent arbitrary handler selection, and redact sensitive fields.
- Restrict pause/replay/cancel operations and record actor, reason, scope, and outcome.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Set per-queue concurrency, rate limits, job/payload size limits, retention, and fairness controls from measured workloads.
- Prevent one tenant or poison job from starving other queues/tenants.
- Load-test throughput, queue lag, retry storms, and graceful scaling with representative jobs.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Unit-test envelopes, validation, error classification, idempotency, scheduling, redaction, and retry calculation.
- Integration-test producers/workers, recurring schedules, duplicates, timeouts, cancellation, DLQ/replay, and Redis recovery.
- Fault-inject worker termination, connection loss, poison messages, clock skew, and rolling deployment.
- Regression-test every migrated job's domain outcome and at-most-once side effect.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Document queue/job catalog, ownership, schemas, SLAs, retries, idempotency, concurrency, retention, DLQ, replay, metrics, alerts, and runbooks.
- Record scheduling ownership and job-versioning decisions in ADRs.
- Provide a checklist for every future job producer and handler.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Hardened scheduler-service and shared job producer/consumer libraries.
- Migrated background workloads, operator controls, telemetry, alerts, and runbooks.
- Fault-injection, idempotency, load, and regression tests.
- A completed Phase 15 report at ERP-PLANNING/phase-completions/PHASE_15_BACKGROUND_JOBS_COMPLETION.md.

## Acceptance Criteria

- [ ] Duplicate delivery, worker crash, or retry cannot duplicate protected side effects.
- [ ] Every job has bounded retry/timeout/retention and an observable terminal state.
- [ ] DLQ items are inspectable and replayable safely by authorized operators.
- [ ] Queue lag, failures, scheduler drift, and tenant starvation trigger documented telemetry/alerts.
- [ ] Fault-injection and representative load tests meet the documented objectives.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_15_BACKGROUND_JOBS_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 15 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 16 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
