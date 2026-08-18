# Service Service

## Purpose

Tenant-scoped source of truth for item categories, services, category/service mappings,
effective-dated pricing, and authoritative Order quotes.

## Scope

- Item and service category management
- Service metadata and branch availability
- Item-category/service mappings
- Branch-specific and tenant-wide effective pricing
- Immutable quote identifiers and pricing snapshots
- System catalog templates and idempotent tenant catalog provisioning

## Inputs

Authenticated tenant/branch context from Auth Service and branch validation through Branch Service.

## Outputs

REST APIs under `/api/v1`, including the Order-compatible
`GET /services/:id/quote?itemCategoryId=...` contract.

## Dependencies

- Central `DatabaseModule` (`MONGODB_URI`)
- Auth Service (`AUTH_SERVICE_BASE_URL`)
- Branch Service (`BRANCH_SERVICE_BASE_URL`)
- Optional production index bootstrap (`CATALOG_CREATE_INDEXES=true`)
- Shared internal provisioning credential (`CATALOG_PROVISIONING_KEY`)

## Deliverables

Catalog schemas, DTO validation, tenant-scoped repositories, RBAC, Swagger, and tests.

## Acceptance Criteria

Catalog writes are Owner/Branch Manager only; Staff/Cashier can read and quote. Prices are
resolved server-side from non-overlapping effective records and never accepted from Order clients.

## Notes

An empty `branchIds` array and a `null` pricing/mapping `branchId` mean tenant-wide availability.

## Catalog template operations

System templates live in the `catalogTemplates` collection and do not contain a `tenantId`.
They are installed as an explicit, idempotent deployment step—not on application startup:

```text
npm run seed:templates
```

Tenant Service calls the protected `POST /api/v1/catalog/provision` integration using
`CATALOG_PROVISIONING_KEY`. The request is never exposed to Flutter. It creates or reuses
tenant-owned item categories, services, and tenant-wide mappings by stable code. Existing names,
custom records, lifecycle state, and prices are preserved. Bundled template version 2 contains an
active tenant-wide default price of at least ₹100 for every predefined item/service mapping. These
defaults are created through the existing Service Management pricing domain and are skipped whenever
the tenant already has pricing for that combination.

After templates have been seeded, existing tenants can be provisioned from their enabled
`tenantServices` by running this explicit Tenant Service operation:

```text
npm run provision:catalogs
```
