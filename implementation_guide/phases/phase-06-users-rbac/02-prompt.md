# Implementation Prompt 06- User Management & RBAC

**Project:** Nexoraa CleanSoft — Multi-Tenant Shop Management System
**Stack:** NestJS (TypeScript) · MongoDB · Mongoose ODM · Redis / BullMQ · Flutter client
**NestJS Path:** `src/users/`
**Companion module:** Module 3A — Branch Management (`src/branches/`)
**Supersedes:** the user half of the combined `branches-users.md` specification.

---

## 0. Objective

Implement a production-ready **User Management and Role-Based Access Control** module for the multi-tenant platform. This module is the single authority for everything about *who a person is and what they may do* — profile, employee code, role, permissions, branch membership, department, designation, invitation, and lifecycle state.

It is **not** the authority for *how a person proves who they are*. Credentials, password hashing, sessions, JWT issue/refresh, and lockout belong to Authentication (`src/auth/`).

---

## 1. Ownership Boundary

### 1.1 This module owns

| Concern | Detail |
|---|---|
| User records | Creation, update, soft deactivation, search |
| Employee profile | Names, contact, employee code, department, designation |
| Lifecycle | `INVITED → PENDING_ACTIVATION → ACTIVE ⇄ SUSPENDED → DEACTIVATED` |
| Roles | Assignment to users; custom role definitions per tenant |
| Permissions | Effective permission resolution, per-user overrides, expiry |
| Branch membership | **`User.branchIds`** and `primaryBranchId` |
| Invitations | Issue, resend, revoke, accept; token hashing and expiry |
| Self-service profile | `GET/PATCH /users/me` |

### 1.2 Owned by other modules

| Module | Owns |
|---|---|
| Authentication (`src/auth/`) | Passwords, `passwordHash`, credential verification, sessions, refresh tokens, JWT issue/refresh, `failedLoginCount`, lockout |
| Tenant Management (`src/tenants/`) | Tenants, subscription plans, `staffLimit` / `branchLimit` |
| Branch Management (`src/branches/`) | Branch records and **`Branch.managerId`** |
| Audit (`src/audit/`) | The append-only `auditLogs` collection and `AuditService` |
| Notifications (`src/notifications/`) | Delivery infrastructure for invitation and lifecycle messages |

### 1.3 Hard prohibitions

User Management **must never**:

- Store, hash, compare, reset, or transmit a password. `passwordHash` lives on the user document but is **written exclusively by Authentication**; this module never reads or writes that field and must exclude it from every projection.
- Issue, verify, refresh, or revoke a JWT or session. Session revocation on suspend/deactivate is requested via `authService.revokeAllSessions()`.
- Write to the `branches` collection or set `Branch.managerId`.
- Write to the `tenants` or `subscriptionPlans` collections.
- Write to `auditLogs` directly — always through the shared `AuditService`.
- Dispatch a WhatsApp/SMS/email message directly — always through the Notifications queue.

### 1.4 Enforcement

```jsonc
// .eslintrc — inside src/users/
"no-restricted-imports": ["error", {
  "patterns": [
    { "group": ["**/branches/schemas/*", "**/tenants/schemas/*", "**/audit/schemas/*"],
      "message": "Use the public service interface for cross-module reads." },
    { "group": ["bcrypt", "bcryptjs", "argon2", "jsonwebtoken", "@nestjs/jwt"],
      "message": "Credentials and tokens are owned by Authentication." }
  ]
}]
```

A `dependency-cruiser` rule asserts `src/users/**` reaches other modules only through their `interfaces/*-public.service.ts` files. CI fails the build on violation.

---

## 2. Data Model

### 2.1 Collection: `users`

```jsonc
{
  "_id": "ObjectId",
  "tenantId": "ObjectId (Ref: tenants, Required, immutable)",
  "employeeCode": "String (Required, server-generated, immutable, unique per tenant, e.g. 'EMP-0007')",

  "profile": {
    "firstName": "String (Required, 1–50)",
    "lastName":  "String (Required, 1–50)",
    "email":     "String (Optional, normalized lowercase+trim, unique per tenant when present)",
    "mobile":    "String (Required, 10 digits, unique per tenant)",
    "altMobile": "String (Optional)",
    "avatarUrl": "String (Optional, storage URL)",
    "dateOfJoining": "Date (Optional)"
  },

  "roleId":          "ObjectId (Ref: roles, Required)",
  "branchIds":       "ObjectId[] (Ref: branches, empty array = tenant-wide access, Owner only)",
  "primaryBranchId": "ObjectId (Ref: branches, Nullable, must be a member of branchIds)",
  "department":      "String (Optional, from tenant-configured list)",
  "designation":     "String (Optional, from tenant-configured list)",

  "status": "String (Enum: 'INVITED','PENDING_ACTIVATION','ACTIVE','SUSPENDED','DEACTIVATED', Default: 'INVITED')",
  "statusReason": "String (Nullable, required for SUSPENDED and DEACTIVATED)",
  "statusChangedAt": "Date (Nullable)",
  "statusChangedBy": "ObjectId (Ref: users, Nullable)",

  "passwordHash": "String (Nullable — WRITTEN AND READ BY AUTHENTICATION ONLY; excluded from every projection in this module)",

  "createdBy": "ObjectId (Ref: users, Nullable — null for the bootstrap Owner)",
  "updatedBy": "ObjectId (Ref: users, Nullable)",
  "createdAt": "Date (Default: Date.now, UTC)",
  "updatedAt": "Date (Default: Date.now, UTC)",
  "version":   "Number (Default: 0, optimistic concurrency token)"
}
```

**Indexes**

- `{ tenantId: 1, employeeCode: 1 }` — unique compound
- `{ tenantId: 1, 'profile.mobile': 1 }` — unique compound
- `{ tenantId: 1, 'profile.email': 1 }` — unique compound sparse
- `{ tenantId: 1, status: 1 }`
- `{ tenantId: 1, roleId: 1 }`
- `{ tenantId: 1, branchIds: 1 }` — multikey
- `{ tenantId: 1, 'profile.firstName': 'text', 'profile.lastName': 'text' }`

A **global Mongoose projection hook** on this schema strips `passwordHash` from every `find`, `findOne`, and aggregation result originating in this module.

### 2.2 Collection: `roles`

```jsonc
{
  "_id": "ObjectId",
  "tenantId": "ObjectId (Ref: tenants, Nullable — null for system default roles)",
  "roleName": "String (Required, e.g. 'Owner','BranchManager','Staff','Cashier', or custom)",
  "description": "String (Optional)",
  "rank": "Number (Required — 100 Owner, 80 BranchManager, 60 Cashier, 40 Staff; lower = fewer privileges)",
  "permissionCodes": "String[] (Required, e.g. ['orders.create','orders.read'])",
  "isDefault": "Boolean (Default: false — true for system roles, which are immutable)",
  "status": "String (Enum: 'Active','Retired', Default: 'Active')",
  "version": "Number (Default: 0)"
}
```

**Indexes:** `{ tenantId: 1, roleName: 1 }` unique compound · `{ tenantId: 1, status: 1 }`

`rank` is the mechanism that prevents privilege escalation (§6.3). It is not decorative.

### 2.3 Collection: `permissions`

```jsonc
{
  "_id": "ObjectId",
  "module": "String (Required, e.g. 'orders')",
  "action": "String (Required, e.g. 'create')",
  "code":   "String (Required, Unique platform-wide, e.g. 'orders.create')",
  "description": "String (Optional)"
}
```

**Indexes:** `{ code: 1 }` unique

Seeded once at deploy time. Never tenant-scoped, never client-writable.

### 2.4 Collection: `userPermissions`

One document per user. Holds the **resolved effective set** plus the overrides that produced it.

```jsonc
{
  "_id": "ObjectId",
  "tenantId": "ObjectId (Ref: tenants, Required)",
  "userId":   "ObjectId (Ref: users, Required, Unique)",
  "roleId":   "ObjectId (Ref: roles, Required — snapshot of the role used in resolution)",
  "rolePermissions": "String[] (copied from role at resolution time)",
  "grants": [ { "code": "String", "grantedBy": "ObjectId", "grantedAt": "Date", "expiresAt": "Date (Nullable)" } ],
  "revokes": [ { "code": "String", "revokedBy": "ObjectId", "revokedAt": "Date" } ],
  "effectivePermissions": "String[] (computed, cached)",
  "resolvedAt": "Date",
  "version": "Number (Default: 0)"
}
```

**Indexes:** `{ userId: 1 }` unique · `{ tenantId: 1 }` · `{ 'grants.expiresAt': 1 }` sparse

**Resolution formula** — deterministic, recomputed on any role/grant/revoke change:

```
effective = (rolePermissions ∪ activeGrants) \ revokes
activeGrants = grants where expiresAt is null OR expiresAt > now
```

Revoke always wins over grant. Cached in Redis under `perm:{tenantId}:{userId}` with a 15-minute TTL, invalidated eagerly on change.

### 2.5 Collection: `userInvitations`

```jsonc
{
  "_id": "ObjectId",
  "tenantId": "ObjectId (Ref: tenants, Required)",
  "userId":   "ObjectId (Ref: users, Required)",
  "tokenHash": "String (Required, SHA-256 of the invitation token — plaintext NEVER stored)",
  "channel": "String (Enum: 'Email','WhatsApp','SMS', Required)",
  "sentTo":  "String (Required, the email/mobile the invite went to)",
  "status":  "String (Enum: 'Pending','Accepted','Expired','Revoked', Default: 'Pending')",
  "expiresAt": "Date (Required, +7 days)",
  "resendCount": "Number (Default: 0, max 5)",
  "lastSentAt": "Date",
  "acceptedAt": "Date (Nullable)",
  "invitedBy": "ObjectId (Ref: users, Required)",
  "createdAt": "Date (Default: Date.now)"
}
```

**Indexes:** `{ tokenHash: 1 }` unique · `{ tenantId: 1, userId: 1, status: 1 }` · `{ expiresAt: 1 }` TTL (retain 30 days past expiry for audit, then purge)

### 2.6 Collection: `outbox`

```jsonc
{
  "_id": "ObjectId",
  "tenantId": "ObjectId (Required)",
  "eventName": "String (Required)",
  "payload": "Mixed (Required)",
  "status": "String (Enum: 'Pending','Published','Failed', Default: 'Pending')",
  "attempts": "Number (Default: 0)",
  "createdAt": "Date", "publishedAt": "Date (Nullable)"
}
```

**Indexes:** `{ status: 1, createdAt: 1 }`

Events are written to this collection **inside the same transaction as the state change**, then drained by a BullMQ worker. This guarantees no event is lost and no event fires for a rolled-back write.

---

## 3. Lifecycle State Machine

```
                    ┌──────────────────────────────────────────┐
                    │                                          │
  [create+invite]   ▼                  [accept]                │
  ──────────► INVITED ──────────► PENDING_ACTIVATION ──────► ACTIVE
                    │                       │                  │  ▲
        [revoke /   │                       │ [expire]         │  │
         expire]    │                       ▼                  │  │ [reactivate]
                    └──────────────────► DEACTIVATED ◄─────────┤  │
                                              ▲                │  │
                                              │ [deactivate]   ▼  │
                                              └──────────── SUSPENDED
```

| From | To | Trigger | Required |
|---|---|---|---|
| — | `INVITED` | `POST /users/invite` | Role, at least one branch (unless Owner) |
| `INVITED` | `PENDING_ACTIVATION` | `POST /user-invitations/accept` | Valid, unexpired token |
| `PENDING_ACTIVATION` | `ACTIVE` | Password set via Authentication | `auth.passwordSet` event |
| `INVITED` | `DEACTIVATED` | Invite revoked or expired | — |
| `ACTIVE` | `SUSPENDED` | `PATCH /users/:id/suspend` | Non-empty reason |
| `SUSPENDED` | `ACTIVE` | `PATCH /users/:id/reactivate` | — |
| `ACTIVE` / `SUSPENDED` | `DEACTIVATED` | `PATCH /users/:id/deactivate` | Non-empty reason |
| `DEACTIVATED` | `ACTIVE` | `PATCH /users/:id/activate` | Re-validate plan `staffLimit` |

**Every other transition is rejected with `409`.** Every transition writes an audit entry, sets `statusChangedAt` / `statusChangedBy`, and publishes an event via the outbox.

**On `SUSPENDED` or `DEACTIVATED`:** call `authService.revokeAllSessions(userId)` synchronously *before* returning `200`. A suspended user must not survive on a valid access token until it expires.

**Terminal-state rule:** users are never hard-deleted. `DEACTIVATED` is the terminal state, preserving every historical reference from orders, payments, expenses, assignments, and audit logs.

---

## 4. REST API

All routes require a valid JWT access token except `POST /user-invitations/accept`. All queries are auto-scoped by `tenantId` via the shared `TenantScopeInterceptor`. All list endpoints return `{ items, total, page, limit }`.

### 4.1 Core CRUD & search

| Method | Route | Purpose | Role Gate |
|---|---|---|---|
| `POST` | `/users` | Create a user directly (no invite; server sets a `PENDING_ACTIVATION` shell for Authentication to complete) | Owner |
| `GET` | `/users` | Search/list — filters: `q`, `status`, `roleId`, `branchId`, `department`, `designation`; paginated, sortable | Owner, Branch Manager *(own branches)* |
| `GET` | `/users/:id` | Retrieve a user profile | Owner, Branch Manager *(own branches)* |
| `PATCH` | `/users/:id` | Update profile fields (names, contact, avatar, joining date) | Owner, Branch Manager *(own branches, non-Owner targets)* |

### 4.2 Self-service

| Method | Route | Purpose | Role Gate |
|---|---|---|---|
| `GET` | `/users/me` | Own profile + effective permissions | Any authenticated user |
| `PATCH` | `/users/me` | Update own names, `altMobile`, avatar **only** | Any authenticated user |

`PATCH /users/me` rejects `roleId`, `branchIds`, `primaryBranchId`, `status`, `employeeCode`, `department`, and `designation` with `403`. Self-elevation is closed at the DTO layer, not by a guard that might be forgotten.

### 4.3 Lifecycle

| Method | Route | Purpose | Role Gate |
|---|---|---|---|
| `PATCH` | `/users/:id/activate` | `DEACTIVATED → ACTIVE` | Owner |
| `PATCH` | `/users/:id/suspend` | `ACTIVE → SUSPENDED` (reason required) | Owner, Branch Manager *(own branches)* |
| `PATCH` | `/users/:id/reactivate` | `SUSPENDED → ACTIVE` | Owner, Branch Manager *(own branches)* |
| `PATCH` | `/users/:id/deactivate` | `→ DEACTIVATED` (reason required) | Owner |

### 4.4 Role, permissions, assignment

| Method | Route | Purpose | Role Gate |
|---|---|---|---|
| `GET` | `/users/:id/role` | Current role + rank | Owner, Branch Manager |
| `PATCH` | `/users/:id/role` | Assign a role (rank-gated) | Owner |
| `GET` | `/users/:id/permissions` | Effective set + grants + revokes | Owner |
| `PATCH` | `/users/:id/permissions` | Apply grants / revokes | Owner |
| `POST` | `/users/:id/permissions/reset` | Drop all overrides, revert to pure role set | Owner |
| `GET` | `/users/:id/branches` | Assigned branches | Owner, Branch Manager |
| `PATCH` | `/users/:id/branches` | Replace `branchIds` | Owner |
| `PATCH` | `/users/:id/primary-branch` | Set `primaryBranchId` | Owner, Branch Manager |
| `PATCH` | `/users/:id/department` | Set department | Owner |
| `PATCH` | `/users/:id/designation` | Set designation | Owner |

### 4.5 Invitations

| Method | Route | Purpose | Role Gate |
|---|---|---|---|
| `POST` | `/users/invite` | Create user in `INVITED` + issue token + queue notification | Owner, Branch Manager *(Staff/Cashier only)* |
| `GET` | `/users/:id/invitation` | Invitation status (never the token) | Owner, Branch Manager |
| `POST` | `/users/:id/invitation/resend` | Re-issue token, increment `resendCount` | Owner, Branch Manager |
| `DELETE` | `/users/:id/invitation` | Revoke invitation → user `DEACTIVATED` | Owner, Branch Manager |
| `POST` | `/user-invitations/accept` | **Public.** Validate token, move to `PENDING_ACTIVATION`, hand off to Authentication for password set | Public *(rate-limited)* |

### 4.6 Roles catalogue

| Method | Route | Purpose | Role Gate |
|---|---|---|---|
| `GET` | `/roles` | List roles for the tenant | Owner, Branch Manager |
| `POST` | `/roles` | Create a custom role *(Enterprise plan feature flag)* | Owner |
| `PATCH` | `/roles/:id` | Update a custom role's permission set | Owner |
| `GET` | `/permissions` | List all permission codes | Owner |

System roles (`isDefault: true`) are immutable — `PATCH` returns `409`.

### 4.7 Examples

**`POST /users/invite` — Request**

```json
{
  "profile": { "firstName": "Sneha", "lastName": "Kadam", "mobile": "9822011223", "email": "sneha@example.com" },
  "roleId": "665f2c1e9a1e4c0012ab35aa",
  "branchIds": ["665f1a0c9a1e4c0012ab3402"],
  "primaryBranchId": "665f1a0c9a1e4c0012ab3402",
  "department": "Operations",
  "designation": "Counter Executive",
  "channel": "WhatsApp"
}
```

**Response — `201`**

```json
{
  "id": "665f2d0a9a1e4c0012ab3600",
  "employeeCode": "EMP-0007",
  "profile": { "firstName": "Sneha", "lastName": "Kadam", "mobile": "9822011223" },
  "status": "INVITED",
  "invitation": { "status": "Pending", "expiresAt": "2026-08-06T00:00:00.000Z", "resendCount": 0 },
  "version": 0
}
```

**`PATCH /users/:id/permissions` — Request**

```json
{
  "grants":  [{ "code": "reports.export", "expiresAt": "2026-09-30T00:00:00.000Z" }],
  "revokes": ["payments.refund"],
  "version": 3
}
```

**Response — `200`**

```json
{
  "userId": "665f2d0a9a1e4c0012ab3600",
  "effectivePermissions": ["orders.create","orders.read","customers.read","reports.export"],
  "grants":  [{ "code": "reports.export", "expiresAt": "2026-09-30T00:00:00.000Z" }],
  "revokes": ["payments.refund"],
  "version": 4
}
```

**`POST /user-invitations/accept` — Request**

```json
{ "token": "6f2a...c91b", "mobile": "9822011223" }
```

**Response — `200`**

```json
{
  "userId": "665f2d0a9a1e4c0012ab3600",
  "status": "PENDING_ACTIVATION",
  "nextStep": "SET_PASSWORD",
  "passwordSetupToken": "issued-by-authentication-module"
}
```

---

## 5. Validation Rules

**Profile**

- `firstName`, `lastName` required, 1–50 chars, letters/spaces/hyphens/apostrophes only.
- `email` normalized (trim + lowercase) before uniqueness check; unique per tenant when present.
- `mobile` exactly 10 digits; unique per tenant. Not unique platform-wide — the same person may work for two tenants.
- `avatarUrl` must be an allowed storage host.

**Employee code**

- Server-generated only. Any client-supplied `employeeCode` is rejected with `400`.
- Format `{prefix}-{sequence}`, produced via the atomic `counters` collection with `findOneAndUpdate` + `$inc`, scoped by `tenantId` + `type='employee'`. Never `count()`.
- Immutable after creation — present in a `PATCH` payload → `400`.

**Role & permissions**

- `roleId` must exist, belong to this tenant (or be a system role), and be `Active`.
- Every `grants[].code` and `revokes[]` entry must exist in the `permissions` collection.
- `grants[].expiresAt`, when present, must be in the future.
- A code cannot appear in both `grants` and `revokes` in the same request → `400`.

**Branches**

- Every `branchIds` entry must exist, belong to this tenant, and be `Active` — validated via `branchesService.verifyBranchesExistAndActive()`.
- `primaryBranchId` must be a member of `branchIds` → otherwise `400`.
- Empty `branchIds` is permitted **only** when the assigned role is `Owner` (tenant-wide access). Any other role with an empty array → `400`.

**Tenant & plan**

- `tenantId` is always taken from the verified JWT, never from the body.
- User creation and reactivation are rejected with `402` when the active count would exceed the plan's `staffLimit`, sourced via `tenantsService.getPlanLimits()`.
- All operations rejected with `403` when the parent tenant status is not `Active`.

**Concurrency & idempotency**

- Every mutating endpoint accepts a `version` field; a mismatch returns `409` `'This record was modified by someone else, please reload'`.
- Every mutating endpoint accepts an `Idempotency-Key` header; a repeated key within 24h replays the stored response rather than re-executing.

**Payload hygiene**

- `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true })` globally — unknown fields return `400`, never silent drops. This closes mass assignment.
- All ObjectId params validated by a `ParseObjectIdPipe`; no raw user string ever reaches a query object. Query operators in string inputs (`$`, `.`) are stripped — closes NoSQL injection.
- Timestamps stored and returned in UTC (ISO-8601).

---

## 6. RBAC & Security

### 6.1 Deny by default

`RolesGuard` + `PermissionsGuard` are registered **globally** via `APP_GUARD`. A route with no `@RequirePermissions()` decorator is inaccessible, not public. Public routes are opted in explicitly with `@Public()`.

### 6.2 Least privilege

| Role | Access in this module |
|---|---|
| **Owner** | Full user CRUD, all lifecycle actions, role and permission assignment, branch assignment, custom roles |
| **Branch Manager** | Read users in own `branchIds`; invite, update, suspend, reactivate **Staff and Cashier only** within own branches. Cannot create branches' users outside scope, cannot assign `BranchManager` or `Owner` roles, cannot grant permissions, cannot deactivate |
| **Staff / Cashier** | `GET /users/me` and `PATCH /users/me` only |
| **Super Admin** | No access to tenant user records. Platform-level views live in Tenant Onboarding |

### 6.3 Privilege escalation prevention — mandatory checks

Enforced in a shared `AuthorizationPolicyService`, called by every mutating handler:

1. **No self role change.** `actor.id === target.id` on `/role` or `/permissions` → `403`.
2. **No self lifecycle change.** Actor cannot suspend, deactivate, or activate themselves → `403`.
3. **Rank ceiling.** `targetRole.rank >= actorRole.rank` → `403`. A Branch Manager (80) cannot assign or modify anyone at rank 80 or above.
4. **Grant ceiling.** An actor may only grant permission codes they themselves hold effectively → `403`.
5. **Branch containment.** A non-Owner actor may only assign branches that are a subset of their own `branchIds` → `403`.
6. **Last Owner protection.** The final `ACTIVE` Owner in a tenant cannot be suspended, deactivated, or have their role changed → `403` `'At least one Owner account must remain active'`.
7. **Cross-tenant.** Any target outside the actor's `tenantId` returns a tenant-safe `404` — never `403`, which would confirm existence.

### 6.4 Invitation security

- Token is 32 bytes of CSPRNG output, base64url-encoded. Only the SHA-256 hash is persisted.
- The plaintext token appears exactly once — in the outbound notification. It is never returned by any API, never logged, never included in an audit `newValue`.
- Acceptance requires token **and** a matching identifier (mobile or email) — possession of the link alone is insufficient.
- `POST /user-invitations/accept` is rate-limited to 5 attempts per IP per 15 minutes.
- `resendCount` caps at 5; each resend invalidates the previous hash.
- Failed acceptance returns a single generic message regardless of cause (unknown / expired / revoked / already accepted) — never reveals which.

### 6.5 Audit

Every privileged action writes to `auditLogs` via `AuditService` with `oldValue` and `newValue`: user creation, profile update, role assignment, permission grant/revoke, branch assignment, primary branch change, every lifecycle transition, invitation issue/resend/revoke/accept. `passwordHash` and invitation tokens are never included in audit payloads.

---

## 7. Cross-Module Contracts

### 7.1 Interface this module **exposes**

```ts
// src/users/interfaces/users-public.service.ts
export interface UserDisplayInfo {
  id: string; employeeCode: string; name: string;
  mobile: string; email?: string; roleName: string; isActive: boolean;
}

export interface UsersPublicService {
  /** Throws UserNotFoundError | UserInactiveError | TenantMismatchError */
  verifyUserExistsAndActive(userId: string, tenantId: string): Promise<void>;

  /** Throws UserNotEligibleError when the resolved role is not Owner or BranchManager */
  verifyEligibleForManagerRole(userId: string, tenantId: string): Promise<void>;

  getDisplayInfo(userId: string, tenantId: string): Promise<UserDisplayInfo | null>;
  getDisplayInfoBatch(userIds: string[], tenantId: string): Promise<Map<string, UserDisplayInfo>>;

  /** For Authentication at login — resolved permission codes for the JWT claim */
  getEffectivePermissions(userId: string, tenantId: string): Promise<string[]>;

  /** For Tenant Management plan enforcement */
  countActiveUsers(tenantId: string): Promise<number>;
}

export const USERS_PUBLIC_SERVICE = Symbol('USERS_PUBLIC_SERVICE');
```

### 7.2 Interfaces this module **consumes**

```ts
authService.revokeAllSessions(userId: string): Promise<void>;
authService.issuePasswordSetupToken(userId: string): Promise<string>;

tenantsService.getPlanLimits(tenantId: string): Promise<{ branchLimit: number; staffLimit: number }>;
tenantsService.isFeatureEnabled(tenantId: string, flag: string): Promise<boolean>;

branchesService.verifyBranchesExistAndActive(branchIds: string[], tenantId: string): Promise<void>;
branchesService.getBranchDisplayInfoBatch(ids: string[], tenantId: string): Promise<Map<string, BranchDisplayInfo>>;

notificationsService.queue(payload: NotificationJob): Promise<void>;
auditService.record(entry: AuditEntry): Promise<void>;
```

Both directions are wired with `forwardRef()` — Users ↔ Branches and Users ↔ Auth are legitimately mutual.

### 7.3 Events

**Published** (via outbox, all carrying `tenantId`, `userId`, `actorId`, `occurredAt`):

`user.created` · `user.updated` · `user.roleAssigned` · `user.permissionsUpdated` · `user.branchesUpdated` · `user.invitationCreated` · `user.invitationAccepted` · `user.activated` · `user.suspended` · `user.reactivated` · `user.deactivated`

**Consumed:**

| Event | Source | Action |
|---|---|---|
| `auth.passwordSet` | Authentication | `PENDING_ACTIVATION → ACTIVE`; mark invitation `Accepted` |
| `branch.deactivated` | Branch Management | Prune the branch from all `branchIds`; clear `primaryBranchId` where it matched and promote another assigned branch, or null it |
| `tenant.suspended` | Tenant Management | Invalidate permission caches for all users of the tenant |

**Branch Management consumes** `user.deactivated`, `user.roleAssigned`, and `user.updated` to null out stale `Branch.managerId` references. This module does not perform that cleanup itself.

---

## 8. Background Jobs

| Job | Schedule | Behaviour |
|---|---|---|
| Outbox drain | Every 10s (BullMQ) | Publish `Pending` outbox rows; exponential backoff, 5 attempts, then `Failed` + Owner alert |
| Invitation reminder | Daily 09:00 tenant TZ | Notify invitees at day 3 and day 6 of a `Pending` invitation |
| Invitation expiry | Hourly | `Pending` past `expiresAt` → `Expired`; user `INVITED → DEACTIVATED` |
| Permission expiry sweep | Hourly | Drop `grants` past `expiresAt`, recompute `effectivePermissions`, bust cache |
| Permission cache refresh | Every 15 min | Warm Redis for users active in the last 24h |
| Role synchronization | On role `PATCH` + nightly safety pass | Recompute `userPermissions` for every user holding the changed role; batched, tenant-scoped |
| Invitation purge | Weekly | Delete invitation records 30+ days past terminal status |

---

## 9. Error Handling

| Status | Condition | Response |
|---|---|---|
| `400` | Validation failure | Field-level error map |
| `400` | `primaryBranchId` not in `branchIds` | `'Primary branch must be one of the assigned branches'` |
| `400` | Client-supplied `employeeCode` | `'Employee code is generated by the system'` |
| `402` | Active user count would exceed `staffLimit` | `'Your current plan does not allow additional staff'` |
| `403` | Self role/permission/lifecycle change | `'You cannot modify your own role or access'` |
| `403` | Rank ceiling breach | `'You cannot assign a role equal to or above your own'` |
| `403` | Granting a permission the actor lacks | `'You cannot grant a permission you do not hold'` |
| `403` | Branch outside actor's scope | `'You can only assign branches you have access to'` |
| `403` | Modifying the last active Owner | `'At least one Owner account must remain active'` |
| `409` | Duplicate mobile / email / employee code in tenant | `'A user with this mobile number already exists'` |
| `409` | Invalid lifecycle transition | `'A user cannot move from {current} to {target}'` |
| `409` | `version` mismatch | `'This record was modified by someone else, please reload'` |
| `409` | Editing a system role | `'System roles cannot be modified'` |
| `410` | Invitation expired or revoked | Generic `'This invitation is no longer valid'` |
| `429` | Invitation acceptance rate limit | Retry-After header |
| `404` | User not found **or** cross-tenant | Standard tenant-safe 404 |

---

## 10. Backend Standards

- NestJS + TypeScript, strict mode, no `any` in service signatures.
- **Repository pattern** — controllers never touch Mongoose models. Every repository method takes `tenantId` as a required first argument; there is no unscoped `find()` anywhere in the module.
- DTOs validated with `class-validator` + `class-transformer`; response shaping via `class-transformer` `@Exclude()` on `passwordHash`.
- Optimistic concurrency on every mutation via `version`.
- Idempotency keys on every mutation, stored in Redis with 24h TTL.
- All timestamps UTC, ISO-8601 on the wire.
- Structured JSON logging with `tenantId`, `actorId`, `requestId`; **never** log `passwordHash`, invitation tokens, or full permission payloads.
- Transactions for multi-document writes (user + userPermissions + invitation + outbox must commit or roll back together).

---

## 11. Flutter Client Scope

Implement: user list with search, filters (status / role / branch / department) and pagination · user detail · create and edit user · self profile view and edit · role assignment · permission assignment with grant/revoke and expiry picker · branch multi-select with primary-branch radio · invitation management (send, status, resend, revoke) · lifecycle actions (activate / suspend / reactivate / deactivate) with mandatory reason dialogs · invitation acceptance deep link.

UI hides controls the user's permissions do not allow, but **client-side hiding is never treated as a substitute for the server-side check**. Every screen handles `409` version conflicts with a reload prompt.

---

## 12. Testing

**Unit** — permission resolution formula across grant/revoke/expiry combinations · rank-ceiling policy · lifecycle transition matrix (every valid and invalid pair) · employee code generation under concurrency (no duplicates) · email normalization · `primaryBranchId` membership rule.

**API** — every endpoint's happy path, validation failures, and role gates.

**Integration** — invite → accept → password set → `ACTIVE` end to end · suspend revokes sessions before the response returns · `branch.deactivated` prunes `branchIds` and fixes `primaryBranchId` · role `PATCH` recomputes `userPermissions` for all holders · outbox rows publish exactly once · rollback of a failed user creation leaves no orphaned invitation or outbox row.

**Security** — self-elevation blocked on every route · Branch Manager cannot assign `BranchManager`/`Owner` · Branch Manager cannot touch users outside their branches · cross-tenant access returns 404 not 403 · `passwordHash` absent from every response body and log line · invitation token never returned by any endpoint · unknown payload fields rejected · `$`-prefixed input neutralized · acceptance endpoint rate-limited.

**Performance** — user search P95 under target with 10k users per tenant · permission resolution served from cache under 5ms · role sync over 500 users completes within the batch window.

**E2E** — full onboarding of all four roles from invitation to first authenticated action.

---

## 13. Acceptance Criteria

- User CRUD is complete and tenant-isolated across every endpoint.
- The lifecycle state machine is enforced; no undocumented transition is reachable.
- Roles and permissions are secure: no self-elevation, no rank breach, no granting of unheld permissions.
- Branch assignments are validated against Branch Management; `primaryBranchId` is always a member of `branchIds`.
- The invitation flow is secure: tokens hashed at rest, single-use, expiring, rate-limited, never returned or logged.
- **Passwords, sessions, and tokens are owned by Authentication** — this module contains no hashing library import and never reads or writes `passwordHash`.
- **`User.branchIds` is owned here; `Branch.managerId` is owned by Branch Management.** Neither module writes the other's field.
- Tenant isolation holds under adversarial testing; cross-tenant probes return tenant-safe 404s.
- RBAC is deny-by-default at the global guard level.
- Audit logging is complete for every privileged action, with old and new values and no secrets.
- All listed events publish exactly once via the outbox pattern.
- Optimistic concurrency and idempotency are honoured on every mutation.
- All test suites pass, including the boundary tests in §12.
- API documentation (OpenAPI) is generated and current.

---

## Appendix — Reconciliation Notes

Decisions taken where the condensed brief and the v1.0 platform specification differed. Flag any you want reversed.

1. **`profile` is a nested object**, not flat fields as in the v1.0 `users` schema. Follows the condensed brief. If existing code assumes flat `name`, a migration is needed.
2. **`name` split into `firstName` / `lastName`.** `UserDisplayInfo.name` returns the concatenation so consumers are unaffected.
3. **Status enum is `SCREAMING_SNAKE`** per the condensed brief, versus `PascalCase` elsewhere on the platform (`Active`, `Suspended`). Kept as briefed, but this is inconsistent with `tenants.status` and `branches.status` — worth a platform-wide decision.
4. **`inviteStatus` on the user document is dropped**, replaced by the dedicated `userInvitations` collection, which supports resend counts and revocation that a single enum field cannot.
5. **`failedLoginCount` moved to Authentication.** It is a credential concern, and the v1.0 spec places lockout logic in Module 1.
6. **`rank` added to `roles`.** The brief requires "prevent assigning higher roles" but supplies no ordering mechanism; rank is that mechanism.
7. **Branch Manager may invite Staff and Cashier only**, matching the v1.0 RBAC table, and is additionally barred from permission grants — an escalation vector the v1.0 table left open.