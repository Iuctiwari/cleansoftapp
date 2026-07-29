# Phase 19 Build Brief — Deployment

## Objective

Implement production delivery only after `OQ-29`–`OQ-32` are approved. This phase re-homes the substantive legacy DevOps/Observability and Deployment prompt content.

## Required topology

Document and implement approved:

- Network ingress/TLS/private service/data subnets.
- Container/runtime deployment for gateway, logical services, workers.
- Managed MongoDB replica set, Redis/BullMQ, private object storage.
- Secret manager and rotation.
- Central logs, metrics, traces, alert routing.
- Backups, point-in-time recovery, restore exercises, DR.
- Flutter Android/iOS build/sign/distribution without committing keys.

## Delivery interfaces

- CI gates: format/lint/type/test/security/contract/image scan.
- Migration: preconditions, tenant safety, backward compatibility, forward/rollback.
- Health: `/health/live`, `/health/ready`.
- Deployment: immutable artifact/version/provenance, staged rollout, smoke/contract checks, rollback trigger.

## Rules

- Production secrets/data never enter repo/lower environments.
- Optional notification/report degradation cannot falsely mark financial/auth readiness.
- Capacity/worker/autoscaling derive from `OQ-28` evidence.
- Alerts have severity/owner/response/runbook.
- Quarterly pre-GA restore and approved RPO/RTO evidence.
- Document cost/noisy-tenant guardrails.

## What not to build

No unapproved cloud/Kubernetes/vendor, no source business logic, no bypassed gates, no production release, no claim that scaffolds are operational evidence.

