# Observability

## Status

The direction is stated in existing planning. Vendor, sampling, final SLO ownership, and alert routing remain engineering/operational decisions under `OQ-31` and `NFR-OBS-04`.

## Correlation and trace context

- Gateway accepts or creates `correlationId`.
- Internal calls, outbox events, jobs, provider attempts, audit obligations, and errors carry correlation.
- `causationId` identifies the immediate triggering request/event/job.
- Trace context propagates through approved authenticated internal transport.
- Correlation is returned on every unexpected public failure.

## Structured log schema

Required safe fields:

- UTC timestamp, severity, environment, service, version.
- Operation/contract ID and outcome.
- Correlation/trace/causation IDs.
- Tenant/branch/actor identifiers only where permitted.
- Duration, dependency, retryability, error category/code.
- Event/job IDs, attempt, queue age, projection checkpoint where applicable.

Never log passwords, OTPs, access/refresh tokens, cookies, signing material, full payment credentials, private signed URLs, provider secrets, or unnecessary customer content.

## Metrics

### Platform/API

Request count, p50/p95/p99 latency, error category, rate-limit decisions, saturation, readiness, dependency latency/failure.

### Security

Login failures, lockouts, reset attempts, refresh reuse, authorization denials, tenant/branch isolation denials, support access, suspicious file/provider callbacks.

### Data

MongoDB connections, slow operations, transaction aborts, replication lag, capacity; Redis memory/eviction/connectivity; backup success/age and restore verification.

### Events/jobs

Outbox pending age, publish failures, consumer lag, deduplication, queue depth/oldest age, retry count, dead letters, worker concurrency/saturation, replay results.

### Business integrity

Duplicate prevention conflicts, numbering contention, payment reconciliation drift, customer/order balance drift, register variance, report/source mismatch.

### Providers/files

Dispatch/delivery/failure/rate-limit, circuit suppression, callback rejection/replay, upload rejection, scan latency/failure, quarantine/orphan cleanup.

### Projections/mobile

Search/report/dashboard freshness/rebuild, export duration/failure; Flutter crash-free sessions, startup time, network failure, session renewal, API compatibility failures.

## Planning objectives

- API availability: 99.9% monthly excluding approved maintenance.
- Common API p95 ≤ 300 ms excluding providers.
- Search p95 ≤ 500 ms.
- Dashboard first useful result ≤ 2 seconds.
- Critical event consumer availability ≤ 5 seconds normally.
- Notification queued ≤ 2 seconds.
- Mobile crash-free sessions ≥ 99.5% during stabilization.
- RPO 15 minutes; RTO 4 hours for regional incident.

These are not production promises until `OQ-28` and `OQ-29` are resolved and load/recovery evidence exists.

## Alerts

Every production alert requires severity, owner, response target, runbook, and safe diagnostic links. Required alert families:

- API/auth/authorization anomaly.
- Database/Redis availability and capacity.
- Outbox/queue lag and dead letter.
- Provider sustained failure/rate limit.
- Projection freshness and reconciliation drift.
- Backup failure/age and restore-test failure.
- File scanning failure/quarantine surge.
- Mobile crash/API incompatibility regression.

## Health

- Liveness proves the process can run.
- Readiness proves required authoritative dependencies are available for the traffic class.
- Optional dependencies such as notifications/reports expose degraded status without necessarily failing order/payment readiness.
- Health output excludes secrets, raw connection strings, tenant data, and internal topology details.

## Audit versus logs

Operational logs are mutable telemetry. `auditRecords` are append-only business/security evidence under `ADR-015`. A log entry never substitutes for `SVC-AUDIT-001`.

