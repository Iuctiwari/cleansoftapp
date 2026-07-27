# Phase 23 — Final Validation

## Phase Number

23

## Phase Name

Final Validation

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 23. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_23_TESTING.md`; its canonical identity is Phase 23 — Final Validation. Implement only this canonical phase.

## Objective

Perform an independent repository-wide validation of requirements, architecture, behavior, security, operations, and release evidence; repair only confirmed in-scope defects.

## Scope

- Phase completion audit, requirement/acceptance traceability, architecture conformance, API/event/data compatibility, UX/accessibility, security, performance, resilience, deployment, and documentation consistency.
- Fresh-environment execution of release gates and critical user journeys.
- Defect remediation limited to already approved behavior, with regression evidence.
- Final unresolved-risk and go/no-go recommendation.

## Out of Scope

- New features, production go-live, relaxing acceptance criteria, retroactively fabricating evidence, and approving one's own unresolved critical risk.
- Broad refactoring without a failed criterion.
- Replacing Phase 20 tests with a checklist-only review.

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

- Completed reports and deliverables for Phases 00-22.
- A release candidate deployed or fully rendered according to Phase 22.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- Validate the implemented system against the current repository, not against assumptions in earlier reports.
- Use evidence hierarchy: executable tests and deployed observations, then code/config inspection, then documentation assertions.
- Every finding maps to a phase, owner, severity, release impact, evidence, and remediation or acceptance decision.
- A missing external prerequisite is a visible gate, not a silently waived criterion.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Read every phase prompt, completion report, ADR, planning document, README, API/event schema, test report, scan report, release manifest, and runbook.
5. Rebuild the acceptance-criteria traceability matrix and verify each claim against current files, automated evidence, and deployed behavior.
6. Run clean install, format/lint/type/test/security/build/container/IaC/package gates and critical web/mobile/service journeys from a fresh environment.
7. Audit service ownership, tenant/branch/RBAC enforcement, money/lifecycle/idempotency, outbox/inbox, storage, search/report convergence, audit coverage, and operational safety.
8. Validate API/event backward compatibility, migrations, rollback, backup/restore, telemetry, alerts, SLOs, accessibility, and performance thresholds.
9. Record findings by severity; fix confirmed in-scope defects, add regression tests, and rerun affected gates.
10. Produce a final validation matrix, unresolved risk register, external gate list, and evidence-backed go/no-go recommendation.
11. Update only documentation made inaccurate by validated fixes and complete the phase report.
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

- Verify every service owns its data, fails closed on missing context, validates inputs, exposes safe health, drains cleanly, and has test/observability coverage.
- Verify no direct cross-service collection access, floating-point money, unbounded list/export, unauthenticated admin endpoint, or unversioned event/job contract remains.
- Reconcile representative source records with search/report/audit projections and exercise repair/rebuild paths.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Validate critical web and mobile journeys across roles, scopes, network conditions, viewport/device sizes, browsers/targets, and session changes.
- Run accessibility checks and verify error/loading/empty/stale/partial states.
- Confirm no mock success paths, debug banners/endpoints, unsafe storage, or cross-scope cached data remains.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Re-run all release-gating scans and adversarial suites on the final candidate.
- Verify secrets, permissions, environment hardening, network exposure, headers/CORS/CSRF, file controls, audit integrity, and deployment provenance.
- Do not mark go unless critical/high release policy is satisfied or an explicit authorized decision is recorded.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Re-run agreed critical-path, dashboard/search/report, queue/export, frontend/mobile, and restore benchmarks on release artifacts.
- Compare against Phase 20/21 baselines and investigate material regressions.
- Validate alert/abort thresholds against observed results.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Execute all release gates from a clean environment and record immutable artifact/evidence references.
- Run targeted exploratory testing around integration seams and prior defects.
- After any fix, rerun the affected unit/integration/E2E/security/performance slice and the full release gate when risk warrants.
- No failed/skipped release-critical check may be summarized as passing.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Produce final traceability, validation findings, unresolved risks, external gates, compatibility, and go/no-go rationale.
- Correct stale docs caused by verified fixes without undertaking the full documentation phase early.
- Ensure evidence links are repository-relative or stable approved artifact references.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Independent final validation report and rebuilt acceptance traceability matrix.
- Regression-tested fixes for confirmed in-scope defects.
- Unresolved risk register, external gate list, and evidence-backed go/no-go recommendation.
- A completed Phase 23 report at ERP-PLANNING/phase-completions/PHASE_23_FINAL_VALIDATION_COMPLETION.md.

## Acceptance Criteria

- [ ] Every phase acceptance criterion has verified current evidence or is explicitly marked failed/blocking.
- [ ] All release gates run from a clean environment and results match the release candidate.
- [ ] No unresolved critical defect, isolation breach, credential exposure, financial-integrity defect, or rollback/restore failure is hidden.
- [ ] All remediation has regression evidence and affected gates were rerun.
- [ ] The go/no-go recommendation is reproducible from cited evidence and external gates.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_23_FINAL_VALIDATION_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 23 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 24 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
