# Phase 02 — Scheduler & Job Foundation

## Objective

Implement the reusable Scheduler & Job Foundation (ADR-005) for the CleanSoft ERP.

This module is shared infrastructure for asynchronous job execution.

It manages scheduling, retries, queues, dead-letter handling, idempotency, recovery, and execution metadata.

It MUST NOT contain business logic.

---

## Tech Stack

- NestJS
- BullMQ
- Redis
- MongoDB
- Mongoose
- Swagger
- JWT

---

## Module Structure

Create Scheduler module containing:

- Scheduler Module
- Service
- Controller
- Repository
- Worker
- Processor
- QueueFactory
- QueueManager
- WorkerFactory
- Retry Strategy
- Backoff Strategy
- Validators
- DTOs
- Interfaces
- Types
- Config
- Enums
- Constants
- Utilities

---

## Responsibilities

Implement only:

- Queue registration
- Queue lifecycle
- Worker lifecycle
- Job scheduling
- Retry policy
- Dead Letter Queue
- Recovery
- Job inspection
- Recurring schedules
- Idempotency
- Validation
- Correlation tracking

---

## Collections

Create only:

- schedulerJobs
- schedulerSchedules

---

## Redis

Create centralized Redis configuration.

Support:

- host
- port
- username
- password
- TLS
- database
- retry strategy
- lazy connection
- health checks
- graceful shutdown

---

## BullMQ

Implement reusable:

- QueueFactory
- WorkerFactory
- QueueManager

Never create duplicate queues.

Never initialize BullMQ inline.

---

## Queue Rules

Queue names must include:

- Environment
- Tenant
- Owner

Examples:

dev:tenant123:billing

prod:tenant001:inventory

Queue names must always be unique.

---

## Job Envelope

Every job must contain:

- jobId
- version
- owner
- tenantId
- environment
- scope
- requestId
- correlationId
- idempotencyKey
- status
- attempts
- maxAttempts
- timestamps
- payloadReference
- payloadChecksum
- priority
- delay
- metadata
- failure reason
- dead-letter reason

Only enqueue references and minimal immutable metadata.

Never enqueue full business objects.

---

## Status Enum

Support:

- Pending
- Waiting
- Delayed
- Active
- Completed
- Failed
- RetryScheduled
- DeadLettered
- Cancelled
- Expired

---

## Scheduling

Support:

- Immediate
- Delayed
- One-Time
- Recurring
- Cron

Infrastructure only.

No business schedules.

---

## Validation

Validate before enqueue and before execution:

- owner
- tenant
- queue
- environment
- payload
- idempotency
- schedule
- delay
- priority
- retry count

Never trust Redis payloads.

---

## Public Service Methods

Implement only:

- scheduleJob()
- inspectJob()
- retryOrReplay()
- registerSchedule()

---

## scheduleJob()

- Validate request
- Validate owner
- Validate tenant
- Validate payload
- Validate idempotency
- Detect duplicates
- Return existing JobId when duplicate
- Persist metadata
- Enqueue BullMQ job

---

## inspectJob()

Return safe job state only.

Expose:

- status
- attempts
- retry information
- owner
- queue
- timestamps
- dead-letter reason

Never expose Redis internals.

---

## registerSchedule()

- Validate cron
- Validate timezone
- Persist schedule
- Return ScheduleId

No business cron logic.

---

## retryOrReplay()

Require:

- Authorization
- Reason
- Audit record

Replay only owner jobs.

Never replay automatically.

---

## Idempotency

One owner

One idempotency key

One job

Duplicate requests return original JobId.

---

## Backoff

Implement reusable exponential backoff.

Support:

- random jitter
- configurable retry limit

---

## Dead Letter Queue

Failed jobs exceeding retry limits must:

- move to DLQ
- persist failure reason
- persist timestamp

Never auto replay.

Never create retry loops.

---

## Recovery

Recovery must:

- validate authorization
- create audit record
- requeue job
- preserve correlation
- increment replay count

---

## Audit Integration

Every recovery action must call:

SVC-AUDIT-001

Audit cannot be bypassed.

---

## Health Checks

Provide:

- Redis connectivity
- Queue health
- Worker health
- DLQ health

---

## Required Indexes

schedulerJobs:

- jobId (unique)
- idempotencyKey
- owner
- tenantId
- status
- requestId
- correlationId
- createdAt
- scheduledAt

schedulerSchedules:

- scheduleId (unique)

---

## Testing

Create:

- Unit Tests
- Integration Tests

Cover:

- Queue registration
- Duplicate detection
- Scheduling
- Retry
- Replay
- DLQ
- Authorization
- Queue naming
- Tenant isolation
- Environment isolation

---

## Do Not Implement

- Billing logic
- Inventory logic
- Payroll logic
- Notifications
- Email/SMS/WhatsApp
- PDFs
- Reports
- Analytics
- Database reconciliation
- Business workflows
- Provider integrations
- File deletion
- Worker autoscaling