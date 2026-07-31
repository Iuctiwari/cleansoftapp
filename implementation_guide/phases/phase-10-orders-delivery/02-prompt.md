```markdown
# PHASE 10 — Order Management Implementation Prompt

## Phase Info
Module: Order Management · Depends on: Authentication, Multi-Tenancy, Branch Management, User Management, Customer Management, Service Management (preserve all; do not modify) · Status: Implementation prompt.

## Role & Boundaries
Implement Order Management only, using only the requirements below. Manage order, order-item, status-history, and attachment records only — reference (don't reimplement) Customers, Services, Employees, Branches, Payments, Notifications. Stop after completion.

## Purpose
Order Management is the central transaction module: it combines tenant + branch + customer + service + employee context into one operational record. Payments, Notifications, Reports, Dashboard, and Search all reference orders created here.

---

## Scope Definition

### In Scope
Order creation, profile management, order-number generation, line items, customer/service association with snapshots, pricing/tax/discount calculation, status workflow, employee assignment, delivery-date tracking (fields only — no delivery execution), notes/attachments, search/filter, cancellation, completion (temporary placeholder — see note below), archive.

### Temporary Placeholder — `PATCH /orders/:orderId/complete`
The `/orders/:orderId/complete` endpoint is only a temporary placeholder for this phase. The actual `Delivered` status, proof of delivery, payment validation, and final order completion will be handled by the Delivery Management module. Once the Delivery module is implemented, it will become the only authorized path to mark an order as `Delivered`, and this endpoint will be removed or restricted to administrative override only. Build it now exactly as specified below, but do not treat its current behavior as final.

### Deferred (not built this phase)
Order-item APIs, attachment APIs, status-history APIs, delivery execution APIs, payment APIs, proof-of-delivery capture, outstanding-balance delivery guard — all owned by Delivery Management and Payment Management in future phases. This module only stores the data structures they'll later consume.

---

## Source of Truth
- **Pricing:** `unitPrice`/service snapshot on `orderItems` is captured once at creation from Service Management's active pricing and never recalculated from live catalog data afterward — protects historical accuracy.
- **`paidAmount` / `paymentStatus`** on `orders` are derived exclusively from Payment Management events; this module exposes the fields but never writes them directly from client input.
- **`customerSnapshot`** and **service snapshot** on order items are frozen at creation; the live Customer/Service record may change later without affecting the order.

---

## Order Status Workflow
`Draft → Received → InProgress → Ready → OutForDelivery → Delivered`, with `Cancelled` reachable from any non-terminal status (mandatory reason required). Invalid/out-of-sequence transitions rejected with 409. Every transition writes to `orderStatusHistory` (previousStatus, newStatus, changedBy, changedAt, remarks) — immutable, no update/delete path exposed.

Editable only in `Draft`/`Received`. `Delivered`/`Cancelled` are immutable except through the documented Cancel/Complete/Archive actions.

**Note:** for this phase, `Delivered` is reachable only via `PATCH /orders/:orderId/complete` (the placeholder). No other endpoint may set `status=Delivered`.

---

## Collections

**`orders`** — tenantId*, branchId*, orderNumber* (tenant-unique, atomic counter), customerId*, customerSnapshot*, orderDate, expectedDeliveryDate, actualDeliveryDate, status* (enum above), paymentStatus (derived), assignedEmployee, notes, subtotal, discount, tax, grandTotal, createdBy/updatedBy/createdAt/updatedAt.

**`orderItems`** — tenantId*, branchId*, orderId*, serviceId*, serviceSnapshot*, quantity* (>0), unitPrice* (≥0), discount, tax, lineTotal (computed), processingStatus, notes.

**`orderStatusHistory`** — tenantId*, orderId*, previousStatus*, newStatus*, changedBy*, changedAt*, remarks. Append-only.

**`orderAttachments`** — orderId*, fileName, fileType, fileUrl, uploadedBy, uploadedAt.

*(`*` = required. All order-scoped collections inherit tenantId/branchId from the parent order.)*

**Order numbering:** atomic counter scoped `tenantId+branchId+type='order'` via `findOneAndUpdate`/`$inc` — never `count()` or client-supplied sequence, to guarantee no duplicates under concurrent creation.

**Pricing formulas:**
```
lineTotal   = (qty × unitPrice) - lineDiscount + lineTax
subtotal    = Σ lineTotal
grandTotal  = subtotal - orderDiscount + orderTax
outstanding = grandTotal - paidAmount   (paidAmount from Payments, read-only here)
```

---

## APIs (exactly 9 — no others)

| Method | Path | Purpose |
|---|---|---|
| POST | `/orders` | Create order; validate customer/services/branch/employee; snapshot pricing; generate order number; init status |
| GET | `/orders/:orderId` | Full detail incl. items, status history, attachments |
| PUT | `/orders/:orderId` | Update editable fields (Draft/Received only) |
| GET | `/orders` | Paginated, filtered (status/paymentStatus/branch/customer), sorted, searched |
| PATCH | `/orders/:orderId/status` | Transition status per workflow matrix (excludes Delivered — see below); write history |
| PATCH | `/orders/:orderId/assign` | Assign/change responsible employee (must belong to order's branch) |
| PATCH | `/orders/:orderId/cancel` | Cancel with mandatory reason; from any non-terminal status |
| PATCH | `/orders/:orderId/complete` | **Temporary placeholder.** Marks order `Delivered` directly, sets `actualDeliveryDate`, writes status history. No proof-of-delivery capture, no outstanding-balance guard — both deferred to Delivery Management. To be removed/restricted once Delivery module ships. |
| PATCH | `/orders/:orderId/archive` | Soft-archive; preserve items/snapshots/history |

`PATCH /orders/:orderId/status` must explicitly reject `Delivered` as a target value (409) — that transition is only reachable through `/complete` in this phase, so there is exactly one code path to audit and later replace.

---

## Validation Rules
- Customer must exist in the same tenant; snapshot captured at creation.
- At least one service line item required; service + pricing snapshot captured at creation.
- `orderNumber` unique within tenant (atomic counter, not app-level check).
- Branch must belong to the tenant; assigned employee must belong to that branch.
- Quantity > 0; unit price, subtotal, grandTotal all ≥ 0.
- Discounts/taxes validated against configured tenant settings.
- Status transitions validated against the workflow matrix; invalid = 409; `Delivered` rejected via `/status` (only `/complete` may set it).
- PUT rejected with 409 if order is not Draft/Received.
- `cancelReason` required and non-empty on cancellation.
- Ordinary updates blocked on Completed/Cancelled orders — only Cancel/Complete/Archive actions may touch them.

## Security

### RBAC Matrix

| Action | Owner | Branch Manager | Cashier | Staff |
|---|:---:|:---:|:---:|:---:|
| Create order | ✅ | ✅ | ✅ | ❌ |
| View order / list / search | ✅ | ✅ | ✅ | ✅ (assigned only) |
| Update order (PUT) | ✅ | ✅ | ✅ | ❌ |
| Update status | ✅ | ✅ | ❌ | ✅ (assigned orders only) |
| Assign employee | ✅ | ✅ | ❌ | ❌ |
| Cancel | ✅ | ✅ | ❌ | ❌ |
| Complete (placeholder) | ✅ | ✅ | ❌ | ❌ |
| Archive | ✅ | ✅ | ❌ | ❌ |

- Staff visibility and status-update rights are limited to orders where they are the `assignedEmployee`.
- Tenant isolation and branch-level access enforced on every route.
- Audit log entry on: creation, update, status change, assignment change, cancel, complete, archive — each with acting user, old/new value. The `/complete` audit entry must explicitly tag `source: "placeholder"` so it is identifiable and reportable once Delivery Management takes over this responsibility.
- Status history, and customer/service/pricing snapshots, are immutable — no update/delete path exists at the API layer.
- Archive is soft-delete only; items, snapshots, and full history are preserved.

## Integrations
- **Customer Management:** validate + snapshot customer at creation.
- **Service Management (Catalog):** validate + snapshot service/pricing at creation — never re-read live pricing after order creation.
- **Branch/User Management:** validate branch ownership and employee branch membership.
- **Payment Management:** consumes `paidAmount`/`paymentStatus` via events; this module never writes them directly. Note: the `/complete` placeholder does **not** check `outstandingAmount` — that guard is explicitly deferred to Delivery Management.
- **Notification Management:** triggers on creation, status change, delivery reminders — implemented by Notifications, not here.
- **Audit Service:** logs every mutating action.
- **Reports / Dashboard / Search:** read-availability only, not implemented here.
- **Expense Management:** referenced per system design, not implemented here.
- **Delivery Management (future):** will supersede `/complete`. Design the status-history write and audit entry from `/complete` so they are structurally identical to what Delivery's completion handler will later produce — avoids a data-shape migration when the placeholder is retired.

## Background Jobs
Order confirmation notification, status-change notification, delivery reminders (via `expectedDeliveryDate`), overdue detection, analytics aggregation, search-index sync, report-data sync, audit-log processing — all tenant/branch scoped, none exposed as user-facing APIs.

## Testing
- **Unit:** creation, customer/service validation, item quantity/price validation, pricing/discount/tax math, status transitions (incl. `/status` rejecting `Delivered`), employee assignment, cancel/complete/archive.
- **Integration:** Customer, Service, Payment, Notification, Search, Reports, Branch, User Management, Audit Service hooks.
- **Security:** tenant/branch isolation, unauthorized access/modification/status-change/assignment, RBAC enforcement, history immutability, soft-delete protection.
- **Performance:** creation, retrieval, paginated listing, search, bulk processing, concurrent order creation (verifies atomic numbering holds under load).
- **Placeholder-specific:** confirm `/complete` audit entries are tagged `source: "placeholder"`; confirm `/status` returns 409 when `Delivered` is requested as a target.

## Implementation Sequence
1. Build 4 collections + atomic order-number counter.
2. Order Creation → Profile Management → Customer/Service Association → Item Management → Pricing/Totals.
3. Status Workflow (matrix above, with `/status` blocking `Delivered`) → Employee Assignment → delivery-date fields → Search/Filtering.
4. Implement the 9 APIs exactly as listed, including the `/complete` placeholder with its audit tag.
5. Apply validation, RBAC matrix, audit logging, background jobs, integrations.
6. Run all test categories; verify acceptance criteria.
7. Document, record completion evidence — explicitly note `/complete` as a placeholder pending Delivery Management — and stop.

## Acceptance Criteria
- [ ] Orders created with valid customer, ≥1 service, tenant-unique order number, valid branch/employee.
- [ ] Pricing (line total, subtotal, discount, tax, grand total) calculated correctly and snapshotted immutably.
- [ ] Status workflow enforced exactly per the matrix; invalid transitions rejected; every transition recorded in `orderStatusHistory`.
- [ ] `PATCH /orders/:orderId/status` rejects `Delivered` as a target (409); only `/complete` can set it.
- [ ] `/complete` sets status=Delivered, actualDeliveryDate, writes history, and tags its audit entry `source: "placeholder"`.
- [ ] Customer, service, and pricing snapshots remain unchanged even after the live source record changes.
- [ ] Editable only in Draft/Received; Completed/Cancelled orders protected from ordinary updates.
- [ ] Employee assignment restricted to same-branch employees; changes audited.
- [ ] RBAC enforced exactly per the matrix, including Staff's assigned-orders-only restriction.
- [ ] Tenant and branch isolation provably enforced on every route.
- [ ] Search/filter/sort/pagination work and remain tenant+branch scoped.
- [ ] Cancel/Complete/Archive all preserve full history, items, and snapshots.
- [ ] All listed integrations functional as read/write-availability or event hooks; no extra API, collection, or module added.
- [ ] All four test categories pass.
- [ ] Documentation and completion report explicitly flag `/complete` as temporary, pending replacement by Delivery Management.

## Completion
Verify all acceptance criteria → run full test suite → record created/modified files, test outcomes, known limitations (explicitly listing the `/complete` placeholder as a known, intentional limitation) → update completion report → confirm no scope was added → stop execution.
```

## Validation Rules
- Customer must exist in the same tenant; snapshot captured at creation.
- At least one service line item required; service + pricing snapshot captured at creation.
- `orderNumber` unique within tenant (atomic counter, not app-level check).
- Branch must belong to the tenant; assigned employee must belong to that branch.
- Quantity > 0; unit price, subtotal, grandTotal all ≥ 0.
- Discounts/taxes validated against configured tenant settings.
- Status transitions validated against the workflow matrix; invalid = 409; `Delivered` rejected via `/status` (only `/complete` may set it).
- PUT rejected with 409 if order is not Draft/Received.
- `cancelReason` required and non-empty on cancellation.
- Ordinary updates blocked on **Delivered/Cancelled** orders — only Cancel/Complete/Archive actions may touch them.

...

## Acceptance Criteria
- [ ] Orders created with valid customer, ≥1 service, tenant-unique order number, valid branch/employee.
- [ ] Pricing (line total, subtotal, discount, tax, grand total) calculated correctly and snapshotted immutably.
- [ ] Status workflow enforced exactly per the matrix; invalid transitions rejected; every transition recorded in `orderStatusHistory`.
- [ ] `PATCH /orders/:orderId/status` rejects `Delivered` as a target (409); only `/complete` can set it.
- [ ] `/complete` sets status=Delivered, actualDeliveryDate, writes history, and tags its audit entry `source: "placeholder"`.
- [ ] Customer, service, and pricing snapshots remain unchanged even after the live source record changes.
- [ ] Editable only in **Draft/Received**; **Delivered/Cancelled** orders are protected from ordinary updates.
- [ ] Employee assignment restricted to same-branch employees; changes audited.
- [ ] RBAC enforced exactly per the matrix, including Staff's assigned-orders-only restriction.
- [ ] Tenant and branch isolation provably enforced on every route.
- [ ] Search/filter/sort/pagination work and remain tenant+branch scoped.
- [ ] Cancel/Complete/Archive all preserve full history, items, and snapshots.
- [ ] All listed integrations functional as read/write-availability or event hooks; no extra API, collection, or module added.
- [ ] All four test categories pass.
- [ ] Documentation and completion report explicitly flag `/complete` as temporary, pending replacement by Delivery Management.