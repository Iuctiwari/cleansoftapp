# Tenant Management UI Design for Flutter

## Purpose

Define the mobile UI design for tenant onboarding, tenant profile, business settings, and tenant-level summary in Nexoraa CleanSoft.

## Scope

- Tenant overview
- Business profile
- Tenant settings hub
- Tenant status and plan information

## Visual Language

- Premium enterprise styling.
- Clear section cards.
- Smart typography and spacing.
- Neutral backgrounds with accent dividers.
- Minimal, focused information density.

## Color System

Use the modern light theme app palette exactly:

- Background: `#F3F4F6` or `#FFFFFF`
- Card: `#FFFFFF`
- Primary: `#2563EB`
- Success: `#10B981`
- Warning: `#F59E0B`
- Error: `#EF4444`
- Text Primary: `#111827`
- Text Secondary: `#6B7280`
- Border: `#E5E7EB`

## Screen Inventory

### Tenant Overview Screen

- Hero card with tenant name and status.
- Summary metrics for branches, users, active services, orders.
- Quick action grid for `Manage Branches`, `Manage Users`, `Billing`.
- Support card for tenant help.

### Tenant Profile Screen

- Business profile card with address and contact.
- Legal and tax information panels.
- Subscription or plan details card.
- Edit button and save CTA.

### Tenant Settings Screen

- List tiles for tenant-wide configuration categories.
- Toggle rows for feature flags and preferences.
- Info tiles for audit, billing, and support.

## Widget Patterns

- Overview tiles: large cards with icon, title, value.
- Settings rows: label, current value, chevron.
- Status chips: pill badges for active/inactive.
- Detail rows: two-column label/value pairs.

## Navigation Flow

- Tenant overview accessible from the main dashboard or admin section.
- Profile and settings accessible by deep link from overview.
- Edit actions open forms or bottom sheets.

## File Structure

- `apps/mobile-app/lib/features/tenants/presentation/screens/tenant_overview_screen.dart`
- `apps/mobile-app/lib/features/tenants/presentation/screens/tenant_profile_screen.dart`
- `apps/mobile-app/lib/features/tenants/presentation/screens/tenant_settings_screen.dart`
- `apps/mobile-app/lib/features/tenants/presentation/widgets/*`

## Acceptance

- Tenant UI should feel authoritative and manage enterprise information clearly.
- Data panels should be easy to distinguish with soft elevation.
- The design should support mobile-first responsiveness and easy navigation.
