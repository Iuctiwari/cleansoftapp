# Phase 00 — Project Setup and Platform Foundation

## Phase Number

00

## Phase Name

Project Setup and Platform Foundation

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 00. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_0_FOUNDATION.md`; its canonical identity is Phase 00 — Project Setup and Platform Foundation. Implement only this canonical phase.

## Objective

Turn the existing monorepo scaffold into a reproducible, buildable, observable development foundation without implementing ERP domain workflows.

## Scope

- Root pnpm and TurboRepo workspace reliability, deterministic dependency management, and shared developer commands.
- Production-shaped NestJS bootstrap conventions for the API gateway and all fourteen domain services.
- Shared package foundations for configuration, types, constants, database access, logging, utilities, common infrastructure, shared contracts, and UI primitives.
- Local MongoDB 8 and Redis 8 development infrastructure, health/readiness conventions, and baseline CI.
- Flutter web and mobile application bootstraps, environment handling, routing shells, theming foundations, and test harnesses without product screens.

## Out of Scope

- Authentication, tenant, branch, user, customer, service, order, payment, expense, notification, reporting, search, or audit business behavior.
- Production cloud resources, production deployment, provider integrations, and final visual design.
- Database collections or API routes that encode later-phase domain behavior.

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

There is no prior phase completion report.

- The checked-in repository scaffold and tool versions.
- No earlier implementation phase.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- Keep the pnpm workspace rooted at apps/* and packages/* and preserve TurboRepo as the task orchestrator.
- Standardize the API gateway and services on Node.js 22+, TypeScript strict mode, NestJS 11, Mongoose 8, Redis/ioredis, and BullMQ where queues are required.
- Use environment-schema validation with fail-fast startup; never silently accept missing production configuration.
- Define liveness as process health and readiness as verified dependency health. Do not expose secrets or dependency credentials in health responses.
- Create shared infrastructure abstractions only when at least two consumers need them; domain models remain owned by their service.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Inspect current package manifests and reconcile incompatible module, TypeScript, lint, test, and build settings while retaining repository intent.
5. Add complete build, lint, test, type-check, development, and production scripts for each backend service and shared package.
6. Establish standard NestJS service bootstraps, configuration modules, graceful shutdown, structured logging, correlation IDs, global validation, error envelopes, and health/readiness endpoints.
7. Create typed shared configuration, logging, database, event-envelope, pagination, error, and test utilities in the appropriate packages; avoid a catch-all shared domain package.
8. Make Docker Compose start MongoDB and Redis with health checks, explicit environment defaults suitable for local use, persistent volumes, and documented startup commands.
9. Create baseline unit and integration test harnesses, an ephemeral test configuration strategy, and CI gates for install, format verification, lint, type-check, test, build, and scaffold integrity.
10. Refactor both Flutter entry points into maintainable application shells with environment configuration, routing, theme tokens, error handling, and smoke tests; do not add domain screens.
11. Update directly affected foundation documentation and record material architecture choices as ADRs.
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

- Every backend application must start independently, validate configuration, expose non-domain health/readiness endpoints, shut down gracefully, and emit structured logs with correlation and service identifiers.
- The gateway must retain the /api boundary, use allowlisted CORS configuration, request validation, bounded request bodies, consistent errors, and a path to API versioning.
- MongoDB and Redis connection factories must support retries with bounded backoff, test isolation, connection cleanup, and redacted diagnostics.
- Do not add domain controllers, domain collections, or cross-service data access.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Web and mobile must load environment-specific non-secret configuration, render a minimal accessible application shell, route predictably, and surface startup failures safely.
- Create reusable design tokens and base components only; no ERP feature screen belongs in this phase.
- Flutter analyzer, unit/widget smoke tests, and build commands must be runnable from the monorepo task graph.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Validate all environment variables, restrict CORS by configuration, set secure HTTP defaults, redact secrets and credentials from logs, and reject oversized or malformed requests.
- Provide secret references only through example environment files with non-sensitive values; never commit active credentials.
- Run dependency and secret scanning in CI with an explicit severity policy and documented exception process.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Bootstraps must avoid synchronous blocking I/O after initialization and must reuse database and Redis connections.
- Define request timeouts, keep-alive behavior, connection-pool bounds, and graceful termination deadlines.
- Capture a baseline for startup time, health latency, and idle resource use so later phases can detect regressions.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Unit-test configuration parsing, error mapping, logging redaction, correlation propagation, and shared utilities.
- Integration-test MongoDB and Redis connectivity, liveness/readiness semantics, graceful shutdown, and gateway request validation.
- Add Flutter smoke/widget tests for both app shells and verify web and debug mobile builds.
- Prove that all root CI commands work from a clean checkout and fail when a required check fails.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Document prerequisites, exact local setup commands, environment variables, service ports, health endpoints, monorepo commands, and troubleshooting.
- Update README files only where Phase 00 establishes real behavior; do not fabricate later features.
- Add ADRs for module format, configuration validation, service bootstrap, error envelope, event envelope, and local dependency strategy when those decisions are made.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- A deterministic, lintable, testable, buildable monorepo foundation across backend services, packages, and both Flutter apps.
- Operational local MongoDB and Redis dependencies with documented health checks.
- Baseline CI, test harnesses, shared infrastructure contracts, and foundation documentation.
- A completed Phase 00 report at ERP-PLANNING/phase-completions/PHASE_00_PROJECT_SETUP_COMPLETION.md.

## Acceptance Criteria

- [ ] A clean checkout can install dependencies and run the documented format check, lint, type-check, tests, and builds without manual file edits.
- [ ] Every backend process starts with valid local configuration, rejects invalid configuration, exposes liveness/readiness, and shuts down cleanly.
- [ ] Both Flutter apps pass analysis and smoke tests; the web app builds and the mobile debug target builds.
- [ ] No ERP domain endpoint, collection, workflow, or product screen has been introduced.
- [ ] CI enforces the same commands used locally and contains no secrets.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_00_PROJECT_SETUP_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 00 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 01 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
