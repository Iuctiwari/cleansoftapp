# Payment Management UI Design for Flutter

## Purpose

Define the mobile UI design for payment collection, payment history, receipts, and outstanding balance management in Nexoraa CleanSoft.

## Scope

- Payment creation
- Payment listing
- Payment detail
- Refund flow
- Outstanding balance view
- Receipt generation

## Color Palette

Use the modern light theme app palette exactly:

- Background: `#F3F4F6` or `#FFFFFF`
- Card: `#FFFFFF`
- Primary Accent: `#2563EB`
- Dark Card Surface: `#1F2937`
- Success: `#10B981`
- Warning: `#F59E0B`
- Error: `#EF4444`
- Text Primary: `#111827`
- Text Secondary: `#6B7280`
- Border: `#E5E7EB`

## Screen Inventory

### Payments Screen

- Clean white App Bar with "Payments" title.
- Top summary panel with a Green solid card for "TODAY COLLECTED" and an outlined white card with red border for "OUTSTANDING".
- Horizontal list of filter chips (Solid blue for active filter "History", outlined white for "Outstanding").
- List of payment cards (white, flat, 1px border) with colored prefix icons and bold green/red text for amounts.

### Payment Detail Screen

- Header with payment number, status badge, and customer name.
- Payment summary card with amount, method, receipt, date.
- Order reference row with link to order detail.
- Transaction notes panel.
- Refund action if refund is permitted.

### Collect Payment Screen

- Form fields: customer, order, amount, payment method, reference, notes.
- Inline outstanding balance summary.
- Primary CTA `Submit Payment`.
- Validation for `amount > 0` and required order/customer.

### Refund Screen

- Refund amount input with max allowed message.
- Reason text area.
- Confirm CTA with warning copy.
- Success state card after refund.
### Cash Register Screen

- Clean white App Bar with "Cash Register" title.
- Large centered lock icon with "Register is Closed" title.
- Outlined input field for "Opening Cash Balance (Rs.)".
- Solid blue "Open Register" CTA button.

## Widget Patterns

- Payment cards:
  - Use flat white cards with 1px border.
  - Show colored amount (+Rs. 850 in green, Rs. 1,400 in red), colored prefix icon, and customer name.
- Status badges:
  - `success` for settled, `warning` for pending, `error` for refunded.
- Summary rows:
  - Label/value pairs with `textSecondary` label and `textPrimary` value.
- Form fields:
  - Use `AuthTextField` style for input consistency.
- Primary CTA:
  - Use full-width `AuthButton` style with `primary` accent.

## Navigation Flow

- Payments are reachable from the main app shell and from order detail screens.
- Payment detail is accessible from payment list cards.
- Collect payment screen pushes from a FAB or action button.
- Refund flow should appear as a modal or full screen from payment detail.

## File Structure

- `apps/mobile-app/lib/features/payments/presentation/screens/payments_screen.dart`
- `apps/mobile-app/lib/features/payments/presentation/screens/payment_detail_screen.dart`
- `apps/mobile-app/lib/features/payments/presentation/screens/collect_payment_screen.dart`
- `apps/mobile-app/lib/features/payments/presentation/screens/refund_payment_screen.dart`
- `apps/mobile-app/lib/features/payments/presentation/widgets/*`

## Acceptance

- Payment UI must match the app's modern light theme and component styling.
- Payment list and detail screens should make amounts and customer context explicit.
- Outstanding balance and refund information must be visible and safe.
- This document must be sufficient for a developer to implement payment flows without additional design discovery.
