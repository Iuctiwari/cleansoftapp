# UI Design Specification

## Flutter Frontend Design System

### Role

You are a Senior Flutter UI Architect and Design System Engineer.

Your responsibility is to analyze the reference design language and recreate an original enterprise Flutter UI system that is modern, premium, clean, and scalable.

### Figma Fidelity Rules

- Treat the Figma-derived layout, spacing, card grouping, and section hierarchy as the authoritative visual language.
- Keep navigation structure, screen flow, and interaction patterns aligned to the Figma prototype.
- Do not substitute an unrelated frontend style, navigation model, or page structure that diverges from the Figma-derived design.
- Preserve the Figma-derived balance between dense data cards and breathing space for enterprise readability.
- When Figma details are unavailable, choose the option that stays closest to the prototype’s visual system.

### Design Goal

Build an original Flutter mobile interface that captures the visual spirit of a premium SaaS dashboard without copying content, labels, data, or business information.

The generated design must be:
- Modern
- Clean
- Responsive
- Scalable
- Material 3-inspired
- Enterprise-grade
- Spacious
- Minimal
- Professional

## Design System Components

### Color System

Create an original palette for the app, including:
- Primary
- Primary Light
- Primary Dark
- Secondary
- Accent
- Background
- Surface
- Card
- Success
- Warning
- Error
- Info
- Border
- Divider
- Shadow
- Text Primary
- Text Secondary
- Disabled
- Hint
- Overlay
- Glass Effect

The palette should reflect the Figma-derived modern, clean light theme with vivid blue accents:
- Bright white and very light gray backgrounds
- Vivid blue primary accents (`#2563EB`) for headers, buttons, and active states
- Clean white card surfaces with subtle 1px light gray borders (`#E5E7EB`)
- Solid, flat colors for status pills (green, blue, orange, red)
- High-contrast dark gray text hierarchy and crisp neutral secondary text

Store colors in:
- `lib/core/theme/app_colors.dart`

### Gradients

Create reusable gradients in an `AppGradients` class:
- Primary Gradient
- Header Gradient
- Accent Gradient
- Surface Gradient
- Card Gradient
- Button Gradient

Do not hardcode colors; derive them from the color palette.

Gradients should be used sparingly for:
- Elevated hero headers
- Primary CTA backgrounds
- Status/metric badges
- Soft glass surfaces

### Typography

Define scalable typography rules for:
- Display
- Headline
- Title
- Subtitle
- Body
- Body Small
- Caption
- Label
- Button
- Navigation

Support accessibility and dynamic text scaling.

### Spacing System

Create `AppSpacing` values:
- 2, 4, 6, 8, 10, 12, 16, 20, 24, 28, 32, 40, 48, 56, 64

### Border Radius

Define `AppRadius` variants:
- Small
- Medium
- Large
- XL
- XXL
- Circular

### Shadow System

Create reusable shadows in `AppShadows`:
- Soft Shadow
- Card Shadow
- Floating Shadow
- Glass Shadow
- Popup Shadow
- Bottom Sheet Shadow
- Button Shadow

### Icon Style

Use outlined rounded icons with support for:
- Container
- Padding
- Radius
- Background color
- Optional border
- Optional gradient

### Button System

Implement reusable button styles:
- Primary Button
- Secondary Button
- Outlined Button
- Icon Button
- Floating Button
- Ghost Button
- Loading Button
- Full Width Button
- Small Button
- Large Button

### Input Components

Create reusable inputs:
- Search Bar
- Text Field
- Password Field
- Dropdown
- Filter Chip
- Tag
- Date Picker
- Search Field
- Phone Input
- OTP Field

### Card System

Create reusable card variants:
- Statistic Card
- Profile Card
- Feature Card
- Status Card
- Summary Card
- Info Card
- Chart Card
- List Card
- Grid Card
- Action Card

Design cards with the Figma-derived structure in mind:
- Rounded rectangles with 16px corner radius
- Solid white fill with 1px subtle light gray border (`#E5E7EB`), flat with minimal shadow
- Multi-row content hierarchy: label, value, detail, and status
- Accent icon or badge in the leading slot
- Trailing action or indicator for navigation
- Compact spacing for list cards, generous spacing for hero cards
- Chip-style status badges above or below key metrics

Each card should support:
- Leading icon
- Title
- Subtitle
- Value
- Badge
- Trailing widget
- Optional button
- Optional progress
- Optional status
- Optional graph

### Badges

Create badge variants:
- Success Badge
- Warning Badge
- Info Badge
- Error Badge
- Neutral Badge
- Count Badge
- Notification Badge
- Dot Badge

### Avatars

Create avatar variants:
- Small Avatar
- Medium Avatar
- Large Avatar
- Status Avatar
- Initial Avatar
- Image Avatar
- Grouped Avatar

### App Bar

Create a reusable custom header supporting:
- Gradient background
- Curved bottom
- Floating actions
- Notification button
- Avatar
- Greeting area
- Search area
- Decorative shapes

The Figma-derived app bar should feel spacious, layered, and clean:
- Often uses a solid vivid blue background with curved bottom edges and subtle circular patterns for hero screens
- Or a clean white background with a simple title for inner screens
- Include a clear title and subtitle hierarchy, with white text on blue or black text on white
- Support top-level notifications and quick add actions
- Allow a compact variant for inner list screens

### Search

Create a reusable search component that is:
- Rounded
- Animated
- Includes leading icon
- Includes clear button
- Supports voice placeholder
- Includes filter button

### Grid System

Support:
- 1 column
- 2 column
- 3 column
- Adaptive grid
- Wrap layout
- Responsive grid

### List Components

Create reusable list items:
- Tile
- Expandable Tile
- Information Tile
- Profile Tile
- Settings Tile
- History Tile
- Timeline Tile

### Navigation

Implement navigation patterns for:
- Bottom navigation
- Floating navigation
- Drawer
- Top tabs
- Segmented control
- Breadcrumb
- Back button

The Figma-derived mobile app should use:
- A fixed bottom tab bar for primary sections (Dashboard, Orders, Customers, Payments, More)
- A floating action or quick action row for task shortcuts on dashboard/order screens
- Inline segmented controls for list filters and date ranges
- Modal bottom sheets for filters, actions, and detail options
- Clear back navigation in hierarchical detail screens

### Dialogs

Create dialog primitives for:
- Confirmation
- Warning
- Delete
- Loading
- Success
- Error
- Bottom sheet
- Action sheet

### Loading

Create loading states:
- Circular loader
- Linear loader
- Skeleton loader
- Shimmer cards
- Empty placeholder
- Retry widget

### Animations

Use subtle animations:
- Fade
- Scale
- Slide
- Hero
- Ripple
- Hover
- Press
- Animated container
- Animated switcher
- Animated list
- Page transition

Do not overuse animations.

### Responsive Design

Support:
- Small phones
- Medium phones
- Large phones
- Foldables
- Tablets
- Landscape
- Portrait

Avoid fixed dimensions where possible. Use:
- `LayoutBuilder`
- `Expanded`
- `Flexible`
- `Wrap`
- `AspectRatio`
- `MediaQuery`

### Accessibility

Support:
- Large text
- Screen readers
- Contrast
- Semantic labels
- Touch targets >= 48dp
- Dynamic text scaling

### Reusable Widgets

Create reusable widgets:
- `CustomHeader`
- `GlassCard`
- `MetricCard`
- `InfoCard`
- `SectionHeader`
- `SearchWidget`
- `IconContainer`
- `RoundedButton`
- `StatusBadge`
- `AvatarWidget`
- `NotificationIcon`
- `ActionCard`
- `SummaryGrid`
- `AdaptiveGrid`
- `EmptyState`
- `LoadingState`
- `ErrorState`
- `CustomDivider`
- `SpacingWidget`
- `AnimatedCard`

### Design Tokens

Generate tokens in:
- `AppColors`
- `AppTypography`
- `AppSpacing`
- `AppRadius`
- `AppIcons`
- `AppDurations`
- `AppShadows`
- `AppGradients`
- `AppBorders`
- `AppOpacity`

### Folder Structure

Place UI code in:
- `lib/`
- `core/`
- `theme/`
- `widgets/`
- `shared/`
- `components/`
- `features/`
- `presentation/`
- `screens/`
- `widgets/`
- `animations/`

Do not generate backend code, API calls, repositories, or business logic.

## Implementation Rules

- Never copy source content from the reference image.
- Never copy names, numbers, labels, or business information.
- Use the image only as inspiration for layout, hierarchy, spacing, cards, and visual relationships.
- Create an original implementation that is consistent with the current Flutter app architecture.
- Do not introduce a different frontend structure, interaction model, or navigation pattern from the Figma-derived prototype.
- Expect that later Flutter generation should produce screens and components that are recognizably faithful to the Figma-derived design system.

## Output Order

1. Analyze the UI.
2. Extract the design system.
3. Define reusable widgets.
4. Define theme files.
5. Define folder structure.
6. Build the screen widget tree.
7. Generate Flutter widgets.
8. Generate the final Flutter screen.

## Notes

- This is a design specification document for planning and frontend implementation guidance.
- The result should be an architecture-focused, reusable Flutter UI system aligned with the service domains in the project.
