# UI/UX Design Index

This index organizes the service-specific mobile UI design artifacts for Nexoraa CleanSoft. Each file describes the Flutter screen structure, theme, widget patterns, and implementation-ready guidance for a service or domain.

## Design Artifacts

- `AUTH_UI_DESIGN.md` — Authentication and password recovery screens.
- `CUSTOMER_UI_DESIGN.md` — Customer list, profile, registration, and preferences.
- `SERVICE_CATALOG_UI_DESIGN.md` — Service catalog, categories, pricing, and branch availability.
- `ORDER_UI_DESIGN.md` — Order creation, order details, order list, and workflow.
- `PAYMENT_UI_DESIGN.md` — Payment collection, history, refunds, and receipts.
- `REPORT_UI_DESIGN.md` — Reports list, previews, filters, and exports.
- `NOTIFICATION_UI_DESIGN.md` — In-app notification center, detail, and preferences.
- `DASHBOARD_UI_DESIGN.md` — Dashboard KPIs, quick actions, and role-aware home screen.
- `BRANCH_UI_DESIGN.md` — Branch list, branch profile, and branch settings.
- `USER_UI_DESIGN.md` — Tenant users, roles, permissions, and profiles.
- `TENANT_UI_DESIGN.md` — Tenant overview, profile, and settings.
- `EXPENSE_UI_DESIGN.md` — Expense capture, list, detail, and categories.
- `SEARCH_UI_DESIGN.md` — Global search, filter, and results experience.
- `UI_DESIGN_SPECIFICATION.md` — Central design system specification and implementation rules.
- `FLUTTER-STRUCTURE-RECOMMENDATIONS.md` — Recommended Flutter app structure and feature boundaries.
- `FRONTEND-DESIGN-PROMPT.md` — Prompt artifact for frontend design planning and implementation handoff.

## How to Use

1. Read `FRONTEND-DESIGN-PROMPT.md` first to understand the planning intent.
2. Use `FLUTTER-STRUCTURE-RECOMMENDATIONS.md` to map service UI files into the Flutter app architecture.
3. Implement or refine service screens using the matching UI design artifact for that domain.
4. Keep theme and shared widget patterns consistent across all service screens.

## Notes

- The mobile design artifacts are scoped to the existing `apps/mobile-app` Flutter app.
- These files are planning and handoff documentation, not production code.
- Maintain the current app theme and existing auth flow while extending service features.
