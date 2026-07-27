# Phase 11 — File Storage

## Phase Number

11

## Phase Name

File Storage

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 11. Work from the repository root. Execute this prompt end to end without asking the user to restate it or manually fill in values that can be discovered from the repository.

The repository is the single source of truth. Read the mandatory material before changing files, inspect current code and git status, preserve unrelated work, and reconcile this prompt with newer authoritative repository decisions. If documentation is still skeletal or conflicts with tested implementation, use the narrowest safe interpretation consistent with the existing scaffold and this phase; record every material assumption as an ADR and in the completion report. Never invent extra product scope.

This file retains the original scaffold filename `PHASE_11_BRANCHES.md`; its canonical identity is Phase 11 — File Storage. Implement only this canonical phase.

## Objective

Implement a provider-neutral, tenant-isolated file metadata and object-storage subsystem for secure uploads, downloads, scanning, retention hooks, and domain attachments.

## Scope

- File metadata, object keys, upload/download authorization, presigned transfer flow or secure streaming, content validation, scan/quarantine states, and lifecycle events.
- Local development storage adapter and production adapter interface without requiring a specific cloud provider.
- Integration with expense attachments and future customer/order documents.
- Web upload/download components and status/error handling.

## Out of Scope

- Document editing, media transcoding, OCR, e-signatures, public anonymous file sharing, and provider-specific production provisioning.
- Business-specific retention periods not established by authoritative requirements.
- Storing file binaries in MongoDB.

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

- Phase 02 tenant isolation, Phase 04 permissions, Phase 09 attachment-reference contract, and Phase 15-compatible job semantics.
- Local Docker infrastructure from Phase 00.

Do not begin feature implementation until required earlier behavior is present and its critical tests pass. If a dependency is incomplete, repair only the minimum dependency defect necessary for this phase, document it, and rerun the dependency's affected acceptance tests.

## Architecture Notes

The checked-in scaffold establishes a pnpm/TurboRepo monorepo; NestJS/TypeScript backend applications; MongoDB/Mongoose persistence; Redis/BullMQ messaging and jobs; a Flutter web application; a Flutter Android/iOS application; shared packages; Docker; initial Terraform/Helm assets; and GitHub Actions CI.

- Store binaries in object storage and metadata in an owning backend module/service selected and documented in an ADR; do not create a new top-level application directory.
- Object keys include non-guessable IDs and tenant partitioning but never raw personal data or original filenames.
- Files move through explicit pending, uploaded, scanning, available, quarantined, failed, and deleted lifecycle states as supported.
- Domain services store file IDs and verify ownership/status through contracts, never direct object-store paths.

Any material deviation requires an ADR explaining context, options, decision, consequences, migration, and rollback.

## Tasks to Perform

1. Re-read the phase scope and build a private implementation checklist mapped to acceptance criteria.
2. Inspect the current repository state, earlier completion evidence, dependency versions, tests, and uncommitted changes.
3. Define or update the contracts, ownership boundaries, data classification, failure modes, and migration/compatibility plan before coding.
4. Define file metadata, ownership, lifecycle, purpose, size/type limits, checksum, scanning, retention, deletion, and event contracts.
5. Implement metadata persistence, tenant-scoped APIs, upload authorization, finalization/checksum verification, safe download authorization, and lifecycle transitions.
6. Implement a local filesystem or compatible development adapter behind the same provider interface used by production adapters.
7. Implement asynchronous malware-scan integration boundary with a deterministic test scanner and quarantine behavior; never mark unscanned content safe.
8. Integrate expense attachment validation and reusable web upload/download components with progress and scan state.
9. Implement orphan cleanup, expired-upload cleanup, and deletion jobs with idempotency and legal-hold/retention hooks.
10. Test path traversal, key guessing, cross-tenant access, content-type spoofing, oversized files, checksum mismatch, malicious files, and race conditions.
11. Update FILE_STORAGE.md, API, security, domain integration, frontend, configuration, and operator documentation.
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

- Generate server-authoritative object keys and enforce maximum size, allowlisted content types/extensions, checksum, purpose, owner, tenant, and expiration.
- Presigned URLs must be short-lived, operation-specific, content-constrained where supported, and returned only after authorization.
- Downloads require current authorization and available scan state; quarantine and deleted objects are not downloadable.
- Metadata and provider operations must be reconciled for partial failures without pretending to have distributed transactions.

All backend work must retain global validation, consistent errors, correlation, graceful shutdown, health/readiness, tenant-aware authorization where applicable, and safe telemetry established in earlier phases.

## Frontend Requirements

- Use reusable upload components with client-side early validation, progress, cancellation, retry, and server-authoritative final status.
- Never render active file content inline unless the type and sandbox policy explicitly allow it.
- Clear tenant-bound upload state on tenant/branch switch and avoid exposing object keys.

Frontend behavior must never be the only enforcement point. Handle loading, empty, validation, forbidden, conflict, retryable failure, terminal failure, and stale-data states explicitly.

## Security Requirements

- Prevent path traversal, SSRF through provider URLs, content sniffing, polyglot upload abuse, stored XSS, cross-tenant access, and unrestricted public ACLs.
- Use safe Content-Disposition and Content-Type headers and separate quarantined objects from available content.
- Encrypt in transit and require provider-side encryption-at-rest capabilities for production adapters.

Apply deny-by-default authorization, data minimization, secret redaction, input validation, output encoding, least privilege, and tenant/branch isolation to every new access path. Add regression tests for each material threat addressed.

## Performance Requirements

- Transfer binaries directly to/from object storage when safe; do not buffer large files in application memory.
- Index tenant/owner/purpose/status/created time and process scans/cleanup asynchronously.
- Set bounded upload sizes, concurrency, timeouts, and provider retry policies.

Define representative data/workloads and record measurements rather than claiming performance from code inspection alone. Do not trade away correctness, security, or isolation for benchmark results.

## Testing Requirements

- Unit-test lifecycle, key generation, authorization, type/size/checksum validation, retention decisions, and error mapping.
- Integration-test local adapter, metadata/object consistency, scan outcomes, cleanup, retries, and domain association.
- Run security tests for traversal, spoofing, malicious content, presigned URL expiry, and cross-tenant access.
- End-to-end test web upload through available/quarantined/failure and authorized download.

At minimum, run all touched-package format/lint/type/test/build commands plus relevant root gates. Tests must cover success, validation, authentication, authorization, tenant/branch isolation, concurrency, idempotency, dependency failure, and recovery wherever applicable.

## Documentation Requirements

- Complete file architecture, lifecycle, metadata, provider interface, security controls, limits, scan integration, APIs, events, cleanup, and incident procedures.
- Record service/module ownership and direct-upload decisions in ADRs.
- Document local development usage and production-provider requirements without embedding credentials.

Documentation must describe implemented behavior only, use safe synthetic examples, contain no secrets, and link to authoritative schemas/tests/ADRs.

## Deliverables

- Tenant-isolated file metadata and object-storage abstraction with local adapter.
- Secure upload/download, scan/quarantine, cleanup, and expense attachment integration.
- Reusable web components, security tests, and full storage documentation.
- A completed Phase 11 report at ERP-PLANNING/phase-completions/PHASE_11_FILE_STORAGE_COMPLETION.md.

## Acceptance Criteria

- [ ] Only authorized users can upload, associate, or download files within their tenant and allowed domain scope.
- [ ] Unscanned, quarantined, failed, deleted, oversized, spoofed, or checksum-mismatched content is unavailable.
- [ ] Large files do not cause unbounded application memory use.
- [ ] Partial failures and orphaned objects are detected and recoverable.
- [ ] Storage lifecycle, isolation, security, and web tests pass.
- [ ] Every task and deliverable in this prompt is complete, and every out-of-scope boundary remains intact.
- [ ] Formatting, linting, type checks, tests, security checks, and builds relevant to touched work pass from documented commands.
- [ ] The completion report is factual, contains exact file lists and test evidence, and identifies all limitations or pending external gates.

## Completion Instructions

1. Review the final diff and map each acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run the full relevant validation suite and record exact commands and outcomes. Never report a check as passing if it was skipped, unavailable, or failed.
3. Update `ERP-PLANNING/phase-completions/PHASE_11_FILE_STORAGE_COMPLETION.md` in place. Replace its authoring guidance with the actual Phase 11 report while retaining every required heading.
4. Under Files Created and Files Modified, list repository-relative paths exactly. State `None` when a category is empty.
5. Under Known Limitations and Pending Work, state `None` only after verifying there is nothing to report; otherwise include impact, owner or required authority, and the next safe action.
6. Include architecture/security decisions, migrations, compatibility notes, test evidence, measured performance, and notes needed by Phase 12 when another phase follows.
7. End work after the completion report and documentation are accurate. Do not begin the next phase.
