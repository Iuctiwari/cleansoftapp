# Phase 02 — Multi-Tenancy

## Phase Number

02

## Phase Name

Multi-Tenancy

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 02. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_2_SYSTEM_PLANNING.md`; its canonical identity is Phase 02 — Multi-Tenancy. Implement only this canonical phase.

## Objective

Establish tenant lifecycle, tenant context, and enforceable data-isolation primitives across the platform before any tenant-owned business data is added.

## Scope

- Tenant creation, retrieval, update, activation/suspension, immutable tenant identity, and tenant-level configuration foundations.
- Identity-to-tenant membership resolution sufficient to authorize tenant access.
- Gateway tenant resolution and trusted propagation; shared tenant-scoping helpers and tests.
- Cross-service isolation rules, indexes, event fields, cache key conventions, and job-context conventions.

## Out of Scope

- Branch management, detailed user roles, subscriptions, billing plans, usage metering, and platform marketplace behavior.
- Domain entities such as customers, services, orders, payments, and expenses.
- Custom domains or vanity URLs unless already required by authoritative documentation.

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

- Phase 00 platform foundation.
- Phase 01 authenticated identity and session context.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- Use a shared-database/shared-collection model only if the repository does not establish a different approved model; every tenant-owned record must carry an immutable tenantId.
- Tenant context must originate from authenticated membership or an explicitly authorized platform-admin operation, never from an unverified request field.
- Service repositories must require tenant scope by construction. Direct unscoped model access is forbidden outside narrowly reviewed platform operations.
- TenantId must be present in domain events, cache keys, job payloads, object-storage prefixes, logs, and metrics labels where safe.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Document the selected isolation model, threat boundaries, tenant lifecycle, membership handshake, and platform-admin exception path.
5. Implement tenant-service persistence and APIs for supported lifecycle operations with optimistic concurrency and immutable identifiers.
6. Implement gateway tenant resolution, membership verification, request context, and downstream signed/trusted metadata propagation.
7. Create shared tenant-aware repository/query, event, cache, queue, and logging utilities with fail-closed behavior.
8. Add tenant isolation lint/test helpers that detect missing scope in repositories and fixtures where practical.
9. Implement a minimal web tenant-selection or tenant-context experience only for identities with more than one authorized tenant.
10. Publish tenant lifecycle events and invalidate membership/context caches safely.
11. Update multi-tenancy, tenant-service, API, database, security, and operations documentation.
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

- All tenant-service endpoints require authenticated platform or tenant authorization appropriate to the operation.
- Tenant-owned unique indexes must include tenantId; global uniqueness is permitted only for explicitly documented platform identifiers.
- Suspended tenants must be denied business access consistently while preserving controlled platform administration and recovery.
- Background consumers must reject messages with absent or invalid tenant context and must never default to a global tenant.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Web state must treat tenant context as explicit, clear tenant-derived state on tenant switch, and prevent stale cross-tenant cache reuse.
- Tenant selection must display only authorized memberships and handle suspension or membership removal safely.
- Do not add tenant administration screens beyond the lifecycle operations required in this phase.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Add horizontal-privilege tests across every tenant API and shared repository helper.
- Prevent tenant enumeration through identifiers, errors, logs, and timing where feasible.
- Authorize platform-admin bypass separately, log it immutably when audit infrastructure is available, and never infer it from tenant roles.
- Do not use client-provided tenantId as authoritative without membership validation.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Create compound indexes beginning with tenantId for common access paths and validate them with explain plans.
- Cache membership and tenant status only with bounded TTL and event-driven invalidation.
- Avoid per-request fan-out to multiple services for context resolution; document the trusted propagation strategy.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Unit-test tenant context, scoped repositories, signed metadata, lifecycle rules, cache keys, and event envelopes.
- Integration-test creation, updates, suspension, memberships, context resolution, and concurrent modifications.
- Run automated two-tenant isolation suites against APIs, persistence, cache, events, and jobs.
- End-to-end test tenant switching and stale state cleanup in the web app.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Complete the multi-tenancy model, data-isolation guarantees, context propagation, platform-admin boundaries, indexes, and incident procedures.
- Record the tenancy model and propagation mechanism in ADRs.
- Document how every later phase must prove tenant isolation.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Tenant-service lifecycle APIs and persistence.
- Gateway and shared-library tenant context enforcement.
- Web tenant selection, isolation tests, events, and architecture documentation.
- A completed Phase 02 report at ERP-PLANNING/phase-completions/PHASE_02_MULTI_TENANCY_COMPLETION.md.

## Acceptance Criteria

- [ ] Every tenant-owned access path fails closed without validated tenant context.
- [ ] Automated tests prove that two tenants cannot read, mutate, search, cache, export, or consume each other's data.
- [ ] Suspension and membership removal take effect within the documented propagation window.
- [ ] Tenant switching clears tenant-derived frontend state.
- [ ] All tenant-aware indexes and contracts are documented and verified.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_02_MULTI_TENANCY_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 02 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 03 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
