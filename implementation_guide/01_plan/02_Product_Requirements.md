# Product Requirements

## Product requirement rollup

### Platform access and security

The platform must provide separate platform and tenant authentication contexts. Tenant-user identity must resolve organization, active membership, tenant, allowed branches, role, permissions, session, and entitlements from trusted server-side state. Missing or uncertain context fails closed.

### Tenant and subscription

Eligible businesses must be onboarded into a usable workspace containing an active tenant only after the coordinated creation of the first branch, Owner membership, defaults, and valid subscription state. Tenant lifecycle, settings, entitlements, branding, limits, and policy changes must be governed and audited.

### Branch operations

A tenant may have one or multiple branches. Branch-owned work must remain branch-scoped, while tenant-wide concepts remain available according to role. Inactive branches remain historically queryable but cannot accept new operational work.

### Users and RBAC

Authorized users must manage invitations, staff profiles, default/custom roles, permissions, branch assignments, and lifecycle. Deny is the default. Privilege escalation, cross-branch grants, and removal of the final active Owner must be prevented.

### Customers

Staff must be able to find, register, classify, update, archive, and restore tenant customers while supporting fast walk-in workflows. Authorized users need customer history and outstanding balance without allowing client-supplied financial truth.

### Catalog

Tenants must manage service categories, item categories, services, price types, tax/discount inputs, durations, branch availability, and lifecycle. Orders must copy authoritative catalog values into immutable historical snapshots.

### Orders and delivery

Authorized staff must create orders with customer/item/service details, server-calculated totals, assignments, expected completion, notes, and snapshots. Orders must move only through allowed states with complete history. Cancellation requires a reason. Pickup and delivery share the governed order lifecycle and may require proof.

### Payments and receipts

The platform must support partial, full, split, advance, and approved overpayments; refunds and corrections; receipts; outstanding calculation; and idempotent processing. Successful financial records must not be silently overwritten.

### Expenses and cash registers

Branches must record categorized expenses and reconcile one cash register per business date using opening cash, cash receipts, cash expenses, refunds, additions, withdrawals, expected cash, actual cash, and explained variance.

### Notifications

Business events must produce durable in-app notifications. Entitled tenants may use approved WhatsApp templates. Provider failure must not reverse the originating business action. Preferences, templates, retry, history, and delivery state remain governed.

### Reports, dashboard, search, and export

Owners and managers need tenant/branch-safe reports, role-aware dashboards, operational search, CSV export, and visible projection freshness. Results must be traceable to source records and rebuildable from authoritative data/events.

### Settings and audit

Authorized Owners manage business settings and policies. Critical changes and business actions create append-only audit evidence with actor, scope, target, correlation, outcome, and approved summaries while excluding secrets and unnecessary personal data.

### Files, jobs, and integrations

Files remain private and tenant-scoped with validation, scanning, signed access, retention, and cleanup. Background work uses bounded retries, idempotency, dead-letter handling, and visible recovery. External providers are accessed through provider-independent contracts.

### Flutter mobile experience

The Flutter Android/iOS application provides role-specific operational workflows, secure session storage, responsive and accessible interaction, locale-aware presentation, explicit retry/offline states, and no embedded secrets. The backend remains authoritative.

## Explicit MVP cut

The MVP includes:

- Authentication, session lifecycle, password reset, and account lockout.
- Tenant onboarding, lifecycle, settings, subscription entitlements, and defaults.
- Branches, staff, roles, permissions, invitations, and branch assignment.
- Customers, walk-in handling, history, and outstanding balance.
- Services, item categories, pricing types, and tenant-specific catalog configuration.
- Orders, item tracking, pricing snapshots, assignments, lifecycle history, cancellation, pickup, delivery, and proof where required.
- Partial/full payments, refunds, adjustments, receipts, and outstanding calculation.
- Expenses, categories, branch cash opening/closing, and reconciliation.
- In-app and plan-gated WhatsApp notifications.
- Audit logs, settings, tenant/branch search, dashboards, core reports, CSV export, and scheduled reconciliation.
- Flutter Android/iOS operational client.

## Post-MVP

- PDF report exports.
- Additional notification channels beyond in-app and WhatsApp.
- Customer self-service portal.
- Advanced workflow configuration.
- Broader subscription billing automation.
- Public API access for eligible plans.
- Advanced analytics and operational forecasting.

## Future scope

- Inventory and consumables.
- Appointments and scheduling.
- Loyalty and promotions.
- Route planning.
- Payroll.
- Regional deployments.
- AI-assisted operations.
- Predictive analytics and smart recommendations.
- Voice-assisted operations.
- Customer-specific and employee-specific mobile applications.
- IoT and marketplace integrations.

## Explicitly out of scope for the current implementation guide

- Restoring the removed Flutter web client.
- Direct storage of card data.
- Client-authoritative tenant, branch, role, permission, total, balance, entitlement, or financial state.
- Direct cross-service writes or reads of private persistence.
- Destructive rewriting of finalized financial/audit history.
- Industry-specific forks of canonical domain concepts.
- Production topology claims for Terraform or Helm foundations that are not yet implemented.
- Post-MVP and future capabilities unless a later approved decision moves them into scope.

