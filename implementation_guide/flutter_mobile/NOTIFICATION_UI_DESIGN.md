# Notification UI Design for Flutter

## Purpose

Describe how notification management and in-app communication should look in the Nexoraa CleanSoft Flutter mobile app.

## Scope

- Notification center
- Notification detail
- Notification preferences
- Scheduled reminders
- Customer and employee messages

## Color Palette

Use the modern light theme app palette exactly:

- Background: `#F3F4F6` or `#FFFFFF`
- Card: `#FFFFFF`
- Hero Header/Primary Accent: `#2563EB`
- Dark Card Surface (e.g. Revenue): `#1F2937`
- Success: `#10B981`
- Warning: `#F59E0B`
- Error: `#EF4444`
- Text Primary: `#111827`
- Text Secondary: `#6B7280`
- Border: `#E5E7EB`

## Screen Inventory

### Notifications Screen

- Header with back arrow, "Notifications" title, and "Mark all read" action (blue text).
- Top summary container with blue outline ("3 unread notifications").
- Horizontal list of filter chips: Solid blue for "All", White with gray border for "Orders", "Payments", "Staff", etc.
- List of notification cards (white with subtle light gray border).
- Notification cards have colored prefix icons based on type (blue, green, purple, yellow, red), bold title, description, and time.
- Unread indicator is a small blue dot in the top right of the card.

### Notification Detail Screen

- Header with notification title and status.
- Message preview panel.
- Recipient summary.
- Delivery log section.
- Actions: `Resend`, `Mark as read`, `Cancel scheduled`.

### Preferences Screen

- Toggle controls for channel preferences: In-App, Email, SMS, WhatsApp.
- Quiet hours settings.
- Preferred language picker.
- Save CTA.

## Component Patterns

- Notification cards: solid white flat cards with 1px border and left-aligned colored icon.
- Status chips: small pill text for channel and delivery status.
- Delivery logs: compact list with icon and timestamp.
- Preference toggles: use `SwitchListTile` styled with `AppTheme.primary`.

## Shared Widgets

- `notification_card.dart`
- `notification_status_chip.dart`
- `notification_log_row.dart`
- `notification_preferences_tile.dart`

## Navigation Flow

- Notifications accessible from main shell or user menu.
- Detail screen opens from list items.
- Preferences screen accessible from notification center settings.

## File Structure

- `apps/mobile-app/lib/features/notifications/presentation/screens/notifications_screen.dart`
- `apps/mobile-app/lib/features/notifications/presentation/screens/notification_detail_screen.dart`
- `apps/mobile-app/lib/features/notifications/presentation/screens/notification_preferences_screen.dart`
- `apps/mobile-app/lib/features/notifications/presentation/widgets/*`

## Acceptance

- Notification UI must clearly convey the channel, audience, and delivery state.
- Preference toggles must be easy to manage on mobile.
- This spec should give a Flutter developer enough detail to build the notification center straight from the document.
