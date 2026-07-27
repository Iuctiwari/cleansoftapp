# Phase 03 — Branch Management

## Phase Number

03

## Phase Name

Branch Management

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 03. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_3_PLAN_AUDIT.md`; its canonical identity is Phase 03 — Branch Management. Implement only this canonical phase.

## Objective

Implement tenant-owned branch lifecycle and branch context so operational data can be safely partitioned and authorized within a tenant.

## Scope

- Branch creation, retrieval, update, activation/deactivation, address/contact/timezone configuration, and stable branch identifiers.
- Branch membership or assignment references needed by later authorization phases.
- Gateway and shared branch-context propagation layered beneath tenant context.
- Web branch administration and branch switching for authorized users.

## Out of Scope

- Employee scheduling, inventory, route planning, geofencing, payroll, or branch financial consolidation.
- Detailed role management beyond the minimum assignment contract.
- Customer, order, payment, expense, and reporting behavior.

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

- Phase 02 tenant isolation and membership context.
- Phase 01 authenticated identity.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- A branch is always tenant owned. Its identity is unique within tenant scope and cannot be moved between tenants.
- Branch context never replaces tenant context; both are verified and propagated.
- Resources may be tenant-wide or branch-scoped only when their owning phase explicitly declares that policy.
- Inactive branches remain referentially intact and must not be hard-deleted when referenced.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Define branch entity, lifecycle, branch-context contract, assignment reference, and tenant-wide versus branch-scoped authorization semantics.
5. Implement branch-service persistence, validation, optimistic concurrency, indexes, and supported CRUD/lifecycle APIs.
6. Implement gateway branch resolution and downstream context propagation with membership/assignment checks.
7. Create shared branch-aware query, cache, event, and job helpers that require tenant context.
8. Build responsive, accessible web branch listing, create/edit, details, status, and branch-switch experiences.
9. Emit versioned branch lifecycle events and invalidate authorization/context caches.
10. Add cross-tenant and cross-branch isolation tests, including inactive branch behavior.
11. Update branch-service, API, data model, RBAC, frontend, and operations documentation.
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

- Every branch query and unique index must include tenantId; branchId alone is never sufficient authorization.
- Validate normalized branch codes, timezone identifiers, addresses, and status transitions without embedding unapproved operational rules.
- Use soft lifecycle status for deactivation and preserve references.
- Branch events must carry tenantId, branchId, version, event ID, correlation ID, and occurred-at time.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Show branch controls only to authorized users and prevent stale branch state after switching.
- Forms must validate server-authoritative fields, preserve unsaved-change warnings, and handle optimistic concurrency conflicts.
- Navigation and data caches must include tenant and branch context.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Verify tenant membership before branch assignment or access and test cross-branch horizontal authorization.
- Never accept an arbitrary branch header without verifying it belongs to the active tenant and identity.
- Log status changes and privileged assignment operations with actor, tenant, branch, correlation, and outcome.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Index tenantId with branch status, normalized code, and common list ordering.
- Paginate branch lists and cache stable branch metadata with bounded invalidation.
- Avoid synchronous fan-out when resolving branch context.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Unit-test normalization, lifecycle, context resolution, authorization predicates, and event payloads.
- Integration-test branch APIs, duplicate constraints, optimistic concurrency, and deactivation with references.
- Run tenant/branch isolation tests and web branch-switch end-to-end tests.
- Include accessibility and responsive-layout widget tests for branch administration.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Document branch ownership, lifecycle, context rules, assignment contract, API schemas, indexes, and events.
- Update RBAC and multi-tenancy guidance with branch-scoped permission semantics.
- Record any choice about tenant-wide versus branch-scoped resource defaults in an ADR.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Branch-service domain implementation and gateway context enforcement.
- Web branch administration and switching.
- Contracts, events, isolation tests, and branch architecture documentation.
- A completed Phase 03 report at ERP-PLANNING/phase-completions/PHASE_03_BRANCH_MANAGEMENT_COMPLETION.md.

## Acceptance Criteria

- [ ] Authorized users can manage and select branches only inside their tenant.
- [ ] Inactive branches cannot receive new operational work but retain existing references.
- [ ] Cross-tenant and unauthorized cross-branch requests fail without data leakage.
- [ ] Branch switch invalidates branch-derived frontend state.
- [ ] API, event, and persistence contracts pass automated tests.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_03_BRANCH_MANAGEMENT_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 03 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 04 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
