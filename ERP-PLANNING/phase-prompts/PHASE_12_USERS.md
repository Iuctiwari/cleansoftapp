# Phase 12 — Search

## Phase Number

12

## Phase Name

Search

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 12. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_12_USERS.md`; its canonical identity is Phase 12 — Search. Implement only this canonical phase.

## Objective

Implement tenant- and permission-aware search projections and APIs for supported ERP entities using the existing search-service.

## Scope

- Search indexing for customers, service catalog items, and orders, with documented expansion hooks.
- Event-driven projection updates, initial/rebuild indexing, deletion/tombstone handling, and index versioning.
- Tenant/branch/RBAC-filtered query API with pagination, filters, ranking, and safe snippets.
- Global and contextual web search experiences.

## Out of Scope

- Internet search, cross-tenant discovery, semantic/vector search, AI-generated answers, and unrestricted full-document indexing.
- Using search as the authoritative source of domain truth.
- Indexing secret, credential, payment-sensitive, private-note, or file-binary content.

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

- Phases 05-07 customer, catalog, and order events.
- Phase 02 tenant isolation, Phase 03 branch scope, Phase 04 RBAC, and Phase 15-compatible job design.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- search-service owns denormalized projections only; source services remain authoritative.
- If no external search engine is established, implement a MongoDB-backed search abstraction that can later be replaced without changing public contracts.
- Every indexed document and query includes tenant scope, resource type, authorization metadata, source version, and tombstone semantics.
- Consumers are idempotent and ignore out-of-order older source versions.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Define searchable fields, data-classification exclusions, projection schemas, index versions, ranking/filter behavior, and permission filters.
5. Implement search-service event consumers, inbox deduplication, projections, indexes, query API, and health/lag metrics.
6. Implement deterministic full rebuild and targeted reindex jobs with checkpoints, alias/version swap, cancellation, and resumability.
7. Implement deletion/tombstone, tenant suspension/removal, role/branch-change effects, and consistency monitoring.
8. Build accessible web global search and contextual entity search with debouncing, pagination, filters, keyboard navigation, and safe highlighting.
9. Add authorization defense in depth by revalidating sensitive resource access at navigation/read time.
10. Load-test representative indexes and verify query plans/ranking determinism.
11. Update search-service, event, privacy/security, API, frontend, and reindex runbook documentation.
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

- Normalize query input, enforce minimum/maximum lengths and bounded filters, and return stable cursor or deterministic pagination.
- Index only allowlisted fields and precompute safe display snippets; never echo unsafe markup.
- Source version and event ID must make update/delete consumers idempotent and order aware.
- Search results include opaque source IDs and route metadata, not entire domain records.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Debounce requests, cancel stale queries, handle empty/error/loading states, and preserve keyboard/screen-reader navigation.
- Escape highlights/snippets and show resource type and branch context clearly.
- Clear results and query caches on logout or tenant/branch switch.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Apply tenant, branch, status, and permission filters before ranking/pagination so unauthorized result counts do not leak.
- Test query injection, regex denial of service, wildcard abuse, stored XSS in snippets, enumeration, and stale authorization.
- Exclude protected personal/financial data and all secrets by an explicit field allowlist.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Set query length/filter/result limits, timeouts, and slow-query telemetry.
- Create compound/text indexes validated with representative explain plans and data volumes.
- Make rebuilds resumable and non-blocking, with bounded queue concurrency and observable lag.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Unit-test normalization, ranking, filters, permission predicates, version ordering, snippets, and tombstones.
- Integration-test event indexing, duplicate/out-of-order events, rebuild/swap, deletion, and source convergence.
- Run cross-tenant/branch/RBAC leakage and adversarial query tests.
- End-to-end test web global/contextual search, navigation authorization, accessibility, and stale request cancellation.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Document indexed resource/field allowlists, ranking, consistency, event contracts, APIs, index versions, rebuild, lag alerts, and privacy exclusions.
- Record the initial search-engine abstraction decision in an ADR.
- Document operator procedures for drift detection and safe reindex.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Search-service projections, event consumers, query API, rebuild jobs, and observability.
- Permission-safe web global/contextual search.
- Isolation, adversarial, convergence, performance, and end-to-end tests.
- A completed Phase 12 report at ERP-PLANNING/phase-completions/PHASE_12_SEARCH_COMPLETION.md.

## Acceptance Criteria

- [ ] Search never returns or counts resources outside the caller's tenant, branch, or permissions.
- [ ] Duplicate and out-of-order events converge to the latest authoritative source version.
- [ ] Rebuild is resumable, observable, and can switch index versions without unsafe downtime.
- [ ] Unsafe/private fields are absent from projections and results.
- [ ] Search latency, accessibility, relevance fixtures, and leakage tests meet documented targets.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_12_SEARCH_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 12 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 13 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
