# Phase 14 — Dashboard

## Phase Number

14

## Phase Name

Dashboard

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 14. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_14_SERVICES.md`; its canonical identity is Phase 14 — Dashboard. Implement only this canonical phase.

## Objective

Deliver a fast, permission-aware web dashboard composed from reporting read models without duplicating domain truth.

## Scope

- Role-aware operational and financial dashboard views using approved report definitions.
- Date, tenant, and branch filters; freshness indicators; summary metrics; trends; actionable operational queues; and navigation.
- A bounded dashboard aggregation API or report-service endpoints optimized for the dashboard.
- Responsive and accessible Flutter web layouts.

## Out of Scope

- Custom drag-and-drop dashboard builders, predictive analytics, arbitrary widgets, mobile dashboard parity, and new report semantics.
- Direct dashboard writes to domain collections.
- Hiding backend authorization behind client-only widget visibility.

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

- Phase 13 reporting definitions and projections.
- Phases 03-04 branch context and RBAC, plus relevant domain phases.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- Dashboard metrics reuse versioned report definitions/projections. Do not independently reimplement financial calculations in Flutter or the gateway.
- Return a composed, cacheable dashboard contract with per-widget authorization, freshness, and graceful partial failure.
- Cache keys include tenant, branch scope, permission/report version, filters, and data watermark.
- Client state is cleared on identity, tenant, or branch change.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Define role-oriented dashboard information architecture, widget contracts, metric definitions, filters, refresh behavior, and navigation targets.
5. Implement optimized dashboard query/composition endpoints with authorization, caching, timeouts, and partial-result semantics.
6. Build responsive web dashboard layouts for desktop/tablet/mobile widths with accessible cards, tables, charts, filters, and skeleton/error/empty states.
7. Implement explicit freshness and last-updated indicators, manual refresh, and stale-data messaging.
8. Ensure every action link is permission-checked at the destination and every metric links to a consistent detailed report/filter.
9. Add telemetry for widget latency, cache behavior, errors, and frontend rendering without leaking tenant data.
10. Load-test representative concurrent dashboard use and optimize the slowest verified paths.
11. Update dashboard API, metric mapping, frontend design, accessibility, cache, and operations documentation.
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

- Compose from report-service/read models through stable contracts; do not query private domain collections.
- Apply authorization before computing or returning a widget and avoid leaking hidden-widget counts.
- Bound each widget query and return explicit partial availability rather than failing the entire dashboard when safe.
- Version dashboard contracts and metric definitions.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Use a coherent design system, semantic heading order, keyboard access, contrast, responsive reflow, and chart alternatives.
- Do not use color alone for status or trend; support reduced motion and text scaling.
- Avoid layout shift, redundant fetches, and stale tenant/branch data.
- Persist only harmless preferences such as selected date range; never persist data payloads across sessions.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Treat widget visibility and drill-down access as separate backend permissions.
- Prevent cache-key collisions and response mixing across tenant, branch, role, and filter contexts.
- Sanitize labels and chart data and avoid exposing personal/financial details in telemetry.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Define and measure API p95, first meaningful render, refresh, payload size, cache hit rate, and widget query budgets.
- Parallelize independent bounded queries, cancel stale client requests, and lazy-load below-the-fold detail.
- Validate cache invalidation against reporting watermarks and permission changes.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Unit-test metric mapping, authorization, cache keys, partial failures, filters, and freshness.
- Integration-test dashboard/report contracts, permission changes, cache invalidation, and degraded dependencies.
- Widget/golden/accessibility-test responsive layouts, chart alternatives, and tenant/branch switching.
- End-to-end and load-test role-specific dashboards and drill-down consistency.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Document information architecture, each widget-to-report mapping, permissions, filters, freshness, caching, errors, and performance budgets.
- Add frontend component usage and accessibility guidance.
- Record dashboard composition and partial-failure decisions in an ADR.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Versioned dashboard query/composition contract.
- Responsive, accessible, role-aware Flutter web dashboard.
- Cache, authorization, performance, visual, accessibility, and end-to-end tests.
- A completed Phase 14 report at ERP-PLANNING/phase-completions/PHASE_14_DASHBOARD_COMPLETION.md.

## Acceptance Criteria

- [ ] Users see only authorized widgets and drill-down data for their tenant/branch context.
- [ ] Dashboard metrics match linked report definitions and fixtures.
- [ ] Partial dependency failures are clear and do not expose stale or cross-context data.
- [ ] Responsive/accessibility checks and performance budgets pass.
- [ ] Tenant/branch/permission changes invalidate cached client and server dashboard state.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_14_DASHBOARD_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 14 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 15 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
