# Phase 17 Plan — Flutter Mobile

## Scope

Android/iOS role-specific navigation and workflows for in-scope APIs; secure session storage/renewal/revocation; tenant/branch selection; customers/catalog/orders/payments/expenses/notifications/reports/dashboard/search/settings/audit views as authorized; localization, accessibility, responsive device behavior, explicit offline/retry.

## Contracts

- **Consumes:** public routes in `API-CONTRACTS.md` used by the mobile workflows and stable public errors.
- **Produces:** no authoritative domain contract; mobile telemetry/compatibility evidence only.

## Acceptance criteria

1. `FR-MOBILE-01`: role workflows use versioned gateway contracts.
2. `FR-MOBILE-02`: refresh credential uses approved secure storage and no secrets enter assets/logs.
3. `FR-MOBILE-03`: offline/retry is explicit and no financial write silently succeeds offline.
4. `FR-MOBILE-04`: locale/currency/timezone/terminology presentation is correct.
5. `FR-MOBILE-05`: accessibility, responsive, crash-free, navigation, and compatibility gates pass.

## Out

Web client, customer portal, employee-only separate app, backend rules, offline financial authority, unapproved state/storage packages.

