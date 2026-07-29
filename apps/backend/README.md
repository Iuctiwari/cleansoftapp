# Backend Applications

## Purpose

Contain the API gateway and backend domain services beneath one repository boundary.

## Scope

Each child directory remains an independent service package with its existing source, tests, configuration, and runtime behavior.

## Inputs

Requests routed through the API gateway, shared workspace packages, environment configuration, and infrastructure dependencies.

## Outputs

The API gateway and independently owned backend service processes.

## Dependencies

Workspace packages under `packages/`, MongoDB, Redis, and other infrastructure described by the architecture documentation.

## Deliverables

The existing gateway and backend service packages, relocated from `apps/<service>/` to `apps/backend/<service>/`.

## Acceptance Criteria

All backend packages are discovered by the monorepo workspace and retain their existing package names and behavior.

## Notes

This directory is organizational only. It does not combine services into a single application or change business logic.
