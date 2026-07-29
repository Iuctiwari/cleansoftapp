# System Architecture

## Style

Nexoraa CleanSoft uses a service-oriented modular monorepo. Each business capability has one logical owner, even when early deployment consolidates multiple owners into fewer runtime units. The API gateway is the only public ingress. Domain services own authoritative writes; other modules call written contracts or consume event-fed projections.

This preserves existing repository service boundaries without forcing premature distributed deployment (`ADR-002`).

## System boundaries

```text
Flutter Android/iOS
        |
        v
API Gateway (public trust boundary)
        |
        +--> Authentication / membership context
        +--> Tenant / entitlement context
        +--> Branch / RBAC context
        |
        +--> Domain owners
               |-- Customer
               |-- Catalog
               |-- Orders + Delivery
               |-- Payments + Receipts
               |-- Expenses + Cash Register
               |-- Notifications
               |-- Files / domain references
        |
        +--> Derived consumers
               |-- Audit
               |-- Search
               |-- Reports
               |-- Dashboard
               `-- Reconciliation / scheduled jobs
```

Private resources include MongoDB, Redis/BullMQ, object storage, logs, traces, metrics, backups, and internal transports. Provider callbacks cross a trust boundary and require signature and replay validation.

## Ownership

| Owner | Authoritative responsibility |
|---|---|
| Gateway | Public transport policy and trusted context propagation; no domain persistence |
| Auth | Credentials, sessions, reset/lockout, auth security state |
| Tenant | Tenant lifecycle, subscription/entitlements, tenant settings and branding |
| Branch | Branch lifecycle, profile, working hours, branch configuration |
| User | Staff membership/profile, roles, permissions, invitations, branch assignments |
| Customer | Customer profile and customer-owned notes/addresses/preferences |
| Catalog | Services, categories, price sources, availability |
| Order | Orders, items, snapshots, status history, assignments, pickup/delivery |
| Payment | Payments, provider transactions, refunds/corrections, receipts |
| Expense | Expenses, categories, cash registers and variance evidence |
| Notification | In-app state, templates/preferences, provider delivery history |
| File | Private object metadata/access lifecycle; business purpose remains with referring domain |
| Audit | Immutable critical-action evidence |
| Search | Rebuildable search projection |
| Report | Rebuildable report/export projection |
| Dashboard | Role-specific KPI projection derived from reports/events |
| Scheduler/job infrastructure | Trigger/execution mechanics; domain owns business meaning |

Settings remain Tenant-owned, delivery Order-owned, and receipts Payment-owned under existing accepted audit decisions.

## Data rules

- Every tenant-owned record carries immutable `tenantId`.
- Branch-owned records also carry immutable `branchId`.
- Platform records are physically/logically distinguishable from tenant records.
- Common indexes begin with tenant and then branch where applicable.
- Local multi-record invariants use MongoDB transactions.
- Cross-owner workflows use outbox events, at-least-once delivery, idempotency, and reconciliation.
- Optimistic concurrency prevents silent overwrites.
- Atomic counters issue scoped business numbers.
- Financial values use integer minor units plus ISO currency code.
- Historical transactions retain customer/catalog/price/tax/discount snapshots.
- Finalized money and audit evidence are immutable; correction is additive.

Detailed entities and indexes are in `DATA-MODEL.md`.

## Request-flow example: create an order

1. Flutter sends a versioned request with correlation and idempotency identifiers to the gateway (`FR-PLATFORM-01`, `FR-PLATFORM-04`).
2. Gateway applies TLS/origin/size/throttling/API-version controls and verifies the access session (`SVC-AUTH-001`).
3. Membership contracts resolve active tenant, allowed branches, permissions, and entitlements (`SVC-TENANT-002`, `SVC-USER-002`).
4. Gateway verifies requested active branch through `SVC-BRANCH-002` and forwards authenticated internal context.
5. Order owner rechecks `order:create`, obtains customer snapshot (`SVC-CUSTOMER-002`) and catalog price snapshots (`SVC-CATALOG-002`).
6. Order owner calculates totals server-side under `ADR-011`, allocates a scoped counter, and commits order/items/history/outbox atomically.
7. Response returns the authoritative order and stable error meaning.
8. `EVT-ORDER-CREATED-001` is delivered at least once. Notification, audit, search, and report consumers update idempotently.
9. A provider notification failure changes notification delivery state only; it never rolls back the order.

## Failure rules

- Authentication/authorization/tenant/financial persistence failure: fail closed.
- Stale version: explicit conflict; never last-write-wins.
- Dependency timeout: stable dependency error with safe retry guidance.
- Duplicate idempotency key with different payload: conflict/security event.
- Cache outage: fall back to authoritative source; never grant from stale authorization.
- Notification/export/search/report outage: source transaction remains committed; lag is observable and recoverable.
- Poison event/job: bounded retry then dead-letter, alert, controlled replay.
- Unknown record outside scope: tenant-safe not-found response without existence leakage.

## Evolution

Public APIs and events are versioned. Additive compatible fields are permitted under declared rules; removals/semantic changes require a new version, migration guidance, usage evidence, compatibility window (`OQ-21`), and an ADR. Service extraction changes deployment, not ownership or contracts.

## Known blockers

The architecture direction is stable, but detailed contracts retain explicit blockers for `OQ-4`–`OQ-32`, especially financial policy, privacy/retention, event governance, compatibility, audit consistency, capacity, and production platform.








