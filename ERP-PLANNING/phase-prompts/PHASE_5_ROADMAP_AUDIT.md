# Phase 05 — Customer Management

## Phase Number

05

## Phase Name

Customer Management

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 05. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_5_ROADMAP_AUDIT.md`; its canonical identity is Phase 05 — Customer Management. Implement only this canonical phase.

## Objective

Implement tenant-safe customer records and operational customer management for later order workflows.

## Scope

- Customer profiles, normalized contact channels, addresses, preferences, notes, status, and branch associations where approved.
- Duplicate detection signals and controlled merge behavior that preserves references.
- Paginated/filterable customer APIs and responsive web management screens.
- Customer lifecycle events for search, audit, and notifications.

## Out of Scope

- Customer self-service portal, loyalty programs, marketing automation, credit scoring, and order/payment behavior.
- Biometric or highly sensitive identity data.
- Unapproved automatic deduplication that can destroy or combine records without review.

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

- Phase 02 tenant isolation.
- Phase 03 branch scope and Phase 04 permissions.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- customer-service owns customer operational data; other services reference customerId and consume versioned events.
- Customers are tenant owned. Branch association semantics must be explicit and must not prevent authorized tenant-wide lookup when requirements allow it.
- Treat contact fields and addresses as personal data with minimization, redaction, export, and deletion/anonymization considerations.
- Merges must create an auditable redirect from duplicate IDs to the surviving record.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Define customer entity, contact/address value objects, status lifecycle, consent/preferences, duplicate signals, and merge contract.
5. Implement customer-service persistence, indexes, validation, optimistic concurrency, pagination, filters, and CRUD/lifecycle APIs.
6. Implement permission and tenant/branch enforcement on every access path.
7. Implement explicit reviewed merge behavior with reference-preservation events and no silent data loss.
8. Build accessible web customer list, search/filter, create/edit, details, notes, status, and merge-review experiences.
9. Publish versioned customer created/updated/status/merged events containing only required data.
10. Add personal-data logging redaction, retention hooks, and export/delete integration contracts without implementing an unapproved retention policy.
11. Update customer-service, domain model, API, privacy/security, and frontend documentation.
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

- Normalize phone/email fields for matching while retaining display-safe originals; validate but do not require data that business requirements do not establish.
- Use tenant-scoped uniqueness only where the project explicitly requires uniqueness; otherwise surface duplicate candidates.
- Use opaque IDs, immutable creation metadata, change versions, and soft lifecycle status.
- Notes must be permission-protected, size-bounded, sanitized on rendering, and excluded from broad events/search unless approved.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Provide fast server-side pagination/filtering and safe display of personal data.
- Forms must support international addresses/contact formats without making country-specific assumptions.
- Merge review must clearly show the survivor, affected fields, and irreversible consequences and require appropriate permission.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Enforce least-privilege access to customer personal data and redact it from logs, metrics, events, URLs, and client errors.
- Test tenant/branch isolation, ID enumeration, mass assignment, stored XSS in notes, and export authorization.
- Record sensitive reads and all mutations in the audit-ready contract when policy requires.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Create tenant-scoped indexes for status, normalized contacts, name lookup, branch association, and update time.
- Use bounded pagination and projection; never return unbounded customer lists.
- Design duplicate matching to avoid full scans and cap candidate results.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Unit-test normalization, validation, duplicate candidates, merge conflict rules, lifecycle, and event redaction.
- Integration-test persistence/index constraints, CRUD, pagination, filters, concurrency, and merge redirects.
- Run tenant/branch isolation and personal-data exposure tests.
- End-to-end test core web customer workflows, accessibility, and responsive behavior.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Document data classification, entity fields, branch scope, merge semantics, API contracts, indexes, events, and privacy hooks.
- Describe operator recovery for mistaken status changes and merge incidents.
- Update domain and relationship documentation with customer ownership and references.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Customer-service domain implementation and tenant/branch-safe APIs.
- Web customer management and duplicate merge review.
- Events, tests, privacy controls, and customer documentation.
- A completed Phase 05 report at ERP-PLANNING/phase-completions/PHASE_05_CUSTOMER_MANAGEMENT_COMPLETION.md.

## Acceptance Criteria

- [ ] Authorized users can manage customers within correct tenant/branch scope with stable pagination and concurrency handling.
- [ ] Duplicate merge preserves references and is fully auditable.
- [ ] Personal data does not leak through logs, events, errors, URLs, or unauthorized APIs.
- [ ] Cross-tenant and unauthorized cross-branch tests pass.
- [ ] Customer APIs and web workflows meet documented accessibility and latency targets.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_05_CUSTOMER_MANAGEMENT_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 05 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 06 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
