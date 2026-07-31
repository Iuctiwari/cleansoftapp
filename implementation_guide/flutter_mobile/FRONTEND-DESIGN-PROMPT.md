# Frontend Design Prompt for Nexoraa CleanSoft Mobile

## Purpose

This prompt describes the desired mobile frontend design work for the Nexoraa CleanSoft customer-facing Flutter app. It is intended for a design or AI-assisted implementation agent that will translate existing Figma-derived UI patterns into a structured Flutter UI architecture.

## Objective

Create a documented frontend design and integration plan that maps the current Figma-derived React prototype into the existing Flutter mobile app architecture. The result should describe the Flutter screen inventory, shared widget library, theme tokens, navigation model, responsive behavior, and recommended project structure.

## Scope

- Inspect the existing repository and the current Flutter app in `apps/mobile-app`.
- Inspect the Figma-derived React prototype source under the Figma make project source, especially its screen and shared UI component definitions.
- Produce one comprehensive frontend design prompt artifact that is suitable for guiding Flutter implementation.
- Recommend specific changes to the Flutter project structure to support the new app screens and shared UI primitives.

## Out of Scope

- Do not implement actual Flutter screens or widgets in source code in this phase.
- Do not modify backend APIs or business logic.
- Do not create new data models or adjust database schema.
- Do not change the existing `apps/mobile-app/lib/features/auth` module unless structure recommendations are required.
- Do not start a full Flutter migration; focus on frontend design planning only.

## Mandatory Reading

Read these files before writing the prompt and recommendations:

- `ERP-PLANNING/ui-ux/README.md`
- `ERP-PLANNING/prompt-engineering/README.md`
- `implementation_guide/phases/phase-16-dashboard/02-prompt.md`
- `apps/mobile-app/lib/app.dart`
- `apps/mobile-app/lib/router/app_router.dart`
- `apps/mobile-app/lib/features/auth/presentation/screens/login_screen.dart`
- `apps/mobile-app/lib/features/auth/presentation/screens/forgot_password_screen.dart`
- `apps/mobile-app/lib/features/auth/presentation/screens/reset_password_screen.dart`
- `apps/mobile-app/lib/core/theme/app_theme.dart`
- The Figma prototype source files in the Figma Make project under `src/screens` and `src/components`

## Key Design Guidance

The Flutter frontend design should capture these core decisions and stay faithful to the Figma-derived visual grammar:

- Use a feature-oriented folder structure for the mobile app.
- Build a shared UI widget library for cards, badges, buttons, inputs, avatars, headers, and section layouts.
- Centralize theme tokens for colors, typography, spacing, shape, and animation.
- Preserve the Figma-derived mobile navigation flow: auth screens, onboarding, tabbed dashboard, orders, customers, payments, reports, and a "More" section.
- Support role-based dashboard variants with a common reusable dashboard architecture.
- Keep screen-level state in feature modules; avoid global UI state unless it is shared across multiple screens.
- Keep the mobile app strictly portrait-first and responsive within phone view constraints.
- Treat the Figma layout, spacing, card structure, and interaction pattern as the authoritative design source.
- Avoid inventing an unrelated frontend visual style or navigation model that diverges from the Figma-derived UI language.

## Design Details to Include

1. Screen inventory based on the Figma source and the current Flutter app.
2. Shared widget inventory with the patterns identified in `src/components/ui.tsx` and the current Flutter UI architecture.
3. Theme token recommendations:
   - Primary, secondary, accent, danger, success, warning, surface, border, background, text colors.
   - Typography scale and weight mapping.
   - Spacing scale.
   - Border radius and elevation conventions.
4. Navigation model:
   - Main tab structure.
   - Auth flow.
   - Onboarding flow.
   - Detail and modal flows.
5. Responsive and interaction notes:
   - Mobile-first behavior.
   - Touch targets and spacing.
   - Visual hierarchy and card layout.
   - Button/CTA behavior.
   - Animation/transition expectations.
10. Fidelity expectations:
   - Preserve Figma card grouping, section spacing, and content hierarchy.
   - Match the Figma-derived color mood, surface treatment, and accent usage.
   - Keep iconography and tile density consistent with the prototype.
   - Use original placeholder copy only where Figma labels are unavailable.
11. Project structure recommendation for the Flutter app.

## Recommended Deliverables

- A detailed prompt artifact describing the frontend design intent and mapping.
- A direct Flutter implementation handoff document with screen blueprints, component mapping, and a Figma fidelity checklist.
- A separate project-structure recommendation document for `apps/mobile-app`.

## Acceptance Criteria

- The prompt artifact clearly maps Figma screens to Flutter feature screens.
- Shared UI primitives are identified and grouped into a reusable widget library.
- Theme tokens are documented with explicit color and spacing recommendations.
- The navigation graph and screen flow are described clearly.
- Flutter project structure changes are recommended with folder names and responsibilities.
- The result is ready to guide a Flutter implementation phase without additional UI design discovery.

## Notes

- The plan is for the existing Flutter app, not a new standalone mobile app.
- The prompt should treat the current `apps/mobile-app` repository as the source of truth.
- This is a planning and documentation artifact, not a source-code change task.
