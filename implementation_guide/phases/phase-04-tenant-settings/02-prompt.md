# Phase 04 Build Brief — Tenant, Subscription, and Settings

## Objective

Implement Tenant-owned lifecycle/settings under `ADR-010` and the bootstrap cycle resolution in `DEPENDENCY-GRAPH.md`.

## Schemas

`tenants` and `tenantSettings` exactly as defined in `DATA-MODEL.md`; immutable tenant ID; optimistic version; lifecycle status; entitlement/policy version.

## Routes

All `/tenants/*` and `/settings*` routes in `API-CONTRACTS.md`.

## Interfaces

`SVC-TENANT-001`–`SVC-TENANT-005`; publish the four Tenant/Settings events.

## Rules

- Create Pending onboarding aggregate and signed bootstrap context.
- Activate last, only after first Branch and Owner membership/credential results.
- Enforce limits server-side on every proposed delta.
- Suspension/deactivation invalidates access and blocks new work.
- Settings keys are allowlisted, typed, versioned, auditable.
- Client flags never grant capability.
- Default INR/Asia-Kolkata/English-India is `A-1`, not hard-coded universal truth.

## What not to build

No invented plan names/limits (`OQ-2`), financial policy (`OQ-4`–`OQ-10`), branch/user storage, automated billing, web client, or production provider setup.

