# Functional Requirements

## Requirement rules

- IDs are stable. A changed requirement receives a new ID or an explicit supersession note; IDs are not silently reused.
- “Authorized” always includes active identity, session, tenant/membership, branch scope where applicable, role, permission, entitlement, and lifecycle checks.
- Detailed routes, schemas, service signatures, and events belong to Layer 2 and must cite these IDs.

## Platform gateway

- **FR-PLATFORM-01:** The gateway shall be the only public backend entry point and shall reject access that bypasses required authentication, API-version, size, origin, or throttling controls.
- **FR-PLATFORM-02:** The platform shall derive identity, tenant, allowed branches, role, permissions, and entitlements from verified server-side context; client identifiers shall never prove access.
- **FR-PLATFORM-03:** Every protected domain service shall revalidate authorization and scope rather than trusting the client or an unsigned internal context.
- **FR-PLATFORM-04:** Operations whose duplication can cause harm shall accept a stable idempotency identity and return the original authoritative outcome for a valid retry.
- **FR-PLATFORM-05:** Requests, downstream calls, jobs, events, and errors shall carry correlation/causation context sufficient for authorized tracing without exposing secrets.
- **FR-PLATFORM-06:** Support access shall be separately authorized, least-privilege, time-bound, and audited rather than inherited from platform administration.

## Authentication

- **FR-AUTH-01:** The system shall authenticate tenant users using organization identity plus email or mobile and shall authenticate platform administrators through a separate platform context.
- **FR-AUTH-02:** Access sessions shall be short-lived; refresh sessions shall be hashed server-side, rotated, individually revocable, and protected against rotated-token reuse.
- **FR-AUTH-03:** Five consecutive failed login attempts shall trigger the currently stated fifteen-minute lockout unless an authorized administrator resets it; final policy remains subject to `OQ-17`.
- **FR-AUTH-04:** Password reset credentials shall be hashed, single-use, short-lived, attempt-limited, and shall revoke all existing sessions after successful reset.
- **FR-AUTH-05:** Account deactivation, membership removal, tenant suspension, password reset, and security-sensitive permission changes shall invalidate authorization within an approved propagation window.
- **FR-AUTH-06:** Authentication and recovery responses shall not disclose whether an identity or record exists outside the caller's authorized scope.

## Tenant and subscription

- **FR-TENANT-01:** An eligible business shall be able to submit required tenant onboarding information, including business identity, initial Owner, initial branch, and selected plan.
- **FR-TENANT-02:** Tenant, initial branch, Owner membership, and required defaults shall be created as a coordinated process; a partial onboarding shall not appear Active.
- **FR-TENANT-03:** The backend shall consistently enforce plan status, branch/staff/order limits, and feature entitlements.
- **FR-TENANT-04:** Authorized users shall manage tenant profile, branding, lifecycle, billing contact, currency, timezone, and approved policies without changing immutable tenant ownership identifiers.
- **FR-TENANT-05:** Suspension or deactivation shall block new business operations while preserving authorized historical access and audit evidence.
- **FR-TENANT-06:** Tenant isolation shall cover persistence, unique constraints, counters, caches, queues, jobs, events, search, reports, exports, files, telemetry, backups, and restoration.

## Branch

- **FR-BRANCH-01:** Authorized users shall create and manage branches within tenant entitlements, including profile, address, contact, working hours, manager, and configuration.
- **FR-BRANCH-02:** Branch identifiers and tenant ownership shall be immutable; branch codes/names shall follow tenant-scoped uniqueness rules defined in Layer 2.
- **FR-BRANCH-03:** Operational branch data shall be accessible only to users explicitly allowed for that branch, except tenant-wide Owner access.
- **FR-BRANCH-04:** Branch switching shall change active view only and shall never expand a user's allowed branch set.
- **FR-BRANCH-05:** An inactive branch shall remain historically queryable by authorized users but shall not accept new operational work.

## Users and RBAC

- **FR-USER-01:** Authorized users shall create and maintain staff profiles, roles, permissions, departments/designations, and branch assignments within their grant ceiling.
- **FR-USER-02:** Invitations shall be scoped to tenant, branch, and role; expire after the stated seven days; become single-use; and require a permanent credential on acceptance.
- **FR-USER-03:** The backend shall deny by default and prevent Owner-level, out-of-tenant, out-of-branch, or otherwise unauthorized privilege grants.
- **FR-USER-04:** Role, permission, assignment, or lifecycle changes shall invalidate affected authorization/session/cache state within the approved propagation window.
- **FR-USER-05:** The final active Owner shall not be removed, deactivated, or demoted.
- **FR-USER-06:** User list and search results shall be tenant/branch scoped and shall exclude credentials, token material, and unauthorized fields.

## Customers

- **FR-CUSTOMER-01:** Authorized staff shall search tenant customers by approved identifiers before creating a possible duplicate.
- **FR-CUSTOMER-02:** The system shall support registered customers and approved lightweight walk-in handling without requiring a dangling customer record.
- **FR-CUSTOMER-03:** Authorized users shall create, update, classify, archive, restore, and view customer profiles, contact information, addresses, preferences, notes, and authorized history.
- **FR-CUSTOMER-04:** Customer outstanding balance shall be a projection derived from authoritative orders/payments and shall be reconcilable rather than client editable.
- **FR-CUSTOMER-05:** Customer data access, search, history, exports, and communication preferences shall remain tenant scoped and privacy controlled.
- **FR-CUSTOMER-06:** Order records shall preserve the customer/contact snapshot required for historical accuracy even when the profile later changes.

## Catalog

- **FR-CATALOG-01:** Authorized users shall manage tenant service categories, item categories, services, codes, descriptions, duration, status, and branch availability.
- **FR-CATALOG-02:** Authorized users shall manage approved price types, tax inputs, discount inputs, currency, and effective pricing while the server enforces validation.
- **FR-CATALOG-03:** Order entry shall expose only active services available to the selected authorized branch and tenant.
- **FR-CATALOG-04:** Catalog changes shall not alter service, price, tax, discount, or terminology snapshots already stored on historical orders.
- **FR-CATALOG-05:** Catalog search/filter/list operations shall be tenant scoped, bounded, and index-supported.

## Orders

- **FR-ORDER-01:** Authorized staff shall create an order containing customer/walk-in context, branch, items, services, quantities, notes, expected completion, and permitted assignments.
- **FR-ORDER-02:** The server shall validate authoritative catalog/customer data, calculate totals using the approved financial policy, and persist customer/catalog/price/tax/discount snapshots.
- **FR-ORDER-03:** Every order shall receive a concurrency-safe unique business number within the approved tenant/branch scope.
- **FR-ORDER-04:** Orders shall transition only through approved states; each transition shall preserve actor, UTC time, prior state, next state, and notes.
- **FR-ORDER-05:** Stale concurrent edits shall fail explicitly; cancellation shall require a reason and produce required downstream corrections/events.
- **FR-ORDER-06:** Authorized users shall list, filter, search, assign, update, complete, archive, and inspect order history without crossing tenant or branch scope.
- **FR-ORDER-07:** Finalized historical snapshots and lifecycle evidence shall not be silently rewritten by later catalog, customer, or configuration changes.

## Delivery

- **FR-DELIVERY-01:** The order domain shall support customer pickup and home delivery through the same governed order lifecycle.
- **FR-DELIVERY-02:** Delivery with an outstanding balance shall be allowed or blocked only according to an approved tenant policy.
- **FR-DELIVERY-03:** Delivery completion shall record receiver identity and approved proof such as confirmation, signature, photograph, or OTP where required.
- **FR-DELIVERY-04:** Delivery-assigned staff shall see only assigned delivery work and the minimum customer/order information required.

## Payments and receipts

- **FR-PAYMENT-01:** Authorized users shall record permitted payment methods and partial, full, split, advance, and policy-approved overpayments against an order.
- **FR-PAYMENT-02:** Order paid/outstanding state shall be derived from authoritative payment/refund/adjustment records using deterministic currency rules.
- **FR-PAYMENT-03:** Payment processing shall enforce idempotency and unique provider/business references so retries have a single financial effect.
- **FR-PAYMENT-04:** The system shall issue immutable receipt evidence tied to the authoritative payment and order history.
- **FR-PAYMENT-05:** Refunds, reversals, and corrections shall create additive records referencing the original transaction; successful originals shall not be silently rewritten.
- **FR-PAYMENT-06:** Sensitive refunds and administrative financial corrections shall enforce the approved approval threshold and separation-of-duties policy.
- **FR-PAYMENT-07:** Payment history, search, and exports shall remain tenant/branch scoped and shall exclude payment credentials.

## Expenses and cash registers

- **FR-EXPENSE-01:** Each branch shall have at most one cash register for an approved tenant-local business date.
- **FR-EXPENSE-02:** Authorized users shall record tenant/branch-scoped expenses with approved categories, evidence, lifecycle, and correction behavior.
- **FR-EXPENSE-03:** A register shall reconcile opening cash, cash receipts, cash expenses, refunds, additions, withdrawals, expected cash, actual cash, and variance.
- **FR-EXPENSE-04:** A non-zero variance shall require explanation and audit evidence; close/reopen/correction shall follow approved authorization and immutability rules.
- **FR-EXPENSE-05:** Expense and register reporting shall derive from authoritative records and expose reconciliation drift rather than hiding it.

## Notifications

- **FR-NOTIFY-01:** Approved business events shall create durable in-app notifications for authorized staff or customers.
- **FR-NOTIFY-02:** Eligible tenants shall be able to use approved WhatsApp templates subject to entitlement, consent, preferences, locale, and provider policy.
- **FR-NOTIFY-03:** Provider failure shall not roll back the originating order, payment, delivery, or other committed business action.
- **FR-NOTIFY-04:** Notification dispatch shall track queued, sent, delivered, failed, retry, and terminal history with idempotent retries.
- **FR-NOTIFY-05:** Authorized users shall manage templates/preferences within their scope while protected/system templates and sensitive content remain controlled.

## Reports and exports

- **FR-REPORT-01:** Reports shall enforce tenant, branch, role, permission, date-range, and data-classification scope.
- **FR-REPORT-02:** Financial and operational reports shall use immutable transaction snapshots or rebuildable event-fed projections and shall reconcile to sources.
- **FR-REPORT-03:** CSV export shall be supported; work exceeding the synchronous size/date budget shall execute asynchronously with authorized retrieval.
- **FR-REPORT-04:** Every reported figure shall be traceable to authorized source records and expose projection freshness where relevant.
- **FR-REPORT-05:** Report projections shall support monitored replay/rebuild without writing into source-domain persistence.

## Dashboard

- **FR-DASHBOARD-01:** The dashboard shall present role-appropriate operational and financial KPIs without exposing unauthorized tenant/branch data.
- **FR-DASHBOARD-02:** Dashboard cards and filters shall expose data freshness and use bounded, rebuildable projections.
- **FR-DASHBOARD-03:** Dashboard totals shall reconcile with corresponding governed reports.

## Search

- **FR-SEARCH-01:** Search shall use tenant-scoped, branch-aware, event-fed indexes for approved searchable domains.
- **FR-SEARCH-02:** Search errors and empty results shall not reveal the existence of unauthorized records or fields.
- **FR-SEARCH-03:** Search indexes shall be rebuildable and expose monitored freshness/lag without becoming authoritative domain storage.

## Settings

- **FR-SETTINGS-01:** Authorized Owners shall manage tenant business settings, numbering, tax, receipt, payment-method, terminology, locale, timezone, and approved operational policies.
- **FR-SETTINGS-02:** Backend services shall independently enforce settings, entitlements, and policies; client flags shall affect presentation only.
- **FR-SETTINGS-03:** Settings changes that alter business behavior shall be validated, version-aware, cached briefly where safe, invalidated promptly, and audited.

## Audit

- **FR-AUDIT-01:** Critical security, access, tenant, branch, order, payment, expense, settings, export, override, and support actions shall create append-only audit evidence.
- **FR-AUDIT-02:** Audit evidence shall include approved scope, actor, module, action, target, UTC time, correlation, result, and safe old/new summaries while excluding secrets and unnecessary personal data.
- **FR-AUDIT-03:** Tenant and platform audit evidence shall have separate authorization boundaries and tenant-safe search/export.
- **FR-AUDIT-04:** A critical audit-write obligation shall be blocked or safely deferred according to an approved consistency policy and shall never be silently ignored.

## Files

- **FR-FILE-01:** Uploaded files shall use private tenant-scoped storage and enforce authorization, purpose, size, type, extension, metadata, and malware controls.
- **FR-FILE-02:** File access shall use short-lived signed operations or an authorized streaming boundary and shall not expose permanent public URLs.
- **FR-FILE-03:** Retention, cleanup, archival, legal hold, and deletion shall preserve business/audit references and tenant isolation.

## Events and background jobs

- **FR-JOB-01:** Committed cross-module facts shall be recorded through an outbox in the same consistency boundary as the domain change.
- **FR-JOB-02:** Consumers and jobs shall be idempotent, tenant scoped, bounded in retry/concurrency, and move poison work to an observable dead-letter state.
- **FR-JOB-03:** Authorized operators shall be able to inspect, replay, reconcile, or rebuild failed derived work according to approved controls.
- **FR-JOB-04:** Scheduled work shall include reminders, overdue detection, reconciliation, retention/archival, subscription checks, provider dispatch, export, and file cleanup only through domain-owned contracts.

## Flutter mobile

- **FR-MOBILE-01:** The Flutter Android/iOS client shall provide role-specific workflows for the in-scope modules through versioned gateway contracts.
- **FR-MOBILE-02:** Mobile refresh credentials shall use platform secure storage; secrets shall not be embedded in Flutter assets, logs, fixtures, or public configuration.
- **FR-MOBILE-03:** Connectivity failures shall produce explicit retry/offline states; bounded cached reads may degrade safely, but authoritative financial actions shall not silently complete offline.
- **FR-MOBILE-04:** The client shall format dates, currency, numbers, pluralization, and terminology using tenant/branch locale settings while storing system time in UTC.
- **FR-MOBILE-05:** The client shall meet approved accessibility, responsive-layout, crash-free-session, navigation, and contract-compatibility requirements.

## Quality assurance

- **FR-QUALITY-01:** The project shall maintain traceable objective test evidence from every implemented `FR-*`, `SVC-*`, `EVT-*`, API contract, and data invariant to its validation result.
- **FR-QUALITY-02:** The assurance process shall execute tenant/branch isolation, state-machine, idempotency, concurrency, financial continuity, contract compatibility, resilience, security, recovery, performance, and Flutter accessibility scenarios applicable to implemented scope.
- **FR-QUALITY-03:** Failed, skipped, blocked, or unavailable validation shall be reported accurately and shall never be represented as passed.
- **FR-QUALITY-04:** Defects shall record severity, affected requirements/contracts, owner, disposition, retest evidence, and residual risk.
- **FR-QUALITY-05:** A phase shall not be marked done because stubs compile or throw “not implemented”; acceptance requires real behavior and factual evidence.

## Deployment and operations

- **FR-DEPLOY-01:** The project shall produce reproducible, versioned, provenance-traceable deployment artifacts and environment promotion for approved backend, worker, data, and Flutter mobile components.
- **FR-DEPLOY-02:** Production deployment shall keep services/data private as designed, source secrets from an approved secret manager, and prevent production secrets or raw customer data from entering the repository or lower environments.
- **FR-DEPLOY-03:** Production operations shall provide health/readiness, correlated telemetry, owned alerts/runbooks, monitored backups, restoration evidence, and approved recovery behavior.
- **FR-DEPLOY-04:** Schema/configuration/application changes shall have tenant-safe preconditions, compatibility analysis, staged rollout, rollback triggers, and verified rollback or forward-recovery procedures.
- **FR-DEPLOY-05:** Deployment documentation shall distinguish executable production evidence from Terraform, Helm, Docker, or other scaffolding that is not operationally complete.

## Release governance

- **FR-RELEASE-01:** A release shall be blocked until required phase statuses/audits, requirement/contract coverage, security/isolation/financial evidence, migrations, recovery, and approvals are complete.
- **FR-RELEASE-02:** Production rollout shall be staged, observed against approved thresholds, and capable of pause or rollback by an explicitly authorized owner.
- **FR-RELEASE-03:** API and Flutter mobile release behavior shall honor the approved compatibility and upgrade window without assuming instant store adoption.
- **FR-RELEASE-04:** Every release shall preserve factual artifact versions, provenance, configuration version, notes, known limitations, decision/risk disposition, and post-release validation results.
