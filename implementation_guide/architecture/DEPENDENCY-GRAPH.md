# Dependency Graph

## Derivation rule

An edge `A → B` means A consumes a contract produced by B, so B's contract must be stable before A's phase plan is finalized. Build tiers below were generated from consumers declared in `CONTRACTS.md`, then checked against the accepted ownership ADRs.

## Direct contract dependencies

| Consumer | Producers called/consumed |
|---|---|
| Gateway/platform | Auth, Tenant, Branch, User, every routed domain |
| Auth | Notification for recovery; Tenant/User status is resolved by gateway/access context rather than private reads |
| Tenant | Auth credential eligibility, Branch bootstrap, User Owner membership, Notification |
| Branch | Tenant entitlement/context, User eligibility for manager |
| User | Auth credential/session, Tenant entitlement/context, Branch assignment, Notification |
| Customer | User/RBAC context, File for attachments, Order/Payment events for balance projection |
| Catalog | Tenant settings/entitlements, Branch availability, User/RBAC |
| Order/Delivery | Customer snapshot, Catalog quote, User assignment/access, Tenant settings, Branch context, File |
| Payment/Receipt | Order settlement, User/RBAC, Tenant settings, Notification |
| Expense/Register | Branch context, User/RBAC, Payment cash events, Tenant settings, File |
| Notification | Tenant entitlement/settings, User/customer recipients, Job dispatch |
| Audit | Events/obligations from every critical producer |
| Search | Customer, Catalog, Order, Branch, User events |
| Report | Customer, Order, Payment, Expense, Branch events |
| Dashboard | Report query/projection |
| Flutter mobile | Gateway public API contracts |
| Scheduler/jobs | Domain-owned typed job contracts; no private domain reads |

## Circular-risk resolution

### Tenant onboarding ↔ Branch/User/Auth

The old prose makes onboarding appear circular: Tenant needs the first Branch and Owner membership, while Branch/User require tenant context.

Resolution:

1. `SVC-TENANT-001` creates a non-Active onboarding aggregate and signed bootstrap context.
2. Branch and User accept only that bootstrap context for first-branch/Owner creation; normal APIs still require active tenant context.
3. Auth creates/links credentials through `SVC-AUTH-006` without granting tenant access itself.
4. Tenant activates only after all required results exist.
5. Failure leaves a resumable/failed onboarding state, never an Active partial tenant.

The Tenant contract is defined before Branch/User, but the full onboarding integration acceptance gate closes after Branch and User phases. No service reads another's collection.

### Auth ↔ User access

Auth proves credential/session identity. User owns membership/role/branch authorization. Gateway composes `SVC-AUTH-001` and `SVC-USER-002`; Auth does not own or synchronously query RBAC. User access changes call Auth revocation and emit `EVT-USER-ACCESS-CHANGED-001`.

### Payment ↔ Order settlement

Payment owns money. Order exposes the payable snapshot and may hold a derived settlement projection; it never writes Payment. Payment emits facts; Order consumes them idempotently. Payment queries `SVC-ORDER-006` before accepting money.

### Customer balance ↔ Order/Payment

Customer profile is authoritative; balance is explicitly a derived projection updated from Order/Payment events and rebuildable. It is never a synchronous prerequisite for payment truth.

### Notification dependencies

Domain commits do not synchronously depend on external dispatch. They record facts; Notification consumes them. Auth recovery/invitations may call durable enqueue, but provider failure does not change identity/domain success.

## Build tiers and numbered phases

Ties within a tier are intentionally broken by phase number. “Contract complete” means the written contract is stable; implementation status remains in phase `04-status.md`.

| Phase | Tier | Module/outcome | Required stable producers before phase |
|---:|---:|---|---|
| 00 | 0 | Platform foundation and shared contract primitives | None |
| 01 | 0 | Audit foundation | Platform envelope/error/context |
| 02 | 0 | Scheduler/job foundation | Platform envelope, audit obligation |
| 03 | 1 | Authentication | Platform, Audit, Job; Notification enqueue contract |
| 04 | 1 | Tenant/subscription/settings core | Platform, Audit, Auth; Branch/User bootstrap contracts |
| 05 | 2 | Branch | Tenant, Auth, Audit |
| 06 | 2 | Users/RBAC | Auth, Tenant, Branch, Audit, Notification enqueue |
| 07 | 2 | File storage | Platform, Tenant/User access, Audit, Job |
| 08 | 3 | Customers | User/Branch access, File, Audit |
| 09 | 3 | Catalog | Tenant settings, Branch, User, Audit |
| 10 | 4 | Orders and delivery | Customer, Catalog, User, Branch, Tenant settings, File, Audit |
| 11 | 5 | Payments and receipts | Order, User, Tenant settings, Audit |
| 12 | 5 | Notifications | Tenant settings/entitlements, User/Customer, Job, source event contracts |
| 13 | 6 | Expenses and cash registers | Payment facts, Branch, User, Tenant settings, File, Audit |
| 14 | 6 | Search projection | Branch/User/Customer/Catalog/Order events, Job |
| 15 | 6 | Reports and exports | Branch/Customer/Order/Payment/Expense events, File, Job |
| 16 | 7 | Dashboard | Report contract/projection |
| 17 | 7 | Flutter mobile | All required gateway/API contracts |
| 18 | 8 | Cross-system testing and security hardening | Phases 00–17 implemented |
| 19 | 9 | Deployment and operational readiness | Phase 18 evidence; `OQ-29`–`OQ-32` resolved |
| 20 | 10 | Controlled release | Phase 19 deployed/verified |

## Parallelism

- Phases 01 and 02 may proceed in parallel after Phase 00 contracts.
- Customer and Catalog may proceed in parallel after Phase 07 prerequisites.
- Notification core can be prepared earlier against stable contracts, but its phase acceptance includes real producer/provider integration.
- Search and Report projection implementations can start once their consumed event versions are stable; final acceptance waits for all declared producers.
- Flutter can begin contract mocks earlier, but phase acceptance waits for versioned gateway endpoints and compatibility tests.

## Phase gate implications

- Authentication phase cannot claim full tenant-login integration until User/Tenant composition is tested; its status must disclose this dependency.
- Tenant phase cannot claim coordinated onboarding complete until Branch/User bootstrap consumers exist.
- Audit and Job foundations must exist before critical domain phases, even though their integrations continue across all phases.
- `03-audit.md` is absent from every planned phase until real business logic exists.
- Open questions listed in a phase's status block finalization but do not authorize invented defaults.

