# Phase 22 — Deployment

## Phase Number

22

## Phase Name

Deployment

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 22. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_22_SETTINGS.md`; its canonical identity is Phase 22 — Deployment. Implement only this canonical phase.

## Objective

Deploy the immutable release candidate to an approved non-production environment, prove migration/rollback/restore and operational readiness, and prepare production deployment artifacts without assuming authority to go live.

## Scope

- Environment configuration, infrastructure plan/apply only for an explicitly approved target, application release, migrations, smoke tests, observability validation, rollback, backup/restore, and deployment runbooks.
- Staging acceptance and production change plan with approvals/decision points represented as documented gates.
- Artifact digest promotion and release manifest.

## Out of Scope

- Production go-live without explicit authorization, DNS/payment/provider/mobile-store changes not already approved, and bypassing release gates.
- Feature development unrelated to deployment defects.
- Committing or printing environment secrets.

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

- Phase 21 immutable artifacts, IaC/charts, telemetry, and CI/CD.
- Phase 20 test evidence and Phase 19 security gates.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- Deploy the exact immutable artifact digest produced by CI and retain a machine-readable release manifest.
- Use expand/contract or backward-compatible data changes so current and previous application versions can coexist during rollout.
- Treat backup and restore as tested behavior, not a configuration assumption.
- Production apply remains a human authorization gate unless the repository explicitly grants it during execution.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Discover the approved target environment and permissions from repository configuration; if none exists, complete a fully rendered dry-run/staging-local deployment package and clearly record the external blocker rather than inventing a provider.
5. Validate secrets references, network policies, certificates, origins, database/Redis/storage connectivity, quotas, resource limits, and environment-specific configuration.
6. Create the release manifest containing source revision, artifact digests, schema versions, config version, checksums, SBOM/provenance, and required commands.
7. Deploy to the approved non-production target using the pipeline, run migrations/compatibility steps, and validate health/readiness/telemetry.
8. Execute smoke/E2E/security/performance checks against the deployed environment and verify event/job processing and external adapter test modes.
9. Exercise rollback/forward recovery, failed deployment, database compatibility, backup creation, restore to isolation, and restore verification.
10. Finalize production rollout, canary/blue-green or rolling strategy, monitoring window, abort thresholds, communications, and rollback runbook.
11. Update deployment, environment, migration, backup/restore, rollback, and incident documentation.
12. Run every required validation, inspect the diff for scope/security/data-isolation regressions, and remove generated junk or secrets.
13. Replace the instructional content in the matching completion report with factual evidence from this implementation.

Do not implement anything listed as out of scope. Do not leave simulated success paths, dormant insecure fallbacks, undocumented breaking changes, or unowned data.

## Coding Standards

- Preserve the monorepo boundaries: backend deployables remain in apps/backend/*, the Flutter application remains in apps/mobile-app, reusable infrastructure in packages/*, planning in ERP-PLANNING/*, documentation in docs/*, and deployment assets in docker/* or infra/*.
- Use Node.js 22+, pnpm 10, strict TypeScript with no implicit any, NestJS dependency injection, class-validator/class-transformer DTO boundaries, and Mongoose repositories with explicit tenant-aware indexes.
- Keep controllers and transport handlers thin; place invariants in testable application/domain services and persistence details behind repositories/adapters.
- Use structured redacted logs, correlation/causation IDs, typed configuration validated at startup, stable machine-readable errors, UTC timestamps, opaque IDs, optimistic concurrency, and integer minor units for money.
- Use versioned API, event, job, and stored-data contracts. Producers and consumers must tolerate documented compatible evolution; breaking changes require migration and ADR.
- Use outbox/inbox and idempotency patterns for cross-service effects. Never reach into another service's private MongoDB collections.
- For Flutter, follow analyzer rules, feature-oriented modules, immutable typed models, accessible Material 3 components, go_router, centralized API/error handling, and no secrets in client assets.
- Format, lint, type-check, test, and build every touched workspace. Do not disable rules, skip tests, weaken types, or catch and ignore errors to obtain a green result.
- Preserve unrelated user changes. Make the smallest coherent changes for this phase and do not rename top-level repository directories.

## Backend Requirements

- Verify each service uses production-safe configuration, encrypted/authenticated dependencies, readiness gates, graceful drain, and compatible schemas.
- Run data changes once through controlled jobs/migrations with idempotency, observability, and recovery.
- Do not expose internal metrics/health/admin endpoints publicly.
- Verify queue consumers and scheduled jobs do not duplicate work during rolling deployment.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Verify Flutter web base path, API origin, CSP, caching/service-worker behavior, error telemetry, and rollback/cache invalidation.
- Generate signed mobile artifacts only when approved signing infrastructure exists; otherwise validate unsigned/test build packaging and document the release gate.
- Run browser/device smoke tests against deployed APIs.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Use protected environment credentials, least privilege, approval gates, artifact verification, and audited deployment actions.
- Confirm no debug mode/default password/insecure CORS/public datastore or secret-bearing artifact is active.
- Re-run targeted dynamic/security configuration checks in the deployed environment.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Validate startup, scaling, p95/p99 latency, queue lag, database/cache saturation, frontend delivery, and telemetry under staging load.
- Set rollout abort thresholds from measured SLOs and confirm alerts trigger.
- Measure backup/restore duration against recovery objectives.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Run deployment smoke, critical E2E, tenant isolation, security configuration, event/job, observability, and performance checks.
- Exercise rollback/forward recovery and verify no duplicate or lost committed business effects.
- Restore a backup into an isolated target and verify integrity/application compatibility.
- Record exact artifact digests, commands, environment, timestamps, evidence, and outcomes.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Complete deployment topology, environment configuration, release manifest, migration, rollout, abort, rollback, backup/restore, smoke, and incident runbooks.
- Document every external approval or missing production prerequisite as a concrete gate, not an assumed completion.
- Record the selected rollout strategy in an ADR.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Approved non-production deployment or complete provider-neutral dry-run package when no target is available.
- Release manifest, staging evidence, rollback/recovery and backup/restore evidence.
- Production rollout/abort/monitoring runbooks and explicit authorization gates.
- A completed Phase 22 report at ERP-PLANNING/phase-completions/PHASE_22_DEPLOYMENT_COMPLETION.md.

## Acceptance Criteria

- [ ] The same verified immutable digests are used throughout deployment and recorded in the release manifest.
- [ ] The approved non-production environment passes smoke, critical E2E, security, isolation, telemetry, and performance checks.
- [ ] Rollback/forward recovery and isolated backup restore succeed within documented objectives.
- [ ] No production change occurs without explicit authority and all external gates are visible.
- [ ] Deployment actions and evidence are reproducible from documentation.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_22_DEPLOYMENT_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 22 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 23 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
