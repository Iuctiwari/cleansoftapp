# Order Management UI Design for Flutter

## Purpose

Provide the exact mobile UI design guidance for order creation, order detail, order workflow, customer association, and order search in Nexoraa CleanSoft Flutter.

## Scope

- Order list
- Order creation flow
- Order detail
- Order status updates
- Customer/service selection
- Price and tax summary


## Screen Inventory

### Orders Screen

- Clean white AppBar with "Orders" title and a solid blue "+ New" button on the right.
- Search bar directly below the app bar (full width, gray outline, right filter icon).
- Horizontal scroll filter chips (Solid blue for active filter like "All", outlined white for "Pending", "Processing", "Ready").
- List of order cards (white, flat, 1px border).
- Order cards feature a prominent colored circle avatar with customer initials.
- Order cards display Customer Name, optional red URGENT pill, Order ID, items summary, time, right-aligned Price, and right-aligned Status pill (Green for Ready, Blue for Processing, Yellow for Pending, Gray for Completed).

### Order Detail Screen

- Top summary banner with order number, customer, branch, status.
- Customer snapshot panel.
- Service items list with quantity, rate, discount, tax, line total.
- Order totals card.
- Status history timeline.
- Action buttons: `Change Status`, `Add Note`, `Create Payment`.

### Create Order Screen

- Step-based flow or full form.
- Select existing customer or add new customer.
- Select branch and service items.
- Show pricing snapshot for each selected service.
- Display subtotal, discount, tax, grand total.
- Required validations with inline error messages.
- Primary `Place Order` CTA.

## Component Patterns

- Use clean white order cards with initial avatars and right-aligned status pills.
- Data rows should use label/value pairs with `textSecondary` labels.
- Use horizontal scroll chips for status filters.
- Order totals should be highlighted in a separate elevated card.

## Shared Widgets

- `order_card.dart`
- `order_status_chip.dart`
- `order_summary_row.dart`
- `order_item_tile.dart`
- `order_timeline.dart`

## Navigation Flow

- Orders should be accessible from the main tab shell.
- Order creation should push a full-screen form.
- Order detail should be reachable from list cards and related customer/payment screens.

## File Structure

- `apps/mobile-app/lib/features/orders/presentation/screens/orders_screen.dart`
- `apps/mobile-app/lib/features/orders/presentation/screens/order_detail_screen.dart`
- `apps/mobile-app/lib/features/orders/presentation/screens/create_order_screen.dart`
- `apps/mobile-app/lib/features/orders/presentation/widgets/*`

## Acceptance

- Order creation must follow the same clean light theme and flat field styles.
- Order list and detail UI must make order status, customer, and total visible at a glance.
- The design should directly support the backend order workflow requirements from `PHASE_15_ORDERS`.
