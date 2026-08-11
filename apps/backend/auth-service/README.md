# Unified Auth Service

This is the backend's public authentication and platform HTTP service. It owns the versioned
`/api/v1/auth/*`, `/api/v1/audit/*`, `/api/v1/scheduler/*`, and `/api/v1/health/*` routes, plus
Swagger at `/api/docs`.

Authentication identities, sessions, login trackers, password resets, notifications, tenants,
owners, and branches use the existing centralized MongoDB models and collection names. Audit and
scheduler APIs are hosted in-process. Redis transport is not started because the merged service
uses direct module calls and has no Redis message handlers.

Copy `.env.example` to `.env`, set the centralized MongoDB URI, and generate distinct access and
refresh token secrets before starting the service.
