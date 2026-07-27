# Phase 13 — Reporting

## Phase Number

13

## Phase Name

Reporting

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 13. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_13_CUSTOMERS.md`; its canonical identity is Phase 13 — Reporting. Implement only this canonical phase.

## Objective

Implement accurate, permission-scoped operational and financial reporting with asynchronous export capabilities through report-service.

## Scope

- A documented initial report catalog covering orders, payments, expenses, customers, and service activity supported by existing data.
- Read models/projections, tenant/branch/date filters, timezone and money semantics, API contracts, and export jobs.
- CSV and, only if supported reliably, PDF export with file-storage integration.
- Responsive web report filters, tables, charts where useful, export status, and downloads.

## Out of Scope

- General-purpose BI builder, arbitrary database queries, statutory accounting statements, forecasts, machine learning, and unsupported tax reports.
- Changing source-domain records from reports.
- Synchronous generation of unbounded exports.

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

- Phases 05-09 source domains and events.
- Phase 11 file storage, Phase 15-compatible jobs, and Phase 04 permissions.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- report-service owns reporting projections and export artifacts; domain services remain authoritative.
- Define report semantics and reconciliation equations before implementation, especially timezone boundaries, status inclusion, refunds, and expense corrections.
- Use event-driven projections plus repeatable reconciliation/rebuild jobs; never join directly across other services' private collections in request paths.
- Exports are immutable artifacts with parameters, source watermark, checksum, expiry, and authorization metadata.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Define the initial report catalog, measures, dimensions, filters, inclusion/exclusion rules, timezone/currency behavior, and reconciliation expectations.
5. Implement report-service projections, event consumers, inbox deduplication, indexes, APIs, and freshness/watermark metadata.
6. Implement bounded synchronous summaries and asynchronous detailed exports with progress, cancellation, retry, expiry, and secure file delivery.
7. Implement CSV formula-injection protection, stable column schemas, locale-neutral machine values, and user-friendly display formatting.
8. Build accessible web report navigation, filter controls, summary cards, tables, fit-for-purpose charts, export history/status, and downloads.
9. Implement reconciliation and rebuild procedures against source-service APIs/events with discrepancy metrics.
10. Test financial precision, timezone boundaries, late/out-of-order events, refunds/corrections, large exports, and permissions.
11. Update report-service, report catalog, API, event, export, frontend, and operations documentation.
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

- Use integer minor units internally and explicit currency; never aggregate incompatible currencies into an unlabeled total.
- Every query/export requires tenant scope and enforces branch/report permissions before work is queued.
- Return report definition version, data watermark/freshness, timezone, currency, and applied filters.
- Cap date ranges and row counts or require asynchronous export.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Display applied timezone, currency, freshness, filters, empty states, and partial/unavailable-data warnings.
- Charts must have accessible table/text equivalents and must not imply unsupported precision.
- Export polling/subscription must handle expiry, failure, cancellation, and permission changes.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Prevent cross-tenant/branch reporting, inference through aggregates, export URL sharing, CSV formula injection, and stored XSS.
- Authorize both export creation and download; use short-lived file access and tenant-bound metadata.
- Audit report/export access according to data sensitivity and redact personal data unless the report explicitly requires it.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Use reporting projections and compound indexes aligned to filters; validate with explain plans.
- Keep large exports off request workers, stream generation to storage, and enforce concurrency/fairness quotas.
- Establish latency targets for dashboards/summaries and throughput/maximum size for exports.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Unit/property-test aggregation, money precision, timezone boundaries, inclusion rules, refunds/corrections, and CSV safety.
- Integration-test event projections, late/out-of-order events, reconciliation, rebuild, export jobs, storage, and expiry.
- Run permission/isolation and aggregate-inference tests.
- End-to-end test web reports, accessible chart alternatives, export lifecycle, and representative golden datasets.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Document every report's business definition, fields, filters, equations, source events, freshness, limitations, APIs, and export schema.
- Provide reconciliation, rebuild, failed-export, and data-correction runbooks.
- Record projection and export architecture decisions in ADRs.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Report-service projections, documented report catalog, query APIs, reconciliation, and export jobs.
- Accessible web reports and secure export delivery.
- Golden datasets, financial/timezone correctness, isolation, performance, and end-to-end tests.
- A completed Phase 13 report at ERP-PLANNING/phase-completions/PHASE_13_REPORTING_COMPLETION.md.

## Acceptance Criteria

- [ ] Report results reconcile to authoritative source fixtures and documented equations.
- [ ] Every response/export declares filters, timezone, currency, definition version, and freshness.
- [ ] Large exports run asynchronously, are bounded, downloadable only by authorized users, and expire safely.
- [ ] CSV exports resist formula injection and preserve precise machine values.
- [ ] Reporting correctness, isolation, accessibility, and performance tests pass.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_13_REPORTING_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 13 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 14 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
