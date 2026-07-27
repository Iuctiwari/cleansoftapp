# Cross-Phase Implementation Audit

## Phase Number

AUDIT

## Phase Name

Cross-Phase Implementation Audit

## Execution Contract

Work from the repository root. Determine the audit target automatically: use the most recently modified numbered completion report that claims implementation work; if no numbered report contains implementation evidence, audit Phase 00 readiness. Do not ask the user to restate a phase that can be discovered. This is an evidence review, not authorization to implement new features or make external changes.

## Objective

Independently verify that the selected phase's prompt, implementation, tests, documentation, and completion claims agree with the current repository and all earlier architectural/security constraints.

## Scope

- The selected phase prompt and completion report.
- Current git diff/status, relevant source/configuration/schemas/migrations/tests/documentation, and earlier dependency reports.
- Acceptance criteria, service/data ownership, tenant/branch/RBAC isolation, security, performance, testing, documentation, and next-phase readiness.
- Reproduction of safe read-only or test/build commands needed to validate claims.

## Out of Scope

- Implementing fixes, new features, production deployment, modifying external systems, accepting risk, or rewriting history.
- Treating unchecked boxes or narrative claims as evidence.
- Expanding the audit to unrelated later phases unless a dependency violation requires it.

## Mandatory Reading

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
- ERP-PLANNING/phase-prompts/README.md and the selected canonical phase prompt.
- ERP-PLANNING/phase-completions/README.md and the selected phase completion report.
- All relevant ADRs, API/event/job schemas, migrations, tests, scan outputs, release manifests, and runbooks cited by the report.

## Dependencies

- At least the repository scaffold and Phase 00 prompt must exist.
- Audit confidence depends on the availability of reproducible tests and evidence; missing evidence is a finding, not a reason to infer success.

## Architecture Notes

- Current executable behavior and schemas outrank stale documentation or completion prose.
- Evidence strength descends from reproducible tests/deployed observations to code/configuration inspection to unsupported claims.
- Every finding must include severity, evidence, violated criterion, impact, and the smallest safe remediation recommendation.
- The audit must verify cross-phase invariants even when the selected phase does not mention them explicitly.

## Tasks to Perform

1. Select and state the audit target and the evidence set used.
2. Map every target-phase acceptance criterion and deliverable to current repository evidence.
3. Re-run safe relevant format/lint/type/test/build/security/performance commands or explain precisely why a command is unavailable.
4. Inspect architecture boundaries, data ownership, tenant/branch/RBAC enforcement, versioned contracts, migrations, idempotency, errors, telemetry, secrets, and recovery.
5. Compare exact created/modified file claims to repository state and flag omissions or unrelated scope.
6. Classify findings as critical, high, medium, low, or informational with release/next-phase impact.
7. Decide PASS, PASS WITH CONDITIONS, or FAIL using evidence; any unmet required acceptance criterion prevents PASS.
8. Write the audit result to ERP-PLANNING/phase-completions/AUDIT_PHASE_COMPLETION.md without changing implementation files.

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

Evaluate these standards; do not modify code during the audit.

## Backend Requirements

- Verify all touched endpoints/services validate input, authorize at the resource boundary, preserve tenant/branch scope, own their persistence, version contracts, and handle failure/concurrency/idempotency.
- Verify health/readiness, shutdown, configuration validation, structured redacted telemetry, indexes, migrations, and test coverage.
- Verify no direct cross-service collection access or unapproved business scope was introduced.

## Frontend Requirements

- Verify touched web/mobile flows use real authorized APIs, clear scoped state, handle all material UI states, and meet accessibility/responsive/security requirements.
- Verify frontend visibility is not treated as authorization and that secrets/sensitive data are not stored or logged unsafely.
- If no frontend was applicable, verify that the prompt's frontend boundary was respected.

## Security Requirements

- Recheck authentication, tenant/branch isolation, RBAC, injection, mass assignment, IDOR, secrets, personal/financial data, files, webhooks, queues, exports, and audit controls relevant to the target.
- Flag missing negative tests and any completion report that omits residual risk or failed scans.
- Do not include sensitive values in the audit report.

## Performance Requirements

- Verify measurements use representative workloads, record percentiles/resources, and match prompt thresholds or documented baselines.
- Flag unbounded queries, exports, uploads, queues, retries, payloads, caches, or synchronous fan-out.
- Distinguish measured results from assertions.

## Testing Requirements

- Reproduce relevant tests where safe and record exact commands and outcomes.
- Verify success, negative, isolation, permission, concurrency, idempotency, dependency failure, recovery, and regression coverage as applicable.
- Treat skipped, flaky, unavailable, or silently disabled checks as findings with impact.

## Documentation Requirements

- Verify touched behavior, schemas, configuration, migrations, events/jobs, security, tests, and operations are accurately documented and linked.
- Flag generic filler, broken links, stale commands, secrets, unsupported claims, and missing ADRs.
- The audit report must cite repository-relative evidence.

## Deliverables

- A criterion-by-criterion evidence matrix for the selected phase.
- A severity-ranked finding list with concrete evidence and remediation recommendations.
- A clear PASS, PASS WITH CONDITIONS, or FAIL decision and next-phase recommendation.
- A completed ERP-PLANNING/phase-completions/AUDIT_PHASE_COMPLETION.md.

## Acceptance Criteria

- [ ] The audit target and evidence set are unambiguous.
- [ ] Every selected-phase acceptance criterion and deliverable has verified evidence or a finding.
- [ ] Relevant architecture, security, performance, testing, documentation, and scope boundaries were checked.
- [ ] Commands/results and file evidence are cited truthfully.
- [ ] The decision follows from findings and does not conceal missing evidence.
- [ ] No implementation or external state was changed.

## Completion Instructions

Replace the authoring guidance in ERP-PLANNING/phase-completions/AUDIT_PHASE_COMPLETION.md with the audit target, evidence matrix, commands/results, findings, decision, limitations, pending remediation, and next-phase recommendation. Retain every required heading and do not modify the audited implementation.
