# Customer Management UI Design for Flutter

## Purpose

Describe the Flutter frontend design for customer management within Nexoraa CleanSoft mobile, based on the current theme and the Figma-derived ERP mobile UX.

## Scope

- Customer list
- Customer search
- Customer profile
- Customer registration
- Customer status and communication preferences
- Customer notes and address details

## Color Palette

Use the modern light theme app palette exactly:

- Background: `#F3F4F6` or `#FFFFFF`
- Card: `#FFFFFF`
- Primary Accent (Active): `#2563EB`
- Success: `#10B981`
- Warning: `#F59E0B`
- Error: `#EF4444`
- Text Primary: `#111827`
- Text Secondary: `#6B7280`
- Border: `#E5E7EB`

## Screen Inventory

### Customers Screen

- Search bar pinned at top.
- Filter chips for active/inactive/classification.
- Collection of customer cards.
- Empty state prompt with `Add Customer` CTA.
- Quick summary: total customers, active branch customers, outstanding balance.

### Customer Detail Screen

- Header with customer name and status badge.
- Contact information panel.
- Address list panel.
- Recent order snapshot section.
- Notes section with add-note action.
- Action buttons: `Edit`, `New Order`, `Message`.

- Clean white App Bar with back button and "Add New Customer" title.
- "CUSTOMER TYPE" selector using a grid of outlined cards (active card has blue outline, blue text, and light blue background).
- "PERSONAL INFORMATION" form fields using standard light gray outlined borders with prefix icons.
- Fields: Full Name, Mobile Number, Alternate Mobile, Email, etc.
- Action buttons pinned at the bottom: outlined "Cancel" and solid blue "Save Customer" CTA.

## Component Patterns

- Use clean flat white cards (`#FFFFFF`) with subtle borders (`#E5E7EB`) for customer rows and selectors.
- Display contact fields as outlined input fields using `GoogleFonts.outfit`.
- Use pill badges for status and classification.
- Use a full-width CTA button at bottom of forms.
- Include a search input with prefix `Icons.search` and clear button.

## Widget Library

Create shared widgets in `core/widgets` or `features/customers/presentation/widgets`:

- `customer_card.dart`
- `customer_status_chip.dart`
- `customer_profile_tile.dart`
- `customer_action_bar.dart`
- `app_search_input.dart`

## Navigation Flow

- Customers screen should be reachable from the main tab shell.
- Customer detail should deep link from order and payment flows.
- Add/edit should present as push screens.

## File Structure

- `apps/mobile-app/lib/features/customers/presentation/screens/customers_screen.dart`
- `apps/mobile-app/lib/features/customers/presentation/screens/customer_detail_screen.dart`
- `apps/mobile-app/lib/features/customers/presentation/screens/add_customer_screen.dart`
- `apps/mobile-app/lib/features/customers/presentation/widgets/*`

## Acceptance

- Customer list and detail screens should feel consistent with the modern clean light theme.
- Forms and selectors should be prominent and easy to use on small phones.
- Customer records must preserve tenant/branch context visibly.
- This design should allow implementation with minimal guesswork from Figma.
