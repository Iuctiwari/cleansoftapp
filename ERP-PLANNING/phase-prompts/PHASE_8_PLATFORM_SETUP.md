# Phase 08 — Payment Management

## Phase Number

08

## Phase Name

Payment Management

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 08. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_8_PLATFORM_SETUP.md`; its canonical identity is Phase 08 — Payment Management. Implement only this canonical phase.

## Objective

Implement auditable payment records, allocation to orders, provider-neutral collection/refund contracts, and secure payment workflows without storing prohibited card data.

## Scope

- Payment intents/records, methods, statuses, order allocation, receipts, refunds/voids where supported, reconciliation metadata, and idempotent webhook/command processing.
- Manual/offline payment recording and provider adapter interfaces with a safe test adapter.
- Payment APIs, events, permissions, and web order-payment experiences.
- Order balance projections driven by payment events without cross-service collection access.

## Out of Scope

- Accounting ledger, bank settlement automation, tax filing, subscription billing, chargeback automation, or storing raw payment-card data.
- A real payment provider unless credentials and approved requirements already exist at execution time.
- Changing completed historical monetary snapshots.

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

- Phase 07 order aggregate and money conventions.
- Phase 04 RBAC, Phase 02 tenant isolation, and Phase 03 branch scope.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- payment-service owns payment and refund state. order-service consumes payment events or a read projection and does not read payment collections.
- Use integer minor units and currency on every financial record. Financial records are append-oriented and corrections use reversal/refund semantics.
- Provider calls and webhooks require idempotency, signature verification, replay protection, and state-machine validation.
- Keep provider-specific payloads behind adapters and persist only the minimal redacted fields required for operations.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Define payment, allocation, refund, receipt, provider adapter, webhook, and reconciliation contracts plus explicit status transitions.
5. Implement payment-service persistence, indexes, domain logic, APIs, optimistic concurrency, and outbox events.
6. Implement manual/offline payment recording and a deterministic test provider; add a real provider only when repository-approved configuration exists.
7. Implement idempotent payment initiation, confirmation, webhook handling, refund/void commands, and duplicate-event suppression.
8. Integrate order balance/status projections through versioned events without distributed transactions.
9. Build secure web payment history, record-payment, receipt, refund/void, and reconciliation-status experiences gated by permission.
10. Add financial audit-ready records, reconciliation checks, and operator recovery paths.
11. Update payment-service, order integration, API, security, event, and operator documentation.
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

- Never accept client-calculated outstanding balance as authoritative; validate against the order/payment projection.
- Enforce currency match, positive bounded amounts, allocation limits, refund limits, and monotonic provider state.
- Store provider transaction references with tenant-scoped uniqueness and redact raw payloads.
- Use atomic outbox/inbox patterns so payment state and events remain consistent.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Clearly distinguish pending, successful, failed, reversed, and refunded states; never show success before server confirmation.
- Prevent duplicate submissions and make uncertain network outcomes recoverable by idempotency-key lookup.
- Mask sensitive references and restrict refund/void actions to explicit permissions with confirmation.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Keep the system outside unnecessary PCI scope: do not collect, transmit, or persist PAN, CVV, magnetic-stripe, or equivalent sensitive authentication data.
- Verify webhook signatures against the raw body, enforce timestamps/nonces, and reject replayed events.
- Protect receipts and transaction references by tenant/branch permission and log all financial mutations.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Index tenant/branch, order, provider reference, idempotency key, status, and transaction time.
- Process webhooks quickly with durable asynchronous follow-up and bounded retries.
- Avoid synchronous report/reconciliation scans in request paths.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Unit/property-test money allocation, status transitions, refunds, idempotency, webhook verification, and redaction.
- Integration-test payment/order event flow, outbox/inbox, duplicate webhooks, concurrency, and recovery.
- Run permission, tenant/branch isolation, tampered webhook, replay, and over-refund tests.
- End-to-end test manual/test-provider payment and refund flows in web.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Document financial state machines, provider adapter contract, money/allocation rules, webhooks, APIs, events, reconciliation, receipts, and incident response.
- Record PCI-scope avoidance and payment/order consistency decisions in ADRs.
- Document test-provider usage without including real credentials.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Payment-service records, allocations, refunds, provider abstraction, webhooks, and events.
- Web payment workflows and order balance integration.
- Financial security, reconciliation, isolation, and end-to-end tests.
- A completed Phase 08 report at ERP-PLANNING/phase-completions/PHASE_08_PAYMENT_MANAGEMENT_COMPLETION.md.

## Acceptance Criteria

- [ ] Duplicate commands or webhooks cannot create duplicate financial effects.
- [ ] Refunds/voids cannot exceed eligible amounts and every financial change is attributable.
- [ ] Order balances converge from events and reconciliation detects discrepancies.
- [ ] No prohibited card data or unredacted provider secrets exist in the repository, persistence, logs, events, or reports.
- [ ] Payment security, concurrency, isolation, and web tests pass.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_08_PAYMENT_MANAGEMENT_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 08 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 09 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
