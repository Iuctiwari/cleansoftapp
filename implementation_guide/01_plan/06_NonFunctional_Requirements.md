# Non-Functional Requirements

## Classification

- **Stated:** Explicit in existing source material.
- **Inferred:** Necessary to satisfy a stated requirement but not stated at the same level of precision; it must be confirmed or converted to an ADR.
- **Gap:** Existing audits identify missing stakeholder or engineering approval. A Gap is not an approved target.

## Security and privacy

| ID | Classification | Requirement |
|---|---|---|
| NFR-SEC-01 | Stated | Missing or uncertain identity, tenant, branch, role, permission, or entitlement context must fail closed. |
| NFR-SEC-02 | Stated | Tenant isolation must cover domain data, caches, queues, jobs, events, search, reports, exports, files, telemetry, backups, restoration, and support tools. |
| NFR-SEC-03 | Stated | TLS protects network traffic and managed production storage uses encryption at rest. |
| NFR-SEC-04 | Stated | Secrets must use a secret manager and must not be committed, logged, embedded in Flutter assets, or copied into lower environments. |
| NFR-SEC-05 | Stated | Inputs are validated at trust boundaries; outputs exclude internal and unauthorized fields. |
| NFR-SEC-06 | Stated | Rate limits apply by IP, identity, tenant, and sensitive operation; exact quotas remain a Gap. |
| NFR-SEC-07 | Stated | Credentials, OTPs, tokens, cookie values, full payment credentials, and private storage signatures must never be logged. |
| NFR-SEC-08 | Stated | Restricted data is minimized, redacted, least-privilege, and monitored. |
| NFR-SEC-09 | Gap | Threat model, abuse-case catalogue, privacy inventory, consent model, support-access process, MFA roadmap, breach ownership, secret rotation, malware-scanning provider, and security-log retention require approval. |

## Performance and capacity

| ID | Classification | Requirement |
|---|---|---|
| NFR-PERF-01 | Stated | Common authenticated reads/writes target p95 ≤ 300 ms excluding external providers. |
| NFR-PERF-02 | Stated | Typical search targets p95 ≤ 500 ms. |
| NFR-PERF-03 | Stated | Dashboard first useful result targets ≤ 2 seconds. |
| NFR-PERF-04 | Stated | Paginated operational first page targets ≤ 1 second. |
| NFR-PERF-05 | Stated | Critical events target consumer availability within 5 seconds under normal load. |
| NFR-PERF-06 | Stated | Notifications target queued state within 2 seconds of the source event. |
| NFR-PERF-07 | Stated | Default page size is 20, approved maximum is 100, and report requests are limited to 366 days before asynchronous handling applies. |
| NFR-PERF-08 | Stated | Standard CSV export becomes asynchronous when size or date range exceeds the synchronous budget. |
| NFR-PERF-09 | Gap | Launch tenant count, typical branches, peak order rate, order size, report concurrency, notification burst, file volume, queue recovery throughput, and “large tenant” thresholds are not approved. |
| NFR-PERF-10 | Inferred | Every performance target must be tied to a reproducible workload and measured environment before it is treated as a release gate. |

## Availability, resilience, and recovery

| ID | Classification | Requirement |
|---|---|---|
| NFR-REL-01 | Stated | Initial monthly API availability target is 99.9%, excluding approved maintenance. |
| NFR-REL-02 | Stated | Initial RPO is 15 minutes for primary business data and initial regional-incident RTO is 4 hours. |
| NFR-REL-03 | Stated | Production uses health/readiness checks, rolling deployment, automated restart, monitored encrypted backups, and point-in-time database recovery. |
| NFR-REL-04 | Stated | Restoration exercises occur quarterly before general availability and at least twice yearly afterward. |
| NFR-REL-05 | Stated | Notification and export outages must not prevent orders or payments; authoritative auth, tenant, and financial dependencies fail closed. |
| NFR-REL-06 | Stated | External adapters use strict timeouts, bounded retry with backoff/jitter, idempotency, rate awareness, replay protection, and observable health. |
| NFR-REL-07 | Gap | Business/operations approval of SLO, RPO, RTO, provider objectives, backup schedule/provider, and disaster-recovery topology is pending. |

## Scalability and consistency

| ID | Classification | Requirement |
|---|---|---|
| NFR-SCALE-01 | Stated | Gateway, services, and workers must be horizontally scalable; service separation occurs only after measured thresholds justify it. |
| NFR-SCALE-02 | Stated | Concurrent business numbering uses atomic scoped counters. |
| NFR-SCALE-03 | Stated | Local multi-record invariants use transactions; cross-service workflows use outbox, eventual consistency, idempotency, and reconciliation. |
| NFR-SCALE-04 | Stated | Optimistic concurrency prevents silent overwrites. |
| NFR-SCALE-05 | Stated | Reports and search use derived, rebuildable projections rather than private cross-service reads. |
| NFR-SCALE-06 | Gap | Local/CI MongoDB transaction parity with the planned production replica set is not demonstrated. |

## Data integrity and lifecycle

| ID | Classification | Requirement |
|---|---|---|
| NFR-DATA-01 | Stated | Currency uses integer minor units plus ISO currency code; quantities/percentages use fixed precision and explicit rounding. |
| NFR-DATA-02 | Stated | Catalog, customer, price, tax, and discount snapshots preserve historical transactions. |
| NFR-DATA-03 | Stated | Refunds and adjustments are additive; finalized payments, receipts, registers, and audit evidence are immutable. |
| NFR-DATA-04 | Stated | Operational deactivation is preferred over destructive deletion where references exist. |
| NFR-DATA-05 | Stated | Retention and archival distinguish operational, financial, audit, notification, file, and telemetry data and preserve authorized traceability/legal hold. |
| NFR-DATA-06 | Gap | Tax rounding boundary, discount allocation, refund tax, overpayment accounting, business-date cutoff, register reopening, currency change, export retention, data residency, and personal-data deletion policy remain unresolved. |

## Maintainability and compatibility

| ID | Classification | Requirement |
|---|---|---|
| NFR-MAINT-01 | Stated | Modules have one owner and communicate through strict versioned contracts; direct cross-service persistence access is prohibited. |
| NFR-MAINT-02 | Stated | TypeScript and Dart use strict analysis, explicit errors, thin transport boundaries, deterministic calculations, and no hidden fallback. |
| NFR-MAINT-03 | Stated | API and event evolution use compatibility periods, migration guidance, usage evidence, and contract tests. |
| NFR-MAINT-04 | Gap | API compatibility window, idempotency lifetime, minimum mobile compatibility, event retention/naming, and contract-test tooling are not approved. |
| NFR-MAINT-05 | Inferred | Stable IDs in this guide are never repurposed; supersession remains explicit to protect downstream traceability. |

## Observability and operations

| ID | Classification | Requirement |
|---|---|---|
| NFR-OBS-01 | Stated | Logs are structured, UTC, centrally aggregated, correlated, and include safe service/operation/outcome/duration/dependency/error context. |
| NFR-OBS-02 | Stated | Metrics and alerts cover API latency/errors/saturation, auth failures, isolation denials, MongoDB, Redis, queues, providers, outbox/consumer lag, projection freshness, reconciliation drift, mobile crashes, and backups. |
| NFR-OBS-03 | Stated | Every production alert has severity, owner, response target, and runbook. |
| NFR-OBS-04 | Gap | Observability vendor, production sampling, alert ownership, and final SLOs are not selected. |

## Accessibility, localization, and mobile quality

| ID | Classification | Requirement |
|---|---|---|
| NFR-UX-01 | Stated | Initial locale assumption is English (India), INR, Asia/Kolkata, and day-month-year presentation; tenant currency/timezone remain configurable. |
| NFR-UX-02 | Stated | System time is UTC; business dates use tenant/branch timezone; currency, date, number, pluralization, and text direction are locale-aware. |
| NFR-UX-03 | Stated | Mobile client crash-free sessions target at least 99.5% during stabilization and must rise before general availability. |
| NFR-UX-04 | Stated | Flutter testing includes widget, accessibility, responsive, navigation, session, and offline/retry behavior. |
| NFR-UX-05 | Gap | Accessibility matrix, supported OS/device matrix, final production locales, state-management choice, contract generation, and secure-storage package are unresolved. |

## Compliance and governance

| ID | Classification | Requirement |
|---|---|---|
| NFR-GOV-01 | Stated | Critical actions create append-only, separately authorized audit evidence with at least twelve months' default retention, configurable upward. |
| NFR-GOV-02 | Stated | Production data is never copied raw to lower environments. |
| NFR-GOV-03 | Stated | Lockfiles are authoritative; dependencies/images are scanned; critical vulnerabilities block release unless formally accepted with compensating controls and expiry. |
| NFR-GOV-04 | Gap | Applicable regulatory obligations, consent, retention, breach response, data residency, legal hold, and audit/security retention require stakeholder approval. |

