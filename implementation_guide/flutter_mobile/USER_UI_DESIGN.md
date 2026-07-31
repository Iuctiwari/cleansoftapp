# User Management UI Design for Flutter

## Purpose

Describe the mobile UI design for tenant user and staff management in Nexoraa CleanSoft, including user lists, profiles, roles, and permissions.

## Scope

- User directory
- User profile
- Role and permission summary
- Invite user flow
- User status management

## Visual Language

- Clean, structured light theme surfaces.
- Strong typography hierarchy.
- Clean white list rows with subtle borders.
- Colorful prefix icons for navigation rows.
- Right chevrons for navigation cues.



## Screen Inventory

### More Tab / Settings Menu Screen

- Clean white App Bar with "More" title.
- Profile Summary Card at the top (flat white card with blue circular initials avatar, name, email, and role/branch).
- Section headers in gray small caps (e.g., FINANCE, ANALYTICS, BUSINESS).
- Navigation list cards for each section (flat white, 1px border).
- Each list card features a colored prefix icon (e.g., green for payments, yellow for expenses) and a right chevron.

### User Directory Screen

- Search bar for name, email, or role.
- Filter chips for active, invited, suspended.
- User tiles with avatar, name, role, and branch.
- Quick action menu on each row.
- Add user FAB.

### User Detail Screen

- Profile summary with avatar.
- Contact panel for email and phone.
- Role and branch assignments.
- Permissions summary with compact tags.
- Action buttons for `Edit`, `Reset Password`, `Deactivate`.

### Invite/Edit User Screen

- Form with name, email, role, branches.
- Role picker and permission summary.
- Save CTA pinned at bottom.
- Note area for invitation status or activation steps.

## Widget Patterns

- Avatar tiles: circular initials (e.g. blue background, white text) or image.
- Permission tags: small pill chips in primary or secondary color.
- Section cards: flat white surfaces with subtle 1px gray borders.
- Navigation rows: colorful prefix icons in rounded squares, with trailing right chevrons.

## Navigation Flow

- User directory reachable from admin dashboard.
- Detail opens from directory row.
- Invite/edit screens pushed from detail or directory header.

## File Structure

- `apps/mobile-app/lib/features/users/presentation/screens/user_directory_screen.dart`
- `apps/mobile-app/lib/features/users/presentation/screens/user_detail_screen.dart`
- `apps/mobile-app/lib/features/users/presentation/screens/invite_user_screen.dart`
- `apps/mobile-app/lib/features/users/presentation/widgets/*`

## Acceptance

- User management UI must reflect enterprise quality with clear access controls.
- Profiles should be readable at a glance with role and branch context.
- The design should support responsive lists and detail panels.
