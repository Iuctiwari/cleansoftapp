# Phase 17 Build Brief — Flutter Mobile

## Objective

Implement the current `apps/mobile-app` client scope under `ADR-008`.

## Architecture/interfaces

- One typed API client for `/api/v1`; stable error mapper; correlation capture.
- Auth/session repository with platform secure storage.
- Feature modules align with Product Modules and do not duplicate backend business rules.
- State-management and contract-generation choices require `OQ-24`; record ADR before implementation.

## Required screens/flows

Login/recovery/session; tenant/branch context; role home/dashboard; customer search/create/profile; catalog picker; order create/detail/assignment/status/delivery; payment/receipt/refund where permitted; expenses/register; notifications; search; reports/export status; settings/audit for authorized roles.

## Rules

- Backend results authoritative for permissions, actions, totals, balances, lifecycle, entitlements.
- Hide unauthorized UI but never treat hiding as authorization.
- Refresh rotation/revocation and secure erase on logout.
- Explicit loading/empty/error/stale/offline/retry states.
- Safe bounded read cache; no silent offline financial commits.
- UTC/API values rendered with effective tenant/branch locale.
- Accessibility semantics, text scaling, touch targets, focus, contrast, screen-size tests.
- No `.env` secrets in compiled assets; public config only.

## What not to build

No web client, new backend route, hard-coded role bypass, unapproved offline sync, loyalty/customer portal/future channels, or business calculation copied from server.

