# Applications

## Purpose

Group deployable applications by runtime boundary.

## Scope

- `backend/` contains the API gateway and all backend domain services.
- `mobile-app/` contains the Flutter client.

## Inputs

Application source, shared packages, environment configuration, and infrastructure services.

## Outputs

Deployable backend services and the Android Flutter application.

## Dependencies

Shared workspace packages under `packages/` and infrastructure defined at the repository root.

## Deliverables

- Backend: `apps/backend/<service>/`
- Flutter: `apps/mobile-app/`

## Acceptance Criteria

Backend services remain separate workspace packages, and the Flutter application remains at `apps/mobile-app/`.

## Notes

The backend grouping is a repository-layout boundary. It does not merge service code or change API and ownership boundaries.
