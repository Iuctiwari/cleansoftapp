# Service Catalog UI Design for Flutter

## Purpose

Define the mobile UI design for managing service catalog entries, service categories, pricing, duration, and branch availability in the Nexoraa CleanSoft Flutter app.

## Scope

- Service list
- Service detail
- Service creation/edit
- Category selection
- Pricing and duration management
- Branch availability indicators

## Color Palette

Use the modern light theme app palette exactly:

- Background: `#F3F4F6` or `#FFFFFF`
- Card: `#FFFFFF`
- Primary Accent: `#2563EB`
- Success: `#10B981`
- Warning: `#F59E0B`
- Error: `#EF4444`
- Text Primary: `#111827`
- Text Secondary: `#6B7280`
- Border: `#E5E7EB`

## Screen Inventory

### Services Screen

- Search bar for service name or code.
- Filter chips for category, branch, status.
- List of service cards with name, category, price, duration, and status.
- `New Service` floating action button.

### Service Detail Screen

- Header with service name and active/archived badge.
- Pricing summary card.
- Duration and tax configuration panel.
- Branch assignment chips.
- Edit button.

### Add / Edit Service Screen

- Input fields for name, code, category, base price, processing time.
- Toggle controls for branch assignments and status.
- Pricing history review collapsed section.
- Save CTA pinned at bottom.

## Component Patterns

- Service cards: background `backgroundCard`, left accent icon, right quick action chevron.
- Inline data rows: label and value pairs using primary/secondary text.
- Branch chips: pill badges with active/inactive styling.
- Pricing preview: card with subtotal, tax, and effective price.

## Shared Widgets

- `service_card.dart`
- `service_status_chip.dart`
- `service_detail_row.dart`
- `service_branch_chip.dart`
- `price_summary_card.dart`

## Navigation Flow

- Service catalog available from the main app shell.
- Service detail screen reachable from service list.
- Add/edit screens should push from the detail or list CTA.

## File Structure

- `apps/mobile-app/lib/features/services/presentation/screens/services_screen.dart`
- `apps/mobile-app/lib/features/services/presentation/screens/service_detail_screen.dart`
- `apps/mobile-app/lib/features/services/presentation/screens/add_service_screen.dart`
- `apps/mobile-app/lib/features/services/presentation/widgets/*`

## Acceptance

- Service screens must use the same modern light theme and card style as the existing Flutter app.
- Service list and detail UI should make business context and branch availability easy to scan.
- The design should reflect the Figma mobile approach: minimal clutter, clear labels, and mobile-first controls.
