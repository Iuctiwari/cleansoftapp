# Flutter Project Structure Recommendations

## Purpose

Recommend a Flutter project structure for the existing `apps/mobile-app` workspace that supports the current Nexoraa CleanSoft mobile UI, preserves clean architecture, and enables the Figma-derived screen set.

## Current Baseline

The current Flutter app includes:

- `main.dart`
- `app.dart`
- `core/`
  - `network/`
  - `storage/`
  - `theme/`
  - `errors/`
- `features/auth/`
  - `data/`
  - `presentation/`
  - `providers/`
- `router/app_router.dart`

This is a good foundation, but the mobile frontend should be expanded with additional feature modules and shared UI support.

## Recommended Structure

```
apps/mobile-app/lib/
  app.dart
  main.dart
  core/
    errors/
      app_exception.dart
    network/
      api_client.dart
    storage/
      token_storage.dart
    theme/
      app_theme.dart
      app_colors.dart
      app_text_styles.dart
      app_dimensions.dart
    widgets/
      app_card.dart
      app_button.dart
      app_badge.dart
      app_input.dart
      app_avatar.dart
      app_section_header.dart
      app_empty_state.dart
      app_divider.dart
  features/
    auth/
      data/
      domain/
      presentation/
        screens/
          login_screen.dart
          forgot_password_screen.dart
          reset_password_screen.dart
          change_password_screen.dart
        widgets/
          auth_text_field.dart
          auth_header.dart
      providers/
    onboarding/
      presentation/
        screens/
          onboarding_screen.dart
        widgets/
          onboarding_step_card.dart
    dashboard/
      data/
      domain/
      presentation/
        screens/
          dashboard_screen.dart
        widgets/
          dashboard_kpi_card.dart
          dashboard_section.dart
          dashboard_quick_action.dart
    orders/
      data/
      domain/
      presentation/
        screens/
          orders_screen.dart
          order_detail_screen.dart
          create_order_screen.dart
        widgets/
          order_card.dart
          order_status_badge.dart
    customers/
      data/
      domain/
      presentation/
        screens/
          customers_screen.dart
          customer_detail_screen.dart
          add_customer_screen.dart
        widgets/
          customer_list_item.dart
    payments/
      data/
      domain/
      presentation/
        screens/
          payments_screen.dart
        widgets/
          payment_summary_card.dart
    reports/
      presentation/
        screens/
          reports_screen.dart
    more/
      presentation/
        screens/
          more_screen.dart
          settings_screen.dart
          profile_screen.dart
          notifications_screen.dart
          branch_management_screen.dart
          staff_management_screen.dart
          worker_availability_screen.dart
    shared/
      widgets/
        bottom_nav.dart
        top_bar.dart
        search_input.dart
        status_chip.dart
        progress_stepper.dart
  router/
    app_router.dart
```

## Folder Responsibilities

- `core/`: cross-cutting application infrastructure, theme tokens, network clients, storage, exceptions, and reusable low-level utilities.
- `core/theme/`: centralized theme tokens and style helpers.
- `core/widgets/`: shared presentation primitives used across features.
- `features/`: feature-based folders for auth, onboarding, dashboard, orders, customers, payments, reports, and more.
- `features/*/presentation/screens/`: screen definitions only.
- `features/*/presentation/widgets/`: reusable feature-specific UI components.
- `features/*/data/`: repository and API integration logic for a feature.
- `features/*/domain/`: business objects, models, and value objects for the feature.
- `router/`: centralized navigation definitions using `GoRouter`.

## Recommended Naming and Composition

- Use `*Screen` suffix for screen widgets.
- Use `*Widget` or descriptive names for reusable UI pieces.
- Keep `screen` files focused on layout and navigation callbacks only.
- Put actual input/field/flow logic into feature widgets and providers.
- Keep presentation logic separate from data and domain models.

## Theme / Design System Recommendations

### Colors

Create `app_colors.dart` with tokens such as:

- `primaryBlue`
- `secondaryPurple`
- `successGreen`
- `warningYellow`
- `dangerRed`
- `surfaceBackground`
- `surfaceCard`
- `borderLight`
- `textPrimary`
- `textSecondary`
- `textMuted`

### Typography

Create `app_text_styles.dart` with:

- `headlineLarge`
- `headlineMedium`
- `headlineSmall`
- `bodyLarge`
- `bodyMedium`
- `bodySmall`
- `labelLarge`
- `labelSmall`

### Dimensions

Create `app_dimensions.dart` with spacing and shape tokens:

- `spacingXs`, `spacingSm`, `spacingMd`, `spacingLg`, `spacingXl`
- `radiusSm`, `radiusMd`, `radiusLg`
- `elevationLow`, `elevationMedium`, `elevationHigh`

## Navigation and Flow

- Keep `app_router.dart` as the single source of route definitions.
- Add named routes for each feature screen.
- Preserve the login, forgot password, reset password, and home redirect flow.
- Use a shell route or nested routes to support the tabbed bottom navigation for dashboard/orders/customers/more.
- Keep onboarding as a separate flow that may be pushed before the main tab view.

## Integration Recommendations

- Retain the existing auth provider and signal route changes through `GoRouter` when login state changes.
- Add a shared `AppShell` or `MainShell` route for bottom navigation.
- Use screen-specific providers for dashboard, orders, customers, payments, and more if state is local to that feature.
- Avoid a single monolithic UI state object; prefer feature-level providers and domain models.

## Suggested Project Structure Changes

1. Create `core/widgets/` for the shared UI primitives identified in the Figma prototype.
2. Add feature modules for `onboarding`, `dashboard`, `orders`, `customers`, `payments`, `reports`, and `more`.
3. Move existing auth screens into `features/auth/presentation/screens/` and keep auth-specific widgets under `features/auth/presentation/widgets/`.
4. Reserve `features/shared/` for app chrome like `top_bar.dart`, `bottom_nav.dart`, and search inputs.
5. Keep theme tokens in `core/theme/` rather than scattered across styles.
6. Add a dedicated `features/dashboard/presentation/widgets/` folder for reusable dashboard components.
7. Add `domain/` folders only when feature business objects or shared value objects are required.

## Notes

- These recommendations are focused on frontend design integration and developer handoff.
- The existing Flutter app is the starting point; avoid introducing an entirely new mobile architecture.
- The recommended structure should make it easier to map Figma screens onto feature modules and shared widgets.
- Actual implementation should still be validated by a later phase prompt that references these planning artifacts.
