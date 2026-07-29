# Migration Source Map

## Purpose

This map prevents information loss and identifies where existing material now lives. Legacy files remain until `OQ-34` decides archive, supersession markers, or removal after final human review.

| Legacy source | Migrated destination | Treatment |
|---|---|---|
| `PHASE_1_SOFTWARE_IDEA.md` | Layer 1 vision, requirements, personas, journeys, glossary | Business intent retained; duplicate theory condensed |
| `PHASE_2_SYSTEM_PLANNING.md` | All Layer 1 files; architecture master/architecture/ADRs/contracts/data/testing/standards/observability | Substantive decisions and targets split by claim type |
| `PHASE_3_PLAN_AUDIT.md` | Assumptions, risks, open questions, ADRs, Audit Pass 001 | Findings retained; unresolved matters remain blockers |
| `PHASE_4_IMPLEMENTATION_ROADMAP.md` | Dependency graph and phases 00–20 | Old list order replaced by contract-consumer order |
| `PHASE_5_ROADMAP_AUDIT.md` | Risks/open questions, dependency gates, testing/release phases | Conditional gaps retained |
| `implementation-prompts/README.md` | Phase plan/prompt/status structure and completion rules | Governance retained without duplicated instruction prose |
| `prompt-engineering/README.md` | Phase briefs, status honesty, audit/evidence rules | Bounded execution and factual reporting retained |
| `PHASE_9_AUTH.md` | Auth ADRs/contracts/API/data/Phase 03 | Web-only instructions removed; auth details retained |
| `PHASE_10_TENANTS.md` | Tenant contracts/API/data/Phase 04 | Web-only instructions removed; unresolved plan values remain open |
| `PHASE_11_BRANCHES.md` | Branch contracts/API/data/Phase 05 | Detailed route/lifecycle/index rules retained |
| `PHASE_12_USERS.md` | User contracts/API/data/Phase 06 | Detailed RBAC/invitation/index rules retained |
| `PHASE_13_CUSTOMERS.md` | Customer contracts/API/data/Phase 08 | Loyalty preserved as deferred future scope, not MVP |
| `PHASE_14_SERVICES.md` | Catalog contracts/API/data/Phase 09 | Catalog/pricing/history rules retained |
| `PHASE_15_ORDERS.md` | Order/delivery contracts/API/data/Phase 10 | Delivery remains Order-owned |
| `PHASE_16_PAYMENTS.md` | Payment/receipt contracts/API/data/Phase 11 | Financial policy gaps remain explicit |
| `PHASE_17_NOTIFICATIONS.md` | Notification contracts/API/data/Phase 12 | Email/SMS/push preserved as post-MVP, not implemented |
| File named `PHASE_18_EXPENSES.md` but containing Mobile Foundation | Phase 17 Flutter Mobile | Re-homed by actual subject; filename conflict retained as `R-18` |
| File named `PHASE_19_REPORTS.md` but containing Security Hardening | Phase 18 Testing/Security | Re-homed by actual subject |
| File named `PHASE_20_DASHBOARD.md` but containing Comprehensive Testing | Phase 18 Testing/Security | Re-homed by actual subject |
| File named `PHASE_21_SEARCH.md` but containing DevOps/Observability | Architecture Observability and Phase 19 Deployment | Re-homed by actual subject |
| File named `PHASE_22_SETTINGS.md` but containing Deployment | Phase 19 Deployment | Re-homed by actual subject |
| `PHASE_23_TESTING.md` | Testing strategy and Phase 18 | Assurance details retained |
| `PHASE_24_DEPLOYMENT.md` | Observability and Phase 19 | Deployment constraints retained |
| `PHASE_25_RELEASE.md` | Phase 20 | Release governance retained |
| Legacy phase-completion templates | New `04-status.md`; future factual `03-audit.md` | No legacy completion claim accepted as evidence |
| Empty root planning/docs placeholders | Corresponding implementation-guide files | No substantive content to migrate beyond subject intent |

## Information intentionally not promoted to current scope

- Flutter web implementation instructions, because the web application was intentionally removed (`ADR-008`).
- Loyalty/promotions, PDF exports, additional messaging channels, public API, customer portal, advanced analytics, and other post-MVP/future items.
- Provider, cloud, financial, privacy, retention, capacity, and governance decisions that remain unresolved `OQ-*`.

Nothing in this map authorizes deletion of legacy sources before `OQ-34` is resolved and migration completeness receives human approval.

