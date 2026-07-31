# Branch Management UI Design for Flutter

## Purpose

Define the mobile UI design for branch selection, branch profile, branch settings, and branch activity in Nexoraa CleanSoft.

## Scope

- Branch list
- Branch selection
- Branch detail
- Branch profile updates
- Branch status and working hours

## Visual Language

- Soft rounded cards.
- Spacious layout with generous padding.
- Dark premium surfaces with subtle gradients.
- Clean label/value rows.
- Minimal iconography.
- Material 3-inspired modal panels.



## Screen Inventory

### Branch List Screen

- Search field at top for branch names.
- Branch summary cards with location, status, and map pin.
- Action badge for active/staged/suspended status.
- Add branch CTA floating button.

### Branch Detail Screen

- Header with branch name, branch code, and status badge.
- Contact panel with address, phone, email.
- Operating hours panel.
- Assigned users summary.
- Capacity or throughput metric card.
- Action buttons for `Edit`, `Select`, `Suspend`, `Activate`.

### Branch Form Screen

- Input sections for branch basic details, contact, and hours.
- Toggle rows for active status and branch assignment.
- Save CTA pinned at bottom.

## Widget Patterns

- Branch cards: rounded rectangles with left accent marker.
- Status chips: pill badges with success, warning, error, or neutral color.
- Row tiles: icon plus label/value pair.
- Section headers: subtle divider and title label.
- Action footer: large full-width button for strong actions.

## Navigation Flow

- Branch list available from settings or multi-branch selector.
- Branch detail opens from a branch card.
- Branch form opens from detail or top-level add action.

## File Structure

- `apps/mobile-app/lib/features/branches/presentation/screens/branch_list_screen.dart`
- `apps/mobile-app/lib/features/branches/presentation/screens/branch_detail_screen.dart`
- `apps/mobile-app/lib/features/branches/presentation/screens/edit_branch_screen.dart`
- `apps/mobile-app/lib/features/branches/presentation/widgets/*`

## Acceptance

- Branch screens must feel part of the same premium enterprise design language.
- Branch status and critical contact information should be easy to scan.
- The design should avoid complex business data and emphasize clean structure.
