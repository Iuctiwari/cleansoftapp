# Nexoraa CleanSoft — Architecture Master Plan

## Purpose

This is the Layer 2 entry point. Product truth lives in `../01_plan/`; engineering truth lives in this directory; phase truth lives in `../phases/`; actual phase status lives in each phase's `04-status.md`.

## Migration authority

The architecture preserves the substantive decisions in the existing Phase 2 System Planning document, corrections accepted by the Plan and Roadmap Audits, and implementation detail in the module prompts. Empty placeholder files are not treated as authority. Unresolved matters remain linked to `OQ-*`; they are not silently decided.

## Technology stack

| Area | Selected technology/direction | Source |
|---|---|---|
| Repository | pnpm/TurboRepo monorepo | Stated; `ADR-001` |
| Backend | NestJS with strict TypeScript | Stated; `ADR-002` |
| Public ingress | API gateway as the only public backend surface | Stated; `ADR-003` |
| Domain shape | Service-oriented logical ownership; initially consolidatable deployment | Stated; `ADR-002` |
| Primary data | MongoDB with Mongoose, managed replica set in production | Stated; `ADR-004`; availability depends on `A-3` |
| Cache/jobs | Redis and BullMQ | Stated; `ADR-005` |
| Cross-service consistency | Local transactions plus transactional outbox, idempotent consumers, reconciliation | Stated; `ADR-006` |
| Object storage | Private S3-compatible storage with time-limited access | Stated; `ADR-007` |
| Client | Flutter Android/iOS application | Stated current repository scope; `ADR-008` |
| External messaging | In-app plus plan-gated WhatsApp through an adapter | Stated; provider blocked by `OQ-19` |
| Observability | OpenTelemetry-compatible traces plus structured centralized logs/metrics | Stated direction; vendor blocked by `OQ-31` |
| Infrastructure | Docker local foundation; Terraform/Helm are foundations, not production-ready claims | Stated audit correction; `ADR-009` |

## NFR-to-mechanism map

| NFRs | Mechanism |
|---|---|
| `NFR-SEC-01`, `NFR-SEC-02` | Verified context, fail-closed guards, immutable tenant IDs, compound scoped indexes, tenant-safe cache/event/job/file keys, isolation tests |
| `NFR-SEC-03`–`NFR-SEC-08` | TLS, private networks/storage, secret manager, input/output policy, multi-dimensional throttling, redaction |
| `NFR-PERF-01`–`NFR-PERF-08` | Bounded pagination/date ranges, compound indexes, derived projections, async export, queue backpressure, load gates |
| `NFR-REL-01`–`NFR-REL-06` | Health/readiness, managed replicated data, backups/restores, bounded retries, circuit suppression, safe degradation |
| `NFR-SCALE-01`–`NFR-SCALE-05` | Stateless gateway/services, atomic counters, local transactions, outbox, idempotency, rebuildable projections |
| `NFR-DATA-01`–`NFR-DATA-05` | Minor units, fixed precision, immutable snapshots, additive corrections, lifecycle status, retention classes |
| `NFR-MAINT-01`–`NFR-MAINT-05` | Single ownership, versioned contracts, compatibility tests, ADRs, stable IDs |
| `NFR-OBS-01`–`NFR-OBS-03` | Correlation, structured logs, traces, metrics, alerts, runbooks |
| `NFR-UX-01`–`NFR-UX-04` | UTC storage, locale-aware client formatting, accessibility/mobile test suites, explicit offline states |
| `NFR-GOV-01`–`NFR-GOV-03` | Append-only audit, environment data separation, lockfile/scanning/release gates |

Gap-classified NFRs remain blockers in the relevant phase statuses and in `PROJECT_STATE.md`.

## Contract-first build order

The authoritative order is derived in `DEPENDENCY-GRAPH.md` from declared consumers in `CONTRACTS.md`.

1. Platform contracts and shared contract/error/context primitives.
2. Authentication.
3. Tenant/subscription.
4. Branch.
5. Users/RBAC.
6. Customer and catalog in parallel after access foundations.
7. Orders/delivery.
8. Payments/receipts and notifications.
9. Expenses/cash registers.
10. Audit, search, and report projections integrated alongside producer phases, then finalized.
11. Dashboard.
12. Settings hardening, file/jobs integration, and Flutter mobile experience.
13. Cross-system testing/security hardening.
14. Deployment and release.

## Layer 2 index

- [System architecture](00-ARCHITECTURE.md)
- [Append-only decisions](DECISIONS.md)
- [Internal and event contracts](CONTRACTS.md)
- [Public API contracts](API-CONTRACTS.md)
- [Data model](DATA-MODEL.md)
- [Dependency graph](DEPENDENCY-GRAPH.md)
- [Testing strategy](TESTING-STRATEGY.md)
- [Coding standards](CODING-STANDARDS.md)
- [Observability](OBSERVABILITY.md)
- [Project state](PROJECT_STATE.md)
- [Documentation audit log](AUDIT-LOG.md)

## Architecture gates

- A phase cannot be finalized if any consumed/produced `SVC-*` or `EVT-*` contract is missing.
- A persistence phase cannot be finalized if its authoritative entities, indexes, consistency boundary, and deletion/retention behavior are absent from `DATA-MODEL.md`.
- A public endpoint cannot be implemented unless it exists in `API-CONTRACTS.md`.
- Open product/data decisions remain explicit blockers; engineering defaults require an ADR and, when provisional, an `A-*`.
- `DECISIONS.md` and `AUDIT-LOG.md` are append-only.

