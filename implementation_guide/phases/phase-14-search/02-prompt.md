# Phase 14 — Search Service (Search Projection) Implementation Prompt (Condensed)

## Phase Info
- **Phase:** 14 — Search Service (Search Projection)
- **Owner:** `apps/backend/search-service`
- **FRs:** FR-SEARCH-01–03 | **Contracts:** SVC-SEARCH-001–002
- **Events:** EVT-SEARCH-PROJECTION-UPDATED-001, EVT-PROJECTION-LAG-001, EVT-SEARCH-REBUILD-STARTED-001, EVT-SEARCH-REBUILD-COMPLETED-001

## Execution Contract
Work from repo root. Read mandatory material; inspect current code, tests, contracts, dependency evidence, and `git status`. Repository source, accepted ADRs, versioned contracts, and tests override conflicting prose. Implement only Phase 14 Search; preserve existing behavior and avoid unrelated changes.

Search is a read-only, eventually consistent projection. Never turn it into authoritative storage, infer private producer fields, read another service's private database, or invent event transport details blocked by OQ-25. If a required producer lacks an approved search-safe event/snapshot contract, implement the consumer boundary deny-by-default, record the blocker, and do not bypass ownership.

## Mandatory Reading
Read all architecture docs (`00-ARCHITECTURE`, `00-MASTER-PLAN`, `API-CONTRACTS`, `AUDIT-LOG`, `CODING-STANDARDS`, `CONTRACTS`, `DATA-MODEL`, `DECISIONS`, `DEPENDENCY-GRAPH`, `OBSERVABILITY`, `PROJECT_STATE`, `TESTING-STRATEGY`), plan docs (`05_Functional_Requirements`, `06_NonFunctional_Requirements`, `08_Project_Glossary`, `10_Open_Questions`), `phase-14-search/01-plan.md`, and dependency completion reports, contracts, schemas, tests, ADRs, and READMEs for every touched integration.

## Purpose
Build a fast, secure, rebuildable Search Projection Service for approved fields from other modules. Provide tenant-scoped, branch-aware discovery with authorization filtering, anti-existence leakage, observable freshness, and eventual consistency. Return search summaries/references; source services remain authoritative.

## Dependencies
Verify Auth actor/tenant context, Branch access, User/RBAC permissions and access version, Customer/Catalog/Order producer events, Jobs (`SVC-JOB-001/002`), Audit (`SVC-AUDIT-001`), MongoDB transactions/concurrency, shared DTO/error/pagination/correlation/outbox/inbox conventions, and approved events from Branch, User, Customer, Catalog, Product, Inventory, Order, Expense, Payment, Notification, and Settings.

Final acceptance waits for every declared producer contract. Fix only minimum dependency defects necessary for this phase; rerun affected tests and do not scope-creep.

## Ownership Boundaries
**Owns:** `searchDocuments`, search indexes, allowlisted projections/tokens/summaries, authorization facets, metadata/checkpoints, projection/index versions, consumer synchronization, lag monitoring, reconciliation, rebuild orchestration, and atomic active-version switching.

**Does not own:** Branches, Users, Customers, Catalog/Products, Inventory, Orders, Expenses, Payments, Notifications, Settings, Reports, Dashboard, Audit records, source validation, or business state.

Never modify source systems. Cross-boundary access uses approved contracts/events only; never read or write another service's private MongoDB collections.

## Core Responsibilities
Ingest approved events idempotently; normalize allowlisted searchable fields; maintain version-aware projections and authorization facets; provide bounded query/suggestion/freshness/index-metadata APIs; enforce tenant/branch/RBAC filtering; expose checkpoint lag; suppress duplicates/stale events; rebuild isolated projection versions; atomically switch active versions; publish safe operational events; audit rebuild/recovery actions.

## Search Workflows
**Incremental projection:** receive event → validate envelope/version/scope → inbox deduplicate → reject stale source version → map only allowlisted safe fields → upsert projection with optimistic concurrency → advance checkpoint transactionally → publish projection/lag event through outbox.

**Query:** authenticate → resolve tenant/branch/access version/permissions → validate bounded query/filter/sort/cursor → select active projection version → apply authorization facets before search → return safe summaries/references + checkpoint freshness → owners reauthorize before any hydrated source record is returned.

**Rebuild:** authorized Operations/Scheduler request → audit reason/scope → create isolated projection/index version → replay approved events or owner snapshot contracts → reconcile counts/checkpoints → validate security/query/performance invariants → atomically switch active-version metadata → publish completion → retain/clean old version per policy.

**Deletion/status:** approved lifecycle event removes or suppresses the derived document; absence of an event never authorizes speculative deletion or indexing.

## Search Rules
- Search is read-only and never updates a source system.
- Build projections only from approved contracts/events; no private database access.
- Index only explicitly allowlisted, minimally necessary fields.
- Never index passwords, authentication secrets, audit logs, internal notes, sensitive/private data, or hidden fields.
- Never perform speculative indexing; build indexes only from measured query requirements.
- Unauthorized and not-found outcomes are indistinguishable.
- Authorize before searching and again before returning any hydrated owner record.
- Suggestions apply the same tenant, branch, RBAC, facet, and anti-existence-leakage rules as full results.
- Every response includes active projection version, checkpoint, observedAt, and freshness/lag.
- Consumers are idempotent; duplicate events have no second effect.
- Older/equal source versions never overwrite newer projections.
- Rebuild into versioned isolated indexes/projections and atomically switch the active version.
- Every rebuild/reconcile/recovery creates Audit evidence.
- Search results never become evidence that a source entity currently exists or is authorized.

## Data Model
Create one collection only: `searchDocuments`. Follow Base Schema/schema-version conventions, timestamps, optimistic concurrency, tenant-first indexes, and derived-data deletion rules.

**Fields:** `_id, tenantId, branchId?, sourceType, sourceId, sourceVersion, searchableFields, searchableTokens, authorizationFacets, displaySummary, metadata, checkpoint, projectionVersion, status, createdAt, updatedAt, version`.

`searchableFields`, tokens, summary, facets, and metadata use per-source allowlist DTOs; reject unknown keys. Store safe normalized values only. `checkpoint` records producer/partition-safe opaque position and observed/event time; never expose transport secrets. Reserved metadata documents in the same collection hold active projection version/rebuild state so no second collection is created.

**Uniqueness:** unique `{tenantId, sourceType, sourceId, projectionVersion}`; event inbox identity follows the existing shared durable-inbox owner, not an ad hoc Search collection.

**Indexes:** tenant-first `{tenantId, projectionVersion, sourceType, status, updatedAt}`; branch query `{tenantId, branchId, projectionVersion, sourceType, status}`; measured token query `{tenantId, searchableTokens, projectionVersion}`; authorization/query indexes only for approved shapes; checkpoint/rebuild metadata lookup. Do not combine incompatible multikey fields or create global/unbounded indexes.

Schema and projection versions are independent. Use `version`/expected version for optimistic concurrency; ignore stale source versions, retry write conflicts, and never regress checkpoint or active projection version.

## REST APIs
Use `/api/v1`, typed DTOs, stable error envelopes, correlation IDs, bounded cursor pagination, allowlisted filtering/sorting, API version compatibility, and freshness metadata on every response.

| Method/path | Purpose | Access |
|---|---|---|
| `GET /api/v1/search` | Domain/query/filter/sort/cursor → authorized result page + freshness | Authenticated Gateway/mobile caller; tenant, branch, domain, and record permission filters |
| `GET /api/v1/search/suggestions` | Bounded prefix suggestions from approved tokens | Same search permission and scope; no hidden-field/existence leakage |
| `GET /api/v1/search/checkpoint` | Scoped active version/checkpoint/lag | Authorized tenant support/search reader for own scope; Operations may inspect assigned scopes |
| `GET /api/v1/search/health` | Sanitized projection readiness/lag summary | Infrastructure/Operations only; never returns documents, tokens, PII, or cross-tenant detail |
| `GET /api/v1/search/index` | Active/index/rebuild version metadata and measured index status | Search Operations/Admin permission only; metadata, never indexed contents |

Infrastructure liveness/readiness remains on platform-standard routes. No public API may trigger rebuild/replay, mutate projection/source data, bypass authorization facets, expose raw tokens, or accept arbitrary MongoDB operators.

## Internal Service Contracts
**SVC-SEARCH-001 — Query:** context + domain/query/allowlisted filter/sort/cursor/limit → scoped safe results + active projection version/checkpoint/freshness. Callers: Gateway/mobile. Enforce tenant, branch, access version, RBAC, and bounded queries.

**SVC-SEARCH-002 — Rebuild/reconcile:** authorized actor/service + domain + tenant/branch scope + checkpoint + target projection version + expected active version + reason → job/rebuild status. Callers: Operations/Scheduler only. Require operator permission, idempotency, optimistic concurrency, audit, and `SVC-JOB-001/002`; never expose as a tenant business route.

Hydration uses authoritative owner contracts outside Search. The owner revalidates tenant/branch/RBAC before returning a record; Search never hydrates from private collections.

## Validation Rules
Require authenticated actor/service and server-derived tenant; validate branch membership/access, domain permission, authorization-facet/access version, source/event/projection versions, checkpoint format, and status.

Query: trim/normalize; enforce configured minimum/maximum length; reject empty/oversized/control-character input; allow prefix/wildcard only for approved domains/positions; reject leading/broad/regex-like wildcards. Filters/sorts use explicit per-domain allowlists. Limit/page/cursor are bounded; cursor is signed/opaque and tied to tenant, scope, sort, and active projection version.

Events: validate envelope, producer, event version, schema, tenant/branch, source identity/version, allowlisted payload, correlation/causation IDs, and monotonic checkpoint. Duplicate events are acknowledged without change; stale events are recorded/ignored; incompatible versions go to governed retry/DLQ handling.

**Stable errors:** `invalid_search_query`, `invalid_search_filter`, `invalid_search_sort`, `invalid_search_cursor`, `invalid_wildcard`, `search_not_allowed`, `projection_unavailable`, `stale_projection`, `checkpoint_invalid`, `event_version_unsupported`, `version_conflict`, `rebuild_in_progress`. Unauthorized, cross-tenant, and missing records return indistinguishable safe detail.

## Security
Tenant isolation applies to API, persistence, events, jobs, caches, metrics, and logs. Enforce branch isolation, deny-by-default RBAC, domain/record authorization facets, access-version invalidation, double authorization for hydration, mass-assignment protection, NoSQL/operator injection protection, replay/duplicate defenses, race/stale-write handling, and bounded resource usage.

Never trust client tenant/branch/facets/checkpoint/version. Redact queries, tokens, PII, source payloads, authorization facets, and secrets from logs/traces/errors. Audit index/rebuild/reconcile/recovery/config changes with actor, reason, correlation, safe before/after metadata. Health/index APIs expose no tenant contents.

## Events & Integrations
**Consume:** approved versioned search-safe events for Branch, User, Customer, Catalog, Product, Inventory, Order, Expense, Payment, Notification, and Settings. Current stable examples include `EVT-BRANCH-CREATED-001`, `EVT-BRANCH-STATUS-001`, `EVT-USER-CREATED-001`, `EVT-USER-ACCESS-CHANGED-001`, `EVT-CUSTOMER-CREATED-001`, `EVT-CUSTOMER-CHANGED-001`, `EVT-CATALOG-CHANGED-001`, `EVT-ORDER-CREATED-001`, `EVT-ORDER-STATUS-001`, `EVT-EXPENSE-RECORDED-001`, `EVT-PAYMENT-RECORDED-001`, `EVT-PAYMENT-CORRECTED-001`, `EVT-NOTIFICATION-DELIVERY-001`, and `EVT-SETTINGS-CHANGED-001`. Product/Inventory projection waits for owner-approved contracts; do not invent payloads.

**Publish transactionally through outbox:** `EVT-SEARCH-PROJECTION-UPDATED-001` (scope/source/version/checkpoint, no indexed content); existing `EVT-PROJECTION-LAG-001` (projection/scope/checkpoint/lag severity); `EVT-SEARCH-REBUILD-STARTED-001` and `EVT-SEARCH-REBUILD-COMPLETED-001` (scope/versions/checkpoints/outcome).

Every event uses the standard envelope, correlation/causation IDs, minimal safe payload, contract version, transactional outbox, durable inbox, idempotency, and at-least-once handling. Physical topics, retention, ordering, replay authorization, and DLQ ownership remain governed by accepted contracts/OQ-25.

**Integrate with:** Auth, Multi-Tenancy, Branch, User/RBAC, Customer, Catalog/Product, Inventory, Order, Expense, Payment, Notification, Settings, Jobs, Audit, Gateway/mobile, Observability, and Operations. Search does not own Reports or Dashboard.

## Background Jobs
Projection synchronization; authorized rebuild scheduling; stale-projection detection; checkpoint/lag updates; measured index optimization; old-version/expired-metadata cleanup; bounded retry/DLQ recovery; reconciliation against approved owner snapshots.

All jobs are tenant-aware, idempotent, retryable with bounded backoff, observable, concurrency-safe, version-aware, and correlation-preserving. Use leases/expected active version to prevent overlapping rebuilds; never silently repair security/contract drift.

## Observability
Structured redacted logs and traces with correlation/causation/event/job/rebuild IDs. Metrics: query/suggestion latency, result counts, projection/consumer lag, indexing throughput, duplicate/stale suppression, write conflicts, failed indexing, retry/DLQ backlog, checkpoint age, rebuild duration/outcome, atomic-switch failures, and authorization filtering.

Dashboards/alerts cover p50/p95/p99 latency, lag SLO, ingestion/rebuild throughput, failure rate, stale scopes, poison events, backlog, readiness, and dependency health. Liveness checks process health; readiness verifies MongoDB, active projection metadata/index, event/job dependencies, and acceptable configured lag without exposing tenant data.

## Performance
Meet project search p95 ≤ 500 ms for representative tenant volumes. Use tenant-first compound indexes, stable cursor pagination, bounded limits/query/token counts, projection-version scoping, covered queries where measured, and query-plan inspection. Avoid offset scans, unbounded regex/wildcards, global search, N+1 hydration, and unbounded result expansion.

Measure query/suggestion latency, concurrency, tenant skew, indexing throughput, consumer catch-up, checkpoint advancement, rebuild time/space, atomic switch, and old-version cleanup. Scale consumers safely by declared ordering key; correctness, isolation, freshness, and authorization outrank benchmarks.

## Testing
**Unit:** normalization/tokenization, per-domain allowlists, hidden/sensitive exclusion, query/filter/sort/wildcard/cursor validation, authorization facets, safe summary mapping, freshness calculation, duplicate/stale/version decisions, optimistic conflicts, active-version selection.

**Integration:** all approved producer events, inbox/outbox, MongoDB uniqueness/indexes/transactions, incremental upsert/delete/status, checkpoint monotonicity, SVC-SEARCH-001/002, five APIs/access gates, owner hydration authorization, Jobs/Audit/Operations, rebuild/reconcile/atomic switch/rollback.

**Security:** cross-tenant/branch/domain access, unauthorized vs missing indistinguishability, hidden-field/token/existence leakage, stale access facets, double authorization, operator endpoints, mass assignment, NoSQL/wildcard injection, replay/duplicate events, log/error/metric redaction.

**Event:** compatible/incompatible versions, out-of-order delivery, duplicate suppression, correction/delete/status events, checkpoint gaps, poison events, retry/DLQ, correlation/causation, Search published-event payload safety.

**Performance:** p95 target, cursor pagination, suggestions, measured index plans, high-cardinality tenants, concurrent queries/ingestion, catch-up/rebuild throughput, active-version switch, cleanup.

**Concurrency:** simultaneous source updates, write conflicts, stale checkpoints, concurrent query/ingestion, overlapping rebuild denial, and active-version switch races.

**Reliability:** crash before/after inbox/outbox/checkpoint/switch, dependency timeout, retry exhaustion, restart recovery, and rollback to the prior active projection.

Run format, lint, type-check, unit, integration, security, event, performance/reliability tests, and build for every touched workspace. Never weaken rules/types, skip failures, or report unavailable checks as passing.

## Implementation Sequence
1. Read mandatory sources and turn acceptance criteria into a checklist.
2. Inspect repo structure, Search code/tests/config, shared foundations, and uncommitted changes.
3. Verify FRs, SVC contracts, producer events, authorization sources, OQ-25/OQ-28 blockers, and dependency evidence.
4. Define per-source allowlists, safe summaries/tokens, facets, versions, errors, DTOs, and freshness semantics.
5. Implement `searchDocuments`, reserved metadata records, schema/projection versions, uniqueness, and measured tenant-first indexes.
6. Implement durable idempotent/version-aware event mapping, stale suppression, deletion/status handling, and checkpoint transactions.
7. Implement active projection-version selection and optimistic-concurrency safeguards.
8. Implement SVC-SEARCH-001 query/filter/sort/cursor/suggestion behavior.
9. Implement the five listed APIs and explicit access gates.
10. Implement authorization facets, access-version handling, anti-existence leakage, and owner-side hydration reauthorization.
11. Implement SVC-SEARCH-002 with Jobs, operator authorization, idempotency, audit, and concurrency leases.
12. Implement isolated rebuild/reconcile, validation, atomic switch, rollback, and old-version cleanup.
13. Implement transactional outbox publishers and declared producer consumers.
14. Implement synchronization, lag/checkpoint, retry, cleanup, optimization, and stale-detection jobs.
15. Implement structured logs, traces, metrics, dashboards, alerts, liveness, and readiness.
16. Add unit, integration, security, event, performance, concurrency, and reliability tests.
17. Update only phase-owned API/contract/schema/event/runbook/migration documentation.
18. Run all validation; inspect query plans and measured performance; review diff for scope, secrets, isolation, and private-database access.
19. Update Phase 14 status/completion evidence factually, including unresolved producer blockers.
20. Stop — do not begin Reports, Dashboard, or later phases.

## Deliverables
Search Service with controller/application/domain/repository layering; five versioned APIs and DTOs; SVC-SEARCH-001/002; `searchDocuments` schema/migration/indexes; source allowlists/mappers/consumers; outbox publishers; authorization/freshness/checkpoint logic; rebuild/reconcile/atomic-switch/rollback tooling; background jobs; stable errors; audit/observability/health/readiness; unit/integration/security/event/performance/concurrency/reliability tests; API/contract/schema/event/operations/migration documentation.

## Acceptance Criteria
**Search:** scoped query and suggestions return accurate allowlisted summaries with bounded stable pagination/filter/sort, no authoritative writes, and freshness/checkpoint/version on every response.

**Projection:** declared events update idempotently; duplicates have no second effect; stale/out-of-order versions never regress documents/checkpoints; lifecycle removal works; source systems remain authoritative; no private database reads occur.

**Security:** tenant/branch/RBAC/facet/access-version filtering and double hydration authorization are enforced; unauthorized/missing are indistinguishable; sensitive/hidden/audit/auth/internal-note data never enters indexes or responses; injection/replay/race/mass-assignment defenses and redaction pass.

**APIs/access:** five routes and SVC-SEARCH-001/002 match their declared caller gates; health/index reveal metadata only; rebuild is internal Operations/Scheduler only; envelopes, correlation, pagination, errors, and API compatibility conform.

**Rebuild/reliability:** versioned isolated rebuild/reconcile is idempotent, audited, observable, concurrency-safe, validated before atomic switch, rollback-capable, and cleans old versions safely; crash/retry/DLQ recovery preserves correctness.

**Events/integrations:** all approved declared producers integrate through versioned inbox consumers; Search events use outbox/minimal safe envelopes/correlation/causation; missing Product/Inventory contracts remain explicit blockers, never private-read workarounds.

**Performance/observability:** representative search p95 ≤ 500 ms; query plans use measured tenant-first indexes; bounded concurrency/ingestion/rebuild targets pass; lag, checkpoints, throughput, duplicates, failures, rebuilds, health, readiness, dashboards, and alerts are operational.

**Quality:** format/lint/type-check/tests/build pass; migrations/rollback/runbooks/docs are accurate; no extra collections, speculative indexes, secrets, unsafe fixtures, unrelated changes, or architecture violations exist.

## Completion Instructions
1. Run repository-prescribed format, lint, type-check, unit/integration/security/event/concurrency/reliability/performance tests, and build for all touched workspaces.
2. Map every acceptance criterion to automated test evidence or a documented operational verification; never report skipped/unavailable/failed checks as passing.
3. Record exact repo-relative changed files, API/access matrix, contracts/events, allowlists, schema/index/query-plan evidence, migrations, compatibility, and rollback notes.
4. Record measured workloads/results for latency, concurrency, ingestion, lag, catch-up, rebuild, atomic switch, and cleanup.
5. Record security evidence for tenant/branch/RBAC/facets, anti-existence leakage, sensitive exclusion, double authorization, injection/replay/race protection, audit, and redaction.
6. Document producer/event gaps, known limitations, impact, required owner/authority, and next safe action; never bypass with private reads.
7. Update Search API/contract/schema/event/rebuild/runbook docs and Phase 14 status/completion report with factual evidence.
8. Review final diff for scope, secrets, junk, unsafe fixtures, unapproved APIs/collections/indexes, and cross-service database access.
9. Confirm all checks and acceptance criteria, list final files, document rollback, and stop after Phase 14.

Do not begin Reports, Dashboard, or any later phase.
