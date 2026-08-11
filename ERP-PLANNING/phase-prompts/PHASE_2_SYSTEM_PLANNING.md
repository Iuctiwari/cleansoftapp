# PHASE 02 – SYSTEM PLANNING

# Nexoraa CleanSoft ERP – System Architecture and Design Plan

## Document Control

| Field | Value |
|---|---|
| Document type | Authoritative system-planning baseline |
| Product | Nexoraa CleanSoft ERP |
| Phase | 02 – System Planning |
| Version | 1.0 |
| Date | 27 July 2026 |
| Status | Ready for architecture review |
| Implementation state | Planning only; no product implementation is defined in this document |
| Primary inputs | Approved software vision, backend module specification, and current repository foundation |

## Purpose

This document defines how Nexoraa CleanSoft will operate as one secure, configurable, multi-tenant ERP platform for service businesses. It establishes the system boundaries, component ownership, technology direction, data and communication model, security controls, operational expectations, and delivery standards that all later implementation work must follow.

The document deliberately remains above source-code level. It does not contain controllers, services, routes, payloads, database schemas, DTOs, Flutter screens, widgets, business-logic implementations, queue implementations, or deployment scripts.

## Executive Summary

Nexoraa CleanSoft is a cloud-oriented ERP for businesses that receive a customer request or item, perform a service, collect payment, and return or deliver the completed work. It supports industries such as laundry, dry cleaning, tailoring, shoe cleaning, repair services, vehicle wash, salons, and other configurable service businesses.

The platform uses a multi-tenant SaaS model. Each business is a tenant, each tenant may operate one or more branches, and every user receives only the access required for their tenant, role, permissions, and assigned branches. Tenant and branch isolation are backend-enforced system invariants, not frontend filters.

The checked-in repository is a pnpm and TurboRepo monorepo containing NestJS service foundations, Flutter web and mobile applications, shared packages, MongoDB, Redis, BullMQ, Docker assets, and future infrastructure locations. The planned architecture preserves those boundaries while avoiding unnecessary distributed-system complexity. Services have explicit domain ownership, but deployment may be consolidated during early stages when operational simplicity is more valuable than independent scaling.

The Unified auth service is the only public backend entry point. Domain services own business capabilities and authoritative data. Cross-service effects use versioned contracts, reliable events, and idempotent background work. MongoDB is the primary system of record, Redis supports bounded caching and BullMQ workloads, S3-compatible object storage holds uploaded assets, and external customer messages are sent through an approved WhatsApp provider.

Flutter is used for both web and Android/iOS clients. The two clients share product behavior, terminology, accessibility standards, localization rules, and design tokens, while retaining platform-specific navigation, storage, connectivity, and release behavior.

## Core Architecture Decisions

| Decision | Selected direction | Reason |
|---|---|---|
| Product model | Multi-tenant, multi-branch SaaS | Supports many independent businesses on one governed platform |
| Repository | pnpm/TurboRepo monorepo | Matches the current foundation and centralizes contracts and quality gates |
| Backend | NestJS/TypeScript service-oriented architecture | Provides clear domain ownership while allowing incremental deployment |
| Public access | Unified auth service as the only public backend entry point | Centralizes transport security, context, throttling, and compatibility |
| Primary data store | MongoDB with Mongoose | Matches the approved specification and flexible service-business model |
| Initial data topology | Shared managed MongoDB deployment with service-owned logical data | Controls cost while preserving ownership boundaries |
| Cross-service data access | No direct access to another service’s private persistence | Prevents hidden coupling and unsafe writes |
| Background processing | Redis and BullMQ with consumer-owned queues | Matches the repository and supports retries, scheduling, and workload isolation |
| Reliable domain events | Transactional outbox, idempotent consumers, and consumer-specific delivery queues | Prevents lost or duplicated cross-module effects |
| Object storage | Private S3-compatible storage with time-limited access | Keeps files outside application databases and supports secure scaling |
| Web and mobile | Flutter web plus Flutter Android/iOS | Matches the repository and supports shared product behavior |
| Financial representation | Integer minor currency units with explicit currency code | Avoids binary floating-point errors |
| Historical pricing | Immutable price and tax snapshots on business transactions | Keeps historical orders and reports accurate after catalog changes |
| Tenant login resolution | Organization identifier plus user email/mobile for tenant users | Avoids ambiguity when the same identifier exists in multiple tenants |
| Delivery ownership | Order service owns delivery for the initial release | Keeps delivery and order lifecycle consistency inside one boundary |
| Tenant settings ownership | Tenant service owns business settings; audit service records changes | Separates configuration authority from immutable audit evidence |
| Search and reporting | Event-fed, tenant-scoped read models | Avoids uncontrolled reads across private service data |
| Time | UTC in system records; tenant timezone for business presentation and business-day rules | Provides consistency across branches and environments |

---

# 1. System Foundation

## 1.1 System Overview

Nexoraa CleanSoft manages the complete service-business lifecycle:

1. A business registers and becomes a tenant.
2. The tenant configures branches, staff access, services, item categories, pricing, tax, payment methods, and branding.
3. Staff identify or create a customer, including lightweight walk-in handling.
4. An order captures items, services, price snapshots, expected completion, and operational notes.
5. Assigned staff progress the order through an approved workflow.
6. One or more payments settle the order, with refunds or corrections recorded additively.
7. The completed order is collected or delivered with optional proof.
8. Expenses and branch cash registers reconcile daily cash movement.
9. Notifications keep staff and customers informed.
10. Dashboards, reports, search, and audit views provide operational control and traceability.

The platform is configurable across service industries. Industry terminology may change in the user experience, but canonical backend concepts remain stable so that one architecture can support every tenant.

## 1.2 System Vision

Nexoraa CleanSoft will become the operating system for small and medium service businesses. Its long-term value is a single source of truth for customers, operations, money, staff accountability, and business insight.

The architecture supports this vision by:

- Keeping each tenant’s data and configuration isolated.
- Allowing branch growth without redesigning the product.
- Preserving financial and historical accuracy.
- Enabling new service industries through configuration rather than code forks.
- Providing web and mobile access from the same governed platform.
- Supporting future public APIs, customer portals, subscriptions, analytics, and AI-assisted workflows without placing those features in the MVP.

## 1.3 System Objectives

### Business objectives

- Replace paper registers, spreadsheets, and disconnected tools with one ERP.
- Reduce order loss, missed updates, payment ambiguity, and manual reconciliation.
- Give Owners real-time tenant-wide visibility while preserving branch restrictions.
- Make routine cashier and staff workflows fast enough for daily point-of-service use.
- Improve customer communication through reliable status and payment notifications.
- Provide traceable reports based on authoritative business records.

### Technical objectives

- Prevent cross-tenant and unauthorized cross-branch access by construction.
- Maintain clear service and data ownership.
- Make all cross-module financial effects reconcilable and idempotent.
- Keep services observable, recoverable, and independently scalable where justified.
- Maintain backward-compatible contracts and controlled versioning.
- Support automated verification across backend, web, mobile, infrastructure, and planning artifacts.

## 1.4 Project Scope

### MVP scope

- Authentication, session lifecycle, password reset, and account lockout.
- Tenant onboarding, lifecycle, business settings, subscription entitlements, and default configuration.
- Branches, staff users, roles, permissions, invitations, and branch assignment.
- Customers, walk-in handling, history, and outstanding balance.
- Services, item categories, pricing types, and tenant-specific catalog configuration.
- Orders, item tracking, pricing snapshots, assignments, status history, and cancellation.
- Partial/full payments, refunds, adjustments, receipts, and outstanding calculation.
- Customer pickup, home delivery, and proof of delivery.
- Expenses, expense categories, cash-register opening/closing, and reconciliation.
- In-app and plan-gated WhatsApp notifications.
- Dashboards, core reports, CSV export, audit logs, settings, search, and scheduled reconciliation.
- Flutter web and Android/iOS operational clients.

### Post-MVP scope

- PDF report exports.
- Additional notification channels.
- Customer self-service portal.
- Advanced workflow configuration.
- Broader subscription billing automation.
- Public API access for eligible plans.
- Advanced analytics and operational forecasting.

### Future scope

- Inventory and consumables.
- Appointments and scheduling.
- Loyalty and promotions.
- Route planning.
- Payroll.
- Regional deployments.
- AI-assisted operations.

## 1.5 Functional Requirements

The system must:

- Resolve authenticated identity, tenant, allowed branches, role, and permissions from trusted server-side context.
- Allow eligible businesses to complete onboarding and create a usable initial configuration.
- Apply subscription limits and feature entitlements consistently.
- Support tenant-wide Owners and branch-restricted operational roles.
- Preserve a complete customer, order, payment, delivery, expense, and audit history.
- Calculate financial values centrally using decimal-safe rules.
- Prevent finalized business records from being silently rewritten or deleted.
- Support concurrent order and receipt numbering without duplicates.
- Provide status workflows with complete transition history.
- Allow multiple payments and additive corrections.
- Reconcile customer balances, order balances, payments, expenses, and branch cash.
- Deliver critical in-app notifications even when an external channel is unavailable.
- Provide tenant- and branch-aware search, dashboard, report, and export results.
- Record critical actions in an immutable audit trail.

## 1.6 Non-Functional Requirements

The system must be:

- Secure by default and deny access when context is missing or uncertain.
- Available for daily business operation with documented recovery procedures.
- Responsive for common point-of-service workflows.
- Scalable across tenants, branches, users, orders, and notification volumes.
- Maintainable through bounded modules, clear ownership, strict contracts, and automated quality gates.
- Observable through correlated logs, metrics, traces, health signals, and alerts.
- Accessible and responsive across web and mobile devices.
- Localizable across language, currency, timezone, date, number, and receipt formats.
- Recoverable through tested backups, restoration, retries, reconciliation, and rollback procedures.

## 1.7 Design Principles

- Tenant and branch isolation are invariants.
- The backend is authoritative for security and business rules.
- Every business capability has one primary owner.
- Services communicate through contracts, not private database access.
- Historical transactions use snapshots.
- Financial corrections are additive and auditable.
- External side effects are idempotent and retryable.
- Synchronous paths remain short; non-blocking work is asynchronous.
- Shared packages provide technical primitives, not hidden business modules.
- Configuration is validated and observable.
- Accessibility and localization are system requirements.
- Architecture evolves from measured needs, not assumed future scale.

## 1.8 System Boundaries

### Internal actors

- Super Admin
- Tenant Owner
- Branch Manager
- Staff
- Cashier
- Delivery-assigned staff
- Support and operations personnel with separately governed access

### External actors

- Customers receiving notifications or receipts
- WhatsApp provider
- Object-storage provider
- Future email, SMS, payment-gateway, or public API consumers

### Trust boundaries

- Flutter clients and all inbound requests are untrusted.
- The Unified auth service is the public trust boundary.
- Authenticated claims are trusted only after signature, session, tenant-status, and membership validation.
- Inter-service context is trusted only through approved authenticated internal transport.
- Provider callbacks are trusted only after signature and replay validation.
- Databases, queues, object storage, logs, and backups are private platform resources.

---

# 2. System Architecture

## 2.1 Overall ERP Architecture

The logical system has six layers:

1. **Experience layer:** Flutter web and Flutter mobile.
2. **Edge layer:** Unified auth service, transport security, routing, throttling, and request context.
3. **Identity and governance layer:** authentication, tenancy, users, roles, permissions, settings, and audit.
4. **Business domain layer:** customers, catalog, orders, delivery, payments, expenses, notifications, reports, and search.
5. **Asynchronous and integration layer:** outbox publishing, BullMQ workers, scheduler, exports, notifications, storage, and provider adapters.
6. **Data and operations layer:** MongoDB, Redis, object storage, observability, backups, CI/CD, and runtime infrastructure.

Flutter clients communicate only with the Unified auth service. The gateway communicates with the service that owns the requested capability. Domain services communicate synchronously only when the caller needs an immediate authoritative answer; otherwise they publish events or schedule background work.

## 2.2 High-Level System Design

### Synchronous path

Flutter client → Unified auth service → owning domain service → owning data store → Unified auth service → Flutter client.

This path is used for user-driven actions that need an immediate result, such as sign-in, viewing a record, creating an order, or recording a payment.

### Asynchronous path

Owning domain service → transactional outbox → event publisher → consumer-owned queues → downstream projections, notifications, audit, reconciliation, or exports.

The originating business action succeeds only after its own authoritative transaction is durable. Non-critical provider activity does not block the user action.

### File path

Client requests upload authorization → owning service verifies tenant, branch, role, file policy, and business context → client uploads to private object storage → asynchronous scanning and metadata confirmation → authorized time-limited retrieval.

### Reporting path

Domain events → report-owned tenant/branch read models → dashboard/report queries → asynchronous export for large results.

## 2.3 Monorepo Architecture

The monorepo is organized by deployability and ownership.

| Location | Responsibility |
|---|---|
| `apps/` | Deployable backend services and Flutter applications |
| `packages/` | Reusable technical capabilities and stable shared contracts |
| `ERP-PLANNING/` | Product, architecture, security, data, prompt, and governance documentation |
| `docs/` | Developer and operational guides |
| `docker/` | Local runtime assets |
| `infra/` | Environment and production infrastructure assets |
| `.github/` | Repository automation and CI/CD workflows |

### Dependency direction

- Applications may depend on shared packages.
- Shared packages may depend on lower-level shared packages.
- Shared packages may not depend on applications.
- A domain service may not import another domain service’s internal modules.
- Flutter applications may share design tokens and public contract models but not backend implementation details.
- `packages/database` owns connectivity and persistence conventions, not domain models.
- `packages/ui` owns cross-client design foundations, not feature screens.

### Deployment strategy

Every backend application remains an explicit deployable unit. During early development, selected services may be deployed together to reduce operational overhead, but service ownership and contracts remain intact. Independent deployment is introduced where scale, reliability, security, or team ownership justifies it.

## 2.4 Backend Architecture and Responsibilities

| Application | Primary responsibility | Authoritative ownership |
|---|---|---|
| `apps/backend/auth-service/` | Public ingress, transport policy, request correlation, authentication, authorization, access/refresh sessions, lockout, OTP, audit, and scheduling | Authentication, session, and platform infrastructure records |
| `apps/backend/tenant-service/` | Tenant onboarding, lifecycle, plans, entitlements, terminology, business settings | Tenants, subscriptions, settings |
| `apps/backend/branch-service/` | Branch identity, lifecycle, contact, operating context | Branches |
| `apps/backend/user-service/` | Staff, roles, permissions, invitations, branch assignment | Users and authorization assignments |
| `apps/backend/customer-service/` | Customer profiles, walk-in policy, customer summaries | Customers and customer projections |
| `apps/backend/service-service/` | Services, item categories, pricing types, branch availability | Tenant catalog |
| `apps/backend/order-service/` | Orders, items, pricing snapshots, status history, assignments, delivery | Order and delivery lifecycle |
| `apps/backend/payment-service/` | Payments, refunds, adjustments, receipts, settlement state | Payment and receipt records |
| `apps/backend/expense-service/` | Expenses, categories, cash registers, cash reconciliation | Expenses and registers |
| `apps/backend/notification-service/` | In-app notifications, templates, external dispatch, delivery state | Notification records and templates |
| `apps/backend/report-service/` | Dashboard projections, reports, exports | Reporting read models and export jobs |
| `apps/backend/audit-service/` | Immutable tenant and platform audit evidence | Audit records |
| `apps/backend/search-service/` | Tenant/branch-scoped search projections | Search indexes and search projections |
| `apps/backend/scheduler-service/` | Schedules, orchestration triggers, job visibility | Schedule definitions and orchestration state |

### Boundary decisions

- Delivery remains inside `order-service` for the initial release because completion directly changes the order lifecycle. It becomes a separate service only if routing, fleet management, or independent scaling creates a clear boundary.
- Tenant settings remain inside `tenant-service`; `audit-service` independently records every approved settings change.
- Receipts remain inside `payment-service` because they represent payment and settlement evidence.
- Dashboard and reporting remain together in `report-service`, but large exports run asynchronously.
- The scheduler triggers domain-owned tasks; it does not own reconciliation formulas or business decisions.

## 2.5 Frontend Architecture

The web and mobile applications use feature-oriented presentation modules aligned with backend capabilities. Both clients use:

- Centralized session, tenant, branch, permission, and feature-entitlement state.
- A single API-client boundary.
- Typed contract models.
- Centralized error interpretation.
- Explicit loading, empty, validation, forbidden, conflict, offline, retryable, and terminal states.
- Navigation filtered by authorized capabilities while retaining backend enforcement.
- Cache keys that always include tenant and branch context where applicable.
- Immediate cache clearing when tenant, branch, membership, or session changes.

The frontend does not calculate authoritative order totals, approve workflow transitions, grant permissions, or infer tenant access.

## 2.6 Flutter Web Architecture

Flutter web is the primary administrative and desktop operational experience.

It is optimized for:

- Tenant and branch administration.
- Staff and permission management.
- Fast point-of-service order entry.
- Payments and cash-register workflows.
- Multi-column operational lists.
- Dashboard, reports, exports, and audit review.
- Keyboard navigation and responsive desktop/tablet layouts.

Web sessions use secure browser-compatible refresh handling. Browser storage contains no raw credentials or long-lived secrets. Tenant and branch switching clears all scoped state before new data loads.

## 2.7 Flutter Mobile Architecture

Flutter mobile supports Android and iOS operational workflows.

It is optimized for:

- Order lookup and status updates.
- Assigned work.
- Customer lookup.
- Payment collection where permitted.
- Delivery assignment and proof capture.
- Notifications and urgent branch tasks.

Mobile-specific rules:

- Refresh credentials use platform secure storage.
- Only minimum operational data is cached locally.
- Offline operation is limited to explicitly designed read or draft workflows; financial submission and authorization require an authoritative server response.
- Retried mutations use idempotency protection.
- Uploads survive app pause/resume where platform capabilities allow.
- Camera, photo, notification, and storage permissions are requested only when needed.
- Logging and crash reports never contain tokens, payment references, OTPs, or unnecessary personal data.

## 2.8 Shared Packages

| Package | Planned responsibility |
|---|---|
| `packages/common/` | Cross-service technical primitives and shared base conventions |
| `packages/config/` | Typed configuration contracts and validation conventions |
| `packages/constants/` | Stable, cross-platform constants with explicit ownership |
| `packages/database/` | MongoDB connection, transaction, health, and persistence foundations |
| `packages/logger/` | Structured logging, redaction, and correlation conventions |
| `packages/shared/` | Narrow reusable capabilities not owned by a specific domain |
| `packages/types/` | Versioned public and inter-service contract types |
| `packages/ui/` | Design tokens, theme foundations, and shared accessibility guidance |
| `packages/utils/` | Pure general-purpose utilities with no domain ownership |

Business rules remain inside the owning service. Shared packages cannot become a shared monolith.

## 2.9 Infrastructure Overview

### Local development

- Docker-hosted MongoDB and Redis.
- Backend services run from the monorepo.
- Flutter web runs locally in a supported browser.
- Flutter mobile runs on an emulator or device.
- Synthetic local storage/provider adapters are permitted only when clearly marked and never reported as production integrations.

### Test and staging

- Isolated databases, queues, buckets, keys, and provider configurations.
- Production-like topology for integration, load, security, migration, and recovery testing.
- Sanitized synthetic data only.

### Production

- Containerized backend applications.
- Managed MongoDB replica set.
- Managed Redis with persistence and failover appropriate to workload.
- Private object storage with lifecycle policy.
- Flutter web assets delivered through secure static hosting/CDN.
- Mobile applications distributed through approved stores.
- Centralized logs, metrics, traces, alerting, backup, and secret management.

## 2.10 Component Relationships

### Allowed relationships

- Gateway calls owning services using authenticated internal transport.
- Services request authoritative decisions from the owning service when an immediate answer is required.
- Services publish versioned events after durable local changes.
- Search, reports, notifications, and audit consume approved events.
- Scheduler invokes approved job triggers with tenant-safe context.

### Prohibited relationships

- Direct client access to domain services.
- Direct service access to another service’s private collections.
- Client-supplied tenant or branch context treated as authoritative.
- Search or report indexes treated as the source of truth.
- Shared packages containing tenant-specific business workflows.
- Provider calls made inside a critical database transaction.

---

# 3. Technology Planning

## 3.1 Technology Stack

| Area | Technology direction |
|---|---|
| Monorepo | pnpm workspaces and TurboRepo |
| Backend runtime | Node.js 22+ |
| Backend framework | NestJS with TypeScript |
| Primary database | MongoDB |
| Object mapping | Mongoose |
| Cache and job coordination | Redis |
| Background jobs | BullMQ |
| Web client | Flutter web |
| Mobile clients | Flutter Android and iOS |
| Routing | `go_router` in Flutter |
| Object storage | AWS S3 or compatible private storage |
| Customer messaging | WhatsApp Cloud API or approved equivalent |
| Local infrastructure | Docker Compose |
| Production packaging | Containers |
| CI/CD | GitHub Actions or approved equivalent |
| Observability | OpenTelemetry-compatible traces plus centralized logs and metrics |

## 3.2 Technology Selection Rationale

### NestJS and TypeScript

NestJS provides clear module boundaries, dependency management, testing support, and transport flexibility. TypeScript allows shared contract governance across backend applications. The main risk is accidental over-abstraction; architecture reviews keep shared layers narrow.

### MongoDB and Mongoose

MongoDB supports varied tenant configuration and order item structures while preserving transactional support for bounded operations. Mongoose provides validation and document mapping. Production requires replica-set capability for transactions and high availability. Financial and audit invariants cannot rely on schema flexibility alone.

### Redis and BullMQ

Redis provides fast bounded caches and BullMQ coordination. BullMQ is appropriate for retries, scheduled work, exports, and notification dispatch. Domain event fan-out uses a reliable publisher and consumer-owned queues; Redis is not treated as the authoritative business store.

### Flutter

Flutter supports one governed UI technology across web, Android, and iOS. Product behavior, localization, accessibility, and design tokens can be shared. Platform-specific interaction and release behavior remain separate where needed.

### S3-compatible storage

Object storage scales independently from application databases and provides lifecycle, encryption, and controlled access. Application databases store only approved metadata and references.

## 3.3 Development Tools

The engineering workflow uses:

- Formatting and linting.
- Strict TypeScript and Dart analysis.
- Unit, contract, integration, end-to-end, widget, and performance tests.
- Dependency vulnerability and license checks.
- Secret scanning.
- Architecture-boundary checks.
- Documentation linting and link validation.
- Container and infrastructure validation.
- Build reproducibility and artifact provenance.

Quality gates cannot be disabled to obtain a passing pipeline.

## 3.4 Third-Party Services

| Service | Data shared | Failure policy |
|---|---|---|
| WhatsApp provider | Minimum customer contact and approved message variables | Queue retry; in-app notification remains available |
| Object storage | Tenant files and approved metadata | Retry uploads; business records remain usable without public file exposure |
| Observability provider | Redacted operational telemetry | Application remains functional if telemetry is temporarily unavailable |
| Future payment gateway | Payment intent and provider references only | Idempotent reconciliation; no unverified callback changes settlement |

Each integration requires timeout, rate-limit, signature, replay, privacy, data-retention, monitoring, and provider-replacement planning.

## 3.5 External Dependency Governance

Dependencies are classified as:

- **Critical:** runtime, database, authentication, queue, and framework dependencies.
- **Replaceable:** storage, messaging, telemetry, and provider adapters.
- **Optional:** plan-specific or non-critical features.
- **Development-only:** testing, formatting, documentation, and build tools.

Updates require compatibility review, automated validation, vulnerability review, changelog assessment, and rollback readiness. Unsupported dependencies are upgraded or retired before production.

## 3.6 Versioning Strategy

- Product releases use semantic versioning.
- Public contracts use explicit major versions.
- Internal contracts and events include contract versions.
- Additive compatible changes precede removals.
- Breaking changes require a migration window and consumer evidence.
- Stored documents carry sufficient version information for controlled evolution.
- Flutter releases remain compatible with the supported backend window.
- Shared package upgrades are coordinated through monorepo dependency checks.
- Architecture documents record version, status, owner, and review date.

---

# 4. Business Module Planning

## 4.1 Module Responsibilities and Dependencies

| Module | Core responsibility | Primary dependencies | Main consumers |
|---|---|---|---|
| Platform gateway | Secure public entry and context propagation | Auth, tenant, user | All clients and services |
| Authentication | Identity, session, lockout, password lifecycle | Tenant/user status, notification OTP | Gateway and all authenticated modules |
| Tenant and subscription | Tenant lifecycle, plans, entitlements, settings | Auth, notification, catalog defaults | Gateway and every tenant module |
| Branch | Branch lifecycle and operating context | Tenant entitlements | Users and every branch-owned module |
| Users and RBAC | Staff, invitations, roles, permissions, assignments | Auth, tenant, branch | Gateway and every protected module |
| Customers | Customer profile and balance projection | Orders and payments | Order entry, reports, notifications |
| Catalog | Services, item categories, price sources | Tenant and branch | Orders and Flutter pickers |
| Orders and delivery | Order lifecycle, items, assignments, delivery | Customer, catalog, payment state, users | Payments, notifications, reports, search |
| Payments and receipts | Settlement, refund, reversal, receipt evidence | Orders, users, settings | Customers, cash register, reports, audit |
| Expenses and cash registers | Expenses and daily branch cash reconciliation | Branch, payments, settings | Reports, audit, notifications |
| Notifications | In-app and external messaging | Tenant entitlements and provider | Staff and customers |
| Reports and dashboard | Tenant/branch analytics and export | Events from business domains | Owners and managers |
| Audit | Immutable critical-action evidence | Events from all modules | Owners, security, operations |
| Search | Tenant-scoped operational discovery | Events from searchable domains | Flutter clients via gateway |
| Scheduler | Timed triggers and recovery visibility | Domain-owned job contracts | All modules with scheduled work |

## 4.2 Module Communication

### Synchronous communication

Used for:

- Identity and authorization decisions required before processing.
- Immediate catalog, customer, order, payment, or settings queries.
- Business validations that require authoritative current state.

Synchronous dependencies have bounded timeouts, no indefinite retries, and safe failure behavior.

### Event communication

Used for:

- Customer aggregate updates.
- Order lifecycle notifications.
- Payment settlement projections.
- Cash-register inputs.
- Search and report projections.
- Audit evidence.
- Cache invalidation.

Events are facts about completed changes, not remote commands disguised as events.

### Background jobs

Used for:

- Provider dispatch.
- Report export.
- Reconciliation.
- Retention and archival.
- Subscription expiry checks.
- Reminder and overdue detection.
- File scanning and cleanup.

## 4.3 Integrated Business Workflows

### Tenant onboarding

The Owner verifies identity, selects a business type and plan, and supplies the first branch. Tenant, first branch, Owner membership, and default catalog are created as one coordinated onboarding process. A partial onboarding cannot appear Active. Entitlements become effective only after the subscription state is valid.

### Staff invitation

An authorized Owner or Branch Manager creates an invitation within tenant, branch, role, and plan limits. The invite expires after seven days. Acceptance creates or activates the intended membership, requires a permanent credential, and revokes the temporary credential.

### Customer and order

Staff search within the tenant before creating a customer. Walk-in orders may use a lightweight customer snapshot without creating a dangling customer record. Order creation captures authoritative catalog prices and customer contact snapshots. The client never supplies trusted totals.

### Order processing

Orders progress through the configured allowed workflow. Each transition records actor, time, previous state, new state, and notes. Assigned Staff can act only within assignment, role, tenant, and branch scope. Cancellation requires a reason and triggers downstream corrections.

### Payments

Payments are recorded independently and summed into order settlement. Partial and split payments are supported. Refunds and corrections create additive records referencing the original transaction; the original successful payment is not silently rewritten.

### Delivery

Customer pickup and home delivery are supported. Delivery completion records receiver and proof where required, then completes the order through the same governed lifecycle. Unpaid delivery is blocked unless the tenant policy explicitly permits it.

### Expenses and cash register

Each branch has at most one register for a business date. Opening cash, cash receipts, cash expenses, refunds, additions, withdrawals, expected cash, actual cash, and variance reconcile. A non-zero variance requires explanation and audit evidence.

### Notifications

Business events create in-app notifications. Eligible tenants also receive WhatsApp delivery through approved templates. Provider failure never rolls back the originating order, payment, or delivery action.

### Reporting and audit

Reports consume immutable transaction snapshots and event-fed projections. Every report figure can be traced to source records. Critical actions generate separate immutable audit evidence.

## 4.4 Future Module Expansion

New modules must:

- Have one bounded owner.
- Use existing tenant, branch, RBAC, audit, and observability foundations.
- Publish compatible events instead of reading private collections.
- Define subscription entitlement and configuration needs.
- Include web/mobile responsibility and accessibility.
- Include data retention, security, and migration planning.
- Avoid changing canonical core concepts solely for one industry.

---

# 5. Data and Communication Architecture

## 5.1 Data Ownership

Each service owns its authoritative logical data even when services share a MongoDB deployment. Ownership means:

- Only the owning service may perform writes.
- Other services use contracts or event-fed projections.
- Collection naming, credentials, and runtime permissions reflect ownership.
- Reporting and search copies are derived and rebuildable.
- Shared packages do not expose domain models across services.

## 5.2 Data Classification

| Classification | Examples | Handling |
|---|---|---|
| Public | Product and plan descriptions | Integrity controlled |
| Internal | Operational configuration and non-sensitive telemetry | Authenticated internal access |
| Confidential | Customer contact, orders, staff details, reports | Tenant/branch authorization and encryption |
| Restricted | Credentials, refresh tokens, OTPs, financial details, audit evidence | Strong encryption, minimal access, redaction, enhanced monitoring |

## 5.3 Financial Data Rules

- Currency values are stored in integer minor units with an ISO currency code.
- Percentage and quantity calculations use fixed precision and explicit rounding policy.
- Rounding occurs at defined calculation boundaries and is consistent across receipt and report views.
- Catalog prices are copied into orders as snapshots.
- Paid and outstanding amounts derive from authoritative payment records.
- Refunds and adjustments are additive.
- Finalized payments, receipts, registers, and audit records are immutable.
- Reconciliation jobs detect drift but do not silently hide it.

## 5.4 Data Flow

1. The client captures user input.
2. The gateway authenticates and attaches trusted context.
3. The owning service validates identity, role, tenant, branch, input, lifecycle, and concurrency.
4. The owning service persists the authoritative change.
5. The same consistency boundary records pending outbound events.
6. The response returns the authoritative result.
7. Background publishers deliver events.
8. Consumers update notifications, audit, search, reports, and reconciliation views idempotently.
9. Retention and archival policies move aged data without breaking authorized traceability.

## 5.5 User Flow

### Super Admin

Uses a platform-only context for tenant and plan administration. Super Admin does not receive an implicit tenant role or unrestricted access to tenant financial and audit data.

### Owner

Uses tenant-wide access, may switch branches for operational views, manages configuration and staff, and accesses tenant-wide reports and audit evidence.

### Branch Manager

Operates only assigned branches, manages allowed staff and workflows, and views branch reports.

### Staff

Views operationally required customer and assigned order information, updates assigned work, and cannot access financial administration.

### Cashier

Creates orders, records permitted payments, issues receipts, and manages the current branch cash register. Refunds and discrepancies follow approval policy.

## 5.6 Request Flow

1. Flutter generates a correlation identifier or accepts one from the gateway response cycle.
2. The gateway applies TLS, origin policy, size limits, throttling, authentication, and API-version checks.
3. Auth and membership state establish identity, tenant, allowed branches, role, permissions, and entitlements.
4. A requested active branch is verified against tenant and assignment.
5. The gateway forwards only signed or mutually authenticated internal context.
6. The domain service rechecks authorization and validates the business request.
7. The domain transaction commits with idempotency and concurrency protection where required.
8. Audit and event obligations are recorded.
9. A safe, correlated response is returned.

## 5.7 Response Flow

Responses follow consistent concepts:

- Successful data is separated from pagination or operation metadata.
- Validation failures identify affected fields without revealing internal structures.
- Authentication and authorization failures do not reveal whether another tenant’s record exists.
- Conflicts distinguish lifecycle, concurrency, duplicate, and business-policy conditions.
- Dependency failures indicate whether retry is safe.
- Every unexpected failure has a correlation identifier.
- User-facing localization occurs in Flutter using stable error meaning; provider-rendered templates are localized server-side where required.

## 5.8 Authentication Flow

### Tenant user login

Tenant users identify the organization plus email or mobile number, removing ambiguity when identifiers repeat across tenants. Credentials are verified against an active membership and active tenant.

### Platform login

Super Admin uses a separate platform context. Platform tokens do not carry tenant access.

### Session lifecycle

- Access sessions are short-lived.
- Refresh sessions are long-lived, rotated, individually revocable, and stored only as hashes server-side.
- Browser refresh credentials use secure HttpOnly cookie handling.
- Mobile refresh credentials use platform secure storage.
- Reuse of a rotated credential revokes the affected session family.
- Password reset revokes all sessions.
- Account deactivation, tenant suspension, or membership removal invalidates authorization promptly.
- Five consecutive failed logins trigger a fifteen-minute lockout unless an authorized administrator resets it.

## 5.9 API Architecture

The API is contract-first and versioned. This phase defines no concrete routes.

API standards:

- The gateway is the only public backend surface.
- Contracts identify the owning service.
- Authentication is required except for an explicitly approved public set.
- Tenant and branch identifiers supplied by clients are selectors, never proof of access.
- Create and financial actions support idempotency where duplication is harmful.
- Lists use bounded pagination with filter and sort allowlists.
- Bulk operations are explicit and separately authorized.
- Error meaning is stable and machine-readable.
- Deprecation includes notice, compatibility period, migration guidance, and usage evidence.
- Contract tests protect gateway, services, Flutter clients, and event consumers.

## 5.10 Event Architecture

Every event includes:

- Unique event identity.
- Event type and version.
- Owning producer.
- Occurrence time in UTC.
- Tenant context and branch context where applicable.
- Correlation and causation identity.
- Actor identity where safe and relevant.
- Minimal business data required by consumers.

Delivery rules:

- Events are recorded through an outbox in the same consistency boundary as the business change.
- Publishers may deliver more than once; consumers are idempotent.
- Each consumer owns its queue and retry policy.
- Poison messages move to a dead-letter state with alerting and controlled replay.
- Consumers tolerate compatible additive changes.
- Sensitive content is minimized.
- Ordering is assumed only within a documented aggregate boundary.

## 5.11 Database Planning

### Topology

Production uses a managed MongoDB replica set. Services initially share a deployment but receive separate logical ownership and least-privilege credentials. High-volume or regulated domains may move to separate databases without changing public contracts.

### Isolation

- Every tenant-owned record carries immutable tenant identity.
- Branch-owned records also carry branch identity.
- Common access patterns begin with tenant scope and include branch scope where applicable.
- Platform records are explicitly separate from tenant records.
- Aggregation, search, export, backup, and restoration preserve the same isolation.

### Consistency

- Local domain invariants use database transactions where multiple records must commit together.
- Cross-service workflows use eventual consistency, outbox events, idempotency, and reconciliation.
- Optimistic concurrency prevents silent overwrites.
- Atomic counters provide sequential business numbering within the defined tenant/branch scope.

### Lifecycle

- Operational deactivation uses lifecycle status rather than destructive deletion where references exist.
- Financial and audit records are append-only or correction-based.
- Retention policy distinguishes operational, financial, audit, notification, file, and telemetry data.
- Archival preserves authorized queryability and legal hold.
- Backup restoration is tenant-safe and audited.

## 5.12 Integration Planning

All provider adapters implement:

- Strict timeouts.
- Bounded retries with backoff and jitter.
- Idempotency.
- Rate-limit awareness.
- Circuit breaking or temporary suppression where appropriate.
- Authentication and signature verification.
- Replay prevention for callbacks.
- Redacted logs.
- Health metrics and alerts.
- Provider-independent internal contracts.

---

# 6. Security and System Governance

## 6.1 Multi-Tenant Architecture

Tenant context originates from the verified authenticated session and active membership. The platform never trusts a tenant header, path value, query value, or body field without matching it to that context.

Isolation applies to:

- Domain queries and writes.
- Unique constraints and counters.
- Cache keys.
- Queue names and job payloads.
- Event envelopes.
- Search indexes.
- Report projections and exports.
- Object-storage prefixes.
- Logs, metrics, and traces.
- Backups, restoration, and support tools.

Missing or invalid tenant context fails closed. Platform administration uses separate authorization and generates platform audit evidence.

## 6.2 Multi-Branch Architecture

Resources are classified as:

- **Tenant-wide:** tenant settings, roles, services available to all branches, shared customers, and tenant-wide reports.
- **Branch-scoped:** orders, payments, deliveries, expenses, cash registers, and branch operations.
- **Configurable scope:** services, staff assignments, notifications, and reports that may apply to selected branches.

Owner access is tenant-wide. Other users receive explicit branch assignments. Branch switching changes the active view but never expands allowed access. Inactive branches remain historically queryable by authorized users but cannot accept new operational work.

## 6.3 RBAC Planning

### Default roles

| Role | Scope | Primary permissions |
|---|---|---|
| Super Admin | Platform | Tenant lifecycle and platform operations only |
| Owner | Entire tenant | Full tenant administration and operations |
| Branch Manager | Assigned branches | Branch operations, permitted staff management, reports |
| Staff | Assigned branches and work | Assigned operational work |
| Cashier | Assigned branches | Order entry, payment collection, receipt, cash register |

### RBAC rules

- Permissions are named by module and action.
- Deny is the default.
- Role checks and permission checks are backend enforced.
- Custom roles are an entitlement-controlled capability.
- A Branch Manager cannot grant Owner-level or out-of-branch access.
- The final active Owner cannot be removed, deactivated, or demoted.
- Sensitive refunds, register reopening, large discounts, and administrative corrections support approval thresholds and separation of duties.
- Permission changes invalidate affected authorization caches and sessions within the defined propagation window.

## 6.4 Security Strategy

### Identity and session

- Passwords use an approved adaptive hash with a work factor reviewed over time.
- OTPs are hashed, single-use, short-lived, attempt-limited, and never logged.
- Refresh credentials are rotated and revocable.
- Privileged authentication receives stronger monitoring and future MFA support.

### Application security

- All input is validated at the trust boundary.
- Output excludes internal and unauthorized fields.
- Rate limits apply by IP, identity, tenant, and sensitive operation.
- CORS uses an explicit allowlist.
- CSRF protection matches the web credential model.
- Security headers are centrally governed.
- File uploads use type, extension, size, malware, metadata, and authorization checks.
- Server-side request forgery, injection, mass assignment, insecure direct-object references, and unsafe deserialization are included in threat testing.

### Data security

- TLS protects all network traffic.
- Managed data stores and object storage use encryption at rest.
- Secrets are held by a secret manager and never committed.
- Restricted data is minimized and redacted.
- Support access is time-bound, approved, and audited.

### Supply-chain security

- Lockfiles are authoritative.
- Dependencies and container images are scanned.
- Build artifacts have provenance.
- Critical vulnerabilities block release unless formally accepted with compensating controls and an expiry.

## 6.5 Audit Strategy

Audit evidence is append-only and owned by `audit-service`.

Audited actions include:

- Authentication security changes.
- Tenant lifecycle and subscription changes.
- Branch and user access changes.
- Role and permission changes.
- Order creation, edits, status transitions, cancellation, and correction.
- Payment, refund, reversal, and receipt actions.
- Expense and cash-register actions.
- Settings and tax changes.
- Manual overrides, export access, and support operations.

Each audit record identifies tenant, branch where relevant, actor, module, action, target, time, correlation, result, and approved old/new summaries. Secrets and unnecessary personal data are excluded. Audit write failure on a critical action blocks or safely defers the action according to the approved consistency policy; it is never silently ignored.

Tenant audit and platform audit remain separately authorized. Retention defaults to at least twelve months and is configurable upward according to legal and business requirements.

## 6.6 Logging Strategy

Logs are structured and centrally aggregated.

Required context:

- Timestamp in UTC.
- Severity.
- Environment and service.
- Operation.
- Correlation and trace identity.
- Tenant and branch identifiers where permitted.
- Actor identifier where permitted.
- Outcome, duration, dependency, and error category.

Never log:

- Passwords.
- OTPs.
- Access or refresh tokens.
- Cookie values.
- Full payment credentials.
- Private storage signatures.
- Unnecessary customer content.

Security events, authorization denials, provider failures, queue failures, and reconciliation drift have defined alerts. High-cardinality and personally identifiable labels are not used in metrics.

## 6.7 Configuration Management

Configuration is:

- Typed and validated at startup.
- Owned by a named application or platform function.
- Separated from secrets.
- Different for local, test, staging, and production.
- Audited when it changes business behavior.
- Versioned when it changes contracts or stored data.
- Rolled back through a documented safe value.

Dynamic configuration is limited to settings that can change safely at runtime. Security-critical or connection configuration normally requires controlled restart or redeployment.

## 6.8 Environment Strategy

| Environment | Purpose | Data policy |
|---|---|---|
| Local | Individual development | Synthetic local data |
| Test | Automated verification | Ephemeral synthetic data |
| Preview | Change review where used | Isolated synthetic data |
| Staging | Production-like validation | Sanitized or generated data |
| Production | Customer operation | Real tenant data with full controls |
| Disaster recovery | Recovery validation and failover | Encrypted replicated production data |

Production secrets and raw customer data are never copied to lower environments.

---

# 7. Infrastructure and Performance

## 7.1 File Storage Strategy

Private object storage holds:

- Tenant logos and branding.
- Order item images.
- Expense attachments.
- Receipts and exports.
- Proof-of-delivery images.

Storage keys are tenant-prefixed and branch-aware where required. Access uses short-lived signed operations after authorization. Upload limits are configurable by file purpose. Files are scanned, encrypted, lifecycle-managed, and deleted or archived according to the owning record’s retention policy. Public buckets are prohibited.

## 7.2 Background Job Planning

| Job class | Owner |
|---|---|
| Notification dispatch and retry | Notification service |
| Report and export generation | Report service |
| Customer/order/payment reconciliation | Owning domain service, triggered by scheduler |
| Cash-register reconciliation | Expense service |
| Subscription expiry and reminder | Tenant service |
| Invite and token expiry cleanup | User/Auth service |
| Overdue order and delivery detection | Order service |
| Audit and file archival | Audit/owning service |

Jobs carry tenant and branch context, correlation identity, idempotency key, version, attempts, and safe retry policy. Jobs never default to global scope.

## 7.3 Caching Strategy

Appropriate cache candidates:

- Active tenant status and entitlements.
- Membership and permission resolution.
- Branch metadata.
- Active catalog pickers.
- Bounded dashboard projections.

Prohibited or tightly limited cache candidates:

- Raw credentials and tokens.
- Final financial truth.
- Unbounded customer or audit data.
- Authorization decisions without revocation strategy.

All keys include environment, service, tenant, branch where applicable, entity, and version. Security-critical caches use short TTLs plus event-driven invalidation. Cache failure degrades to the authoritative source; it never grants access.

## 7.4 Performance Requirements

Initial production targets, validated through testing:

| Workload | Target |
|---|---|
| Common authenticated read/write | p95 at or below 300 ms excluding external providers |
| Search | p95 at or below 500 ms for typical tenant volumes |
| Dashboard first useful result | At or below 2 seconds |
| Paginated operational list | First page at or below 1 second |
| Critical event available to consumers | Within 5 seconds under normal load |
| Notification queued | Within 2 seconds of originating event |
| Standard CSV export | Async when result size or date range exceeds synchronous budget |
| Client crash-free sessions | At least 99.5% during stabilization, rising before general availability |

Default list pagination is 20 items, with an approved maximum of 100. Report date ranges are limited to 366 days per request. Large work is asynchronous.

## 7.5 Scalability Planning

The initial architecture scales horizontally at gateway, service, worker, and Flutter web-delivery layers.

Expected hotspots and controls:

- **Concurrent order numbering:** atomic tenant/branch counters.
- **Payment duplication:** idempotency and unique provider references.
- **Notification bursts:** separate queues, rate-aware workers, and backpressure.
- **Report load:** read models, rollups, async exports, and read scaling.
- **Search growth:** dedicated tenant-scoped indexes and rebuildable projections.
- **Large tenants:** compound tenant/branch access patterns and archival.
- **Noisy tenants:** per-tenant quotas and workload isolation.
- **Cache stampede:** bounded locking or stale-while-revalidate for safe reads.

Database or service separation occurs only after measured capacity, security, failure-domain, or team-ownership thresholds justify it.

## 7.6 High Availability and Recovery

Initial service targets:

- Monthly API availability target: 99.9%, excluding approved maintenance.
- Recovery point objective: 15 minutes for primary business data.
- Recovery time objective: 4 hours for a regional production incident.

Production uses:

- Multi-zone managed data services where available.
- Health and readiness probes.
- Rolling deployment.
- Automated restart and workload redistribution.
- Point-in-time database recovery.
- Versioned object storage where appropriate.
- Encrypted, monitored backups.
- Quarterly restoration exercises before general availability, then at least twice yearly.

Critical business actions degrade safely. Notification and export outages do not prevent orders or payments. Authentication, authorization, tenant status, and financial persistence fail closed when their authoritative dependencies are unavailable.

## 7.7 Monitoring and Observability

The platform monitors:

- API traffic, latency, error rate, and saturation.
- Authentication failures and lockouts.
- Authorization and isolation denials.
- MongoDB health, slow operations, replication, and capacity.
- Redis health, memory, eviction, and connectivity.
- Queue depth, age, retries, dead letters, and worker saturation.
- Provider delivery and failure rates.
- Outbox lag and consumer lag.
- Report and search freshness.
- Reconciliation drift.
- Flutter crashes, startup, and network failure.
- Backup success and restore verification.

Every production alert has severity, owner, response target, and runbook.

---

# 8. Development Standards

## 8.1 Development Workflow

1. Requirement and ownership review.
2. Architecture and contract review for cross-module changes.
3. Small, scoped implementation branch.
4. Automated formatting, linting, type, security, and test checks.
5. Peer review with tenant/branch/security checklist.
6. Staging verification and migration review.
7. Controlled release with rollback.
8. Documentation and completion evidence.

Unrelated changes are not mixed. Critical security, financial, and migration changes require additional review.

## 8.2 Coding Standards

Future implementation follows:

- Strict TypeScript and Dart analysis.
- Explicit domain ownership.
- Thin transport boundaries.
- Server-authoritative validation and financial calculations.
- Integer minor units and deterministic rounding.
- UTC storage and tenant-local display.
- Explicit tenant and branch scope.
- Idempotency for repeatable side effects.
- Optimistic concurrency for editable records.
- No ignored errors or hidden fallbacks.
- No direct cross-service persistence access.
- No secrets in code, client assets, logs, fixtures, or documentation.

## 8.3 Documentation Standards

Authoritative documents have:

- Purpose and scope.
- Owner and review date.
- Status: draft, approved, superseded, or retired.
- Decisions and alternatives.
- Diagrams with explanatory text.
- Links to related requirements, contracts, tests, and runbooks.
- Change history.

Duplicate documentation is avoided. A superseded document links to its replacement.

## 8.4 Error Handling Strategy

Errors are categorized as:

- Validation.
- Authentication.
- Authorization.
- Not found within authorized scope.
- Conflict or concurrency.
- Rate limit.
- Dependency unavailable.
- Timeout.
- Internal failure.

Every category has stable meaning for Flutter clients, safe user messaging, correlation, logging severity, retry guidance, and alerting expectations. Internal stack traces and cross-tenant existence are never exposed.

## 8.5 Testing Strategy

| Test level | Coverage |
|---|---|
| Unit | Calculations, validation, permissions, lifecycle, mapping, retry decisions |
| Contract | Gateway/service, service/service, events, jobs, Flutter/backend compatibility |
| Integration | MongoDB, Redis, queues, object storage adapters, transactions |
| End-to-end | Complete business journeys across web/mobile and backend |
| Isolation | Two tenants, multiple branches, roles, search, cache, files, exports, events, jobs |
| Security | Authentication, authorization, abuse, upload, injection, secrets, dependencies |
| Financial | Rounding, partial payment, refund, reconciliation, cash variance, concurrency |
| Resilience | Timeouts, retries, dead letters, provider outage, cache outage, database failover |
| Performance | Common API, order concurrency, reports, search, notification bursts |
| Flutter | Widget, accessibility, responsive, navigation, session, offline/retry |
| Recovery | Backup restore, projection rebuild, replay, rollback |

Tests use synthetic tenant-safe data and deterministic clocks where time affects behavior.

## 8.6 Quality Assurance Strategy

Release entry requires:

- Approved requirements and acceptance criteria.
- Resolved ownership and contract changes.
- Ready test environments and synthetic data.
- Migration and rollback plan where needed.

Release exit requires:

- Passing mandatory quality gates.
- No unresolved critical/high security defect.
- Verified tenant and branch isolation.
- Financial reconciliation evidence for affected modules.
- Accessibility evidence for affected UI.
- Observability and runbook readiness.
- Product and technical approval.

---

# 9. Deployment and Future Planning

## 9.1 Deployment Planning

Backend applications are built as immutable container artifacts. The same artifact is promoted between environments with environment-specific configuration supplied at runtime.

Deployment order:

1. Backward-compatible data preparation.
2. Shared platform changes.
3. Event consumers that tolerate old and new contracts.
4. Domain producers.
5. Gateway.
6. Flutter web.
7. Mobile release after backend compatibility is confirmed.

Rollback never assumes destructive data reversal. Database changes use expand-and-contract migration. Mobile compatibility accounts for delayed store adoption.

## 9.2 CI/CD Planning

The pipeline includes:

- Dependency restoration from lockfiles.
- Formatting and lint checks.
- Type and Dart analysis.
- Unit and contract tests.
- Integration and isolation tests.
- Security, dependency, secret, and image scanning.
- Backend and Flutter builds.
- Artifact signing/provenance.
- Staging deployment and smoke checks.
- Approval for production.
- Production health verification.
- Automated or operator-guided rollback.

No deployment script or pipeline implementation is included in this phase.

## 9.3 Production Readiness

Before launch:

- Threat model approved.
- Tenant and branch isolation independently tested.
- Backups and restoration proven.
- Capacity and performance targets met.
- Monitoring, alerts, and runbooks active.
- Provider limits and templates approved.
- Support access governed.
- Data retention and privacy terms approved.
- Mobile and web accessibility reviewed.
- Financial reconciliation controls approved.
- Incident, rollback, and communication plans rehearsed.
- Known limitations documented.

## 9.4 Future Scalability

Architecture evolution triggers include:

- Sustained database or queue saturation.
- A domain requiring independent availability or release cadence.
- Large-tenant workload affecting others.
- Regional data residency.
- Report/search workloads affecting transactional performance.
- Team ownership becoming a delivery bottleneck.

Possible evolution:

- Separate databases for high-risk domains.
- Dedicated event broker.
- Regional read models.
- Independent delivery service.
- Dedicated analytics platform.
- Tenant sharding.
- Edge caching for public/static assets.

## 9.5 Future Expansion Strategy

Future capabilities use extension contracts rather than modifying core records unpredictably. New industries customize labels, catalog, workflows, templates, and entitlements. New payment, notification, storage, and analytics providers use adapters. Public APIs use separate credentials, quotas, scopes, audit, and compatibility commitments.

## 9.6 Long-Term Architecture Vision

The target is a modular SaaS platform that can scale independently by domain while remaining understandable as one product. The architecture deliberately avoids premature service proliferation. Clear ownership, events, read models, and contract governance create the option to distribute further when evidence supports it.

---

# 10. Project Governance

## 10.1 Architecture Governance

Architecture decisions are recorded when they affect:

- Domain or data ownership.
- Service boundaries.
- Tenant or branch isolation.
- Contract compatibility.
- Security or privacy.
- Financial integrity.
- Runtime topology.
- Vendor commitment.
- Migration or rollback.

Each decision records context, options, selection, consequences, migration, rollback, owner, and review trigger.

## 10.2 Risk Register

| Risk | Probability | Impact | Primary mitigation |
|---|---|---|---|
| Cross-tenant data leakage | Low | Critical | Fail-closed context, scoped access, isolation tests, least privilege |
| Cross-branch privilege error | Medium | High | Explicit assignments, branch-aware checks, multi-branch tests |
| Ambiguous service ownership | Medium | High | Ownership matrix and architecture review |
| Distributed consistency drift | Medium | High | Outbox, idempotency, reconciliation, observable lag |
| Financial rounding error | Medium | Critical | Minor units, fixed precision, deterministic tests |
| Duplicate payment or order | Medium | High | Idempotency, atomic counters, unique business references |
| Provider outage | High | Medium | Queues, retry, in-app fallback, provider abstraction |
| Report load affects transactions | Medium | High | Read models, rollups, async exports |
| Cash-register discrepancy | Medium | High | Blind count, mandatory variance note, audit and reconciliation |
| Audit evidence gap | Low | Critical | Reliable audit events and failure policy |
| Malicious file upload | Medium | High | Private storage, validation, scanning, signed access |
| Configuration drift | Medium | High | Typed config, secret manager, controlled promotion |
| Mobile connectivity loss | High | Medium | Limited caching, retries, explicit offline states |
| Premature microservices complexity | Medium | High | Consolidated deployment with preserved boundaries |

## 10.3 Assumptions

- The primary initial market uses INR and Asia/Kolkata, but each tenant retains configurable currency and timezone.
- English (India) is the initial product locale.
- Hindi and Marathi are the first planned additional locales.
- MongoDB and Redis managed services are available in production.
- WhatsApp provider onboarding and template approval are external prerequisites.
- Internet connectivity is normally available for authoritative financial operations.
- Subscription billing is manually recorded for MVP.
- No card data is stored directly by Nexoraa CleanSoft.
- Regulatory retention requirements will be confirmed before production.

## 10.4 Constraints

- The current monorepo, service folders, NestJS, MongoDB, Redis/BullMQ, and Flutter foundations remain the baseline.
- This phase contains planning information only.
- Tenant isolation is mandatory for every capability.
- Branch isolation is mandatory for branch-owned data.
- The MVP must remain supportable by a small engineering and operations team.
- External provider availability cannot be guaranteed.
- Mobile releases cannot be forced instantly after store publication.

## 10.5 Configuration and Environment Variables

### Server configuration catalogue

| Category | Planned names |
|---|---|
| Runtime | `APP_NAME`, `APP_ENV`, `SERVICE_NAME`, `HOST`, `PORT`, `LOG_LEVEL` |
| MongoDB | `MONGODB_URI`, `MONGODB_DATABASE`, connection-pool and timeout settings |
| Redis/BullMQ | `REDIS_URL`, queue prefix, worker concurrency, retry policy |
| Authentication | access-token lifetime, refresh-token lifetime, signing-key reference, cookie policy |
| Gateway | API prefix/version, CORS allowlist, request-size limits, rate limits |
| Object storage | endpoint, region, private bucket, key reference, signed-operation lifetime |
| WhatsApp | provider endpoint, account reference, secret reference, template namespace |
| Observability | service identity, trace endpoint, metrics endpoint, sampling policy |
| Files | purpose-specific size and content-type limits, scanning policy |

### Flutter public configuration

- Application environment.
- Public Unified auth service base URL.
- Public observability identifier where approved.
- Feature-discovery bootstrap location.

Secrets never enter Flutter assets. Environment examples contain names and safe placeholders only.

## 10.6 Feature Flags and Entitlements

### Subscription entitlements

- Branch limit.
- Staff limit.
- Monthly order limit.
- WhatsApp enabled.
- Custom branding enabled.
- Custom roles enabled.
- API access enabled.
- Advanced reports enabled.

### Tenant policies

- Allow overpayment.
- Allow delivery with outstanding balance.
- Enabled payment methods.
- Tax enabled and default tax policy.
- Receipt and numbering preferences.

### Release and operational flags

- Controlled rollout of incomplete or high-risk capabilities.
- Provider kill switch.
- Export suppression during incident.
- Background job pause.

Client flags affect presentation only. The backend independently enforces every entitlement and policy. Flag changes are audited, cached briefly, and invalidated promptly.

## 10.7 Localization

### Initial locale

- English (India).
- Default currency: INR.
- Default timezone: Asia/Kolkata.
- Default date display: day-month-year.

### Planned locales

- Hindi.
- Marathi.
- Additional locales based on tenant demand.

Rules:

- System time is stored in UTC.
- Business dates are calculated using the branch/tenant timezone.
- Currency, dates, numbers, pluralization, and text direction use locale-aware formatting.
- Backend errors expose stable meaning; Flutter owns human-language translation.
- WhatsApp and receipt templates have explicit locale versions.
- Tenant terminology changes display labels, not canonical system concepts.

## 10.8 Theme Requirements

The clients use a shared accessible Material 3 design foundation.

Theme includes:

- Light and dark modes.
- Shared color, typography, spacing, radius, elevation, and motion tokens.
- WCAG AA contrast for essential text and controls.
- Consistent semantic colors for success, warning, error, payment, and order status.
- Responsive breakpoints for mobile, tablet, and desktop.
- Tenant logo and controlled brand accent.
- Safe default when tenant branding is missing or invalid.
- Receipt and export branding derived from approved tenant settings.

Tenant branding cannot change security indicators, semantic error colors, or accessibility requirements.

## 10.9 Implementation Prompt Library Plan

Later implementation prompts are organized by:

1. Platform foundation and shared standards.
2. Unified auth service.
3. Authentication.
4. Tenant and subscription.
5. Branches.
6. Users and RBAC.
7. Customers.
8. Services and item categories.
9. Orders and assignments.
10. Delivery.
11. Payments and receipts.
12. Expenses and cash registers.
13. Notifications.
14. Dashboard and reports.
15. Audit and settings.
16. Search.
17. Scheduler and reconciliation.
18. Flutter web.
19. Flutter mobile.
20. Shared packages.
21. File storage and integrations.
22. Observability and operations.
23. Security and isolation verification.
24. Testing and quality assurance.
25. Deployment and release.

Every future prompt is enterprise-grade, production-ready, architecture-driven, module-specific, self-contained, fully executable, scalable, maintainable, and secure.

Every future prompt covers:

- Business objective.
- Scope and out of scope.
- Functional and non-functional requirements.
- Architecture and repository locations.
- Folder structure.
- Backend, frontend, and Flutter responsibilities.
- Data, request, response, and event flows.
- Database and API documentation.
- Validation, RBAC, tenant isolation, and branch isolation.
- Security, logging, audit, performance, and scalability.
- Configuration, environment variables, and feature flags.
- Localization and theme.
- Testing, deliverables, and acceptance criteria.

The prompt library must apply this system plan; it must not redefine system ownership or architecture independently.

## 10.10 Deliverables

Phase 02 establishes:

- The system foundation and scope.
- Architecture and component ownership.
- Technology and dependency direction.
- Module responsibilities and communication.
- Data, request, response, authentication, API, event, database, and integration concepts.
- Multi-tenant, multi-branch, RBAC, security, logging, and audit strategy.
- Storage, jobs, caching, performance, scalability, availability, and observability plans.
- Development, testing, quality, deployment, and future-evolution standards.
- Configuration, environment, feature-flag, localization, and theme requirements.
- Risk, assumption, constraint, and governance baseline.
- Implementation-prompt catalogue and required content standard.

## 10.11 Acceptance Criteria

- [ ] Every approved business module has one primary owner.
- [ ] Every repository application and shared package has a defined responsibility.
- [ ] The public, internal, data, storage, queue, and provider trust boundaries are clear.
- [ ] Tenant isolation covers APIs, persistence, cache, events, jobs, search, reports, files, logs, backups, and support tools.
- [ ] Branch isolation and tenant-wide exceptions are explicit.
- [ ] RBAC covers platform, tenant, branch, default roles, custom permissions, and sensitive approvals.
- [ ] Order, payment, refund, delivery, expense, cash-register, reporting, and audit integrity are planned.
- [ ] Data ownership and cross-service communication prohibit private persistence access.
- [ ] API and database planning remains conceptual and contains no routes, payloads, schemas, or implementation logic.
- [ ] Flutter web and mobile responsibilities, security, connectivity, accessibility, localization, and theme are defined.
- [ ] Configuration, environments, secrets, feature flags, and entitlements are governed.
- [ ] Performance, availability, recovery, monitoring, and scalability targets are measurable.
- [ ] Testing covers contracts, security, tenant/branch isolation, finance, resilience, accessibility, performance, and recovery.
- [ ] Risks, assumptions, constraints, and architecture decisions are visible.
- [ ] The future implementation-prompt library has a complete module catalogue and mandatory content standard.
- [ ] No product source code, API implementation, database schema, UI component, Flutter screen, queue implementation, event implementation, or deployment script is included.

## 10.12 Expected Outcome and Conclusion

Nexoraa CleanSoft now has a coherent system-planning baseline for implementation. The platform is planned as a secure multi-tenant ERP with explicit branch control, domain ownership, reliable business workflows, auditable financial behavior, event-fed supporting services, Flutter web/mobile clients, and production-oriented operational governance.

The architecture preserves the current monorepo and technology foundation while keeping deployment complexity proportional to real needs. It resolves key ownership questions for delivery, settings, receipts, reporting, search, and scheduling. Later phases must implement this plan without weakening its isolation, data integrity, security, or contract boundaries.

Phase 02 provides architecture and implementation guidance only. No application logic, API, database schema, UI, Flutter screen, infrastructure code, or deployment automation is implemented in this document.
