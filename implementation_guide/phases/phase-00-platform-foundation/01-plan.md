# Phase 00 Plan — Platform Foundation

## Scope

Establish shared, implementation-ready primitives for versioned gateway transport, typed public/internal errors, trusted context, correlation, idempotency, optimistic concurrency, contract versioning, health, and tenant-safe repository interfaces.

### In

- `SVC-PLATFORM-001`, `SVC-PLATFORM-002`.
- Standard event envelope used by every `EVT-*`.
- `/api/v1` envelope/header/error conventions and health endpoints.
- Shared money/time/pagination/version/idempotency types.
- Contract-test harness interfaces and strict quality gates.

### Out

- Domain business endpoints, credentials, tenant onboarding, provider integrations, production infrastructure.
- Any unscoped repository helper or client-authoritative access rule.

## Contracts

- **Produces:** `SVC-PLATFORM-001`, `SVC-PLATFORM-002`, event envelope, public response/error conventions.
- **Consumes:** None.

## Acceptance criteria

1. `FR-PLATFORM-01`: versioned gateway boundary and public health behavior are defined and tested.
2. `FR-PLATFORM-02`: trusted context type cannot be constructed from arbitrary client selectors.
3. `FR-PLATFORM-03`: domain adapter interface requires scope revalidation.
4. `FR-PLATFORM-04`: idempotency contract distinguishes replay from key/payload conflict.
5. `FR-PLATFORM-05`: correlation/causation flows through request, event, and job primitives.
6. `FR-PLATFORM-06`: support context is a distinct type, not a Super Admin shortcut.

