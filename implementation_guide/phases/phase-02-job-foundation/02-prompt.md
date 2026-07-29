# PHASE 02 — SCHEDULER & JOB FOUNDATION
# PART 1 — ARCHITECTURE, INFRASTRUCTURE & DATA MODEL

## ADR Reference

ADR-005

## Objective

Build the enterprise Scheduler Foundation for the CleanSoft platform.

This scheduler is NOT a business service.

It is shared infrastructure that allows every bounded context to execute asynchronous work safely and consistently.

Examples of future owners include:

- Billing
- Inventory
- HR
- CRM
- Payroll
- Delivery
- Purchasing
- Warranty
- Notification
- Analytics

The scheduler MUST NEVER own domain business logic.

Every business service remains responsible for its own workflow.

The scheduler only manages lifecycle, reliability, retries, execution metadata, scheduling and recovery.

------------------------------------------------------------
GENERAL REQUIREMENTS
------------------------------------------------------------

Implement production-quality code.

Do not generate demo code.

Do not generate mock implementations.

Do not create placeholder methods.

Do not leave TODO comments.

Everything must compile successfully.

No TypeScript errors.

No ESLint warnings.

Use dependency injection everywhere.

Follow NestJS best practices.

Follow SOLID principles.

Follow Clean Architecture.

Follow Repository Pattern.

Follow Service Pattern.

Follow Adapter Pattern where applicable.

Do not modify unrelated modules.

Maintain backward compatibility.

------------------------------------------------------------
TECH STACK
------------------------------------------------------------

NestJS

BullMQ

Redis

TypeScript

MongoDB

Mongoose

Jest

Swagger

JWT Authentication

------------------------------------------------------------
PROJECT STRUCTURE
------------------------------------------------------------

Create

src/modules/scheduler

scheduler.module.ts

scheduler.service.ts

scheduler.controller.ts

scheduler.repository.ts

scheduler.worker.ts

scheduler.processor.ts

scheduler.queue.factory.ts

scheduler.queue.manager.ts

scheduler.retry.strategy.ts

scheduler.backoff.ts

scheduler.constants.ts

scheduler.enums.ts

scheduler.interfaces.ts

scheduler.types.ts

scheduler.utils.ts

scheduler.decorators.ts

scheduler.validators.ts

scheduler.config.ts

dto/

guards/

responses/

workers/

adapters/

------------------------------------------------------------
RESPONSIBILITIES
------------------------------------------------------------

Scheduler MUST provide

Queue registration

Job scheduling

Retry policy

Dead Letter Queue

Recovery

Job inspection

Recurring schedules

Idempotency

Validation

Correlation tracking

Queue lifecycle

Worker lifecycle

Nothing more.

------------------------------------------------------------
OUT OF SCOPE
------------------------------------------------------------

Never implement

Billing logic

Inventory logic

Payroll calculations

Invoice generation

Email sending

SMS sending

WhatsApp sending

PDF generation

Report generation

Database reconciliation

Business state machines

Any domain queries

Notification providers

Business validations

File deletion

Worker autoscaling

------------------------------------------------------------
REDIS CONFIGURATION
------------------------------------------------------------

Create centralized Redis configuration.

Environment driven.

Support

host

port

username

password

tls

db

connection timeout

retry strategy

lazy connection

health check

Graceful shutdown.

------------------------------------------------------------
BULLMQ CONFIGURATION
------------------------------------------------------------

Create reusable BullMQ configuration.

Single QueueFactory.

Single WorkerFactory.

Reusable QueueManager.

No duplicated queue creation.

No inline BullMQ initialization.

------------------------------------------------------------
QUEUE NAMING
------------------------------------------------------------

Queue names MUST contain

Environment

Tenant

Owner

Example

dev:tenant123:billing

dev:tenant123:inventory

prod:tenant001:delivery

Queue names must never collide.

------------------------------------------------------------
JOB OWNERSHIP
------------------------------------------------------------

Every job has exactly one owner.

Owner examples

Billing

Inventory

Delivery

HR

CRM

Payroll

Warranty

Notification

Owner remains responsible for

validation

execution

business rules

scheduler never owns them.

------------------------------------------------------------
JOB ENVELOPE
------------------------------------------------------------

Every queued job MUST follow DATA-MODEL.md.

Fields

jobId

version

owner

tenantId

environment

scope

correlationId

requestId

idempotencyKey

status

attempts

maxAttempts

createdAt

scheduledAt

startedAt

finishedAt

nextRetryAt

payloadReference

payloadChecksum

priority

delay

metadata

deadLetterReason

failureReason

lastError

------------------------------------------------------------
PAYLOAD RULES
------------------------------------------------------------

Never enqueue full business objects.

Only enqueue

reference IDs

minimal metadata

small immutable payloads

Large payloads must remain inside owner database.

Scheduler stores references only.

------------------------------------------------------------
STATUS ENUM
------------------------------------------------------------

Pending

Waiting

Delayed

Active

Completed

Failed

RetryScheduled

DeadLettered

Cancelled

Expired

------------------------------------------------------------
JOB VERSIONING
------------------------------------------------------------

Every envelope contains

version

Future schema evolution must remain backward compatible.

Never break existing workers.

------------------------------------------------------------
CORRELATION
------------------------------------------------------------

Support

requestId

correlationId

traceId

These values must flow through retries.

------------------------------------------------------------
TENANT ISOLATION
------------------------------------------------------------

Jobs from different tenants must never share queues.

Never execute another tenant's job.

------------------------------------------------------------
ENVIRONMENT ISOLATION
------------------------------------------------------------

Development

Testing

Production

must never share queues.

------------------------------------------------------------
PRIORITY
------------------------------------------------------------

Support BullMQ priority.

Validate range.

Reject invalid priority.

------------------------------------------------------------
SCHEDULE TYPES
------------------------------------------------------------

Immediate

Delayed

Recurring

Cron

One Time

Do not implement business schedules.

Only infrastructure.

------------------------------------------------------------
VALIDATION
------------------------------------------------------------

Validate

owner

tenant

queue

environment

payload

idempotency

schedule

delay

priority

attempt count

before enqueue.

Validate again before execute.

Never trust Redis data.

------------------------------------------------------------
DEPENDENCY INJECTION
------------------------------------------------------------

Inject

QueueManager

QueueFactory

WorkerFactory

Repository

Audit Service Interface

Redis Client

Never instantiate manually.

------------------------------------------------------------
CONFIGURATION
------------------------------------------------------------

Environment variables

REDIS_HOST

REDIS_PORT

REDIS_PASSWORD

REDIS_USERNAME

QUEUE_PREFIX

QUEUE_ENV

DEFAULT_ATTEMPTS

DEFAULT_DELAY

DEFAULT_PRIORITY

Enable validation.

Fail startup on invalid config.

# PHASE 02 — SCHEDULER FOUNDATION
# PART 2 — REPOSITORY, QUEUE MANAGEMENT & CORE SERVICES

Continue from Part 1.

Do not rewrite existing code.

Extend the scheduler module.

------------------------------------------------------------
OBJECTIVE
------------------------------------------------------------

Implement

Queue Repository

Queue Manager

Job Scheduling

Job Inspection

Recurring Schedule Registration

Recovery

Dead Letter Queue

Idempotency

Repository Layer

------------------------------------------------------------
DATABASE
------------------------------------------------------------

Create collections

schedulerJobs

schedulerSchedules

No additional collections.

------------------------------------------------------------
SCHEDULER JOB DOCUMENT
------------------------------------------------------------

Store

jobId

owner

tenantId

queueName

status

attempts

maxAttempts

delay

priority

idempotencyKey

requestId

correlationId

createdAt

scheduledAt

startedAt

finishedAt

lastError

deadLetterReason

payloadReference

environment

------------------------------------------------------------
SCHEDULE DOCUMENT
------------------------------------------------------------

scheduleId

owner

tenantId

cron

timezone

enabled

createdAt

updatedAt

lastRun

nextRun

------------------------------------------------------------
INDEXES
------------------------------------------------------------

Unique

jobId

idempotencyKey

scheduleId

Indexes

owner

tenantId

status

correlationId

requestId

createdAt

scheduledAt

------------------------------------------------------------
QUEUE MANAGER
------------------------------------------------------------

Responsible for

register queue

retrieve queue

remove queue

pause queue

resume queue

drain queue

clean queue

health check

No business logic.

------------------------------------------------------------
QUEUE FACTORY
------------------------------------------------------------

Factory creates queues.

Never duplicate queue creation.

Return existing queue if registered.

------------------------------------------------------------
WORKER FACTORY
------------------------------------------------------------

Responsible only for

worker creation

worker shutdown

worker configuration

No business execution.

------------------------------------------------------------
PUBLIC SERVICE METHODS
------------------------------------------------------------

scheduleJob()

inspectJob()

retryOrReplay()

registerSchedule()

------------------------------------------------------------
scheduleJob()
------------------------------------------------------------

Validate request.

Validate owner.

Validate tenant.

Validate payload.

Validate idempotency.

Validate schedule.

Check duplicate.

If duplicate exists

Return existing JobId.

Else

Persist metadata.

Enqueue BullMQ job.

Return JobId.

------------------------------------------------------------
inspectJob()
------------------------------------------------------------

Return

status

attempts

nextRetry

queue

owner

createdAt

startedAt

finishedAt

deadLetterReason

SafeJobState only.

Never expose Redis internals.

------------------------------------------------------------
registerSchedule()
------------------------------------------------------------

Register recurring schedule.

Validate cron.

Validate timezone.

Persist schedule.

Return ScheduleId.

No business cron implementation.

------------------------------------------------------------
retryOrReplay()
------------------------------------------------------------

Require authorization.

Require reason.

Call Audit Service (SVC-AUDIT-001).

Replay only owner jobs.

Never replay automatically.

------------------------------------------------------------
IDEMPOTENCY
------------------------------------------------------------

One owner

One idempotency key

One job

Duplicates return original JobId.

------------------------------------------------------------
BACKOFF STRATEGY
------------------------------------------------------------

Implement reusable strategy.

Exponential backoff.

Add random jitter.

Maximum retry limit configurable.

Exact physical defaults remain configurable until OQ-25.

------------------------------------------------------------
DEAD LETTER QUEUE
------------------------------------------------------------

Failed jobs exceeding retries

Move to DLQ.

Never loop infinitely.

Never auto replay.

Persist failure reason.

Persist timestamp.

------------------------------------------------------------
ALERTING
------------------------------------------------------------

Expose alert hook interface.

No Email.

No SMS.

No Slack.

Infrastructure only.

------------------------------------------------------------
RECOVERY
------------------------------------------------------------

Recovery must

validate authorization

record audit

requeue job

increment replay count

preserve correlation

------------------------------------------------------------
AUTHORIZATION
------------------------------------------------------------

Only owner

or platform administrator

may replay jobs.

------------------------------------------------------------
AUDIT INTEGRATION
------------------------------------------------------------

Every recovery action

must call

SVC-AUDIT-001

Never bypass audit.

------------------------------------------------------------
HEALTH CHECK
------------------------------------------------------------

Implement

Redis connectivity

Queue status

Worker status

DLQ availability

------------------------------------------------------------
UNIT TESTS
------------------------------------------------------------

Test

queue registration

duplicate detection

job scheduling

inspection

retry

replay

DLQ

backoff

authorization

------------------------------------------------------------
INTEGRATION TESTS
------------------------------------------------------------

Verify

BullMQ integration

Redis connectivity

queue naming

tenant isolation

environment isolation

dead letter routing

------------------------------------------------------------
PERFORMANCE
------------------------------------------------------------

Avoid duplicate queue creation.

Reuse Redis connections.

Minimize serialization.

Support thousands of queued jobs.

------------------------------------------------------------
SECURITY
------------------------------------------------------------

Reject malformed payloads.

Validate owner.

Validate queue.

Validate tenant.

Validate idempotency.

Never execute unauthorized recovery.

