# Phase 06 — Service Catalog Management

## Phase Number

06

## Phase Name

Service Catalog Management

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 06. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_6_IMPLEMENTATION_PROMPTS.md`; its canonical identity is Phase 06 — Service Catalog Management. Implement only this canonical phase.

## Objective

Implement the tenant-owned catalog of sellable cleaning services and configurable operational metadata required to create orders.

## Scope

- Service categories, service items, descriptions, units, base pricing representation, duration estimates, availability status, and branch availability/overrides when documented.
- Catalog versioning and snapshot contracts for downstream orders.
- Paginated/filterable APIs and web catalog administration.
- Catalog events for search, cache invalidation, reporting, and audit.

## Out of Scope

- Dynamic pricing engines, promotions, tax engines, inventory/BOM, employee scheduling, and order execution.
- Automatic repricing of historical orders when catalog data changes.
- Marketplace or cross-tenant catalog sharing.

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

- Phase 02 tenant isolation, Phase 03 branch scope, and Phase 04 RBAC.
- Phase 05 customer management is not a hard runtime dependency but must be complete in execution order.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- service-service owns the current catalog. Orders must store immutable service-description and monetary snapshots, not dereference mutable prices for historical totals.
- Represent money as integer minor units plus ISO currency; never use binary floating point.
- Branch overrides must inherit explicitly and remain tenant-scoped.
- Catalog mutations use optimistic concurrency and versioned events.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Define category, service item, unit, money, availability, branch override, and order snapshot contracts without inventing unsupported pricing policy.
5. Implement service-service persistence, indexes, validation, lifecycle, pagination, filtering, and CRUD APIs.
6. Implement deterministic resolution of tenant defaults and branch overrides where branch pricing/availability is authorized.
7. Provide an API that returns an immutable catalog snapshot suitable for order creation.
8. Build accessible web category and service list/create/edit/detail/status/branch-override experiences.
9. Publish catalog events and establish safe cache invalidation.
10. Test currency precision, concurrent edits, inactive services, tenant/branch isolation, and snapshot stability.
11. Update service-service, API, data model, event, frontend, and operational documentation.
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

- Validate currency, minor-unit amount bounds, units, duration bounds, and normalized category/service codes.
- Do not hard-delete catalog entries referenced by orders; use inactive status and preserve version history needed for audit.
- All unique constraints and cache keys must include tenant and, for overrides, branch scope.
- Return explicit resolved source metadata when an override is applied.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Use locale-aware display formatting but send and store precise minor-unit values.
- Clearly distinguish tenant defaults, inherited values, and branch overrides.
- Prevent accidental loss of unsaved edits and surface version conflicts.
- Do not implement order screens in this phase.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Restrict catalog writes and price changes to explicit permissions; reads follow tenant/branch policy.
- Protect against mass assignment, currency manipulation, negative or overflow amounts, and stored markup in descriptions.
- Emit audit-ready before/after metadata for price, availability, and status changes.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Index tenant/branch/category/status/code and common ordering fields.
- Cache read-heavy resolved catalogs with versioned keys and reliable event invalidation.
- Use projection and pagination for administration while providing bounded snapshot reads for order creation.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Unit-test money handling, override resolution, lifecycle, snapshot creation, validation, and event versioning.
- Integration-test CRUD, indexes, pagination, concurrency, caching, and inactive references.
- Run tenant/branch isolation and permission tests.
- End-to-end test web catalog administration and locale-aware money entry/display.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Document catalog entities, money/unit conventions, inheritance, lifecycle, snapshot semantics, APIs, indexes, and events.
- Record the price snapshot and branch override decisions in ADRs.
- Document the extension point for later tax or pricing policy without implementing it.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Service catalog domain implementation, snapshot API, and branch-aware resolution.
- Web catalog administration.
- Precise money handling, events, tests, and documentation.
- A completed Phase 06 report at ERP-PLANNING/phase-completions/PHASE_06_SERVICE_MANAGEMENT_COMPLETION.md.

## Acceptance Criteria

- [ ] Catalog data is isolated by tenant and resolved by branch exactly as documented.
- [ ] Money is precise and validated; no floating-point monetary storage or arithmetic exists.
- [ ] Historical snapshot contracts remain stable after catalog updates or deactivation.
- [ ] Unauthorized price or availability changes are rejected and recorded.
- [ ] Catalog API and web tests pass for concurrency, accessibility, and performance.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_06_SERVICE_MANAGEMENT_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 06 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 07 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
