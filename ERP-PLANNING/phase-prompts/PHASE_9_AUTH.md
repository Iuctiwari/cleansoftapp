# Phase 09 — Expense Management

## Phase Number

09

## Phase Name

Expense Management

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 09. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_9_AUTH.md`; its canonical identity is Phase 09 — Expense Management. Implement only this canonical phase.

## Objective

Implement tenant- and branch-scoped expense capture, categorization, attachment references, review lifecycle, and operational web management.

## Scope

- Expense categories, expense records, money/currency, dates, vendor/payee text, notes, attachment metadata references, status/review history, and reversal/correction behavior.
- Paginated/filterable APIs, events, permissions, and responsive web screens.
- Reporting and audit integration contracts.

## Out of Scope

- Full double-entry accounting, payroll, purchase orders, bank feeds, tax filing, reimbursements, and unsupported multi-stage approvals.
- File binary storage, which belongs to Phase 11; use the storage metadata contract.
- Automatic classification using external AI or financial data.

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

- Phase 02 tenant isolation, Phase 03 branches, Phase 04 RBAC, and Phase 06 money conventions.
- Phase 11 will complete file storage; until then use a stable attachment reference interface.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- expense-service owns expense and category records. Financial history is append-oriented; corrections preserve the original record and attribution.
- Review/approval complexity must follow authoritative requirements. If none exist, implement a minimal draft-to-recorded lifecycle with explicit correction and record the choice.
- Store file metadata references only; do not embed binaries in MongoDB records.
- Use outbox events for reporting/search/audit consumers.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Define category, expense, money, attachment reference, lifecycle, correction, and event contracts.
5. Implement expense-service persistence, indexes, domain/service layer, validated APIs, optimistic concurrency, pagination, and filters.
6. Implement category lifecycle and safe behavior when categories are in use.
7. Implement draft/record/review/correct operations required by current requirements with explicit permissions and immutable history.
8. Integrate attachment references through an interface compatible with Phase 11.
9. Build accessible web category administration and expense list/create/edit/detail/review/correction experiences.
10. Publish versioned expense events and audit-ready before/after records.
11. Update expense-service, API, domain, event, storage-integration, frontend, and operator documentation.
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

- Use integer minor units, ISO currency, bounded amounts, explicit expense date/timezone semantics, and server-side validation.
- All category and expense access must include tenant and branch scope according to documented permissions.
- Referenced/inactive categories remain resolvable; hard deletion is forbidden for used financial categories.
- Attachment IDs must be tenant-bound and verified before association.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Use locale-aware money/date presentation while sending precise values and explicit dates.
- Provide server-side filtering by branch, category, status, and date range with stable pagination.
- Surface attachment scan/processing state without treating an unverified upload as safe.
- High-impact corrections require clear confirmation and permission.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Restrict financial reads/writes/approvals/corrections by explicit permissions and branch scope.
- Sanitize notes/vendor text, validate attachment ownership, and prevent formula injection in later exports.
- Record all financial mutations and sensitive reads required by policy.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Index tenant/branch, category, status, expense date, created time, and report filter combinations.
- Paginate lists and defer binary operations to file storage/background jobs.
- Validate report-range query plans with representative data.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Unit-test money/date handling, lifecycle, category behavior, corrections, permissions, and attachment validation.
- Integration-test CRUD, concurrency, filters, indexes, events, and category-in-use behavior.
- Run tenant/branch isolation, authorization, malicious text, and attachment-reference tests.
- End-to-end test web expense and category workflows.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Document entity fields, financial lifecycle, category rules, permissions, APIs, events, indexes, attachment contract, and corrections.
- Record any approval-scope decision in an ADR.
- Document operator recovery and export-safety requirements for later reporting.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Expense-service categories, expenses, lifecycle, corrections, APIs, and events.
- Web expense management and storage-compatible attachment references.
- Financial precision, isolation, security, and workflow tests.
- A completed Phase 09 report at ERP-PLANNING/phase-completions/PHASE_09_EXPENSE_MANAGEMENT_COMPLETION.md.

## Acceptance Criteria

- [ ] Expenses are precise, attributable, tenant/branch isolated, and cannot be destructively rewritten after recording.
- [ ] Used categories cannot be hard-deleted or break historical records.
- [ ] Attachment association rejects cross-tenant or unsafe references.
- [ ] Unauthorized financial operations fail consistently and are test-covered.
- [ ] Expense API and web workflows meet documented correctness and latency targets.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_09_EXPENSE_MANAGEMENT_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 09 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 10 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
