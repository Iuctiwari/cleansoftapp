# Phase 01 Build Brief — Audit Foundation

## Objective

Implement immutable audit evidence under `ADR-015`.

## Schema

Use `auditRecords` exactly as defined in `DATA-MODEL.md`: platform/tenant scope, optional branch, actor, module/action/target, UTC time, correlation, result, safe old/new summaries, classification/retention tags, and unique source obligation.

## Interfaces

- `recordAudit(obligation, context): AuditRecordId`
- `queryAudit(authorization, filters, page): AuditPage`
- `requestAuditExport(authorization, query, idempotency): ExportIntent`

## Public routes

- `GET /api/v1/audit`
- `GET /api/v1/audit/:auditId`
- `POST /api/v1/audit/exports`

Writes are internal only.

## Rules

- Append-only; no update/delete API.
- Deduplicate by source obligation.
- Separate platform and tenant policy.
- Old/new summaries are allowlisted and minimized.
- Until `OQ-26` resolves, expose explicit `Committed | DurablyDeferred | FailedRequired` outcomes; callers must not infer success.
- Retention/delete execution remains blocked by `OQ-12`.

## What not to build

No SIEM vendor, operational log store, unsupported retention deletion, domain-specific business logic, or public audit-write endpoint.

```text
# PHASE 01 — AUDIT FOUNDATION IMPLEMENTATION
## ADR-015 Enterprise Immutable Audit Service
## Target Stack
- NestJS
- TypeScript
- MongoDB
- Mongoose
- REST API
- Swagger
- JWT Authentication
- Enterprise Multi-Tenant Architecture

==================================================================
OBJECTIVE
==================================================================

Build the Audit Foundation described in ADR-015.

This phase creates the reusable audit infrastructure that every
future module (Orders, Billing, Inventory, HR, CRM, Delivery,
Payments, etc.) will use.

This phase DOES NOT implement business-specific auditing.

The audit system must be immutable, append-only, tenant-aware,
platform-aware, secure, scalable, and production-ready.

Never modify existing business logic.

Never break existing APIs.

Never change unrelated modules.

==================================================================
GENERAL REQUIREMENTS
==================================================================

Implement everything as production code.

No mock code.

No TODO comments.

No placeholder implementations.

No fake repositories.

No temporary DTOs.

Follow NestJS best practices.

Use dependency injection.

Follow SOLID principles.

Follow Clean Architecture.

Follow repository pattern.

Follow service pattern.

Follow DTO validation.

Follow centralized exception handling.

Everything must compile successfully.

No TypeScript errors.

No lint errors.

No breaking changes.

==================================================================
PROJECT STRUCTURE
==================================================================

Create a dedicated Audit module.

Example structure

src/modules/audit

audit.module.ts

audit.controller.ts

audit.service.ts

audit.repository.ts

audit.schema.ts

audit.constants.ts

audit.types.ts

audit.interfaces.ts

audit.mapper.ts

audit.validators.ts

audit.decorators.ts

audit.enums.ts

audit.utils.ts

dto/

guards/

responses/

swagger/

==================================================================
DATABASE COLLECTION
==================================================================

Collection name

auditRecords

Do not change the collection name.

==================================================================
DOCUMENT PROPERTIES
==================================================================

Implement every field defined by ADR-015.

_id

auditId

tenantId

platformScope

branchId

actor

actorType

actorId

actorName

module

action

targetType

targetId

targetName

requestId

correlationId

sourceObligation

timestampUtc

result

oldSummary

newSummary

classification

retentionPolicy

metadata

createdAt

==================================================================
IMMUTABLE RULE
==================================================================

Audit documents are immutable.

Allowed operations

INSERT

Forbidden operations

UPDATE

PATCH

DELETE

REPLACE

UPSERT

Never expose repository methods that modify an audit record.

Never expose service methods that modify an audit record.

Never expose controller methods that modify an audit record.

==================================================================
SOURCE OBLIGATION
==================================================================

Each audit event must contain

sourceObligation

Create a unique database index.

Duplicate obligations must never create duplicate records.

If duplicate request arrives

Return existing AuditRecordId.

Never insert twice.

==================================================================
TIMESTAMP
==================================================================

Always use UTC.

Never use local timezone.

Always generate timestamp on the server.

Do not trust client timestamps.

==================================================================
TENANT ISOLATION
==================================================================

Support

Platform Scope

Tenant Scope

Optional Branch Scope

Never allow tenant A to query tenant B records.

Platform administrators may query platform records.

Tenant users may only query their tenant.

==================================================================
CLASSIFICATION
==================================================================

Implement classification enum

PUBLIC

INTERNAL

CONFIDENTIAL

RESTRICTED

Store classification in every record.

==================================================================
RETENTION
==================================================================

Store retention metadata only.

Do NOT implement deletion.

Retention execution is blocked.

Never create cleanup jobs.

Never schedule deletion.

==================================================================
OLD SUMMARY
==================================================================

Never store full objects.

Store only allowlisted fields.

Example

status

amount

role

approvalState

Never store

password

token

otp

secret

credit card

refresh token

jwt

hash

==================================================================
NEW SUMMARY
==================================================================

Apply same allowlist rules.

Keep summaries minimal.

Avoid sensitive data.

==================================================================
RESULT ENUM
==================================================================

Implement

Committed

DurablyDeferred

FailedRequired

Applications must use these values.

Never infer success.

==================================================================
EXPORT
==================================================================

Implement ExportIntent only.

Do not generate files.

Do not create CSV.

Do not create Excel.

Do not create PDF.

Only register export request.

==================================================================
REPOSITORY
==================================================================

Repository responsibilities

Insert record

Query records

Find by ID

Find by obligation

Create export intent

Nothing else.

==================================================================
SERVICE
==================================================================

Implement

recordAudit()

queryAudit()

requestAuditExport()

These are the only public service methods.

==================================================================
recordAudit()
==================================================================

Validate request.

Validate tenant.

Validate actor.

Validate obligation.

Validate classification.

Validate summaries.

Check duplicate obligation.

If duplicate

Return existing ID.

Else

Insert immutable record.

Return

AuditRecordId

Never throw duplicate key errors to caller.

Handle gracefully.

==================================================================
queryAudit()
==================================================================

Support filters

tenant

branch

module

actor

action

dateFrom

dateTo

classification

result

targetId

requestId

correlationId

Support pagination.

Support sorting.

Default sort

Newest First.

==================================================================
requestAuditExport()
==================================================================

Validate authorization.

Validate query.

Generate ExportIntent.

Persist ExportIntent.

Return intent identifier.

Do not generate files.

==================================================================
DTO VALIDATION
==================================================================

Use class-validator.

Validate

UUID

Mongo IDs

Enums

Strings

Dates

Booleans

Arrays

Maximum lengths

Minimum lengths

Reject invalid payloads.

==================================================================
PAGINATION
==================================================================

Support

page

limit

total

totalPages

items

Maximum page size

100

Default

20

==================================================================
SORTING
==================================================================

Default

createdAt DESC

Support

timestamp

module

actor

==================================================================
FILTERS
==================================================================

Support filtering by

tenant

branch

module

action

actorId

actorName

classification

result

requestId

correlationId

targetType

targetId

date range

==================================================================
INDEXES
==================================================================

Create indexes

sourceObligation unique

tenantId

timestampUtc

module

action

actorId

classification

requestId

correlationId

targetId

Compound indexes where beneficial.

==================================================================
API ENDPOINTS
==================================================================

GET

/api/v1/audit

GET

/api/v1/audit/:auditId

POST

/api/v1/audit/exports

No write endpoint.

No update endpoint.

No delete endpoint.

==================================================================
AUTHORIZATION
==================================================================

Require authentication.

Require authorization.

Tenant users

Own tenant only.

Platform users

Platform scope only.

Reject unauthorized requests.

==================================================================
SWAGGER
==================================================================

Document every endpoint.

Document every DTO.

Document every response.

Document every enum.

==================================================================
RESPONSES
==================================================================

200

201

400

401

403

404

409

500

Use consistent response format.

==================================================================
ERROR HANDLING
==================================================================

Never leak stack traces.

Never leak Mongo errors.

Never expose internal exceptions.

Return friendly API errors.

==================================================================
LOGGING
==================================================================

Do not use audit collection as log storage.

Application logging remains separate.

Audit is evidence.

Logging is diagnostics.

==================================================================
DEPENDENCY INJECTION
==================================================================

Use Nest providers.

Inject repository.

Never instantiate manually.

==================================================================
TRANSACTIONS
==================================================================

Use Mongo transactions only where necessary.

Avoid unnecessary sessions.

==================================================================
SECURITY
==================================================================

Escape user input.

Validate filters.

Prevent injection.

Protect pagination.

Prevent regex abuse.

Prevent DOS via page size.

==================================================================
PERFORMANCE
==================================================================

Lean queries.

Projection.

Indexes.

Cursor pagination readiness.

Avoid N+1 queries.

==================================================================
TESTS
==================================================================

Create

Unit Tests

Repository Tests

Service Tests

Controller Tests

Integration Tests

Cover

Duplicate obligation

Tenant isolation

Unauthorized access

Pagination

Filtering

Append-only behavior

Classification validation

Summary allowlisting

==================================================================
ACCEPTANCE CRITERIA
==================================================================

✔ Immutable audit collection

✔ No update API

✔ No delete API

✔ Unique obligation enforcement

✔ Tenant isolation

✔ Platform isolation

✔ Append-only writes

✔ Read APIs

✔ Export intent API

✔ UTC timestamps

✔ Allowlisted summaries

✔ Explicit result enum

✔ Swagger documentation

✔ DTO validation

✔ Proper indexes

✔ Repository pattern

✔ Service layer

✔ Production-ready implementation

✔ No placeholders

✔ No TODOs

✔ No compilation errors

✔ No lint errors

✔ Existing project remains fully functional

==================================================================
IMPORTANT RESTRICTIONS
==================================================================

DO NOT implement SIEM integration.

DO NOT implement Elasticsearch.

DO NOT implement Splunk.

DO NOT implement Kafka.

DO NOT implement event sourcing.

DO NOT implement retention deletion.

DO NOT implement scheduled cleanup jobs.

DO NOT implement audit dashboards.

DO NOT implement analytics.

DO NOT implement report generation.

DO NOT implement CSV export.

DO NOT implement PDF export.

DO NOT implement Excel export.

DO NOT create a public audit write endpoint.

DO NOT modify unrelated modules.

DO NOT break existing APIs.

Maintain backward compatibility.

Build only the Audit Foundation required for ADR-015 Phase 01.
```

