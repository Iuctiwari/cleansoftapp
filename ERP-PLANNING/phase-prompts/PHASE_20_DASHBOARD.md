# Phase 20 — Comprehensive Testing and Quality Engineering

## Phase Number

20

## Phase Name

Comprehensive Testing and Quality Engineering

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 20. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_20_DASHBOARD.md`; its canonical identity is Phase 20 — Comprehensive Testing and Quality Engineering. Implement only this canonical phase.

## Objective

Establish and execute a complete, reliable, release-gating test strategy across backend services, contracts, events, web, mobile, security, performance, resilience, and data isolation.

## Scope

- Test pyramid/portfolio, fixtures/builders, isolated environments, deterministic clocks/IDs, contract tests, integration/E2E suites, coverage policy, flaky-test controls, and CI sharding.
- Functional and negative coverage for every completed phase.
- Performance, soak, resilience/fault-injection, accessibility, compatibility, backup/restore, and migration tests.
- Repair of defects discovered by these tests within existing documented behavior.

## Out of Scope

- New product features, arbitrary coverage-percentage gaming, masking flaky tests with retries, and changing requirements to make failures disappear.
- Production deployment.
- External certification claims.

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

- Phases 00-19 completed with their phase tests and contracts.
- Stable CI foundation and security gates.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- Prefer deterministic tests at the lowest effective layer while retaining real MongoDB, Redis, queue, storage, and network-boundary integration coverage.
- Consumer/provider contracts and event schemas are versioned release artifacts.
- Test isolation must include unique tenant/branch/test-run data and reliable cleanup without deleting non-test resources.
- Coverage is risk based: authorization, money, lifecycle, idempotency, tenancy, and recovery paths require stronger evidence than trivial accessors.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Create a requirement-to-test traceability matrix covering every phase acceptance criterion and high-risk security control.
5. Standardize backend unit/integration/contract/E2E harnesses, deterministic factories, clocks, test containers/dependencies, and cleanup.
6. Standardize Flutter unit/widget/golden/integration/accessibility harnesses for web and mobile.
7. Implement missing cross-service contract/event compatibility, tenant/branch isolation, RBAC matrix, money/property, idempotency, and concurrency tests.
8. Implement performance/load/soak scenarios, resilience/fault injection, migration/rollback, backup/restore, and degraded-dependency tests.
9. Integrate coverage, junit/results, screenshots, logs, performance baselines, and security artifacts into CI with quarantine-free flaky-test policy.
10. Fix verified defects in current scope and add regression tests without expanding features.
11. Update testing strategy, commands, environments, fixtures, traceability, performance baselines, and troubleshooting documentation.
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

- Test every public API's success, validation, authentication, authorization, isolation, concurrency, idempotency, pagination, rate-limit, and stable error behavior.
- Test every event/job schema, duplicate/out-of-order delivery, retry, DLQ, and backward compatibility.
- Use real dependency integration for critical persistence/queue/storage paths and mock only external provider boundaries.
- Verify clean migrations and supported rollback/forward-recovery paths against production-like data volumes.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Test route guards, permission states, tenant/branch switching, forms, network errors, session expiry, responsive layouts, accessibility, localization/timezone/money display, and critical user journeys.
- Keep golden tests intentional and reviewable; pair charts with semantic/accessibility assertions.
- Test web on supported browser matrix and mobile on documented Android/iOS targets or emulators/simulators available to CI.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Keep Phase 19 scanning and adversarial suites as mandatory gates.
- Ensure fixtures/logs/artifacts contain no real secrets or unnecessary personal data.
- Test destructive cleanup guards so test tooling cannot target production-like environments accidentally.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Define dataset sizes, workload models, SLO-aligned thresholds, warmup, percentiles, resource metrics, and regression tolerances.
- Measure gateway and critical domain paths, dashboard/search/report, queues, exports, and mobile/web performance.
- Store versioned baselines and fail CI/release gates on material regressions according to documented policy.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Run the complete clean-checkout pipeline at least twice to detect order dependence and flakiness.
- Run targeted load/soak, chaos/dependency-loss, backup/restore, security, accessibility, and compatibility suites.
- Record commands, environment, versions, duration, pass/fail/skipped counts, coverage by risk area, and artifact locations.
- No skipped release-critical test is accepted without documented owner, reason, compensating evidence, and expiry.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Complete docs/testing/README.md and ERP testing guidance with strategy, environments, commands, fixtures, matrices, thresholds, CI artifacts, flake policy, and defect workflow.
- Publish the acceptance-criteria traceability matrix and performance baselines.
- Document known platform constraints and any explicit test gap as a release risk.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Comprehensive automated test portfolio and deterministic test infrastructure.
- Traceability matrix, performance baselines, CI artifacts/gates, and defect regressions.
- Executed evidence for functional, contract, integration, E2E, security, accessibility, performance, resilience, migration, and restore tests.
- A completed Phase 20 report at ERP-PLANNING/phase-completions/PHASE_20_TESTING_COMPLETION.md.

## Acceptance Criteria

- [ ] Every phase acceptance criterion maps to passing automated evidence or a documented release-blocking gap.
- [ ] The full clean-checkout test pipeline is deterministic across repeated runs with no quarantined flaky release gate.
- [ ] Isolation, RBAC, money, lifecycle, idempotency, events/jobs, and security risk areas have explicit negative coverage.
- [ ] Performance and resilience results meet documented thresholds.
- [ ] All discovered in-scope defects are fixed with regression tests or clearly block release.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_20_TESTING_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 20 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 21 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
