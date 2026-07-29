# Phase 12 Plan — Notifications

## Scope

Durable in-app notifications, entitled WhatsApp adapter boundary, templates/locales, preferences/consent, scheduled dispatch, idempotent retry/history/read state, callbacks, and source-event consumers.

## Contracts

- **Consumes:** Tenant settings/entitlements, User/Customer recipient contracts, `SVC-JOB-001/002`, source `EVT-*`, `SVC-AUDIT-001`.
- **Produces:** `SVC-NOTIFY-001`, `SVC-NOTIFY-002`, `SVC-NOTIFY-003`, `EVT-NOTIFICATION-DELIVERY-001`.

## Acceptance criteria

1. `FR-NOTIFY-01`: domain facts create durable scoped in-app notifications.
2. `FR-NOTIFY-02`: WhatsApp requires entitlement/template/consent/locale policy.
3. `FR-NOTIFY-03`: provider failure never reverses source action.
4. `FR-NOTIFY-04`: attempt/retry/terminal history is idempotent.
5. `FR-NOTIFY-05`: template/preferences updates are authorized and protected.

## Out

Email/SMS/push (post-MVP), source business mutations, provider guess, marketing campaigns, customer portal.
