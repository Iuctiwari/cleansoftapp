# Search UI Design for Flutter

## Purpose

Define the mobile UI design for search experiences in Nexoraa CleanSoft, including global search, filtered search, and search results.

## Scope

- Global search input
- Search results screen
- Search filters
- Search history
- Search suggestions

## Visual Language

- Rounded search bar with soft background.
- Clear separation between search controls and results.
- Minimal, data-focused result cards.
- Accent highlights for active filters.

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

### Search Landing Screen

- Large rounded search field.
- Recent searches list with clear affordance.
- Suggested categories or entities.
- Quick filter chips.

### Search Results Screen

- Search field pinned at top.
- Result tabs for `Customers`, `Orders`, `Payments`, `Services`, `Reports`.
- Result cards with title, subtitle, metadata.
- Empty state with illustrative placeholder.

### Advanced Search Panel

- Filter groups for date, status, branch, category.
- Toggle rows and tag chips.
- Apply/Reset buttons.

## Widget Patterns

- Search input: rounded container with icon and clear button.
- Result cards: compact, full-width cards with minimal text.
- Filter chips: active/inactive styling with outline.
- History rows: subtle background and trailing delete icon.

## Navigation Flow

- Search accessible from the top app bar or shell quick link.
- Results update in place as user types.
- Advanced filters open as a bottom sheet or panel.

## File Structure

- `apps/mobile-app/lib/features/search/presentation/screens/search_landing_screen.dart`
- `apps/mobile-app/lib/features/search/presentation/screens/search_results_screen.dart`
- `apps/mobile-app/lib/features/search/presentation/widgets/*`

## Acceptance

- Search UI must be responsive and easy to use on small phones.
- Filters and results must be clearly separated.
- This design should read as a polished discovery experience.
