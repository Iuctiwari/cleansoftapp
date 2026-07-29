# Phase 21 — DevOps and Observability

## Phase Number

21

## Phase Name

DevOps and Observability

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 21. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_21_SEARCH.md`; its canonical identity is Phase 21 — DevOps and Observability. Implement only this canonical phase.

## Objective

Create production-shaped containers, CI/CD pipelines, infrastructure modules, observability, and operational controls without deploying production.

## Scope

- Reproducible multi-stage container images, non-root runtime, health checks, SBOM/signing hooks, registry flow, and local orchestration.
- CI/CD stages for validation, security, build, artifact provenance, environment promotion, and rollback hooks.
- Terraform/Helm foundations for application, MongoDB/Redis connectivity, object storage, networking, secrets references, autoscaling, and policies.
- Structured logs, metrics, traces, dashboards, alerts, SLOs, and runbook links.

## Out of Scope

- Applying production infrastructure, changing cloud accounts/DNS, storing live secrets, and claiming a successful deployment.
- Provider-specific resources without an approved target environment in repository documentation.
- Disabling quality/security gates for pipeline speed.

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

- Phase 20 passing quality gates and Phase 19 security controls.
- Phase 15 job telemetry and Phase 16 audit monitoring.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- Build once and promote the same immutable digest through environments; never rebuild different production bits from the same source tag.
- Use provider-neutral modules and Helm values until a target platform is approved. Keep secrets as references to an external secret mechanism.
- Propagate correlation/trace context through HTTP, events, queues, and provider callbacks.
- Use low-cardinality tenant-safe telemetry; never put personal data, raw tenant names, tokens, or unbounded IDs in metric labels.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Create hardened multi-stage Dockerfiles and ignore files for all deployable backend and Flutter web artifacts; define mobile build artifacts separately.
5. Create local/CI image build, vulnerability scan, SBOM, provenance/signing hooks, and startup/health validation.
6. Expand CI into ordered install/format/lint/type/test/security/build/container/package gates with caching and immutable artifacts.
7. Implement parameterized Helm charts and Terraform modules/environment skeletons for approved generic capabilities, with validation/lint/plan tests and no apply.
8. Implement centralized structured logging, metrics, distributed tracing, service/job/database/cache/storage dashboards, and actionable alerts.
9. Define SLIs/SLOs, alert severity and routing references as configuration, on-call runbook links, and error-budget policy.
10. Test container shutdown, non-root permissions, read-only filesystems where feasible, autoscaling signals, config/secret injection, and telemetry correlation.
11. Update infrastructure, CI/CD, observability, SLO, artifact, and operations documentation.
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

- Expose standardized liveness/readiness/metrics endpoints with network and auth policy appropriate to orchestration.
- Handle SIGTERM, stop accepting work, drain HTTP/queues, flush telemetry within bounds, and exit deterministically.
- Use immutable configuration at startup and secret references; never bake environment secrets into images.
- Provide safe database migration/compatibility hooks for Phase 22 deployment.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Build Flutter web with environment-safe runtime or build-time configuration that contains no secrets and supports immutable promotion strategy.
- Publish source maps only to approved protected error tooling and avoid public leakage.
- Define mobile CI build/test artifact flow without release signing credentials in source.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Run containers as non-root with minimal base images, dropped capabilities, scoped filesystem writes, and pinned/verified base references.
- Generate and retain SBOM/provenance, scan images/IaC, and enforce Phase 19 severity policy.
- Use least-privilege CI permissions, protected environments, short-lived credentials/OIDC hooks, and no secrets in logs/artifacts.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Measure image size, startup/readiness, graceful drain, CI duration, telemetry overhead, and autoscaling signals.
- Set resource requests/limits and queue/HTTP scaling policies from Phase 20 baselines.
- Ensure logging/tracing sampling and batching do not create unbounded cost or latency.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Build and run every container as its runtime user; test health, configuration failure, SIGTERM/drain, and read-only constraints.
- Lint/validate Helm and Terraform, render environment variants, and scan generated manifests/IaC.
- Run an ephemeral end-to-end stack from immutable images and verify traces/logs/metrics across representative flows.
- Test CI permissions, artifact integrity, cache isolation, and rollback hooks.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Complete infrastructure, CI/CD, container, artifact promotion, observability, SLO, alert, secret reference, and incident/runbook documentation.
- Record image strategy, deployment packaging, telemetry, and infrastructure-provider assumptions in ADRs.
- Document exact commands to validate/render/plan without applying resources.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Hardened immutable container artifacts and expanded CI/CD.
- Validated Helm/Terraform foundations without production apply.
- End-to-end logs, metrics, traces, dashboards, alerts, SLOs, and runbooks.
- A completed Phase 21 report at ERP-PLANNING/phase-completions/PHASE_21_DEVOPS_COMPLETION.md.

## Acceptance Criteria

- [ ] Every deployable image builds reproducibly, runs non-root, passes security gates, reports health, and drains cleanly.
- [ ] CI produces immutable identified artifacts only after all quality/security gates pass.
- [ ] Helm/Terraform variants validate and contain no live secrets or unintended public exposure.
- [ ] A representative request/job can be traced across services with redacted correlated telemetry.
- [ ] SLIs/SLOs, actionable alerts, and runbooks cover critical user and background paths.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_21_DEVOPS_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 21 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 22 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
