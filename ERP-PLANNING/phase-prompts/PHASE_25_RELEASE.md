# Phase 25 — Production Readiness and Release

## Phase Number

25

## Phase Name

Production Readiness and Release

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 25. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_25_RELEASE.md`; its canonical identity is Phase 25 — Production Readiness and Release. Implement only this canonical phase.

## Objective

Assemble and verify the final production-readiness dossier, close release-blocking gaps, and execute production release only when explicit authorization and every go-live gate are present.

## Scope

- Readiness checklist, ownership/on-call, SLO/capacity, security/privacy, data migration, backup/restore/DR, support, observability, provider configuration, change management, release manifest, communications, and rollback.
- Final artifact and evidence verification, go/no-go meeting inputs, and post-release validation/monitoring plan.
- Production deployment only when explicit authority, target, credentials, approvals, and gates are confirmed at execution time.

## Out of Scope

- Waiving failed gates, inventing approvals, unapproved production changes, new features, external certification claims, and permanent acceptance of unresolved critical risk.
- Publishing mobile apps to stores without approved accounts/signing/privacy assets.
- Disclosing production secrets or customer data in the completion report.

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

- Phase 23 evidence-backed validation and Phase 24 complete documentation.
- Phase 22 deployment/rollback/restore evidence and Phase 19-21 security, testing, and operations gates.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- Release the exact immutable artifact digests validated in prior phases; verify provenance and configuration separately.
- Go-live is a controlled change with named decision authority, abort thresholds, rollback ownership, and monitoring window.
- Readiness is not binary when external gates are absent: record NO-GO with precise blockers rather than implying production completion.
- Post-release success requires user-path, financial-integrity, isolation, queue, audit, and telemetry validation.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Assemble a production-readiness matrix covering product scope, quality, security, privacy, performance/capacity, availability, data, DR, operations, support, documentation, legal/business approvals, and external providers.
5. Verify each gate against current immutable evidence, release manifest, scan/test results, staging observations, runbooks, ownership, and contact/escalation references.
6. Close only in-scope release-blocking defects, add regression evidence, and rebuild/revalidate artifacts when any source changes.
7. Run a final backup/restore or tabletop DR exercise, capacity review, alert/runbook drill, security incident tabletop, and deployment/rollback rehearsal.
8. Prepare exact go-live timeline, responsibilities, communications, maintenance/customer impact, migration order, smoke tests, monitoring, abort thresholds, rollback, and post-release review.
9. Confirm production credentials/config/provider/webhook/DNS/certificates/mobile-signing readiness without exposing values.
10. If and only if explicit production authorization is present, execute the approved pipeline, monitor, validate critical paths, and roll back on threshold breach; otherwise stop at a documented NO-GO gate.
11. Complete the final report with actual outcome, artifact digests, evidence, residual risks, limitations, and next operational actions.
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

- Verify production configuration, least privilege, migrations, dependency connectivity, rate/resource limits, health, drain, queues/schedules, audit ingestion, reconciliation, and repair procedures.
- Run post-release smoke checks for authentication, tenant isolation, representative order/payment/expense, notification test mode/approved channel, search/report freshness, file security, jobs, and audit.
- Reconcile financial and event/projection counts after migration/deployment.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Verify production web asset/API configuration, CSP/origins, cache invalidation, source-map policy, critical journeys, accessibility, and rollback.
- Verify mobile version/API compatibility and distribution prerequisites; do not publish without explicit separate authority.
- Monitor client errors, performance, and session behavior during the release window.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Require passing final scans, no disallowed findings, verified secrets/keys/certificates rotation posture, incident contacts, audit integrity, and production access review.
- Use least-privilege time-bounded deployment access and record all changes.
- Ensure the completion report references secret locations abstractly and never includes secret values.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Confirm capacity model, resource quotas, autoscaling, database/cache/storage headroom, queue throughput, provider limits, and cost guardrails.
- Monitor SLO indicators and abort thresholds during rollout and the defined observation window.
- Compare production smoke performance to staging baselines while accounting for safe low-volume validation.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Run final immutable-artifact verification, critical smoke/E2E, security configuration, isolation, migration, reconciliation, backup/restore or DR, and rollback rehearsal checks.
- Execute approved post-release validation if go-live is authorized.
- Record every gate as pass, fail, not applicable with rationale, or externally blocked; never leave ambiguous status.
- Any source fix requires a new artifact digest and rerun of affected release gates.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Finalize readiness matrix, release notes, change record, go-live/rollback plan, support handoff, residual risks, operational ownership, and post-release review plan.
- Record actual production authorization and deployment outcome without including credentials.
- Ensure all runbooks and contacts are current and accessible to the responsible team.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Complete production-readiness dossier and gate matrix.
- Final immutable release manifest, release notes, go-live/rollback/monitoring plan, drills, and support handoff.
- A clearly evidenced GO, conditional GO with authorized conditions, or NO-GO decision and actual deployment outcome.
- A completed Phase 25 report at ERP-PLANNING/phase-completions/PHASE_25_PRODUCTION_READINESS_COMPLETION.md.

## Acceptance Criteria

- [ ] Every readiness gate has an explicit status, evidence, owner, and release impact.
- [ ] No production action occurs without explicit authority and all required credentials/approvals/targets.
- [ ] The release candidate digest matches the validated artifact and any fix triggers revalidation.
- [ ] Rollback, restore/DR, alert/runbook, security-incident, and support procedures have exercised evidence.
- [ ] The final decision and outcome are truthful, reproducible, secret-free, and leave no hidden release blocker.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_25_PRODUCTION_READINESS_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 25 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and the information required for production operations and post-release review.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
