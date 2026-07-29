# Public API Contracts

## Status

This catalogue migrates the REST routes explicitly present in the detailed module prompts and completes missing MVP resource surfaces using `ADR-016`. All routes are served by the gateway under `/api/v1`. Paths are stable planning contracts; unresolved policy fields remain blocked by their `OQ-*`.

## Common transport

### Headers

- `Authorization: Bearer <access-token>` except explicitly public authentication/onboarding/recovery routes.
- `X-Correlation-ID` accepted or generated.
- `Idempotency-Key` required for create, payment, refund, lifecycle, retry, export, and other harmful-duplicate commands.
- `If-Match: <version>` required for concurrency-sensitive updates/transitions.
- `Content-Type: application/json`; uploads use the file authorization contract rather than arbitrary multipart domain endpoints.

### Success envelope

```text
{ data: <typed resource>, meta?: { page, pageSize, nextCursor, total?, freshness?, correlationId } }
```

### Error envelope

```text
{
  error: {
    code: stable-machine-code,
    category: validation|unauthenticated|forbidden|not_found|conflict|rate_limit|dependency_unavailable|timeout|internal,
    messageKey: stable-localization-key,
    fields?: [{ field, code }],
    retryable: boolean,
    correlationId: string
  }
}
```

Errors never reveal cross-tenant existence, stack traces, secrets, token material, provider internals, or private collection details.

### List input

`pageSize` defaults to 20 and is capped at 100. Cursor/page, search, filter, and sort fields are endpoint allowlists. Report ranges are capped at 366 days before asynchronous export.

### Shared authorization gates

- `Public`: no session, but rate limiting and anti-enumeration apply.
- `Platform`: platform context only; no implicit tenant data.
- `Tenant`: active tenant membership and permission.
- `Branch`: Tenant plus authorized active branch.
- `Owner`: active tenant Owner.
- `Assigned`: Branch plus work assignment.

## Authentication

| Method/path | Request → response | Gate | Specific errors |
|---|---|---|---|
| `POST /auth/login` | organization + email/mobile + password + device → token/session/access summary | Public | invalid_credentials, locked, tenant_inactive |
| `POST /auth/refresh` | refresh credential/device → rotated token/session pair | Public credential | invalid/reused/revoked/expired session |
| `POST /auth/logout` | current/all/family selector → revocation result | Tenant/Platform session | already_revoked |
| `POST /auth/forgot-password` | organization + email/mobile → generic accepted response | Public | rate_limited only; no existence disclosure |
| `POST /auth/reset-password` | recovery proof + new password → reset/revocation result | Public verified proof | invalid/expired/attempt_limit |
| `POST /auth/change-password` | current + new password → changed/revoked sessions summary | Tenant/Platform | invalid_current, policy_failed |
| `GET /auth/session` | none → current safe session/access summary | Tenant/Platform | session_inactive |

Authentication DTOs never return password/token hashes. Refresh credential transport/storage details follow `ADR-014`; lifetimes remain `OQ-17`.

## Tenant and settings

| Method/path | Request → response | Gate |
|---|---|---|
| `POST /tenants/onboard` | business + Owner + first branch + plan → coordinated onboarding status | Public eligible identity |
| `GET /tenants/current` | none → tenant profile/lifecycle/plan/effective policies | Tenant |
| `PATCH /tenants/current` | allowed profile/branding/billing patch + version → tenant view | Owner |
| `PATCH /tenants/current/activate` | reason/version → lifecycle result | Platform |
| `PATCH /tenants/current/suspend` | reason/version → lifecycle result | Platform |
| `PATCH /tenants/current/reactivate` | reason/version → lifecycle result | Platform |
| `PATCH /tenants/current/deactivate` | reason/version → lifecycle result | Platform/Owner policy |
| `GET /tenants/current/entitlements` | none → effective limits/features/version | Tenant |
| `PATCH /tenants/current/subscription` | plan/status/effective date/version → subscription view | Platform |
| `GET /settings` | optional branch + key groups → effective versioned settings | Tenant |
| `PATCH /settings` | allowlisted tenant setting patch/version → settings view | Owner |
| `POST /settings/reset` | key groups/version → inherited/default settings | Owner |

Specific errors: entitlement_exceeded, invalid_lifecycle, protected_setting, unresolved_policy, version_conflict. Plan/policy contracts are blocked by `OQ-2`, `OQ-4`–`OQ-10`, `OQ-13`.

## Branches

The following routes are preserved from the branch prompt:

| Method/path | Request → response | Gate |
|---|---|---|
| `POST /branches` | profile/address/contact/hours/config → branch view | Tenant `branch:create` |
| `GET /branches` | scoped list query → branch page | Tenant |
| `GET /branches/accessible` | none → minimal allowed branch choices | Tenant |
| `GET /branches/current` | none → trusted active branch | Branch |
| `GET /branches/default` | none → visible tenant default | Tenant |
| `GET /branches/:branchId` | ID → branch details/version/actions | Tenant scoped |
| `PATCH /branches/:branchId` | mutable profile patch/version → branch view | `branch:update` |
| `GET/PUT /branches/:branchId/contact` | none or contact/version → contact view | scoped read/update |
| `GET/PUT /branches/:branchId/address` | none or address/version → address view | scoped read/update |
| `GET/PUT /branches/:branchId/working-hours` | none or canonical hours/timezone/version → hours view | scoped read/update |
| `GET/PATCH /branches/:branchId/configuration` | none or allowlisted overrides/version → effective config | scoped read/update |
| `POST /branches/:branchId/configuration/reset` | keys/version → effective config | `branch:configure` |
| `GET/PUT/DELETE /branches/:branchId/manager` | none or eligible user/version → manager/result | scoped manage |
| `PATCH /branches/:branchId/default` | version → default switch result | Owner |
| `PATCH /branches/:branchId/activate` | reason/version → lifecycle result | Owner |
| `PATCH /branches/:branchId/suspend` | reason/version → lifecycle result | Owner |
| `PATCH /branches/:branchId/reactivate` | reason/version → lifecycle result | Owner |
| `PATCH /branches/:branchId/deactivate` | reason/version → lifecycle result | Owner |
| `POST /branches/:branchId/select` | session/version intent → active context | assigned Tenant user |

Specific errors: branch_limit, branch_not_assigned, default_branch_invariant, manager_ineligible, branch_inactive, version_conflict.

## Users and RBAC

Routes preserved from the user prompt:

| Method/path | Request → response | Gate |
|---|---|---|
| `POST /users` | profile + role + branches + invitation option → user view | scoped `user:create` |
| `GET /users` | scoped query → user page | scoped `user:read` |
| `GET/PATCH /users/me` | none or self-service fields → own safe profile | Tenant |
| `GET/PATCH /users/:userId` | none or mutable profile/version → user view | scoped read/update |
| `PATCH /users/:userId/activate` | reason/version → lifecycle result | scoped manage |
| `PATCH /users/:userId/suspend` | reason/version → lifecycle result | scoped manage |
| `PATCH /users/:userId/reactivate` | reason/version → lifecycle result | scoped manage |
| `PATCH /users/:userId/deactivate` | reason/version → lifecycle result | scoped manage |
| `GET/PATCH /users/:userId/role` | none or role/version → role/access summary | authorized grant |
| `GET/PATCH /users/:userId/permissions` | none or overrides/version → permission summary | authorized grant |
| `POST /users/:userId/permissions/reset` | version → role-derived permissions | authorized grant |
| `GET/PATCH /users/:userId/branches` | none or branch set/primary/version → assignments | authorized grant |
| `PATCH /users/:userId/primary-branch` | eligible branch/version → assignments | scoped manage |
| `PATCH /users/:userId/department` | department/version → user view | scoped manage |
| `PATCH /users/:userId/designation` | designation/version → user view | scoped manage |
| `POST /users/invite` | recipient + profile + role + branches → invitation status | scoped `user:invite` |
| `GET /users/:userId/invitation` | none → safe invitation status | scoped manage |
| `POST /users/:userId/invitation/resend` | version → rotated invitation status | scoped manage |
| `DELETE /users/:userId/invitation` | reason/version → cancellation | scoped manage |
| `POST /users/invitations/accept` | invitation proof + profile/password → activation result | Public valid proof |

Specific errors: grant_exceeds_actor, final_owner, branch_not_allowed, user_limit, invitation_expired/consumed, duplicate_identity, version_conflict.

## Customers

| Method/path | Request → response | Gate |
|---|---|---|
| `POST /customers` | profile/contact/address/preferences → customer view | Branch `customer:create` |
| `GET /customers` | scoped query → customer page | Branch/Tenant read |
| `GET /customers/search` | normalized identifiers/query → safe candidates | Branch/Tenant read |
| `GET /customers/:customerId` | ID → profile/history summary/actions | scoped read |
| `PATCH /customers/:customerId` | mutable patch/version → customer view | scoped update |
| `POST /customers/:customerId/addresses` | address/version → address view | scoped update |
| `PATCH /customers/:customerId/addresses/:addressId` | patch/version → address view | scoped update |
| `POST /customers/:customerId/notes` | minimized note/file refs → note view | scoped permission |
| `GET /customers/:customerId/history` | filters/page → authorized history | scoped read |
| `GET /customers/:customerId/balance` | none → reconciled balance/freshness | scoped financial read |
| `PATCH /customers/:customerId/archive` | reason/version → lifecycle result | scoped update |
| `PATCH /customers/:customerId/restore` | reason/version → lifecycle result | scoped update |

The legacy `/customers/:customerId/loyalty` route is intentionally not in MVP because loyalty is future scope. Errors: duplicate_candidate, customer_archived, privacy_restricted, version_conflict.

## Catalog

| Method/path | Request → response | Gate |
|---|---|---|
| `POST /services` | service/category/duration/availability → service view | Tenant catalog manage |
| `GET /services` | branch-aware query → service page/picker | Tenant/Branch read |
| `GET /services/:serviceId` | ID → service/pricing/availability | scoped read |
| `PATCH /services/:serviceId` | mutable patch/version → service view | catalog manage |
| `POST /services/categories` | category → category view | catalog manage |
| `PATCH /services/categories/:categoryId` | patch/version → category view | catalog manage |
| `POST /item-categories` | item category → item category view | catalog manage |
| `PATCH /item-categories/:categoryId` | patch/version → item category view | catalog manage |
| `PATCH /services/:serviceId/pricing` | effective pricing/version → pricing view | catalog pricing manage |
| `PATCH /services/:serviceId/branches` | branch availability/version → service view | catalog manage |
| `PATCH /services/:serviceId/archive` | reason/version → lifecycle result | catalog manage |
| `PATCH /services/:serviceId/restore` | reason/version → lifecycle result | catalog manage |

Errors: duplicate_code, invalid_effective_range, overlapping_price, branch_not_allowed, unresolved_tax_policy, version_conflict.

## Orders and delivery

| Method/path | Request → response | Gate |
|---|---|---|
| `POST /orders` | customer/walk-in + lines + notes + expected time + assignment → authoritative order | Branch order create |
| `GET /orders` | scoped filters/page → order page | Branch/Tenant read |
| `GET /orders/:orderId` | ID → order/items/history/settlement/actions | scoped read |
| `PATCH /orders/:orderId` | allowlisted mutable patch/version → order view | scoped update |
| `PATCH /orders/:orderId/status` | target state/notes/version → order + transition | Assigned/scoped transition |
| `PATCH /orders/:orderId/assign` | eligible users/version → assignment | scoped assign |
| `POST /orders/:orderId/cancel` | reason/version → cancelled order | scoped cancel |
| `POST /orders/:orderId/complete` | version → completed order | scoped complete |
| `PATCH /orders/:orderId/archive` | reason/version → archived view | scoped archive |
| `POST /orders/:orderId/delivery/assign` | assignee/type/schedule/version → delivery view | scoped delivery manage |
| `POST /orders/:orderId/delivery/complete` | receiver + proof refs + version → completed delivery/order | Assigned delivery |

Create response returns server-calculated snapshots/totals; clients never submit trusted totals. Errors: invalid_transition, stale_order, service_unavailable, assignee_ineligible, outstanding_delivery_blocked, unresolved_financial_policy.

## Payments and receipts

| Method/path | Request → response | Gate |
|---|---|---|
| `POST /payments` | order + method + money + reference → payment/settlement | Branch payment record |
| `GET /payments` | scoped filters/page → payment page | scoped financial read |
| `GET /payments/:paymentId` | ID → payment/transactions/refunds/actions | scoped read |
| `PATCH /payments/:paymentId` | only explicitly mutable pre-final fields/version → payment | scoped update |
| `POST /payments/:paymentId/verify` | provider/manual verification proof → verified payment | scoped verify |
| `POST /payments/:paymentId/refund` | money + reason + approval → additive refund | approved refund |
| `GET /payments/:paymentId/receipt` | none → immutable receipt metadata/content intent | scoped read |
| `GET /payments/order/:orderId` | none → settlement/payment history | scoped read |

Errors: duplicate_payment, amount_exceeds_policy, currency_mismatch, payment_finalized, refund_ineligible, approval_required, unresolved_financial_policy.

## Expenses and cash registers

| Method/path | Request → response | Gate |
|---|---|---|
| `POST /expenses` | category + money + business date + evidence → expense | Branch expense create |
| `GET /expenses` | branch/date/category/status page → expenses | scoped read |
| `GET /expenses/:expenseId` | ID → expense/actions | scoped read |
| `PATCH /expenses/:expenseId` | permitted pre-final patch/version → expense | scoped update |
| `POST /expenses/:expenseId/correct` | additive correction + reason/approval → linked correction | approved correction |
| `POST /expense-categories` | category → category | Owner/manager policy |
| `PATCH /expense-categories/:categoryId` | patch/version → category | scoped manage |
| `POST /cash-registers/open` | branch + business date + opening cash → register | Branch cashier |
| `GET /cash-registers/current` | branch → current register | Branch |
| `GET /cash-registers/:registerId` | ID → register/movements/reconciliation | scoped read |
| `POST /cash-registers/:registerId/movements` | addition/withdrawal + money + reason → movement | approved cashier/manager |
| `POST /cash-registers/:registerId/close` | actual cash + variance explanation + version → close evidence | Branch cashier/approval |
| `POST /cash-registers/:registerId/reopen` | reason + approval + version → reopened correction state | approved role |

Errors: register_already_exists, register_not_open, business_date_mismatch, variance_reason_required, approval_required. Final policy blocked by `OQ-9`, `OQ-10`.

## Notifications

| Method/path | Request → response | Gate |
|---|---|---|
| `POST /notifications` | approved internal/manual intent → notification | authorized send |
| `GET /notifications` | recipient/channel/status/page → notification page | scoped recipient/admin |
| `GET /notifications/:notificationId` | ID → safe notification/history | scoped read |
| `POST /notifications/send` | existing notification/version → dispatch status | authorized internal/admin |
| `POST /notifications/:notificationId/retry` | reason/version → retry state | scoped operator |
| `GET /notifications/templates` | filters → template page | scoped manage/read |
| `PATCH /notifications/templates/:templateId` | allowlisted content/version → template | scoped manage |
| `GET/PATCH /notifications/preferences` | none or preferences/consent version → effective preferences | own/scoped admin |
| `PATCH /notifications/:notificationId/read` | version → read state | recipient |

MVP channels are in-app and entitled WhatsApp. Email/SMS/push details preserved in legacy docs remain post-MVP. Errors: channel_not_entitled, consent_required, template_unapproved, provider_unavailable, terminal_delivery.

## Files

| Method/path | Request → response | Gate |
|---|---|---|
| `POST /files/upload-authorizations` | purpose + name/type/size/checksum → private upload/quarantine instructions | scoped domain permission |
| `POST /files/:fileId/complete` | upload proof/checksum → scanning/pending status | same scope |
| `GET /files/:fileId/access` | purpose → short-lived read authorization | authorized domain read |
| `DELETE /files/:fileId` | reason/version → deletion/retention result | authorized + policy |

Errors: type/size/purpose_invalid, scan_failed, quarantined, retention_blocked, file_not_found_in_scope. Final limits/provider blocked by `OQ-20`.

## Audit

| Method/path | Request → response | Gate |
|---|---|---|
| `GET /audit` | scope/action/actor/target/date/page → audit page | Owner/security/platform separate |
| `GET /audit/:auditId` | ID → immutable evidence | separately authorized |
| `POST /audit/exports` | authorized query → async export status | separately authorized |

Audit writes are internal through `SVC-AUDIT-001`, never a general public route.

## Search, reports, dashboard

| Method/path | Request → response | Gate |
|---|---|---|
| `GET /search` | domain/query/branch/filter/page → scoped results + freshness | Tenant/Branch |
| `GET /reports/:reportKey` | scope/date/filter → report + lineage/freshness | report permission |
| `POST /reports/:reportKey/exports` | scope/date/filter/format=csv → async export status | export permission |
| `GET /reports/exports/:exportId` | ID → pending/ready/expired access | original authorized requester/scope |
| `GET /dashboard` | branch/date → role-allowed cards + freshness | Tenant/Branch |

Errors: invalid_filter/sort/range, projection_unavailable, export_expired, report_not_allowed, stale_projection (warning or error by report).

## Internal operational routes

Health/readiness/metrics and provider callbacks are not tenant business APIs:

- `GET /health/live` and `GET /health/ready`: infrastructure access policy.
- `POST /callbacks/whatsapp/:provider`: signed/replay-protected provider callback; exact provider pending `OQ-19`.
- Replay, projection rebuild, and dead-letter operations are internal operator contracts (`SVC-JOB-002`, `SVC-SEARCH-002`, `SVC-REPORT-003`), not public endpoints.

