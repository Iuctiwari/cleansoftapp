# Phase 17 — Admin Panel and Settings

## Phase Number

17

## Phase Name

Admin Panel and Settings

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 17. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_17_NOTIFICATIONS.md`; its canonical identity is Phase 17 — Admin Panel and Settings. Implement only this canonical phase.

## Objective

Deliver a cohesive, permission-safe Flutter web administration panel for platform and tenant operations, configuration, audit review, and system health.

## Scope

- Unified navigation and administration surfaces for tenant, branch, users/RBAC, customers, catalog, orders, payments, expenses, notifications, files, jobs, audit, and supported settings.
- Strict separation of platform-admin, tenant-admin, and branch-operational views.
- Settings registry with typed ownership, validation, versioning, defaults, and safe change history.
- Operational health summaries and approved job/audit controls.

## Out of Scope

- Support impersonation unless explicitly approved with step-up authentication and audit policy.
- Direct database editing, arbitrary configuration keys, secret-value display/editing, and bypass of domain APIs.
- New domain behavior or analytics beyond completed services.

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

- Phases 02-16 and their stable APIs, permissions, health, job, and audit contracts.
- Phase 14 dashboard design system and web shell.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- The admin panel is an API client, not an authorization boundary. Every action remains enforced by the owning backend service.
- Separate platform routes/permissions from tenant routes/permissions and make active scope visually unmistakable.
- Settings are typed and owned by a specific service; a registry/composition layer may expose them but must not create an unowned global settings document.
- High-impact operations require explicit confirmation, reason capture where appropriate, optimistic concurrency, and audit records.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Create an admin information architecture, route/permission matrix, navigation model, design-system components, and platform-versus-tenant visual boundaries.
5. Integrate completed administration screens into a consistent responsive shell with breadcrumbs, search, tables, forms, error/loading/empty states, and scope switching.
6. Implement missing tenant/platform settings APIs through their owning services with typed schemas, validation, defaults, versions, and events.
7. Implement audit viewer filters/details/export handoff, redaction display, and integrity/ingestion status for authorized users.
8. Implement redacted job/queue health and safe pause/retry/replay/cancel controls using Phase 15 APIs.
9. Implement platform tenant lifecycle/support views without cross-tenant data browsing beyond explicit permissions.
10. Run comprehensive route, permission, accessibility, responsive, concurrency, scope-switch, and dangerous-action tests.
11. Update admin IA, permission matrix, settings registry, operator workflows, accessibility, and support documentation.
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

- Add only the composition/settings endpoints required by the admin experience; continue routing mutations to owning services.
- Settings updates require schema validation, scope validation, version checks, permission checks, events, and audit records.
- Operational endpoints return bounded/redacted summaries and never raw queue payloads, environment values, or credentials.
- High-risk platform operations must support reason, correlation, and step-up hooks where policy requires.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Meet WCAG 2.2 AA-oriented behavior: keyboard access, focus management, labels, contrast, text scaling, reduced motion, and accessible validation.
- Use server-side pagination/filtering and virtualized tables where measured data size requires it.
- Clear all scoped state on logout/tenant/branch change and prevent opening stale deep links without reauthorization.
- Use consistent confirmation patterns and never rely on color alone for risk/status.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Test every route and action against the permission matrix at frontend and backend layers.
- Prevent confused-deputy operations between platform and tenant contexts, stale-scope mutations, CSRF where applicable, and unsafe redirects.
- Never render secrets, raw tokens, credentials, sensitive job payloads, or unredacted audit fields.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Lazy-load feature areas, paginate large datasets, cancel stale requests, and set frontend bundle/render budgets.
- Compose health summaries with short timeouts and partial failure instead of synchronous unbounded fan-out.
- Measure route transition, table interaction, and high-volume audit/job page performance.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Unit/widget-test permission-aware components, forms, settings validation, scope boundaries, and dangerous-action confirmations.
- Integration-test settings ownership/events/audit, admin composition endpoints, job controls, and audit viewer.
- End-to-end test platform admin, tenant admin, branch user, and denied-user journeys across routes/actions.
- Run automated accessibility scans plus keyboard/screen-reader-oriented manual checks recorded in the completion report.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Document admin navigation, route/permission matrix, settings registry/ownership, dangerous operations, support workflows, accessibility, and troubleshooting.
- Document platform-versus-tenant boundaries and explicitly prohibited admin capabilities.
- Record the settings ownership/composition decision in an ADR.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Cohesive Flutter web admin panel and design-system integration.
- Typed settings registry/owned APIs, audit viewer, and safe job/system controls.
- Permission, scope, accessibility, responsive, security, and end-to-end tests.
- A completed Phase 17 report at ERP-PLANNING/phase-completions/PHASE_17_ADMIN_PANEL_COMPLETION.md.

## Acceptance Criteria

- [ ] Every admin route/action is protected by the documented backend permission matrix.
- [ ] Platform, tenant, and branch contexts are never confused or mixed in state, cache, navigation, or mutations.
- [ ] Settings are typed, validated, versioned, owned, evented, and audited.
- [ ] Audit/job operational data is redacted and dangerous controls are attributable.
- [ ] Accessibility, responsive, permission, and performance suites meet documented gates.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_17_ADMIN_PANEL_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 17 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 18 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
