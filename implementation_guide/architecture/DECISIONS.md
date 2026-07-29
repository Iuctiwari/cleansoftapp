# Architecture Decisions

> Append-only log. Existing entries are never deleted or rewritten. A changed decision gets a new ADR that names the superseded ADR; the earlier entry remains and is marked superseded in place.

## ADR-001 — Monorepo

- **Date:** 2026-07-27 (migrated 2026-07-28)
- **Status:** Accepted
- **Decision:** Use the existing pnpm/TurboRepo monorepo for backend applications and shared technical packages; Flutter remains a workspace application.
- **Reasoning:** Supports `NFR-MAINT-01`, central quality gates, shared contracts, and the repository foundation already approved in Phase 2.
- **Trade-off accepted:** Repository coordination and dependency discipline become mandatory; a large workspace can increase install/build complexity.
- **Alternatives considered:** Separate repositories were rejected because they would fragment early contracts, quality gates, and a small team's delivery.

## ADR-002 — Logical service ownership with initially consolidatable deployment

- **Date:** 2026-07-27 (migrated 2026-07-28)
- **Status:** Accepted
- **Decision:** Preserve one logical owner per domain service while allowing initial runtime consolidation; extraction is evidence-driven.
- **Reasoning:** Satisfies `FR-PLATFORM-03`, `NFR-MAINT-01`, and `R-3` while controlling `R-13`.
- **Trade-off accepted:** Logical boundaries must be enforced in code/contracts even when process boundaries do not enforce them automatically.
- **Alternatives considered:** Immediate independent microservices were rejected as premature operational complexity; one undifferentiated NestJS application was rejected because it obscures ownership and future scaling.

## ADR-003 — API gateway is the only public backend entry point

- **Date:** 2026-07-27 (migrated 2026-07-28)
- **Status:** Accepted
- **Decision:** All public client/API traffic enters through `apps/api-gateway`; domain services remain private.
- **Reasoning:** Centralizes versioning, context, throttling, transport security, compatibility, and tenant-safe errors for `FR-PLATFORM-01` and `FR-PLATFORM-02`.
- **Trade-off accepted:** Gateway availability and latency are critical, and gateway/domain contract compatibility must be tested.
- **Alternatives considered:** Public domain services were rejected because they duplicate security policy and expand attack surface.

## ADR-004 — MongoDB logical ownership on a managed replica set

- **Date:** 2026-07-27 (migrated 2026-07-28)
- **Status:** Accepted, production provider pending `OQ-31`
- **Decision:** Use MongoDB/Mongoose. Services may initially share a managed deployment but own separate logical collections/credentials; production requires replica-set transaction capability.
- **Reasoning:** Matches the existing stack and flexible service-business model while supporting local transactions and later separation (`NFR-SCALE-03`).
- **Trade-off accepted:** Cross-service relational constraints are not database-enforced, and local/CI parity must be deliberately provided (`R-10`).
- **Alternatives considered:** Relational replacement was rejected because it contradicts the approved baseline; one shared unrestricted database model was rejected because it violates ownership.

## ADR-005 — Redis and BullMQ for bounded caching and background work

- **Date:** 2026-07-27 (migrated 2026-07-28)
- **Status:** Accepted
- **Decision:** Use Redis for bounded cache/revocation support and BullMQ for queues/jobs.
- **Reasoning:** Supports notification bursts, retries, scheduled work, cache invalidation, and recovery visibility (`FR-JOB-*`).
- **Trade-off accepted:** Redis becomes an operational dependency; cache/job isolation, memory, retries, and dead letters require explicit governance.
- **Alternatives considered:** In-process jobs/cache were rejected as non-durable and non-scalable; using Redis as financial truth was rejected.

## ADR-006 — Transactional outbox and idempotent consumers

- **Date:** 2026-07-27 (migrated 2026-07-28)
- **Status:** Accepted
- **Decision:** Commit domain state and pending events in one local consistency boundary; publish at least once; require idempotent consumers and reconciliation.
- **Reasoning:** Prevents lost cross-module effects and addresses `R-4` while keeping services independently owned.
- **Trade-off accepted:** Consumers observe eventual consistency and must maintain deduplication, lag monitoring, dead-letter, replay, and rebuild paths.
- **Alternatives considered:** Distributed transactions were rejected as operationally heavy; best-effort post-commit publish was rejected because it loses facts.

## ADR-007 — Private S3-compatible object storage

- **Date:** 2026-07-27 (migrated 2026-07-28)
- **Status:** Accepted, provider/scanner pending `OQ-20` and `OQ-31`
- **Decision:** Store files privately outside MongoDB; use purpose validation, malware controls, tenant prefixes, and time-limited signed access.
- **Reasoning:** Satisfies `FR-FILE-*`, isolation, scaling, and secure evidence handling.
- **Trade-off accepted:** Upload scanning, orphan cleanup, retention, provider availability, and signed-link leakage must be operated.
- **Alternatives considered:** Public buckets were rejected as unsafe; database blobs were rejected for scaling/backup impact.

## ADR-008 — Flutter mobile is the current client scope

- **Date:** 2026-07-28
- **Status:** Accepted
- **Decision:** Current implementation scope contains the Flutter Android/iOS application only; the former Flutter web application and its implementation obligations are retired.
- **Reasoning:** The user explicitly removed `apps/web-frontend`; Layer 1 MVP now requires `FR-MOBILE-*` without web scope.
- **Trade-off accepted:** Desktop/browser operations are unavailable unless a future product decision reintroduces a client and contracts.
- **Alternatives considered:** Keeping stale web plans was rejected because they reference deleted implementation; recreating web was rejected because it is not authorized.

## ADR-009 — Terraform and Helm are foundations, not production readiness

- **Date:** 2026-07-27 (migrated 2026-07-28)
- **Status:** Accepted
- **Decision:** Describe current infrastructure directories as foundations until provider/topology decisions and executable evidence exist.
- **Reasoning:** Preserves factual documentation and avoids false release confidence (`OQ-31`).
- **Trade-off accepted:** Deployment phase remains blocked on production decisions and implementation.
- **Alternatives considered:** Treating scaffolds as completed infrastructure was rejected as inaccurate.

## ADR-010 — Domain ownership of delivery, settings, and receipts

- **Date:** 2026-07-27 (migrated 2026-07-28)
- **Status:** Accepted
- **Decision:** Order owns delivery, Tenant owns settings, and Payment owns receipts.
- **Reasoning:** Matches current repository service boundaries and avoids artificial services for tightly coupled lifecycle/financial/configuration facts.
- **Trade-off accepted:** These services have broader bounded contexts and must maintain internal separation.
- **Alternatives considered:** Dedicated delivery/settings/receipt services were rejected because no repository owner or independent scaling/consistency need exists.

## ADR-011 — Financial representation and immutable history

- **Date:** 2026-07-27 (migrated 2026-07-28)
- **Status:** Accepted direction; detailed policy pending `OQ-4`–`OQ-10`
- **Decision:** Use integer minor currency units plus ISO currency; fixed precision for quantities/percentages; snapshot transaction inputs; additive refunds/corrections; immutable finalized records.
- **Reasoning:** Protects `FR-ORDER-02`, `FR-PAYMENT-02`, `NFR-DATA-01`–`NFR-DATA-03`, and mitigates `R-5`.
- **Trade-off accepted:** Every boundary must convert/round deterministically, and policy changes require migrations/versioned snapshots.
- **Alternatives considered:** Binary floating point and mutable historical totals were rejected as financially unsafe.

## ADR-012 — Event-fed report/search/dashboard projections

- **Date:** 2026-07-27 (migrated 2026-07-28)
- **Status:** Accepted
- **Decision:** Reports, search, and dashboard use owner-fed, tenant-scoped, rebuildable projections rather than reading private collections.
- **Reasoning:** Protects ownership and transactional workloads while enabling `FR-REPORT-*`, `FR-SEARCH-*`, and `FR-DASHBOARD-*`.
- **Trade-off accepted:** Results can lag; freshness, replay, reconciliation, and rebuild are product/operational concerns.
- **Alternatives considered:** Direct cross-service aggregation was rejected for coupling/security/load; making projections authoritative was rejected.

## ADR-013 — Separate platform and tenant authorization contexts

- **Date:** 2026-07-27 (migrated 2026-07-28)
- **Status:** Accepted
- **Decision:** Super Admin uses platform-only tokens; tenant users authenticate with organization plus email/mobile and active membership.
- **Reasoning:** Prevents implicit tenant access, identity ambiguity across tenants, and cross-tenant support escalation (`FR-AUTH-01`, `R-1`).
- **Trade-off accepted:** Platform and tenant flows, guards, audit, and support processes must be maintained separately.
- **Alternatives considered:** Globally unique user login without organization context and universal admin tokens were rejected for ambiguity and excessive privilege.

## ADR-014 — Rotating revocable refresh-session families

- **Date:** 2026-07-27 (migrated 2026-07-28)
- **Status:** Accepted direction; lifetimes pending `OQ-17`
- **Decision:** Store refresh credentials only as hashes, rotate on use, revoke individually/family-wide on reuse, and use platform secure storage on mobile.
- **Reasoning:** Supports revocation and reduces replay impact for `FR-AUTH-02`, `FR-MOBILE-02`.
- **Trade-off accepted:** Session-family state and race handling add persistence and UX complexity.
- **Alternatives considered:** Stateless long-lived JWTs were rejected because prompt revocation is required; plaintext token storage was rejected.

## ADR-015 — Append-only audit evidence separate from logs

- **Date:** 2026-07-27 (migrated 2026-07-28)
- **Status:** Accepted; critical failure matrix pending `OQ-26`
- **Decision:** Audit service owns immutable critical-action evidence; operational logs remain separately governed telemetry.
- **Reasoning:** Satisfies `FR-AUDIT-*`, accountability, security review, and financial traceability.
- **Trade-off accepted:** Reliable audit delivery, retention, privacy-safe summaries, query authorization, and failure behavior add cross-cutting work.
- **Alternatives considered:** Using logs as audit was rejected because logs are mutable/operational and lack domain guarantees.

## ADR-016 — Versioned resource-oriented REST surface

- **Date:** 2026-07-28
- **Status:** Accepted engineering default, subject to compatibility decision `OQ-21`
- **Decision:** Expose the existing planned resource paths through a gateway prefix `/api/v1`; use nouns for resources, explicit action subresources only for lifecycle commands, bounded query parameters for lists, `Idempotency-Key` for harmful duplicates, and `If-Match`/expected version for concurrency-sensitive mutations.
- **Reasoning:** Existing module prompts already define REST paths for authentication, branches, users, customers, catalog, orders, payments, and notifications. One consistent convention completes the missing module surfaces while supporting `NFR-MAINT-03`.
- **Trade-off accepted:** Action endpoints such as `/cancel` or `/close` are less purely RESTful but make business commands, authorization, and audit meaning explicit.
- **Alternatives considered:** GraphQL was rejected because it is not in the approved source and complicates field-level authorization; unversioned routes were rejected because mobile releases cannot update instantly; generic CRUD-only routes were rejected because lifecycle commands have distinct invariants.

## ADR-017 — Backend services grouped under one application directory

- **Date:** 2026-07-28
- **Status:** Accepted; repository-structure change only
- **Decision:** The backend gateway and domain-service directories move from `apps/<service>/` to `apps/backend/<service>/`; the Flutter application remains at `apps/mobile-app/`. This changes repository paths only and does not supersede the ingress or service-boundary decisions in `ADR-002`.
- **Reasoning:** The repository owner requested one explicit backend boundary under `apps/` while retaining the existing service separation and mobile application location.
- **Trade-off accepted:** Workspace patterns, tooling, documentation, CI/CD, and developer commands must use one additional path segment, and stale external automation may require corresponding path updates.
- **Alternatives considered:** Keeping all deployables as direct children of `apps/` was rejected because it does not provide the requested backend grouping; combining service source code into one package was rejected because it would alter architecture and risk application behavior.
