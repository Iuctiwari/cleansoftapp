# Flutter Mobile Implementation Roadmap

## Current Assessment

The Nexoraa CleanSoft repository is a monorepo centered on Node.js, pnpm, Turbo, and a growing set of backend services. The mobile app is currently a lightweight Flutter scaffold under the apps/mobile-app workspace, but the actual entry point is still a placeholder and the Flutter planning assets in this folder are design-oriented rather than implementation-ready.

## What This Folder Should Become

This folder should serve as the bridge between design planning and real Flutter implementation. Its purpose is to:

- translate the UI design artifacts into concrete mobile features;
- align the Flutter app structure with the existing monorepo conventions;
- provide a practical implementation sequence for the next development phase.

## Recommended Next Changes

### 1. Turn the Flutter scaffold into a real app shell

Focus on the existing app entry point and establish:

- a Material app foundation;
- a basic theme from the design system;
- a navigation shell for auth and dashboard entry points;
- placeholder screens for the first milestone.

### 2. Create the first feature modules

Start with the highest-value modules that match the planning docs:

- auth
- dashboard
- customers
- orders
- more/settings

These should be introduced as feature folders under the mobile app structure rather than a single large screen file.

### 3. Map UI design docs to implementation tasks

Use the existing design files in this folder as the source of truth for UI composition and navigation flow:

- AUTH_UI_DESIGN.md
- DASHBOARD_UI_DESIGN.md
- ORDER_UI_DESIGN.md
- CUSTOMER_UI_DESIGN.md
- UI_DESIGN_SPECIFICATION.md

### 4. Add shared widgets and theme tokens early

Before implementing many screens, define shared building blocks such as:

- app button
- app card
- app input field
- app header
- bottom navigation shell
- status badge

This will reduce duplication and keep the design consistent.

## Suggested Implementation Sequence

1. Build the app shell and theme.
2. Implement the auth flow.
3. Add the dashboard landing screen.
4. Implement the main navigation structure.
5. Add feature-specific screens for orders and customers.
6. Refine the UI using the design artifacts and shared widgets.

## Recommended Deliverables

- a working Flutter entry point with a basic home/dashboard experience;
- feature-based folders for auth and dashboard;
- a shared theme and reusable UI widget layer;
- a clear link between the planning docs and code implementation.

## Suggested First Milestone

The first milestone should be a basic but navigable mobile experience that includes:

- login screen;
- dashboard screen;
- bottom navigation shell;
- a clean theme aligned with the design system.

This milestone will create the foundation for the rest of the service modules.
