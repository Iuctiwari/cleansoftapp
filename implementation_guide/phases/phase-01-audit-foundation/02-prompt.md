# Phase 01 — Audit Foundation

## Objective

Implement the immutable Audit Foundation (ADR-015) as production-ready infrastructure.

This module provides reusable, append-only audit evidence for all future ERP modules.

## Scope

Implement:

- Audit module
- auditRecords collection
- Immutable audit schema
- Repository, Service, Controller
- DTOs
- Interfaces
- Validators
- Swagger documentation
- Indexes
- Unit and integration tests

## Public Contracts

Implement only:

- recordAudit(obligation, context)
- queryAudit(authorization, filters, page)
- requestAuditExport(authorization, query, idempotency)

Public Routes:

- GET /api/v1/audit
- GET /api/v1/audit/:auditId
- POST /api/v1/audit/exports

No public write endpoint.

## Core Rules

- Append-only collection.
- Never allow Update/Delete/Replace/Upsert.
- Deduplicate using sourceObligation.
- Duplicate requests return existing AuditRecordId.
- Always generate UTC timestamps server-side.
- Platform/Tenant/Branch isolation.
- Store only allowlisted summaries.
- Never store secrets, passwords, tokens, hashes or sensitive data.
- Store retention metadata only.
- Do not implement retention execution.
- Export requests create ExportIntent only.
- Never generate CSV/PDF/Excel files.

## Query Features

Support:

- Pagination
- Sorting
- Filtering
- Authorization
- Tenant isolation
- Platform isolation

## Required Indexes

Create indexes for:

- sourceObligation (unique)
- tenantId
- timestampUtc
- module
- action
- actorId
- classification
- requestId
- correlationId
- targetId

## Acceptance Criteria

- Immutable audit records
- No update/delete APIs
- Unique obligation enforcement
- Tenant isolation
- Platform isolation
- Append-only writes
- Read APIs
- Export intent
- UTC timestamps
- Allowlisted summaries
- Explicit result enum
- DTO validation
- Swagger documentation
- Repository pattern
- Service layer
- Production-ready implementation

## Do Not Implement

- SIEM integrations
- Kafka
- Event sourcing
- Analytics
- Dashboards
- Report generation
- CSV/PDF/Excel exports
- Cleanup jobs
- Retention deletion
- Public audit write endpoint
- Business-domain logic