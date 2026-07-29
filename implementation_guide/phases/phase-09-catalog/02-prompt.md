# Phase 09 Build Brief — Catalog

## Schemas

Implement `serviceCategories`, `services`, `servicePricing`, and `itemCategories` from `DATA-MODEL.md`, including tenant code uniqueness, effective-price index/invariant, status, branch availability, audit/version.

## Routes/interfaces

Implement all `/services`, `/services/categories`, `/item-categories` routes and `SVC-CATALOG-001`–`003`.

## Rules

- Tenant scope immutable; code unique within tenant.
- Effective pricing cannot overlap for same service/branch/type.
- Quote uses effective UTC/business context and returns immutable source IDs/versions plus money/tax/discount inputs.
- Inactive/unavailable entries cannot enter new orders but remain referenced historically.
- Branch assignment validated against same tenant.
- Tax rounding and discount allocation remain blocked by `OQ-4`, `OQ-5`; store inputs, do not invent results.

## What not to build

No orders, inventory, loyalty, hard-coded industry catalog, direct branch persistence access, or client-authoritative prices.

