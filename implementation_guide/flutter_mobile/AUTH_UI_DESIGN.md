# Auth UI Design for Flutter

## Purpose

Describe the exact Flutter UI design for authentication flows in Nexoraa CleanSoft mobile, using the existing app theme and the Figma-derived mobile design language.

## Scope

- Login
- Forgot Password
- Reset Password
- Change Password
- Auth-related onboarding / welcome copy



## Typography

Use `GoogleFonts.outfit` across auth screens.

- Page headings: 24, weight 700
- Section headings / labels: 13-15, weight 500-600
- Body text: 14-16, weight 400-500
- Button text: 16, weight 600
- Helper / notice text: 12-13, weight 400

## Widget Patterns

- Inputs: `AuthTextField` with filled `backgroundElevated`, rounded `14` radius, `border` color, and primary focus border.
- Buttons: `AuthButton` primary with full-width CTA, or outlined secondary style for alternative actions.
- Banners: use gradient overlays with `#003329` to `#00221C` for hero/welcome cards.
- Cards: backgrounds `backgroundCard` with border `border` and soft `20` radius.
- Status chips: small pill labels with `primary`/`success`/`warning` backgrounds and subtle text.

## Screen Layouts

### Login Screen

- Top 35% hero section with solid vivid blue background (`#2563EB`), subtle circular decorative pattern, and checkmark icon.
- Bold white "Welcome back" title and subtitle on the blue background.
- Bottom 65% solid white background containing the form.
- Primary input fields: Email Address and Password with standard light gray outlined borders and prefix icons.
- Actions: Right-aligned `Forgot password?` link (blue text), full-width solid blue `Sign In` button.
- Secondary Actions: "or" divider with lines, outlined `Create Business Account` button.
- Footer: "By signing in you agree to our Terms of Service" with blue link.

### Forgot Password Screen

- Simple header and instruction copy.
- Single input for email/mobile.
- Primary CTA to submit request.
- Text link to go back to login.
- Success state uses a subtle success card with green accent.

### Reset Password Screen

- Header describing code or email validation.
- Two password fields for new password and confirm password.
- Primary CTA to reset.
- Instructional helper text about password strength.

### Change Password Screen

- Current password field plus new password fields.
- Primary CTA to save changes.
- Secondary explanatory text warning about strong-password policy.

## Navigation

- Auth routes are already defined in `router/app_router.dart`.
- Keep auth flow separate from the home/dashboard shell.
- Preserve redirect behavior on unauthenticated access.

## File Structure

Place screens under:

- `apps/mobile-app/lib/features/auth/presentation/screens/`

Place shared auth widgets under:

- `apps/mobile-app/lib/features/auth/presentation/widgets/`

## Acceptance

- Screens must use the new modern light theme colors.
- Inputs and buttons must reuse `AuthTextField` and `AuthButton` patterns.
- Auth screens must be responsive across phone sizes.
- UI copy must be ready for the real Figma wording once available.
- This doc should allow a developer to implement auth screens without additional design exploration.
