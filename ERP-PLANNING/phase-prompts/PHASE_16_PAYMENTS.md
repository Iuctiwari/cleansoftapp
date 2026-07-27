# Phase 16 — Audit Logging

## Phase Number

16

## Phase Name

Audit Logging

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 16. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_16_PAYMENTS.md`; its canonical identity is Phase 16 — Audit Logging. Implement only this canonical phase.

## Objective

Implement tamper-evident, tenant-aware audit capture, storage, query, retention hooks, and privileged access through audit-service.

## Scope

- Versioned audit event contract, ingestion, append-only storage, integrity chaining/signing strategy, sensitive-field redaction, query APIs, and export integration.
- Capture of authentication, tenant, branch, user/RBAC, customer, catalog, order, payment, expense, notification, file, search/report, and job administration actions as appropriate.
- Audit viewer integration contract for Phase 17.
- Retention/legal-hold hooks and operational integrity verification.

## Out of Scope

- General application debug logs, SIEM replacement, full legal/compliance certification, and mutable correction of audit history.
- Recording secrets, credentials, tokens, file contents, or unrestricted before/after personal data.
- End-user analytics.

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

- All domain and infrastructure phases through Phase 15.
- Phase 02 tenant context, Phase 04 permissions, and shared event/correlation contracts.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- audit-service owns audit records. Producers emit a minimal versioned audit event through a durable path and never write the audit collection directly.
- Audit records are append-only and include actor type/id, tenant/branch context, action, resource type/id, outcome, time, correlation, source, schema version, and redacted changes.
- Integrity controls must detect modification/deletion; they do not replace database access controls, backups, or external archival.
- Platform and tenant audit access are separate permission domains.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Define the audit taxonomy, required fields, data-classification/redaction rules, integrity model, retention/hold hooks, access policy, and source coverage matrix.
5. Implement audit-service ingestion with schema validation, idempotency, ordering metadata, append-only persistence, indexes, and outbox/inbox reliability.
6. Implement tamper-evidence verification and a scheduled integrity-check job with alerting and operator procedures.
7. Integrate standardized audit emission across gateway, services, job controls, file access, reports/exports, and privileged configuration changes.
8. Implement tenant/platform-scoped query APIs with bounded filters, pagination, secure export handoff, and no mutation endpoints.
9. Backfill only audit information available from reliable existing histories; do not fabricate actors or changes.
10. Test redaction, event loss/duplication, tamper detection, clock/order behavior, query isolation, and high-volume ingestion.
11. Update audit-service, taxonomy, source coverage, API, security, retention, integrity, and incident documentation.
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

- Audit ingestion must be idempotent by event ID and resilient to duplicate/out-of-order delivery.
- No public update/delete endpoint may exist for audit records; retention deletion uses a separately authorized, recorded, policy-driven process.
- Normalize timestamps in UTC while preserving source time metadata when needed.
- Query endpoints require bounded ranges, indexed filters, permission checks, and redacted response projections.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- No full viewer is required until Phase 17.
- Provide typed contracts and, if needed for validation, a minimal internal view that never bypasses audit-query permissions or redaction.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Redact/hide passwords, tokens, authorization headers, cookies, reset links, payment secrets, file contents, and excessive personal data at the producer and consumer.
- Protect audit encryption keys/integrity secrets through environment secret references and rotation design.
- Alert on integrity failure, ingestion lag, source coverage gaps, unauthorized query attempts, and disabled producers.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Design append-heavy indexes for tenant/time, actor/time, resource/time, action/outcome, and integrity traversal without over-indexing.
- Buffer and batch ingestion safely while preserving durability and bounded memory.
- Archive/query older records according to documented retention tiers without blocking current writes.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Unit-test taxonomy mapping, redaction, canonical serialization, integrity chaining/signing, retention decisions, and permissions.
- Integration-test ingestion, duplicate/out-of-order events, source adapters, queries, export handoff, and integrity checks.
- Tamper with test records to prove detection and alert behavior.
- Run coverage-matrix tests ensuring each high-risk operation emits success and failure audit records.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Complete audit taxonomy, schema, source coverage matrix, redaction, retention/legal hold, access roles, integrity model, APIs, alerts, and incident runbooks.
- Record append-only storage and integrity-control choices in ADRs.
- Document explicit non-guarantees and any unavoidable event-loss window.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Audit-service ingestion, append-only storage, tamper evidence, queries, and scheduled verification.
- Standardized audit emission across completed platform capabilities.
- Coverage, tamper, isolation, redaction, load, and recovery tests.
- A completed Phase 16 report at ERP-PLANNING/phase-completions/PHASE_16_AUDIT_LOGGING_COMPLETION.md.

## Acceptance Criteria

- [ ] All high-risk operations in the coverage matrix emit redacted, attributable success/failure audit records.
- [ ] Audit records cannot be mutated through application APIs and test tampering is detected.
- [ ] Tenant users cannot query platform or other-tenant audit data.
- [ ] Duplicate events do not duplicate records and ingestion lag is observable.
- [ ] Retention, integrity, redaction, isolation, and load tests pass.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_16_AUDIT_LOGGING_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 16 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 17 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
