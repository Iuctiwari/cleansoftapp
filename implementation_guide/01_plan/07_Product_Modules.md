# Product Modules

## Tier A — Trust and platform foundations

### Platform gateway

Owns public ingress, API versioning, request controls, authentication integration, trusted context propagation, correlation, and consistent errors. It does not own domain business data.

### Authentication

Owns credential verification, access/refresh session lifecycle, lockout, password reset, and security-session evidence. It consumes active membership/tenant state and notification delivery contracts where recovery messaging is required.

### Tenant and subscription

Owns tenant lifecycle, plans, entitlements, business profile, branding, and tenant settings. It does not own branch operations or user credentials.

### Branch

Owns branch lifecycle, profile, operating context, hours, and branch configuration. It consumes tenant entitlement/policy contracts.

### Users and RBAC

Owns staff profiles, membership, invitations, roles, permissions, departments/designations, and branch assignments. It consumes authentication, tenant, and branch contracts.

## Tier B — Core operating domains

### Customers

Owns customer profiles, addresses, preferences, notes, classifications, and customer projections. It does not own orders or authoritative payments.

### Catalog

Owns services, item/service categories, pricing sources, duration, tax/discount inputs, and branch availability. It does not own historical order snapshots.

### Orders and delivery

Owns order lifecycle, items, snapshots, assignments, numbering, transition history, cancellation, pickup, and home delivery. Delivery remains part of the order domain because no separate delivery service exists.

### Payments and receipts

Owns payment transactions, settlement, refunds/reversals/corrections, and receipt evidence. Receipt ownership remains here because no separate receipt service exists.

### Expenses and cash registers

Owns expense records, categories, business-date registers, cash movement, expected/actual cash, variance, and reconciliation.

## Tier C — Derived and communication capabilities

### Notifications

Owns in-app notification state, templates, preferences, provider dispatch, retry, and history. Source business actions remain owned by their domains.

### Reports

Owns authorized report projections, traceable calculations, exports, freshness, and rebuild. It does not write source business records.

### Dashboard

Owns role-aware operational presentation projections and freshness. Dashboard truth reconciles to reports/sources.

### Search

Owns tenant/branch-safe searchable projections and rebuild. It is not authoritative storage.

### Audit

Owns append-only critical-action evidence and separately governed query/export. Domains remain responsible for reliably recording audit obligations.

### Scheduler and background jobs

Owns timed triggers, dispatch infrastructure, dead-letter/recovery visibility, and job execution controls. Each domain owns the business meaning and contract of its jobs.

### File storage

Owns private object-storage access patterns, validation/scanning boundary, signed access, cleanup, and retention integration. Domain services own file purpose and references.

## Tier D — Client

### Flutter mobile application

Owns Android/iOS presentation, navigation, secure local session storage, locale-aware formatting, accessibility, and explicit offline/retry states. It consumes only gateway/public contracts and never owns authoritative business rules.

## Interaction preview

1. Mobile calls the gateway.
2. Gateway/auth/user/tenant/branch contracts establish trusted context.
3. The owning domain validates and commits authoritative state.
4. The same consistency boundary records outbound event/audit obligations.
5. Event consumers update notification, report, dashboard, search, and audit projections idempotently.
6. Scheduler/jobs handle delayed work and reconciliation through domain-owned contracts.
7. Mobile reads authoritative or explicitly fresh derived results through the gateway.

This is an informal preview only. Layer 2 `CONTRACTS.md` will define `SVC-*` and `EVT-*` seams, and `DEPENDENCY-GRAPH.md` will derive build order from actual consumers.

## Ownership conflicts preserved for Layer 2 resolution

- Existing documents describe service-oriented ownership with optional consolidated deployment. Deployment shape must not erase logical ownership.
- Existing phase prompts 18–22 have filenames that conflict with their contents and cannot be treated as canonical module plans.
- Settings belong to tenant service, delivery to order service, and receipts to payment service under the accepted existing audit decisions.
- The removed Flutter web application is no longer a current module; stale references remain historical source discrepancies only.

