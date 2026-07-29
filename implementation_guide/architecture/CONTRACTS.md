# Internal Service and Event Contracts

## Contract rules

1. IDs are stable and never repurposed.
2. Every internal call carries authenticated service identity, correlation ID, and trusted tenant/branch/actor context where applicable.
3. Tenant/branch selectors are never proof of access.
4. Inputs are versioned DTOs; outputs exclude private persistence models and unauthorized fields.
5. Compatible evolution is additive: optional fields with safe defaults. Removal, rename, changed meaning, changed requiredness, or changed error semantics requires a new major contract/version and ADR.
6. Money is `{ amountMinor: integer, currency: ISO-4217 }`; time is UTC ISO-8601; business dates include timezone context.
7. Errors use stable categories: validation, unauthenticated, forbidden, not-found-in-scope, conflict, rate-limit, dependency-unavailable, timeout, internal.
8. Every mutating contract declares idempotency and expected-version behavior where relevant.

## Service contracts

### Platform and authentication

| ID | Owner / operation | Input → output | Declared consumers | Requirements |
|---|---|---|---|---|
| `SVC-PLATFORM-001` | Gateway: build internal request context | verified access token + requested branch → signed internal context | Every protected domain | `FR-PLATFORM-02`, `FR-PLATFORM-03` |
| `SVC-PLATFORM-002` | Gateway: normalize error | internal typed error → tenant-safe public error + correlation | Flutter mobile, every route adapter | `FR-AUTH-06`, `NFR-MAINT-03` |
| `SVC-AUTH-001` | Auth: verify access session | bearer token/device context → active session identity or typed denial | Gateway | `FR-AUTH-01`, `FR-AUTH-02` |
| `SVC-AUTH-002` | Auth: login tenant user | organization + email/mobile + password + device → token/session pair | Gateway/mobile | `FR-AUTH-01`, `FR-AUTH-03` |
| `SVC-AUTH-003` | Auth: rotate refresh session | refresh credential + device → rotated pair or reuse denial | Gateway/mobile | `FR-AUTH-02` |
| `SVC-AUTH-004` | Auth: revoke sessions | actor + user/session/family selector + reason → revocation result | User, Tenant, Gateway | `FR-AUTH-02`, `FR-AUTH-05` |
| `SVC-AUTH-005` | Auth: password recovery | organization + identity / verified OTP + new password → safe recovery status | Gateway, Notification | `FR-AUTH-04`, `FR-AUTH-06` |
| `SVC-AUTH-006` | Auth: initialize invited credential | valid invitation proof + password → activated credential | User invitation acceptance | `FR-USER-02`, `FR-AUTH-04` |

### Tenant, branch, and users

| ID | Owner / operation | Input → output | Consumers | Requirements |
|---|---|---|---|---|
| `SVC-TENANT-001` | Tenant: coordinated onboarding | business + Owner + first branch + plan + idempotency → onboarding result | Gateway, Auth, Branch, User | `FR-TENANT-01`, `FR-TENANT-02` |
| `SVC-TENANT-002` | Tenant: resolve active context | tenant ID → lifecycle, currency, timezone, policy, plan version | Gateway, all tenant domains | `FR-TENANT-03`, `FR-TENANT-05` |
| `SVC-TENANT-003` | Tenant: authorize entitlement | tenant + feature/limit + proposed delta → allow/deny + reason | Branch, User, Notification, Settings, Gateway | `FR-TENANT-03` |
| `SVC-TENANT-004` | Tenant: manage profile/lifecycle | expected version + allowed patch/transition + reason → tenant summary | Gateway/platform operations | `FR-TENANT-04`, `FR-TENANT-05` |
| `SVC-TENANT-005` | Tenant: resolve effective settings | tenant + optional branch + keys → versioned effective settings | Catalog, Order, Payment, Expense, Notification, Mobile | `FR-SETTINGS-01`, `FR-SETTINGS-02` |
| `SVC-BRANCH-001` | Branch: manage branch | create/update/transition/configuration + expected version → branch summary | Gateway, Tenant onboarding | `FR-BRANCH-01`, `FR-BRANCH-05` |
| `SVC-BRANCH-002` | Branch: authorize/select context | actor + requested branch → authorized active branch context | Gateway, Auth session selection, all branch domains | `FR-BRANCH-03`, `FR-BRANCH-04` |
| `SVC-BRANCH-003` | Branch: list/get visible branches | actor + filters/page → scoped branch summaries | Gateway/mobile, User assignment | `FR-BRANCH-03` |
| `SVC-USER-001` | User: manage membership/profile | actor + create/update/lifecycle/assignment + version → safe user summary | Gateway, Tenant onboarding | `FR-USER-01`, `FR-USER-05` |
| `SVC-USER-002` | User: resolve effective access | tenant + user → active membership, role, permissions, branch set, access version | Gateway, Auth, every protected domain | `FR-USER-03`, `FR-USER-04` |
| `SVC-USER-003` | User: invitation lifecycle | create/resend/cancel/accept + idempotency → safe invitation status | Gateway, Auth, Notification | `FR-USER-02` |
| `SVC-USER-004` | User: authorize grant | actor access + target role/permissions/branches → allow/deny | User commands, Branch manager assignment | `FR-USER-03`, `FR-USER-05` |
| `SVC-USER-005` | User: list/get safe profiles | actor + scoped filters/page → safe profiles | Gateway/mobile, Order assignment | `FR-USER-06` |

### Customer and catalog

| ID | Owner / operation | Input → output | Consumers | Requirements |
|---|---|---|---|---|
| `SVC-CUSTOMER-001` | Customer: manage profile | create/update/archive/restore + version → customer summary | Gateway/mobile | `FR-CUSTOMER-03`, `FR-CUSTOMER-05` |
| `SVC-CUSTOMER-002` | Customer: resolve order snapshot | actor + customer ID or walk-in data → immutable safe snapshot | Order | `FR-CUSTOMER-02`, `FR-CUSTOMER-06` |
| `SVC-CUSTOMER-003` | Customer: scoped search/list | actor + query/filters/page → safe results | Gateway/mobile, Order entry | `FR-CUSTOMER-01`, `FR-CUSTOMER-05` |
| `SVC-CUSTOMER-004` | Customer: apply/reconcile balance projection | payment/order event or rebuild command → projection state | Payment events, Report/reconciliation | `FR-CUSTOMER-04` |
| `SVC-CATALOG-001` | Catalog: manage category/service/pricing | actor + create/update/archive/branch assignment + version → catalog summary | Gateway/mobile | `FR-CATALOG-01`, `FR-CATALOG-02` |
| `SVC-CATALOG-002` | Catalog: quote authoritative snapshot | tenant/branch + selected services/items/qty + effective time → price/tax/duration snapshots | Order | `FR-CATALOG-03`, `FR-CATALOG-04` |
| `SVC-CATALOG-003` | Catalog: scoped picker/search | actor + branch + query/page → active available catalog | Gateway/mobile, Order entry | `FR-CATALOG-03`, `FR-CATALOG-05` |

### Orders and delivery

| ID | Owner / operation | Input → output | Consumers | Requirements |
|---|---|---|---|---|
| `SVC-ORDER-001` | Order: create | context + customer/walk-in + lines + assignment + idempotency → authoritative order | Gateway/mobile | `FR-ORDER-01`–`FR-ORDER-03` |
| `SVC-ORDER-002` | Order: get/list | context + ID/filters/page → scoped order summaries/details | Gateway/mobile, Payment, Notification | `FR-ORDER-06` |
| `SVC-ORDER-003` | Order: update mutable fields | context + allowed patch + expected version → updated order | Gateway/mobile | `FR-ORDER-05`, `FR-ORDER-07` |
| `SVC-ORDER-004` | Order: transition/cancel/complete | context + transition + expected version + reason/notes → order + transition | Gateway/mobile, Delivery | `FR-ORDER-04`, `FR-ORDER-05` |
| `SVC-ORDER-005` | Order: assignment | context + eligible user + expected version → assignment result | Gateway/mobile | `FR-ORDER-01`, `FR-USER-03` |
| `SVC-ORDER-006` | Order: settlement snapshot | order ID → currency, total, paid, refunded, outstanding, lifecycle | Payment, Delivery | `FR-PAYMENT-02`, `FR-DELIVERY-02` |
| `SVC-ORDER-007` | Delivery: assign/complete | context + order + receiver/proof + version → delivery/order result | Gateway/mobile, File | `FR-DELIVERY-01`–`FR-DELIVERY-04` |

### Payments, expenses, and receipts

| ID | Owner / operation | Input → output | Consumers | Requirements |
|---|---|---|---|---|
| `SVC-PAYMENT-001` | Payment: record/verify | context + order + method + money + reference + idempotency → payment | Gateway/mobile, Order settlement | `FR-PAYMENT-01`–`FR-PAYMENT-03` |
| `SVC-PAYMENT-002` | Payment: refund/correct | context + original + money + reason + approval + idempotency → additive correction | Gateway/mobile | `FR-PAYMENT-05`, `FR-PAYMENT-06` |
| `SVC-PAYMENT-003` | Payment: settlement summary | order/customer/branch scope → authoritative settlement aggregates | Order, Customer projection, Expense, Reports | `FR-PAYMENT-02` |
| `SVC-PAYMENT-004` | Receipt: generate/retrieve | authorized payment/order → immutable receipt evidence | Gateway/mobile, Notification | `FR-PAYMENT-04` |
| `SVC-PAYMENT-005` | Payment: scoped history/list | context + filters/page → safe payment/refund history | Gateway/mobile, Reports | `FR-PAYMENT-07` |
| `SVC-EXPENSE-001` | Expense: manage expense | context + category/money/evidence/lifecycle + version → expense | Gateway/mobile, File | `FR-EXPENSE-02` |
| `SVC-EXPENSE-002` | Register: open/mutate/close | branch + business date + cash action + version → register state | Gateway/mobile | `FR-EXPENSE-01`, `FR-EXPENSE-03`, `FR-EXPENSE-04` |
| `SVC-EXPENSE-003` | Register: reconcile | branch/date + authoritative cash movements → expected/actual/variance evidence | Payment events, Expense, Reports, Scheduler | `FR-EXPENSE-03`, `FR-EXPENSE-05` |

### Notifications, files, audit, search, reports, dashboard, jobs

| ID | Owner / operation | Input → output | Consumers | Requirements |
|---|---|---|---|---|
| `SVC-NOTIFY-001` | Notification: enqueue domain notification | event + recipients + template intent → durable notification IDs | Auth, Tenant, User, Order, Payment, Delivery, Expense | `FR-NOTIFY-01`, `FR-NOTIFY-03` |
| `SVC-NOTIFY-002` | Notification: manage template/preferences | context + allowed update/version → effective template/preferences | Gateway/mobile | `FR-NOTIFY-02`, `FR-NOTIFY-05` |
| `SVC-NOTIFY-003` | Notification: list/read/retry | context + ID/filter/action → scoped delivery history/state | Gateway/mobile, Operations | `FR-NOTIFY-04` |
| `SVC-FILE-001` | File: authorize upload | context + purpose + metadata → upload/quarantine contract | Order, Delivery, Customer, Expense |
| `SVC-FILE-002` | File: authorize read/delete | context + file reference + purpose → signed read/delete result | Referring domains, Gateway/mobile |
| `SVC-AUDIT-001` | Audit: record obligation | safe audit envelope + idempotency → accepted/committed result | Every critical domain | `FR-AUDIT-01`, `FR-AUDIT-02`, `FR-AUDIT-04` |
| `SVC-AUDIT-002` | Audit: scoped query/export | platform/tenant authorization + filters → immutable evidence | Gateway/mobile, Security/operations | `FR-AUDIT-03` |
| `SVC-SEARCH-001` | Search: query | context + domain/query/filter/page → scoped results + freshness | Gateway/mobile | `FR-SEARCH-01`, `FR-SEARCH-02` |
| `SVC-SEARCH-002` | Search: rebuild/reconcile | authorized domain/scope/checkpoint → rebuild status | Operations/Scheduler | `FR-SEARCH-03` |
| `SVC-REPORT-001` | Report: query | context + report type/scope/date/filter → data + lineage + freshness | Gateway/mobile, Dashboard | `FR-REPORT-01`, `FR-REPORT-02`, `FR-REPORT-04` |
| `SVC-REPORT-002` | Report: request/retrieve export | context + report definition/idempotency → job/download status | Gateway/mobile, Job/File | `FR-REPORT-03` |
| `SVC-REPORT-003` | Report: rebuild/reconcile projection | authorized domain/scope/checkpoint → rebuild status | Operations/Scheduler | `FR-REPORT-05` |
| `SVC-DASHBOARD-001` | Dashboard: role view | context + branch/date → permitted cards + freshness | Gateway/mobile | `FR-DASHBOARD-01`–`FR-DASHBOARD-03` |
| `SVC-JOB-001` | Job: schedule/dispatch domain work | owner + typed job + scope + idempotency → job ID | All domain owners |
| `SVC-JOB-002` | Job: inspect/retry/replay | authorized operator + job/DLQ + reason → recovery result | Operations/domain owner |

## Event envelope

Every `EVT-*` contains `eventId`, `eventType`, `eventVersion`, `producer`, `occurredAtUtc`, `tenantId`, optional `branchId`, `correlationId`, `causationId`, safe optional `actorId`, aggregate ID/version, and minimal payload. Delivery is at least once; every consumer deduplicates by event ID/consumer and handles compatible additive fields.

## Event contracts

| ID | Producer | Fact / minimal payload | Declared consumers |
|---|---|---|---|
| `EVT-AUTH-SESSION-REVOKED-001` | Auth | user/session/family, reason, effective time | Gateway caches, User, Audit |
| `EVT-AUTH-SECURITY-001` | Auth | lockout/reset/reuse/security outcome | Audit, Notification, Observability |
| `EVT-TENANT-CREATED-001` | Tenant | tenant, owner, first branch, plan/version | Auth, Branch, User, Audit |
| `EVT-TENANT-STATUS-001` | Tenant | prior/new lifecycle, reason, version | Gateway/Auth caches, all domains, Audit |
| `EVT-TENANT-ENTITLEMENT-001` | Tenant | entitlement/limit version changed | Gateway, Branch, User, Notification, Settings cache, Audit |
| `EVT-SETTINGS-CHANGED-001` | Tenant | changed safe keys, version, scope | Catalog, Order, Payment, Expense, Notification, Mobile bootstrap, Audit |
| `EVT-BRANCH-CREATED-001` | Branch | branch summary/version | User, Search, Report, Audit |
| `EVT-BRANCH-STATUS-001` | Branch | prior/new lifecycle, reason | Gateway/User caches, Order, Payment, Expense, Search, Report, Audit |
| `EVT-BRANCH-CONFIG-001` | Branch | safe changed keys/version | Order, Expense, Notification, Audit |
| `EVT-USER-CREATED-001` | User | safe profile, role, branch assignments | Auth, Search, Audit, Notification |
| `EVT-USER-ACCESS-CHANGED-001` | User | access version, role/branch/lifecycle delta | Auth/Gateway caches, all protected domains, Audit |
| `EVT-USER-INVITED-001` | User | invitation ID, recipient channel, expiry | Auth, Notification, Audit |
| `EVT-CUSTOMER-CREATED-001` | Customer | safe customer projection fields | Search, Report, Audit |
| `EVT-CUSTOMER-CHANGED-001` | Customer | safe changed projection fields/version | Search, Report, Audit |
| `EVT-CATALOG-CHANGED-001` | Catalog | service/category/pricing/availability version | Order picker cache, Search, Audit |
| `EVT-ORDER-CREATED-001` | Order | order ID/number, customer/branch, totals snapshot, state | Payment, Notification, Search, Report, Audit |
| `EVT-ORDER-STATUS-001` | Order | prior/new state, assignment, expected completion, version | Notification, Search, Report, Audit |
| `EVT-ORDER-CANCELLED-001` | Order | order, reason, settlement impact intent | Payment, Notification, Report, Audit |
| `EVT-DELIVERY-COMPLETED-001` | Order | order, delivery type, safe proof reference, receiver | Notification, Report, Audit |
| `EVT-PAYMENT-RECORDED-001` | Payment | payment/order/customer/branch, money, method, state | Order projection, Customer balance, Expense register, Notification, Report, Audit |
| `EVT-PAYMENT-CORRECTED-001` | Payment | original/correction, money, reason/type | Order projection, Customer balance, Expense register, Notification, Report, Audit |
| `EVT-RECEIPT-ISSUED-001` | Payment | receipt/payment/order, safe retrieval intent | Notification, Audit |
| `EVT-EXPENSE-RECORDED-001` | Expense | expense/branch/category/money/lifecycle | Register, Report, Audit |
| `EVT-REGISTER-CLOSED-001` | Expense | branch/date, expected/actual/variance, close version | Report, Notification, Audit |
| `EVT-NOTIFICATION-DELIVERY-001` | Notification | notification/channel/provider-safe status/attempt | Audit where critical, Observability |
| `EVT-FILE-STATUS-001` | File | file/purpose, quarantine/clean/rejected/deleted state | Referring domain, Audit |
| `EVT-AUDIT-RECORDED-001` | Audit | audit ID/category/target/time (no private summaries) | Security monitoring only |
| `EVT-PROJECTION-LAG-001` | Search/Report | projection/scope/checkpoint/lag severity | Observability, Operations |

## Event-governance blockers

Names above are stable guide IDs and event meanings. Physical topic/queue naming, retention, ordering boundaries, replay authorization, dead-letter ownership, and response targets remain blocked by `OQ-25`. Phase prompts must not invent them.

