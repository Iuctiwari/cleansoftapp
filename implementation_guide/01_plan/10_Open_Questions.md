# Open Questions

These questions require stakeholder or explicit engineering decisions. They are not assumptions. “Decision needed by” names the affected build phase; numeric phase ordering will be assigned only after Layer 2 contracts produce the dependency graph.

## Product and commercial policy

### OQ-1 — Initial supported industries

- **Question:** Which industries are explicitly supported and tested at launch?
- **Why it matters:** Terminology defaults, catalog seeds, acceptance journeys, and marketing scope depend on it.
- **Decision needed by:** Tenant/catalog phase planning.

### OQ-2 — Plans, limits, and billing

- **Question:** What are the approved plan names, branch/staff/order limits, feature entitlements, trial rules, suspension behavior, and manual billing workflow?
- **Why:** Changes tenant data, onboarding, enforcement, and acceptance criteria.
- **Decision needed by:** Tenant/subscription phase.

### OQ-3 — Customer self-service timing

- **Question:** Is all customer-facing access post-MVP, and when should portal/public-customer contracts be introduced?
- **Why:** Changes identity, privacy, API surface, and mobile/product scope.
- **Decision needed by:** Before public API or customer-portal planning.

## Financial policy

### OQ-4 — Tax rounding boundary

- **Question:** Is tax rounded per line, tax component, invoice subtotal, or final invoice, and with which rounding mode?
- **Why:** Changes stored snapshots, totals, receipts, refunds, and reports.
- **Decision needed by:** Catalog/order contracts.

### OQ-5 — Discount allocation

- **Question:** How are order-level discounts allocated across lines, taxes, refunds, and reporting?
- **Why:** Changes financial data model and correction behavior.
- **Decision needed by:** Catalog/order contracts.

### OQ-6 — Refund tax and eligibility

- **Question:** What are refund eligibility windows, approval thresholds, partial-refund rules, and tax treatment?
- **Why:** Changes payment/refund contracts, RBAC, receipts, and reports.
- **Decision needed by:** Payment phase.

### OQ-7 — Overpayment and corporate credit

- **Question:** Are overpayments allowed, how are they accounted for, and is corporate/customer credit part of MVP?
- **Why:** Changes balances, customer projections, payment entities, and reconciliation.
- **Decision needed by:** Payment phase.

### OQ-8 — Payment providers and regulated data

- **Question:** Which payment methods/providers are in MVP, and can any provider flow introduce regulated payment data beyond the stated “no card storage” boundary?
- **Why:** Changes compliance scope, integrations, webhooks, secrets, and audit.
- **Decision needed by:** Payment architecture.

### OQ-9 — Cash-register business date

- **Question:** What defines register cutoff, overnight operation, timezone precedence, and one-register-per-date exceptions?
- **Why:** Changes register uniqueness, close behavior, reports, and reconciliation.
- **Decision needed by:** Expense/cash-register contracts.

### OQ-10 — Register reopening and corrections

- **Question:** Who may reopen or correct a register, what approvals apply, and how is the original close preserved?
- **Why:** Changes RBAC, immutable evidence, and audit contracts.
- **Decision needed by:** Expense/cash-register phase.

## Privacy, retention, and localization

### OQ-11 — Consent and privacy model

- **Question:** What consent is required for customer data, WhatsApp messages, files, proof photographs/signatures, and support access?
- **Why:** Changes collection, notification, file, audit, and deletion behavior.
- **Decision needed by:** Customer/notification/file contracts.

### OQ-12 — Retention, deletion, residency, and legal hold

- **Question:** What retention period and deletion exceptions apply to operational, financial, audit, notification, file, and telemetry data, and where may production data reside?
- **Why:** Changes every data model, indexes, archival jobs, backup, restore, and production topology.
- **Decision needed by:** Data model finalization, before any persistence phase is finalized.

### OQ-13 — Currency changes

- **Question:** May an existing tenant change currency, and if so what happens to existing orders, balances, reports, and registers?
- **Why:** Changes tenant settings, data invariants, and report semantics.
- **Decision needed by:** Tenant/settings and financial contracts.

### OQ-14 — Launch locales

- **Question:** Are English (India), INR, and Asia/Kolkata approved launch defaults, and are Hindi/Marathi commitments or only future candidates?
- **Why:** Changes acceptance testing, templates, receipts, and release scope.
- **Decision needed by:** Mobile/notification phase planning.

## Identity, authorization, and security

### OQ-15 — MFA roadmap

- **Question:** Is MFA required at launch for Super Admin, Owner, refunds, support access, or other privileged actions?
- **Why:** Changes authentication flows, recovery, threat controls, and acceptance criteria.
- **Decision needed by:** Authentication architecture.

### OQ-16 — Support-access authority

- **Question:** Who approves support access, what data may be viewed, how long may access last, and who reviews evidence?
- **Why:** Changes platform authorization, audit, privacy, and incident procedures.
- **Decision needed by:** Platform/audit architecture.

### OQ-17 — Session and lockout policy

- **Question:** Are the stated five failures/fifteen-minute lockout, access/refresh lifetimes, invitation seven-day expiry, and permission propagation window approved?
- **Why:** Changes auth contracts, rate limits, cache invalidation, and UX.
- **Decision needed by:** Authentication phase.

### OQ-18 — Custom roles and approval thresholds

- **Question:** Which plans receive custom roles, and which refunds, discounts, overrides, or corrections require separation of duties?
- **Why:** Changes entitlement, RBAC, and financial acceptance criteria.
- **Decision needed by:** User/RBAC phase before financial phases.

### OQ-19 — WhatsApp provider

- **Question:** Which provider, regions, templates, consent rules, callback security, retention, and delivery objectives are approved?
- **Why:** Changes adapter, event, webhook, secret, and operational contracts.
- **Decision needed by:** Notification architecture.

### OQ-20 — Malware scanning and file limits

- **Question:** Which scanner/provider and purpose-specific file types/sizes/retention rules are approved?
- **Why:** Changes upload contracts, quarantine state, jobs, cost, and security testing.
- **Decision needed by:** File architecture.

## API, event, and mobile compatibility

### OQ-21 — API/mobile compatibility window

- **Question:** How many API versions and mobile releases remain supported, and when may the server require an upgrade?
- **Why:** Store releases are delayed; this changes deprecation, contracts, feature flags, and rollout.
- **Decision needed by:** API contracts before the first mobile phase.

### OQ-22 — Idempotency and export authorization lifetime

- **Question:** How long are idempotency outcomes retained, and how long may an export retrieval authorization remain valid?
- **Why:** Changes persistence, security, cleanup jobs, and retry behavior.
- **Decision needed by:** API/payment/export contracts.

### OQ-23 — Offline write boundary

- **Question:** Are any non-financial mobile writes permitted offline, and what conflict policy applies?
- **Why:** Changes client storage, data model, synchronization, and user journeys.
- **Decision needed by:** Mobile architecture.

### OQ-24 — Flutter engineering choices

- **Question:** Which state-management approach, API contract-generation strategy, and secure-storage package are approved?
- **Why:** Changes mobile module structure and contract compatibility tooling.
- **Decision needed by:** Mobile phase.

### OQ-25 — Event governance

- **Question:** What event naming/versioning convention, retention, ordering boundaries, replay authorization, consumer queues, dead-letter ownership, and recovery targets apply?
- **Why:** Changes every `EVT-*` contract and the dependency graph.
- **Decision needed by:** Layer 2 `CONTRACTS.md` before domain phase plans.

### OQ-26 — Critical audit consistency

- **Question:** Which actions must block when audit evidence cannot be committed, and which may safely defer through outbox/reconciliation?
- **Why:** Changes transaction boundaries and business availability.
- **Decision needed by:** Audit contracts before critical domain phases.

## Delivery, quality, and production

### OQ-27 — Test governance

- **Question:** Who owns unit/contract/integration/security/performance/UAT approval, what minimum coverage applies, and who signs release evidence?
- **Why:** Existing audits identify missing ownership and exit gates.
- **Decision needed by:** Testing strategy and before any phase can be marked done.

### OQ-28 — Capacity baseline

- **Question:** What are launch tenant/branch/user volumes, peak orders, order size, report concurrency, notification bursts, file volume, and queue recovery throughput?
- **Why:** Changes indexes, worker concurrency, projection strategy, load tests, and cost.
- **Decision needed by:** Data/observability architecture before performance phase plans.

### OQ-29 — SLO/RPO/RTO approval

- **Question:** Are 99.9% API availability, 15-minute RPO, and 4-hour regional RTO approved business commitments?
- **Why:** Changes topology, backup, alerting, staffing, and cost.
- **Decision needed by:** Deployment architecture.

### OQ-30 — Team and repository governance

- **Question:** What are team size/composition, branch naming, merge strategy, required reviewers, code owners, and decision owners?
- **Why:** Changes phase parallelism, review gates, and realistic timeline.
- **Decision needed by:** Before Layer 3 execution begins.

### OQ-31 — Production platform

- **Question:** Which cloud, region, network topology, secret manager, managed database/cache, object storage, backup provider, and observability platform are approved, and is Kubernetes required?
- **Why:** Changes production architecture, infrastructure contracts, recovery, security, and cost.
- **Decision needed by:** Deployment architecture; it does not block Layer 1.

### OQ-32 — Production cost guardrails

- **Question:** What budget and per-tenant/noisy-tenant controls must the design satisfy?
- **Why:** Changes provider selection, quotas, retention, scaling, and reporting/export limits.
- **Decision needed by:** Deployment and capacity architecture.

### OQ-33 — Conflicting legacy phase documents

- **Question:** May the migration treat the roadmap's Phase 00–25 catalogue as canonical and re-home the mismatched content of files named phases 18–22 by actual subject?
- **Why:** Their filenames and content conflict; preserving both as authoritative would create impossible phase plans.
- **Decision needed by:** Before Layer 3 folders are created.

### OQ-34 — Retirement of legacy documentation

- **Question:** After every substantive detail and cross-reference is migrated and audited, should legacy `ERP-PLANNING` and placeholder `docs` documents be retained as an archive, marked superseded, or removed?
- **Why:** Determines the final clean repository structure without risking information loss.
- **Decision needed by:** Final documentation migration phase.

