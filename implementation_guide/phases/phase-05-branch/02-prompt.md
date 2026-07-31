# Implementation Prompt 05 —  Branch Management

**Project:** Nexoraa CleanSoft — Multi-Tenant Shop Management System
**Stack:** NestJS (TypeScript) · MongoDB · Mongoose ODM · Redis/BullMQ
**NestJS Path:** `src/branches/`
**Supersedes:** the combined `branches-users.md` specification (Module 3), which is now split into two independent modules.

---

## 0. Objective

Implement Branch Management as a **self-contained module that owns branch data only**. All user lifecycle concerns — creation, invitation, updates, roles, activation, deletion, credentials, sessions, permissions — belong to the **User Management module** (`src/users/`) and must not appear anywhere in this codebase.

The Branch Manager is stored on the branch as a **reference (`managerId`) only**. Assigning or removing a manager writes exactly one field on one document: `branches.managerId`. It never touches a user record.

---

## 1. Ownership Boundary

### 1.1 This module owns

| Concern | Detail |
|---|---|
| Branch creation | Including subscription `branchLimit` enforcement |
| Branch updates | Name, address, city, contact details |
| Branch status lifecycle | `Active` ⇄ `Inactive` |
| Branch operating settings | `openingTime`, `closingTime`, branch `code` |
| Branch contact information | `phone`, `email` |
| Manager reference assignment | The value of `branches.managerId` — nothing else |

### 1.2 User Management exclusively owns

User creation · user invitation · user updates · profile management · activation/deactivation · deletion · role assignment · **`User.branchIds`** · passwords · authentication credentials · sessions · permissions · RBAC definitions.

### 1.3 Hard prohibitions

Branch Management **must never**:

- Create, update, delete, activate, or deactivate a user.
- Change a user's role, permissions, profile, status, or `branchIds`.
- Modify passwords, credentials, tokens, or any authentication data.
- Import `UserSchema`, `RoleSchema`, `PermissionSchema`, or any User Management Mongoose model.
- Register `MongooseModule.forFeature([{ name: User.name, ... }])` for user-owned collections.
- Read from or write to the `users`, `roles`, `permissions`, `refreshTokens`, or `passwordResetTokens` collections — directly, via aggregation, via `$lookup`, or via `populate()`.

> **`populate('managerId')` is banned.** Manager display data is fetched through `usersService.getDisplayInfo()`. A `populate` call reaches into the users collection from inside this module and violates the boundary even though it is read-only.

### 1.4 Enforcement (not optional)

The prohibitions above are enforced mechanically, not by convention:

```jsonc
// .eslintrc — inside src/branches/
"no-restricted-imports": ["error", {
  "patterns": [
    { "group": ["**/users/schemas/*", "**/users/*.schema", "**/auth/schemas/*"],
      "message": "Branch Management must not import User/Role/Auth schemas. Use UsersPublicService." }
  ]
}]
```

Add a `dependency-cruiser` (or Nx module-boundary) rule asserting `src/branches/**` has no dependency edge into `src/users/**` other than `src/users/interfaces/users-public.service.ts`. CI fails the build on violation.

---

## 2. Manager Reference Rule

`branches.managerId` is a **non-authoritative foreign key**. Branch Management writes the field; it never dereferences the field into a user mutation.

On assign (`PATCH /branches/:id/manager`), Branch Management performs exactly these steps:

1. Call `usersService.verifyUserExistsAndActive(userId, tenantId)`.
2. Call `usersService.verifyEligibleForManagerRole(userId, tenantId)`.
3. On success, set `branches.managerId = userId` and emit `branch.managerAssigned`.
4. Write an audit entry via the shared `AuditService`.

On remove (`DELETE /branches/:id/manager`), set `managerId = null`, emit `branch.managerUnassigned`, write audit entry.

**Explicitly out of scope of both operations:** granting the user the `BranchManager` role, adding the branch to `User.branchIds`, or altering user status. If the business flow requires those changes, the caller performs them separately against User Management endpoints. Branch Management does not orchestrate them and does not silently perform them as a side effect.

Eligibility validation is **mandatory, not optional**. A branch may only reference a user whose resolved role is `Owner` or `BranchManager` within the same tenant.

---

## 3. Cross-Module Contract

### 3.1 The only permitted interface

Define in User Management, consume in Branch Management. No other surface is permitted.

```ts
// src/users/interfaces/users-public.service.ts
export interface UserDisplayInfo {
  id: string;
  name: string;
  mobile: string;
  email?: string;
  roleName: string;
  isActive: boolean;
}

export interface UsersPublicService {
  /** Throws UserNotFoundError | UserInactiveError | TenantMismatchError */
  verifyUserExistsAndActive(userId: string, tenantId: string): Promise<void>;

  /** Throws UserNotEligibleError if the user's role is not Owner or BranchManager */
  verifyEligibleForManagerRole(userId: string, tenantId: string): Promise<void>;

  /** Read-only projection. Returns null if not found. Never throws on absence. */
  getDisplayInfo(userId: string, tenantId: string): Promise<UserDisplayInfo | null>;

  /** Batch variant for list endpoints — avoids N+1 calls */
  getDisplayInfoBatch(userIds: string[], tenantId: string): Promise<Map<string, UserDisplayInfo>>;
}

export const USERS_PUBLIC_SERVICE = Symbol('USERS_PUBLIC_SERVICE');
```

Injected by token, not by concrete class:

```ts
constructor(
  @Inject(USERS_PUBLIC_SERVICE) private readonly usersService: UsersPublicService,
) {}
```

Wire with `forwardRef()` in both module definitions to resolve the circular reference (Branches needs Users for manager validation; Users needs Branches for `branchIds` validation).

### 3.2 Error contract

| Thrown by UsersPublicService | Branch Management returns |
|---|---|
| `UserNotFoundError` | `400` — `'The selected user does not exist'` |
| `TenantMismatchError` | `400` — same message as above (never confirm cross-tenant existence) |
| `UserInactiveError` | `409` — `'The selected user is not active'` |
| `UserNotEligibleError` | `409` — `'The selected user is not eligible to be a branch manager'` |

Cross-tenant lookups return the *not found* message, never a distinguishing error — consistent with the platform rule that 404s and error messages are tenant-scoped and never leak foreign-tenant data.

### 3.3 Event contract — stale-reference cleanup

Neither module may write the other's collection, so lifecycle drift is resolved by events on the shared internal event bus (`@nestjs/event-emitter`, or BullMQ for durability).

| Emitter | Event | Consumer | Action |
|---|---|---|---|
| User Management | `user.deactivated` | **Branches** | Set `managerId = null` on every branch where `managerId` matches; audit as system action |
| User Management | `user.deleted` | **Branches** | Same as above |
| User Management | `user.roleChanged` | **Branches** | If the new role is not manager-eligible, null out `managerId` on referencing branches |
| **Branches** | `branch.deactivated` | User Management | Prune the branch from affected users' `branchIds` |
| **Branches** | `branch.created` | User Management | Informational only — no mutation required |
| **Branches** | `branch.managerAssigned` | Notifications | Dispatch in-app notification to the assigned user |

Each handler is idempotent and scoped by `tenantId`.

### 3.4 Bootstrap ordering (tenant registration)

Tenant Onboarding (Module 2) creates tenant + first branch + Owner user in a single transaction. Resolve the ordering as:

1. Create `tenant`.
2. Create `branch` with `managerId: null` — no user exists yet, so no validation call fires.
3. Create Owner `user` (User Management), which sets `branchIds: []` for tenant-wide access.
4. Optionally, Tenant Onboarding calls `branchesService.assignManager(branchId, ownerId)` as the final step.

Branch creation must therefore **accept a null `managerId`** and must not require a manager to exist at creation time.

### 3.5 Other cross-module reads

The same discipline applies beyond users. Branch Management must not import `TenantSchema` or `OrderSchema` either.

- `branchLimit` enforcement → `tenantsService.getPlanLimits(tenantId): Promise<{ branchLimit: number; staffLimit: number }>`
- Open-order check on deactivation → `ordersService.countNonTerminalByBranch(tenantId, branchId): Promise<number>`

---

## 4. Database Design

Branch Management owns **one collection**.

```jsonc
// Collection: branches
{
  "_id": "ObjectId",
  "tenantId": "ObjectId (Ref: tenants, Required)",
  "name": "String (Required)",
  "code": "String (Required, Unique per tenant, e.g. 'MAIN')",
  "address": "String (Required)",
  "city": "String (Required)",
  "phone": "String (Required)",
  "email": "String (Optional)",
  "openingTime": "String (e.g. '09:00')",
  "closingTime": "String (e.g. '21:00')",
  "managerId": "ObjectId (Ref: users, Nullable — reference only, never dereferenced into a user mutation)",
  "status": "String (Enum: 'Active', 'Inactive', Default: 'Active')",
  "createdAt": "Date (Default: Date.now)"
}
```

**Indexes**

- `{ tenantId: 1, code: 1 }` — unique compound
- `{ tenantId: 1, status: 1 }`
- `{ tenantId: 1, managerId: 1 }` — sparse; supports the `user.deactivated` cleanup handler

The `Ref: users` annotation documents intent for readers. It does **not** authorize `populate()`. See §1.3.

---

## 5. REST API

All routes require a valid JWT access token. All queries are auto-scoped by `tenantId` via the shared `TenantScopeInterceptor` — no service method accepts an unscoped `find()`.

| Method | Route | Purpose | Role Gate |
|---|---|---|---|
| `GET` | `/branches` | List branches for the tenant (paginated, filter by `status`) | Owner, Branch Manager *(own branches only)* |
| `POST` | `/branches` | Create a branch; enforces subscription `branchLimit` | Owner |
| `GET` | `/branches/:id` | Retrieve branch detail | Owner, Branch Manager *(own branch)* |
| `PATCH` | `/branches/:id` | Update branch details, contact info, operating hours | Owner |
| `PATCH` | `/branches/:id/status` | Activate / deactivate a branch | Owner |
| `DELETE` | `/branches/:id` | Deactivate a branch (soft; blocked if open orders exist) | Owner |
| `PATCH` | `/branches/:id/manager` | Set `managerId` after validation | Owner |
| `DELETE` | `/branches/:id/manager` | Clear `managerId` | Owner |

**Routes that must NOT exist in this module:** `/users`, `/users/invite`, `/users/:id`, `/roles`, or any nested variant such as `/branches/:id/users` or `/branches/:id/staff`. Staff listings by branch are served by User Management at `GET /users?branchId=`.

List responses follow the platform envelope: `{ items, total, page, limit }`.

### Example — `POST /branches`

**Request**

```json
{
  "name": "Kothrud Branch",
  "code": "KTD",
  "address": "Paud Road, Kothrud",
  "city": "Pune",
  "phone": "9876543212",
  "openingTime": "09:00",
  "closingTime": "21:00"
}
```

**Response** — `201`

```json
{
  "id": "665f1a0c9a1e4c0012ab3403",
  "name": "Kothrud Branch",
  "code": "KTD",
  "city": "Pune",
  "managerId": null,
  "status": "Active"
}
```

### Example — `PATCH /branches/:id/manager`

**Request**

```json
{ "managerId": "665f2d0a9a1e4c0012ab3600" }
```

**Response** — `200` — manager block is hydrated via `getDisplayInfo()`, not `populate()`

```json
{
  "id": "665f1a0c9a1e4c0012ab3403",
  "managerId": "665f2d0a9a1e4c0012ab3600",
  "manager": { "id": "665f2d0a9a1e4c0012ab3600", "name": "Sneha Kadam", "roleName": "BranchManager" }
}
```

---

## 6. Validations & Business Rules

- `code` must be unique within the tenant; case-normalized to uppercase before the uniqueness check.
- Branch creation is rejected with `402` if it would exceed the tenant's subscription `branchLimit`, sourced via `tenantsService.getPlanLimits()`.
- `openingTime` / `closingTime` match `HH:mm` (24-hour); closing must not equal opening.
- `phone` is a valid 10-digit mobile number; `email` is a valid address when supplied.
- `managerId`, when supplied, must reference an existing, active, manager-eligible user **in the same tenant** — validated through `UsersPublicService` only.
- `managerId` may be `null` at creation and at any point thereafter. A branch without a manager is a valid state.
- A branch cannot be deactivated while it has orders in a non-terminal status (`Received`, `InProgress`, `Ready`, `OutForDelivery`) — checked via `ordersService.countNonTerminalByBranch()`.
- A tenant must retain at least one `Active` branch; deactivating the last active branch is rejected with `409`.
- All create/update DTOs are validated with `class-validator`; invalid payloads return `400` with a field-level error map.

---

## 7. RBAC — Consumed, Not Defined

Branch Management **consumes** authorization. It does not define roles, permissions, JWT claims, role hierarchy, or authorization rules — those belong to Authentication and User Management.

This module only:

- Applies the shared `JwtAuthGuard`, `RolesGuard`, and `PermissionsGuard`.
- Annotates routes with `@Roles('Owner')` / `@RequirePermissions('branches.create')`.
- Reads `tenantId`, `branchIds`, `role`, and `permissions` from the verified JWT.

| Role | Access |
|---|---|
| Owner | Full CRUD on branches within the tenant; assign/remove managers |
| Branch Manager | Read-only on their assigned branch(es); cannot create, update, or deactivate |
| Staff / Cashier | Read-only minimal branch info (name, code, contact) for receipts and headers |
| Super Admin | No tenant-branch access by default; platform views live in Tenant Onboarding |

Branch context is always derived from the verified JWT, never from a client-supplied header or body field. Client-side hiding of UI controls is never a substitute for a server-side check.

---

## 8. Background Jobs

- **Weekly cron** — report branches with `managerId: null` to the Owner via Notifications. *(Reports only. Does not assign anyone.)*
- **Nightly integrity check** — for each branch with a non-null `managerId`, call `verifyUserExistsAndActive()`; log and null out any dangling reference missed by the event handlers.

The invite-expiry cron from the original combined module has moved to User Management and must not appear here.

---

## 9. Error Handling

| Status | Condition | Response |
|---|---|---|
| `409` | Duplicate branch code within tenant | `'A branch with this code already exists'` |
| `402` | Branch limit exceeded for the active plan | `'Your current plan does not allow additional branches'` |
| `409` | Deactivating a branch with open orders | `'Cannot deactivate a branch with unresolved orders'` |
| `409` | Deactivating the last active branch | `'At least one active branch must remain'` |
| `400` | `managerId` references a non-existent or cross-tenant user | `'The selected user does not exist'` |
| `409` | `managerId` references an inactive user | `'The selected user is not active'` |
| `409` | `managerId` references a manager-ineligible user | `'The selected user is not eligible to be a branch manager'` |
| `404` | Branch not found within tenant scope | Standard tenant-safe 404 |

---

## 10. Verification & Testing

**Boundary tests (new, and the point of this refactor)**

- Static analysis: `src/branches/**` contains zero imports from `src/users/schemas`, `src/auth/schemas`, or any user-owned Mongoose model. Assert via the lint/dependency-cruiser rule in CI.
- Static analysis: no `populate()` call in this module targets `managerId`.
- Integration: after `PATCH /branches/:id/manager`, the referenced user document is **byte-identical** to its pre-call state — role, `branchIds`, `isActive`, and `updatedAt` all unchanged.
- Integration: after `DELETE /branches/:id/manager`, the previously referenced user document is likewise unchanged.
- Runtime: mock `UsersPublicService` entirely and confirm the full branch test suite passes with **no users collection present in the test database**.

**Functional tests**

- Unit: `branchLimit` enforcement against the active subscription plan.
- Unit: `code` uniqueness is scoped per tenant — the same code in two tenants is allowed.
- Integration: branch creation with `managerId: null` succeeds (bootstrap path).
- Integration: `user.deactivated` event nulls `managerId` on all referencing branches within the tenant.
- Integration: `branch.deactivated` event causes User Management to prune the branch from affected `branchIds`.
- Integration: deactivating a branch with a non-terminal order returns `409`.
- Security: a Branch Manager cannot `POST /branches` or `PATCH` a branch outside their `branchIds` (403).
- Security: Tenant A's Owner cannot read or modify Tenant B's branch (tenant-safe 404).

---

## 11. Acceptance Criteria

**Original criteria — preserved**

- Every order, payment, and expense record can resolve to exactly one valid, active branch.
- Branch-scoped users never see data for branches outside their `branchIds`.
- Branch `code` uniqueness holds within each tenant.
- Subscription `branchLimit` is enforced consistently at creation.

**Separation criteria — new**

- No User Management functionality exists inside the Branch Management module.
- All user operations are delegated to User Management.
- `managerId` is treated purely as a foreign-key reference.
- Branch Management never imports User or Role schemas — verified by an automated CI rule, not by review.
- Branch Management never writes to the `users` collection.
- Branch Management communicates with User Management only through the public service interface.
- Assigning or removing a Branch Manager updates the branch document and nothing else.
- User lifecycle management remains completely isolated inside the User Management module.
- Deleting `src/users/` breaks compilation only at the `UsersPublicService` import — no other coupling exists.

---

## 12. Preservation Constraint

Do not modify existing APIs, schemas, routes, validation rules, integrations, testing strategy, or business logic beyond the architectural separation described above. Platform-wide standards continue to apply unchanged: decimal-safe money handling, `TenantScopeInterceptor` on every query, `class-validator` on every DTO, pagination envelope on every list endpoint, `AuditService` entries on every high-risk action, and atomic counters for all sequential numbering.