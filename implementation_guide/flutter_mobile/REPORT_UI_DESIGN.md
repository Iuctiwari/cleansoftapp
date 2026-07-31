# Report UI Design for Flutter

## Purpose

Describe the mobile UI design for report browsing, filters, exports, and summary dashboards in Nexoraa CleanSoft.

## Scope

- Report list
- Report detail / preview
- Report filters
- Export actions
- Summary cards

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

### Reports Screen

- Search bar for report title.
- Filter chips for report type, date range, branch.
- Grid or list of report cards.
- Each card shows report name, last run, and quick action icons.
- Button for `Run Report` or `Export`.

### Report Detail Screen

- Header with report title and status.
- Summary metrics row.
- Filter tags and applied criteria.
- Preview section with key values and data highlights.
- Actions: `Download CSV`, `Send`, `Refresh`.

## Component Patterns

- Report cards:
  - Use bordered cards with icon, title, and last-run text.
- Summary tiles:
  - Small cards with metric value, label, and trend icon.
- Filter chips:
  - Toggle chips with active/inactive states.
- Preview rows:
  - Use label/value pairs and mini progress bars if needed.

## Shared Widgets

- `report_card.dart`
- `report_metric_tile.dart`
- `report_filter_chip.dart`
- `report_preview_row.dart`

## Navigation Flow

- Reports accessible from the main app shell.
- Report detail pushes from selected report cards.
- Filter and export actions occur in-context on the report screen.

## File Structure

- `apps/mobile-app/lib/features/reports/presentation/screens/reports_screen.dart`
- `apps/mobile-app/lib/features/reports/presentation/screens/report_detail_screen.dart`
- `apps/mobile-app/lib/features/reports/presentation/widgets/*`

## Acceptance

- Report UI must present business metrics clearly and support the Figma-derived dashboard style.
- Report filters must be easy to apply on mobile.
- Export actions must be visible and accessible.
- The design should be complete enough for Flutter implementation directly from this document.
