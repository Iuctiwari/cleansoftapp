```markdown
# PHASE 04 — Tenant Onboarding & Subscription Implementation Prompt

## Phase Info
Module: Tenant Onboarding & Subscription (`src/tenants/`) · Depends on: Branch Management, User Management, Catalog (Services & Item Categories), Notifications (used for OTP/welcome delivery, not implemented here) · Status: Implementation prompt.

## Role & Boundaries
Implement Tenant Onboarding & Subscription only, using only the requirements below. This module owns tenant identity, lifecycle status, OTP-based registration verification, and subscription/plan assignment. It orchestrates atomic creation of the first Branch and Owner User at registration but does not implement Branch or User Management logic itself. Do not implement unrelated modules. Stop after completion.

## Purpose
Tenant Onboarding is the platform entry point: every other module's data exists because a tenant was created here. It establishes tenant identity, business type, lifecycle status, and the subscription plan whose feature flags (`branchLimit`, `staffLimit`, `whatsappEnabled`, `customBrandingEnabled`, `apiAccessEnabled`) are read and enforced by other modules at their own service layer — this module stores and exposes those flags but does not itself enforce them inside other modules. OTP generation and delivery for self-service registration is owned by this module, not by Authentication.

---

## Scope Definition

### In Scope
OTP request/generation for registration, self-service registration (OTP-verified), atomic tenant+first-branch+Owner creation, business-type-driven catalog seeding trigger, tenant settings read/update, tenant lifecycle status management (Super Admin), subscription plan listing, plan assignment/change with downgrade guard, platform-wide owner identity uniqueness.

### Schema-Only / Background (no dedicated user-facing API)
Subscription expiry/grace-period transitions — handled entirely by background cron, not a callable endpoint.

### Deferred (not built this phase)
Payment gateway integration (billing recorded manually by Super Admin for MVP), tenant self-service plan cancellation flow, multi-currency billing, invoicing.

### Resolved Ambiguities (from prior analysis)
- **`ownerEmail`/`ownerPhone` uniqueness is platform-wide**, not tenant-scoped — the one deliberate exception to this system's usual `{tenantId, field}` isolation pattern, because these identify the *person* registering, not tenant data. Enforced via a global unique index, and checked **before OTP is even issued**.
- **Registration is a single distributed transaction** spanning this module + Branch/User Management (first branch + Owner user) + Catalog (`SVC-CATALOG-003` seed call). All writes succeed together or roll back together — no partial tenant. OTP verification happens strictly before this transaction begins.
- **Downgrade guard requires a live read** from Branch Management (branch count) and User Management (staff count) at `/subscribe` time before allowing a plan change — this module has an explicit read-dependency on those two modules for this one check.
- **Overdue/grace-period handling introduces a 5th tenant status: `Restricted`** (read-only, distinct from `Suspended`) — closes the gap where the original spec described "restricted read-only" behavior with no matching status value.
- **Feature-flag enforcement is fully decentralized.** This module never itself blocks an action based on a flag — it only stores/serves the flags. Enforcement lives in the consuming module.
- **OTP ownership:** this module owns OTP generation, delivery triggering (via Notifications), expiry, resend cooldown, and rate limiting for the registration flow specifically — separate from any OTP mechanism Authentication may use for login/password reset.

---

## Tenant Lifecycle
```
PendingVerification → Active → Restricted → Suspended → Cancelled
```
- `PendingVerification → Active`: automatic on successful OTP verification during registration.
- `Active → Restricted`: automatic, via background job, when subscription is overdue beyond grace period. Restricted tenants can log in and view data but cannot create/update records in billed modules (enforced downstream by feature-flag checks, not here).
- `Restricted → Active`: automatic on payment recorded, or manual by Super Admin.
- `Active/Restricted → Suspended`: Super Admin only.
- `Suspended → Active`: Super Admin only (reactivation).
- `Any → Cancelled`: Super Admin only; terminal unless Super Admin explicitly reactivates.
- `Suspended`/`Cancelled` block login for **all** tenant users — enforced in the Authentication module by reading this module's `tenants.status`, not enforced here.

---

## Collections

**`tenants`**
`_id, businessName*, businessType* (enum: Laundry/DryCleaning/Tailoring/ShoeCleaning/ApplianceRepair/MobileRepair/VehicleWash/Salon/General/Custom), ownerName*, ownerEmail* (unique platform-wide), ownerPhone* (unique platform-wide), currency (default INR), timezone (default Asia/Kolkata), dateFormat (default DD-MM-YYYY), invoicePrefix (default INV), orderPrefix (default ORD), taxEnabled (default true), defaultTaxPct (default 0), subscriptionPlanId* (ref subscriptionPlans), status* (enum: PendingVerification/Active/Restricted/Suspended/Cancelled, default PendingVerification), createdAt, updatedAt, version.`
Indexes: `{ownerEmail}` unique, `{ownerPhone}` unique, `{status}`.

**`registrationOtps`**
`_id, ownerEmail, ownerPhone, otpHash* (hashed, never stored plaintext), purpose (fixed: TenantRegistration), expiresAt* (createdAt + configured timeout), attempts (default 0), resendCount (default 0), lastSentAt*, used (default false), createdAt.`
Indexes: `{ownerEmail}`, `{ownerPhone}`, `{expiresAt}` TTL index.

**`subscriptionPlans`**
`_id, planName* (enum: Starter/Business/Enterprise), price* (monthly), branchLimit*, staffLimit*, monthlyOrderLimit (nullable = unlimited), features* (object: { whatsappEnabled: boolean, customBrandingEnabled: boolean, apiAccessEnabled: boolean }), status (Active/Retired, default Active).`
Index: `{planName}` unique.
Feature flags are stored as a strongly typed object, never as a string array.

**`tenantSubscriptions`**
`_id, tenantId* (ref tenants), planId* (ref subscriptionPlans), startDate*, expiryDate*, paymentStatus (Paid/Pending/Overdue, default Pending), status (Active/Expired/Cancelled, default Active).`
Indexes: `{tenantId, status}`, `{expiryDate}`.

---

## Registration Flow
1. Client calls `POST /tenants/request-otp`.
2. System validates that `ownerEmail` and `ownerPhone` are not already registered platform-wide.
3. OTP is generated and hashed for storage.
4. OTP is delivered via the Notification module (email/SMS/WhatsApp per contact method).
5. Client submits `POST /tenants/register` with the OTP plus registration payload.
6. OTP is verified against `registrationOtps` (not expired, not already used, attempt count within limit).
7. Registration transaction begins.
8. Tenant, first Branch, Owner User, and default Catalog are created atomically.
9. Transaction commits; OTP record marked used.
10. Registration completes successfully; tenant status becomes `Active`.

If OTP validation fails at step 6, registration must not begin — no partial writes, no transaction opened.

---

## APIs (exactly 8 — no others)

| Method | Path | Purpose | Role Gate |
|---|---|---|---|
| POST | `/tenants/request-otp` | Generate and send an OTP to the owner's email or phone for tenant registration. Reject duplicate platform-wide `ownerEmail`/`ownerPhone` before issuing an OTP. Apply OTP expiration, resend cooldown, and rate limiting. | Public |
| POST | `/tenants/register` | Verify OTP; atomically create tenant + first branch + Owner user; trigger catalog seed | Public |
| GET | `/tenants/:id` | Retrieve tenant profile and settings | Owner (own tenant), Super Admin (any) |
| PATCH | `/tenants/:id/settings` | Update business settings (currency, tax defaults, prefixes, branding) | Owner (own tenant) |
| GET | `/tenants` | List all tenants with onboarding/subscription status | Super Admin |
| PATCH | `/tenants/:id/status` | Activate, suspend, restrict, or reactivate a tenant | Super Admin |
| GET | `/subscription-plans` | List available subscription plans | Public / Authenticated |
| POST | `/tenants/:id/subscribe` | Assign or change a tenant's subscription plan (with downgrade guard) | Owner (own tenant), Super Admin |

### `POST /tenants/request-otp` — Example

Request:
```json
{
  "ownerEmail": "rahul@example.com",
  "ownerPhone": "9876543210"
}
```

Response:
```json
{
  "otpSentTo": { "email": "rahul@example.com", "phone": "9876543210" },
  "expiresAt": "2026-07-30T10:15:00.000Z",
  "resendAvailableAfter": "2026-07-30T10:01:00.000Z"
}
```

### `POST /tenants/register` — Example

Request:
```json
{
  "ownerName": "Rahul Patil",
  "ownerEmail": "rahul@example.com",
  "ownerPhone": "9876543210",
  "otp": "482913",
  "businessName": "Sparkle Laundry",
  "businessType": "Laundry",
  "firstBranch": { "name": "Main Branch", "address": "MG Road, Pune", "phone": "9876543211" }
}
```

Response:
```json
{
  "tenantId": "665f1a0c9a1e4c0012ab3401",
  "branchId": "665f1a0c9a1e4c0012ab3402",
  "ownerId": "665f1b2c9a1e4c0012ab34cd",
  "status": "Active",
  "defaultServicesSeeded": 6,
  "defaultItemCategoriesSeeded": 9
}
```

---

## Validation Rules
- `ownerEmail` and `ownerPhone` must be unique **across the entire platform** — checked before any OTP is generated, and re-checked before the registration transaction begins.
- OTP must be generated through `POST /tenants/request-otp`; registration cannot supply a self-issued or externally sourced code.
- OTP expires after the configured timeout; expired OTP → 400 on verification.
- Resend requests must respect cooldown and rate-limiting policies; excessive requests → 429.
- Duplicate platform-wide `ownerEmail` or `ownerPhone` must be rejected **before** generating an OTP, not just at registration time.
- Registration cannot proceed without successful OTP verification — no transaction is opened on OTP failure.
- `businessType` must be one of the defined enum values or `Custom`.
- Registration is all-or-nothing: if branch creation, Owner user creation, or catalog seeding fails, the tenant record itself must not persist (transaction rollback, not a lingering `PendingVerification` orphan).
- `branchLimit`/`staffLimit` from the active plan are enforced by Branch/User Management, not here — this module only exposes the numbers.
- A tenant cannot self-downgrade to a plan whose `branchLimit`/`staffLimit` is below its **current live usage** — `/subscribe` must read current branch count (Branch Management) and staff count (User Management) before allowing a downgrade; reject with 402 if it would violate the new plan's limits.
- `defaultTaxPct` and other settings fields validated per existing tenant settings rules.

## Security

### Role Access Matrix

| Action | Super Admin | Owner (own tenant) | Owner (other tenant) | Branch Manager / Staff / Cashier |
|---|:---:|:---:|:---:|:---:|
| POST /tenants/request-otp | ✅ (n/a — public) | — | — | — |
| POST /tenants/register | ✅ (n/a — public) | — | — | — |
| GET /tenants/:id | ✅ (any) | ✅ | ❌ | ❌ |
| PATCH /tenants/:id/settings | ❌ | ✅ | ❌ | ❌ |
| GET /tenants (list all) | ✅ | ❌ | ❌ | ❌ |
| PATCH /tenants/:id/status | ✅ | ❌ | ❌ | ❌ |
| GET /subscription-plans | ✅ | ✅ | ✅ | ✅ |
| POST /tenants/:id/subscribe | ✅ (any) | ✅ | ❌ | ❌ |

- Branch Manager, Staff, and Cashier have **no access** to this module at all — Tenant Onboarding is exclusively Owner (own tenant) + Super Admin (platform-wide).
- Super Admin tokens carry no `tenantId` and are scoped to platform-level routes only (per Auth module contract) — cannot obtain a tenant-scoped session through this module.
- All 404s must be tenant-safe: an Owner requesting another tenant's `:id` gets a generic not-found, never a distinguishing error revealing the tenant exists.
- Every mutating action (OTP request, register, settings update, status change, subscribe) writes an audit log entry via the existing AuditService (actor, tenantId where applicable, old/new value, timestamp).

## Integrations
- **Branch Management:** create the first branch inside the registration transaction; read live branch count for downgrade-guard checks.
- **User Management:** create the Owner user inside the registration transaction; read live staff count for downgrade-guard checks.
- **Catalog (`SVC-CATALOG-003`):** called inside the registration transaction to seed default `serviceCategories`/`services`/`itemCategories` per `businessType`.
- **Authentication:** exposes `tenants.status` for Auth's login-gate check (Suspended/Cancelled tenants block all logins) — read-only dependency in the other direction, not implemented here.
- **Notifications:** delivers the registration OTP and the post-registration welcome message — referenced, not implemented here.
- **Audit Service:** every mutation logged.

## Background Jobs
- Daily cron checks `tenantSubscriptions.expiryDate`; flags/notifies tenants nearing or past expiry.
- Daily cron auto-transitions tenants with `paymentStatus=Overdue` beyond the grace period to `status=Restricted` (not `Suspended` — Restricted is reversible automatically on payment, Suspended requires Super Admin).
- Daily/TTL cleanup of expired `registrationOtps` entries (also covered by TTL index as a safety net).
- All jobs write audit entries for every automatic status transition they perform.

---

## Build Order
1. Collections and indexes (`tenants`, `registrationOtps`, `subscriptionPlans`, `tenantSubscriptions`).
2. OTP request and verification flow (`/tenants/request-otp` + OTP checks embedded in `/tenants/register`).
3. Registration transaction (tenant + branch + Owner + catalog seed, atomic, gated on OTP success).
4. Tenant profile APIs (`/tenants/:id` GET, `/tenants/:id/settings` PATCH).
5. Super Admin APIs (`/tenants` list, `/tenants/:id/status`).
6. Subscription Plan APIs (`/subscription-plans` GET).
7. Subscription assignment (`/tenants/:id/subscribe` with downgrade guard).
8. RBAC guards across all 8 routes per the matrix above.
9. Audit logging on every mutation.
10. Background jobs (expiry-approaching flag, overdue → Restricted transition, OTP cleanup).

## Testing
- **Unit:** default service/item-category seed selection per `businessType`; plan feature-flag object shape resolution; downgrade-guard math (reject when new plan's limits < live usage); OTP hashing/comparison logic.
- **Integration:** `/tenants/register` creates tenant + branch + Owner atomically — a failure in any one step rolls back all three/four; Super Admin suspending a tenant blocks all its users from login (via Auth's read of `status`) within one request cycle; `/subscribe` downgrade is rejected when it would violate live branch/staff counts.
- **Security:** platform-wide uniqueness rejects a second registration with the same `ownerEmail`/`ownerPhone`; Owner of Tenant A cannot `GET /tenants/:id` for Tenant B (tenant-safe 404); Branch Manager/Staff/Cashier blocked from every route (403); Super Admin cannot obtain a tenant-scoped token via this module.
- **OTP-specific:**
  - OTP generation succeeds and delivers via Notifications.
  - OTP expiration is enforced — verification with an expired OTP returns 400.
  - OTP resend cooldown is enforced — resend before cooldown elapses returns 429.
  - OTP rate limiting is enforced — excessive request-otp calls return 429.
  - Duplicate `ownerEmail` rejected before OTP generation (no OTP issued).
  - Duplicate `ownerPhone` rejected before OTP generation (no OTP issued).
  - Registration with invalid OTP is rejected and no transaction is opened.
  - Registration with expired OTP is rejected and no transaction is opened.
- **Regression:** overdue-cron correctly moves a tenant to `Restricted` (not `Suspended`) and reverses automatically once `paymentStatus=Paid`.

---

## Acceptance Criteria
- [ ] A new business can complete registration end-to-end (request OTP → verify OTP → tenant + branch + Owner + catalog seed, all atomic) and the Owner can immediately create their first order.
- [ ] `ownerEmail` and `ownerPhone` are enforced unique across the entire platform, checked **before** OTP generation and again before the registration transaction begins.
- [ ] OTP generation works successfully and delivery is triggered via the Notification module.
- [ ] OTP expiration is enforced; expired OTPs cannot be used to complete registration.
- [ ] OTP resend cooldown works correctly, preventing rapid repeat requests.
- [ ] OTP rate limiting works correctly, preventing abuse of `/tenants/request-otp`.
- [ ] Registration cannot proceed without successful OTP verification — no partial writes occur on OTP failure.
- [ ] Duplicate `ownerEmail` and `ownerPhone` are rejected before OTP generation, not just at registration.
- [ ] Registration remains fully atomic after OTP verification: a failure at any step (branch, Owner, or catalog seed) leaves no orphaned tenant record.
- [ ] Suspending or cancelling a tenant blocks all its users' logins within one request cycle.
- [ ] The lifecycle correctly includes and transitions through `Restricted` for overdue subscriptions, distinct from `Suspended`.
- [ ] Subscription plan `features` are stored as a strongly typed object (`whatsappEnabled`, `customBrandingEnabled`, `apiAccessEnabled`), never as a string array.
- [ ] Plan feature flags are stored and exposed here but never enforced inside this module — enforcement is confirmed to live in the consuming modules.
- [ ] `/subscribe` blocks a downgrade whenever it would violate the new plan's `branchLimit`/`staffLimit` against current live usage, based on a real-time read from Branch/User Management.
- [ ] RBAC matches the Role Access Matrix exactly across all 8 APIs: Owner (own tenant) + Super Admin only for protected routes; Branch Manager/Staff/Cashier fully blocked.
- [ ] All 404 responses are tenant-safe — no cross-tenant existence leakage.
- [ ] Every mutating action (OTP request, register, settings update, status change, subscribe) produces a correct audit log entry.
- [ ] Business-type default catalog seeding produces a working starter configuration with no manual setup.
- [ ] Background jobs correctly flag near/at-expiry subscriptions, auto-transition overdue ones to `Restricted` (reversible on payment), and clean up expired OTP records.
- [ ] Unit, Integration, Security, and OTP-specific tests all pass.
- [ ] Module compiles without TypeScript errors and integrates without breaking existing Authentication, Branch Management, User Management, or Catalog functionality.

## Completion
Verify all acceptance criteria → run full test suite → record created/modified files, test outcomes, known limitations (e.g. manual billing only, no payment gateway) → update completion report → confirm no scope was added beyond the 8 listed APIs and 4 listed collections → stop execution.
```