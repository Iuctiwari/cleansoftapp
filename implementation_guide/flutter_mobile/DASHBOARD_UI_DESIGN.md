# Dashboard UI Design for Flutter

## Purpose

Define the mobile dashboard UI design that brings core business metrics and service health into the Nexoraa CleanSoft Flutter app.

## Scope

- Dashboard home screen
- KPI cards
- Quick action widgets
- Trend charts / summaries
- Role-aware dashboard views


## Screen Inventory

### Dashboard Screen

- Hero header (vivid blue) with greeting, user name, role, notification bell, and circular decorative pattern.
- Search bar seamlessly integrated inside the blue header.
- Dark theme card (`#1F2937`) overlapping the blue header for "TODAY'S REVENUE" with a green percentage pill.
- Grid of KPI cards (white, flat, 1px gray border): Today's Orders, Payments, Expenses, Outstanding, Ready, Delayed. Each with a colored icon (blue, green, yellow, red).
- Branch Performance section with progress bars.
- Quick action grid for core modules: New Order, Payments, Reports, Assign.
- Recent Orders list with colored initial avatars and status pills.
- Bottom navigation bar with white background and blue active state.

### Quick Action / Shortcut Panel

- Icon-based buttons for immediate navigation.
- Use `AppTheme.primary` and gradient highlights.
- Include `New Order`, `New Customer`, `View Reports`, `Collect Payment`.

## Component Patterns

- KPI cards: small rectangular cards with metric, label, and subtle trend indicator.
- Summary cards: large cards for revenue and pending totals.
- Quick action tiles: icon, label, and accent background.
- Activity timeline: compact rows with event type and timestamp.

## Shared Widgets

- `dashboard_kpi_card.dart`
- `dashboard_quick_action.dart`
- `dashboard_summary_card.dart`
- `dashboard_activity_row.dart`

## Navigation Flow

- Dashboard is the main authenticated landing screen.
- Quick actions route to the corresponding feature screens.
- Detailed KPI cards may open corresponding list/detail screens.

## File Structure

- `apps/mobile-app/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `apps/mobile-app/lib/features/dashboard/presentation/widgets/*`

## Acceptance

- Dashboard must use the app theme and feel consistent with the current home screen.
- KPIs and quick actions should be readable at a glance.
- This design should directly support later implementation of a role-aware dashboard shell.
