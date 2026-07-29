# Testing Strategy

## Principle

Tests prove requirements at real ownership seams. Passing a stub that throws “not implemented” is not completion. Every phase plan maps acceptance criteria to `FR-*`, `SVC-*`, `EVT-*`, API, entity/index, and NFR evidence.

## Test categories mapped to actual seams

### Unit

- Financial calculation, fixed precision, rounding policy, snapshots, refunds, register variance (`ADR-011`; blocked details `OQ-4`–`OQ-10`).
- Lifecycle transition guards for tenant, branch, user, order, payment, notification, and register.
- Permission/grant-ceiling decisions and final-Owner invariant.
- Idempotency decisions, retry classification, mapping/redaction, locale/business-date calculations.

### Contract compatibility

- Gateway ↔ every `SVC-*` provider.
- Each `EVT-*` producer ↔ all declared consumers.
- Flutter generated/manual client ↔ every public endpoint used by the app.
- Additive field compatibility and rejection of semantic breaking changes.
- Stable public error codes and tenant-safe not-found behavior.

### Persistence and transaction

- MongoDB replica-set transaction behavior for every boundary in `DATA-MODEL.md`.
- Compound tenant/branch indexes and unique scoped counters.
- Optimistic concurrency conflicts.
- Outbox atomicity, consumer receipts, replay/rebuild.
- Lifecycle/deletion/retention invariants.

### Tenant and branch isolation

Mandatory scenarios:

- Tenant A cannot read/write Tenant B through IDs, search, filters, sort, aggregation, export, cache, event, job, file, backup/restore, or error differences.
- Branch A cannot access Branch B without assignment; Owner tenant-wide access remains explicit.
- Platform context does not imply tenant access.
- Suspended tenant/inactive branch blocks new work.
- Permission/assignment changes invalidate authorization.
- Missing tenant context fails closed.

### State-machine

- Every allowed and forbidden order transition.
- Cancellation reason and correction effects.
- Payment/refund/finalization lifecycle.
- Invitation single-use/expiry.
- Register open/close/reopen/correction.
- Notification retry/terminal states and file quarantine lifecycle.

### Idempotency and concurrency

- Duplicate order/payment/refund/onboarding/invitation/export requests have one effect.
- Same idempotency key with different payload conflicts.
- Concurrent order/receipt/payment/expense numbering remains unique.
- Stale updates reject rather than overwrite.
- Duplicate events/jobs have one consumer effect.

### Financial continuity

- Partial/split/advance/full payments reconcile.
- Refunds/corrections remain additive and within approved policy.
- Customer/order balances equal authoritative payment facts.
- Cash register expected cash equals scoped source movements.
- Reports match immutable source snapshots.
- Drift is visible and repair is audited.

### Cross-boundary journeys

- Tenant onboarding across Tenant/Branch/User/Auth.
- Staff invitation through User/Auth/Notification.
- Customer → Catalog → Order creation.
- Order transition → Notification/Search/Report/Audit.
- Payment → Order/Customer/Register/Report/Audit.
- Delivery proof through File/Order/Notification/Audit.
- Export through Report/Job/File.

### Resilience

- Dependency timeout, cache outage, Redis interruption, MongoDB failover, provider outage, queue backpressure, poison messages, outbox lag.
- Notification/export/search/report outage does not roll back source transaction.
- Auth/tenant/financial authoritative dependency failure fails closed.
- Controlled dead-letter replay and projection rebuild preserve tenant scope.

### Security

- Authentication replay/session-family reuse, lockout, reset, invitation abuse.
- Horizontal/vertical access, mass assignment, injection, IDOR, unsafe deserialization, SSRF where adapters/files apply.
- Rate limits and anti-enumeration.
- File type/extension/size/metadata/malware controls.
- Secret scanning, dependency/container scanning, log redaction.
- Provider callback signature and replay protection.

### Flutter

- Widget, navigation, role visibility, tenant/branch selection, session renewal/revocation, secure-storage behavior.
- Accessibility and responsive device matrix (`OQ-24`, `NFR-UX-05`).
- Explicit offline/retry and no silent financial offline success.
- Locale/currency/timezone formatting and stable error localization.
- Contract compatibility across supported mobile versions (`OQ-21`).

### Performance

- Common API p95, search, dashboard, list, event lag, notification queue, and export thresholds from `NFR-PERF-*`.
- Workloads use the approved capacity baseline from `OQ-28`; until then results are exploratory, not release proof.

### Recovery

- Point-in-time database recovery, object restore, tenant-safe restoration.
- Projection rebuild, outbox replay, queue dead-letter replay.
- Deployment rollback and backward contract compatibility.
- RPO/RTO evidence after `OQ-29` approval.

## Test data

- Synthetic data only outside production.
- At least two tenants, multiple branches, overlapping customer identifiers, multiple roles, suspended/inactive states, large/edge financial values, duplicate retries, and time-boundary cases.
- Deterministic clocks for expiry, business date, reminder, and retention behavior.
- No production credentials or raw customer data in fixtures.
- Final test-data ownership and generation tooling remain `OQ-27`.

## Phase evidence

Each phase must record:

1. Requirement/contract under test.
2. Test level and scenario.
3. Exact command/environment.
4. Result and evidence location.
5. Skipped/unavailable checks.
6. Defects and severity.
7. Residual risk.

`03-audit.md` is created only after real logic exists and independently checks this evidence against `01-plan.md`.

## Release gates

- No unresolved critical/high security defect.
- Tenant and branch isolation passes across all relevant paths.
- Financial reconciliation passes for affected modules.
- Contract compatibility passes for all declared consumers.
- Required performance/resilience/recovery evidence meets approved targets.
- Flutter accessibility/device evidence meets the approved matrix.
- Observability/runbooks and rollback are ready.
- UAT/security/release owners from `OQ-27` approve.

