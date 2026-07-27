# Phase 01 — Authentication

## Phase Number

01

## Phase Name

Authentication

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 01. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_1_SOFTWARE_IDEA.md`; its canonical identity is Phase 01 — Authentication. Implement only this canonical phase.

## Objective

Implement secure identity authentication and session lifecycle capabilities in auth-service, expose them through the gateway, and provide the web authentication experience.

## Scope

- Credential-based sign-in, sign-out, access-token renewal, password reset, email verification, session revocation, and lockout/rate-limit controls.
- Authentication identity records and session records owned exclusively by auth-service.
- Gateway authentication enforcement and trusted propagation of identity context.
- Accessible Flutter web screens and state handling for authentication flows.

## Out of Scope

- Tenant provisioning, tenant authorization, branch assignment, user profile administration, and full RBAC policy management.
- Third-party social identity providers, SAML/OIDC enterprise federation, and mobile authentication UI.
- Business-module permissions or domain data.

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

- Phase 00 completion and its verified platform foundation.
- Approved email-delivery abstraction may be stubbed behind an interface until Phase 10; secrets and real provider credentials are not required.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- Separate authentication identity and credentials from the user-service profile. Reference identities by immutable opaque IDs.
- Use short-lived access tokens and server-controlled rotating refresh sessions; store only hashed refresh-token material.
- Publish versioned authentication lifecycle events through the shared event envelope without embedding credentials or tokens.
- Gateway verification must fail closed and must not trust caller-supplied identity headers.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Define and document authentication API contracts, error codes, token/session model, and abuse-control behavior.
5. Implement identity persistence with unique normalized identifiers, password hashing, verification state, lockout metadata, refresh-session rotation, and revocation.
6. Implement register or invitation-acceptance behavior only to the extent supported by current requirements; do not create tenant or user-profile behavior here.
7. Implement sign-in, sign-out, refresh rotation, sign-out-all, email verification, forgot-password, and reset-password workflows with single-use expiring tokens.
8. Add gateway guards, decorators, and trusted context propagation with uniform unauthorized and forbidden responses.
9. Build web sign-in, forgot/reset password, verification, session-expired, and sign-out experiences with safe loading/error states.
10. Emit audit-ready security events and authentication lifecycle events without sensitive payloads.
11. Update API, security, auth-service, gateway, and web-auth documentation and complete the phase report.
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

- Use an industry-standard adaptive password hash with centrally configured cost and migration support; never encrypt or log plaintext passwords.
- Refresh rotation must detect replay, revoke the affected token family, and be safe under concurrent requests.
- Verification and reset tokens must be random, hashed at rest, single use, purpose bound, and expire.
- All write endpoints require validated DTOs, consistent errors, explicit idempotency where retries are expected, and structured security logging.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Implement web authentication routes, guarded navigation, session restoration, token refresh coordination, and accessible forms.
- Keep access credentials in the safest platform-appropriate mechanism; do not persist long-lived secrets in browser local storage.
- Prevent duplicate submissions, avoid account enumeration in recovery messaging, and clear sensitive form state after use.
- Mobile UI remains out of scope; publish reusable API contracts for Phase 18.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Apply rate limits by route, account signal, and network signal without enabling easy denial of service against a single account.
- Use constant-behavior recovery responses, strong password-policy validation, secure cookie attributes when cookies are used, CSRF protection where applicable, and token audience/issuer checks.
- Redact authorization headers, cookies, credentials, reset tokens, and verification tokens from all telemetry.
- Test brute force, token replay, session fixation, open redirect, account enumeration, and expired/revoked token cases.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Index normalized login identifiers, token hashes, session ownership, and expiration fields.
- Bound password-hash concurrency and response latency without weakening the configured hash cost.
- Avoid authentication database lookups on every request when cryptographic verification is sufficient; perform revocation checks according to the documented threat model.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Unit-test token issuance/verification, password hashing, normalization, expiry, rotation, replay detection, and error mapping.
- Integration-test all auth endpoints against real test persistence and Redis-based rate limiting.
- End-to-end test web sign-in, refresh, protected navigation, recovery, verification, sign-out, and forced expiry.
- Include negative security tests for tampering, replay, enumeration resistance, lockout boundaries, and concurrent refresh.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Document auth endpoints, schemas, status/error codes, session lifecycle, configuration, event contracts, and operational revocation procedures.
- Record the token storage and refresh architecture in an ADR.
- Add safe developer instructions for test accounts without committing reusable credentials.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Production-grade auth-service identity and session lifecycle implementation.
- Gateway authentication enforcement and web authentication flows.
- Versioned contracts, tests, security documentation, and authentication events.
- A completed Phase 01 report at ERP-PLANNING/phase-completions/PHASE_01_AUTHENTICATION_COMPLETION.md.

## Acceptance Criteria

- [ ] Valid users can complete the supported authentication lifecycle; invalid, expired, replayed, and revoked credentials fail consistently.
- [ ] Refresh tokens rotate atomically and replay revokes the token family.
- [ ] Protected gateway routes cannot be reached with caller-forged identity context.
- [ ] The web authentication flows pass accessibility-focused widget/end-to-end tests.
- [ ] No plaintext credential or live token appears in persistence, logs, events, fixtures, or reports.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_01_AUTHENTICATION_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 01 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 02 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
