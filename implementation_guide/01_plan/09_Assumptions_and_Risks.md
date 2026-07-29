# Assumptions and Risks

## Classification rule

An assumption is a provisional statement that permits planning to continue with a named consequence if wrong. A stakeholder decision that changes product behavior, policy, data, contracts, or production commitments is not an assumption; it appears in `10_Open_Questions.md`.

## Assumptions

### A-1 — Initial market defaults

- **Assumption:** The first market uses INR, Asia/Kolkata, English (India), and day-month-year presentation while tenants retain configurable currency/timezone.
- **Why planning can proceed:** These defaults already appear in the approved system-planning source.
- **Risk if wrong:** Seed data, formatting, business-date behavior, receipts, and tests require revision.
- **Linked risks/questions:** `R-5`, `OQ-13`, `OQ-14`.

### A-2 — Planned additional locales

- **Assumption:** Hindi and Marathi are the first planned additional locales.
- **Why:** Explicit existing planning assumption; they are not MVP commitments.
- **Risk if wrong:** Translation preparation may target the wrong languages.
- **Linked question:** `OQ-14`.

### A-3 — Managed MongoDB and Redis availability

- **Assumption:** Managed MongoDB replica-set and Redis services are available for production.
- **Why:** Existing architecture depends on transactions, recovery, caching, BullMQ, and managed operations.
- **Risk if wrong:** Persistence, queue, recovery, and deployment architecture must change before implementation/deployment phases.
- **Linked risks/questions:** `R-10`, `OQ-31`.

### A-4 — WhatsApp onboarding is external

- **Assumption:** WhatsApp provider account and template approval are external prerequisites and may not be immediately available.
- **Why:** Existing source makes WhatsApp plan-gated and preserves in-app delivery as the critical fallback.
- **Risk if wrong:** Notification acceptance timing or provider adapter scope changes.
- **Linked risks/questions:** `R-8`, `OQ-19`.

### A-5 — Online authority for financial operations

- **Assumption:** Internet connectivity is normally available when committing authoritative financial operations.
- **Why:** Existing mobile strategy permits bounded cached reads but does not authorize offline financial truth.
- **Risk if wrong:** An offline transaction/conflict model would be a major product and data-model change.
- **Linked question:** `OQ-23`.

### A-6 — Manual subscription billing for MVP

- **Assumption:** Subscription billing state is recorded manually during MVP.
- **Why:** Explicit existing MVP boundary; broader subscription billing automation is post-MVP.
- **Risk if wrong:** Payment-provider, webhook, invoice, delinquency, and reconciliation contracts enter MVP.
- **Linked question:** `OQ-2`.

### A-7 — No card data storage

- **Assumption:** Nexoraa CleanSoft does not directly store card data.
- **Why:** Explicit existing security assumption.
- **Risk if wrong:** Compliance scope, threat model, data classification, provider architecture, and audit requirements change substantially.
- **Linked question:** `OQ-8`.

### A-8 — Small delivery team

- **Assumption:** MVP must be supportable by a small engineering and operations team.
- **Why:** Explicit existing constraint and rationale for preserving service boundaries while permitting consolidated deployment.
- **Risk if wrong:** Ownership, deployment, on-call, and sequencing plans may be over- or under-designed.
- **Linked questions:** `OQ-28`, `OQ-30`.

### A-9 — Store releases are not instantaneous

- **Assumption:** Android/iOS releases cannot be forced instantly after store publication.
- **Why:** Explicit existing constraint.
- **Risk if wrong:** API compatibility and forced-upgrade policies could be designed incorrectly.
- **Linked question:** `OQ-21`.

## Risks

### R-1 — Cross-tenant data leakage

- **Probability:** Low.
- **Impact:** Critical.
- **Controls already stated:** Fail-closed context, scoped access, least privilege, tenant-isolation tests, tenant-safe derived systems and recovery.

### R-2 — Cross-branch privilege error

- **Probability:** Medium.
- **Impact:** High.
- **Controls:** Explicit assignment, branch-aware authorization, deny-by-default, multi-branch tests.

### R-3 — Ambiguous ownership or circular coupling

- **Probability:** Medium.
- **Impact:** High.
- **Controls:** Single-owner module matrix, contract-first seams, prohibited private persistence access, dependency graph derived from consumers.

### R-4 — Distributed consistency drift

- **Probability:** Medium.
- **Impact:** High.
- **Controls:** Local transactions, outbox, idempotent consumers, reconciliation, observable lag, rebuildable projections.

### R-5 — Financial rounding or policy error

- **Probability:** Medium.
- **Impact:** Critical.
- **Controls:** Minor units, fixed precision, snapshots, additive corrections, deterministic tests.
- **Unresolved exposure:** `OQ-4` through `OQ-10`.

### R-6 — Duplicate order or payment

- **Probability:** Medium.
- **Impact:** High.
- **Controls:** Idempotency, atomic counters, unique references, concurrency tests.

### R-7 — Audit evidence gap

- **Probability:** Low.
- **Impact:** Critical.
- **Controls:** Append-only audit, reliable obligation recording, explicit critical failure policy.
- **Unresolved exposure:** `OQ-26`.

### R-8 — External provider outage or onboarding delay

- **Probability:** High.
- **Impact:** Medium.
- **Controls:** In-app fallback, queues, bounded retry, provider abstraction, templates, delivery history.

### R-9 — Report/search load affects transactions

- **Probability:** Medium.
- **Impact:** High.
- **Controls:** Derived read models, rollups, bounded date/page ranges, asynchronous exports, rebuildable indexes.

### R-10 — Local/CI transaction behavior differs from production

- **Probability:** Medium.
- **Impact:** High.
- **Controls needed:** Transaction-capable local/CI MongoDB validation before transaction-dependent phases are accepted.

### R-11 — Malicious or mis-scoped file upload

- **Probability:** Medium.
- **Impact:** High.
- **Controls:** Private tenant prefixes, authorization, size/type/extension/metadata validation, scanning, signed access.
- **Unresolved exposure:** `OQ-20`.

### R-12 — Mobile connectivity loss

- **Probability:** High.
- **Impact:** Medium.
- **Controls:** Explicit offline states, bounded safe cache, retry/idempotency, no silent offline financial commits.

### R-13 — Premature microservice complexity

- **Probability:** Medium.
- **Impact:** High.
- **Controls:** Logical ownership with optional consolidated initial deployment; evidence-driven separation.

### R-14 — Documentation and phase drift

- **Probability:** High.
- **Impact:** High.
- **Evidence:** Placeholder canonical files, conflicting phase filenames/contents, old completion sequence, and duplicated guides.
- **Controls:** This migration, stable IDs, append-only decisions/audits, status source-of-truth rule, cross-reference checks.

### R-15 — Removed web scope remains in historical planning

- **Probability:** High.
- **Impact:** Medium.
- **Evidence:** Existing Phase 1/2/roadmap/module prompts still describe Flutter web, but `apps/web-frontend` has been intentionally removed.
- **Controls:** Current Layer 1 excludes web scope; Layer 2/3 migration must remove web implementation obligations while preserving historical context.

### R-16 — Unproven performance and recovery targets

- **Probability:** Medium.
- **Impact:** High.
- **Evidence:** Targets exist but capacity volumes, environments, provider topology, and measured evidence do not.
- **Controls:** Treat targets as planning objectives until approved and measured; resolve `OQ-28` through `OQ-32`.

### R-17 — Personal-data lifecycle noncompliance

- **Probability:** Medium.
- **Impact:** Critical.
- **Evidence:** Consent, retention, deletion exceptions, residency, breach ownership, and legal obligations are unresolved.
- **Controls:** Block affected data/production contracts until `OQ-11` and `OQ-12` are resolved.

### R-18 — Legacy prompts preserve conflicting implementation details

- **Probability:** High.
- **Impact:** High.
- **Evidence:** Files named phases 18–22 contain unrelated Mobile, Security, Testing, DevOps, and Deployment content rather than Expenses, Reports, Dashboard, Search, and Settings.
- **Controls:** Preserve those details as source fragments, but re-home them by actual subject in Layer 2/3 rather than trusting filenames.

