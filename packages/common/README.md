# Common Package

NestJS-specific, application-neutral foundations shared by backend services.

## Public API

- `CommonModule`
- `SystemClock` and `InjectClock`
- `FoundationException`

`CommonModule` is intentionally not global. A service opts into its providers by importing it.

## Dependency Boundary

This package may depend on NestJS and `@nexoraa/shared`. It must not contain business rules,
transport handlers, persistence code, or feature-specific contracts.
