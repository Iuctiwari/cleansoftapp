# Phase 10 — Notification System

## Phase Number

10

## Phase Name

Notification System

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 10. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_10_TENANTS.md`; its canonical identity is Phase 10 — Notification System. Implement only this canonical phase.

## Objective

Implement reliable, tenant-aware notification templates, preferences, delivery orchestration, and channel adapters driven by domain events.

## Scope

- Notification templates and versioning, recipient resolution, preferences, email/in-app adapter contracts, delivery records, retries, suppression, and status tracking.
- Event consumers for approved authentication, customer, order, payment, and expense events.
- Web notification center and tenant template/preference administration where authorized.
- Integration with scheduler-service/BullMQ for durable asynchronous delivery.

## Out of Scope

- Marketing campaigns, unsolicited bulk messaging, unsupported SMS/push providers, and arbitrary user-authored executable templates.
- Background-job platform generalization beyond notification needs; Phase 15 owns platform-wide jobs.
- Real provider activation without approved credentials and sender-domain configuration.

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

- Phase 01 auth recovery/verification delivery contract.
- Phases 02-09 tenant, user, customer, order, payment, and expense events.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- notification-service owns templates, preferences, delivery records, and adapters; scheduler-service executes durable jobs without owning notification policy.
- Use inbox deduplication for source events and idempotent delivery keys to prevent duplicate sends.
- Templates are data, sandboxed and context-allowlisted; never evaluate arbitrary code.
- Provider adapters expose normalized results and redact content/credentials from logs.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Define event-to-notification policies, template schema/versioning, recipient resolution, preferences, delivery state machine, and adapter contracts.
5. Implement notification-service persistence, APIs, template rendering, preferences, delivery history, suppression, inbox/outbox, and events.
6. Implement deterministic console/test and in-app adapters; implement email only through approved configuration.
7. Implement BullMQ delivery jobs with idempotency, bounded retries/backoff, rate controls, dead-letter handling, and operator replay.
8. Consume approved domain events and prevent duplicate notifications under redelivery or concurrency.
9. Build accessible web notification center, read/unread controls, preferences, and authorized template administration/preview.
10. Add safe template variable validation, locale/timezone hooks, and personal-data minimization.
11. Update notification architecture, service, API, event, template, provider, frontend, and runbook documentation.
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

- Persist source event ID, tenant, recipient reference, template version, channel, idempotency key, status, attempts, timestamps, and redacted provider result.
- Recipient addresses are resolved at send time under tenant policy and are never trusted from arbitrary event payload fields.
- Template rendering must fail on missing/unknown variables and escape output for the target channel.
- Preferences cannot suppress mandatory security/transactional messages when policy classifies them as mandatory.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Notification center must paginate and virtualize as needed, expose read state, and avoid leaking message content across tenant switches.
- Template preview uses representative non-sensitive sample data and the same escaping/rendering engine as delivery.
- Preference controls clearly distinguish mandatory and optional categories.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Protect provider credentials, sender identities, recipient personal data, and rendered content from logs and unauthorized APIs.
- Prevent template injection, HTML/script injection, header injection, cross-tenant template use, and malicious redirect links.
- Rate-limit high-risk security messages and alert on delivery abuse or repeated failures.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Keep notification delivery off request paths; enqueue durably and return accepted status when appropriate.
- Index tenant/recipient/status/source event/created time and expire low-value delivery details according to documented retention.
- Apply provider-aware concurrency and rate limits without starving tenants.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Unit-test rendering, escaping, variables, preferences, policy classification, idempotency, retry decisions, and redaction.
- Integration-test event consumption, queue processing, duplicate delivery prevention, adapter failures, dead-letter/replay, and read state.
- Run tenant isolation, template injection, header injection, malicious-link, and credential-redaction tests.
- End-to-end test notification center, preferences, preview, and representative transactional flows.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Complete notification architecture, event mapping, template variables, channels, preferences, delivery states, retries, DLQ, provider setup, and operator runbooks.
- Document which notifications are mandatory and the approved basis for that classification.
- Record template sandbox and idempotency decisions in ADRs.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Notification-service templates, preferences, delivery records, adapters, and event consumers.
- Durable notification jobs and web notification experiences.
- Injection, idempotency, retry, isolation, and end-to-end tests.
- A completed Phase 10 report at ERP-PLANNING/phase-completions/PHASE_10_NOTIFICATION_SYSTEM_COMPLETION.md.

## Acceptance Criteria

- [ ] A source event produces at most one delivery per intended recipient/channel/template policy despite redelivery.
- [ ] Failed deliveries retry within bounds, enter a visible dead-letter state, and can be replayed safely.
- [ ] Templates cannot execute code or inject unsafe channel content.
- [ ] Preferences and mandatory-message rules are enforced server-side.
- [ ] Notification web flows, provider abstraction, isolation, and load tests pass.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_10_NOTIFICATION_SYSTEM_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 10 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 11 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
