# Phase 07 Plan — File Storage

## Scope

Private tenant-scoped upload authorization, quarantine/scanning state, signed read, authorized deletion/retention, cleanup, metadata, and domain references.

## Contracts

- **Consumes:** platform/User/Tenant context, `SVC-AUDIT-001`, `SVC-JOB-001`.
- **Produces:** `SVC-FILE-001`, `SVC-FILE-002`, `EVT-FILE-STATUS-001`.

## Acceptance criteria

1. `FR-FILE-01`: purpose/type/extension/size/metadata/authorization/scan controls gate usable state.
2. `FR-FILE-02`: private time-limited authorized access; no permanent public URL.
3. `FR-FILE-03`: retention/deletion/legal hold preserves tenant scope and business/audit references.

## Out

Provider/scanner invention, domain attachment business rules, public bucket, database blobs, retention execution before decisions.

