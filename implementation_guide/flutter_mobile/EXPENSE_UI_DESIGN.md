# Expense Management UI Design for Flutter

## Purpose

Describe the Flutter UI design for expense capture, expense list, expense detail, and expense reporting in Nexoraa CleanSoft.

## Scope

- Expense dashboard
- Expense creation
- Expense list
- Expense detail
- Expense categories

## Visual Language

- Clean, structured financial surfaces.
- Soft information cards.
- Accent colors for expense type and approval status.
- Minimal typography with strong numeric hierarchy.

## Color System

Maintain the modern light theme app palette exactly:

- Background: `#F3F4F6` or `#FFFFFF`
- Card: `#FFFFFF`
- Primary Accent: `#2563EB`
- Hero Card (Expenses): `#F59E0B` (Orange/Yellow)
- Success: `#10B981`
- Warning: `#F59E0B`
- Error: `#EF4444`
- Text Primary: `#111827`
- Text Secondary: `#6B7280`
- Border: `#E5E7EB`

## Screen Inventory

### Expenses Screen

- Clean white App Bar with "Expenses" title and solid blue "+ Add" button.
- Large orange/yellow hero card for "THIS MONTH" total expenses.
- Horizontal list of filter chips (Solid blue for active filter "All", outlined white for "Utilities", "Supplies", etc.).
- Expense list cards (white, flat, 1px border) with colorful icons in rounded boxes.
- Red text for expense amounts right-aligned on the cards.

### Expense Detail Screen

- Header with expense title, amount, and status badge.
- Transaction summary card.
- Vendor and category panel.
- Notes and attachment section.
- Approval actions.

### Add/Edit Expense Screen

- Form inputs for amount, date, category, vendor, notes.
- Receipt upload placeholder.
- Save CTA pinned at bottom.

## Widget Patterns

- Expense cards: flat white row with leading colorful icon in a rounded box and trailing red amount.
- Status chips: discrete pill labels.
- Summary tiles: compact metrics with label and numeric value.
- Form groups: section headings with subtle dividers.

## Navigation Flow

- Expenses accessible from the finance or reports shell.
- Detail navigates from list cards.
- Add/edit opens a full-screen form.

## File Structure

- `apps/mobile-app/lib/features/expenses/presentation/screens/expenses_screen.dart`
- `apps/mobile-app/lib/features/expenses/presentation/screens/expense_detail_screen.dart`
- `apps/mobile-app/lib/features/expenses/presentation/screens/add_expense_screen.dart`
- `apps/mobile-app/lib/features/expenses/presentation/widgets/*`

## Acceptance

- Expense screens must maintain a financial app feel without clutter.
- Amounts and approval statuses should be immediately scannable.
- The design should support a production-ready expense management flow.
