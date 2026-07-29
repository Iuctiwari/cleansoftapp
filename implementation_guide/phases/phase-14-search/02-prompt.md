# Phase 14 Build Brief — Search Projection

## Schema

Implement `searchDocuments`: tenant/branch, domain/type, source ID/version, approved fields/tokens, authorization facets, updated time/checkpoint; tenant-first indexes and unique source.

## Routes/interfaces

- `GET /api/v1/search`
- `SVC-SEARCH-001`, `SVC-SEARCH-002`
- Consume Branch/User/Customer/Catalog/Order events; emit lag event.

## Rules

- Validate context before query and again when hydrating any source detail.
- Index only allowlisted minimally necessary fields.
- Event consumer is idempotent and version-aware; out-of-order older version cannot overwrite newer.
- Empty/not-found is indistinguishable for unauthorized records.
- Return freshness/checkpoint.
- Rebuild into isolated version then safely switch; recovery is audited.

## What not to build

No cross-service private reads for bulk indexing, no authoritative writes, no unrestricted full-text customer/audit content, no unmeasured global index design.

