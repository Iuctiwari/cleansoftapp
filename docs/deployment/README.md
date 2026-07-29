# Nexoraa CleanSoft Deployment Strategy

## 1. Purpose

This document defines the deployment strategy for the Nexoraa CleanSoft
monorepo. It is based on the applications and infrastructure that currently
exist in this repository and clearly separates:

- what can be run and verified today;
- what should be deployed to development and staging;
- the target production architecture; and
- the work and approvals required before a production release.

The repository is not production-deployable yet. The NestJS API gateway and
Flutter foundation are runnable, but the domain services, production
containers, Terraform, Helm charts, database migrations, observability, and
continuous-delivery workflow are still scaffolds.

## 2. Current Deployment Readiness

| Component | Location | Current state | Deployment status |
| --- | --- | --- | --- |
| API gateway | `apps/backend/api-gateway` | Runnable NestJS application | Development-ready |
| Flutter mobile app | `apps/mobile-app` | Runnable Android/iOS Flutter foundation | Development-ready |
| Domain services | `apps/backend/*-service` | Package, TypeScript, and environment scaffolds only | Not deployable |
| MongoDB | Root `docker-compose.yml` | MongoDB 8 local container | Local development only |
| Redis | Root `docker-compose.yml` | Redis 8 local container | Local development only |
| Shared packages | `packages/*` | Package foundations | Not independently deployable |
| CI | `.github/workflows/ci.yml` | Runs only `pnpm verify` | Foundation only |
| Docker images | `docker/` | Placeholder directories; no application Dockerfiles | Not implemented |
| Terraform | `infra/terraform` | Placeholder `main.tf` | Not implemented |
| Helm | `infra/helm` | Placeholder chart directory | Not implemented |
| Monitoring and logging | `infra/monitoring`, `infra/logging` | Placeholders | Not implemented |

Production deployment must not proceed while any required item in the
production readiness gate in section 14 remains incomplete.

## 3. Repository and Tooling Baseline

All Node.js workspace commands use the repository root:

```text
D:\flutter\nexoraa-cleansoft
```

The supported baseline declared by the repository is:

- Node.js `>=22.13.0`;
- pnpm `>=10.0.0`, with pnpm `10.13.1` declared by the root package;
- Flutter SDK `>=3.8.0 <4.0.0`;
- MongoDB `8.0` for local development; and
- Redis `8.0` for local development.

The root `pnpm-lock.yaml` is the authoritative monorepo dependency lockfile.
Deployment automation must use pnpm consistently and must not generate or
update dependency state with npm.

## 4. Environment Strategy

Use three permanently separated environments:

| Environment | Purpose | Data | Deployment trigger |
| --- | --- | --- | --- |
| Development | Local development and feature verification | Local or synthetic data only | Developer command |
| Staging | Integration, migration, security, and release-candidate validation | Synthetic or approved sanitized data only | Merge to `main` |
| Production | Customer workloads | Production data | Approved immutable release |

Each environment must have separate:

- network boundaries;
- application configuration;
- MongoDB databases and credentials;
- Redis instances and credentials;
- encryption keys;
- service identities;
- signing credentials;
- logs and telemetry;
- backup destinations; and
- DNS names.

Production credentials and production data must never be copied into
development or staging.

### 4.1 Configuration ownership

The following checked-in files define names and safe examples only:

- root `.env` variables are used by local Docker Compose;
- `apps/backend/api-gateway/.env.example` defines gateway variables;
- `apps/backend/*-service/.env.example` defines future service variables; and
- `apps/mobile-app/.env` contains build-time, non-secret Flutter configuration.

Local `.env` files remain untracked. Staging and production secrets must come
from the selected platform's secret manager and be injected at runtime.
Secrets must not be stored in Git, container images, CI logs, Flutter assets,
Helm values committed to Git, or Terraform state in plain text.

### 4.2 Required gateway configuration

The API gateway currently requires:

```env
APP_NAME=Nexoraa CleanSoft
NODE_ENV=production
HOST=0.0.0.0
PORT=3000
API_PREFIX=api
API_VERSION=v1
```

`PORT`, `API_PREFIX`, and `API_VERSION` form part of the deployment contract.
With the values above, the current health endpoint is:

```text
GET /api/v1/health
```

### 4.3 Flutter API configuration

The current Flutter application loads `apps/mobile-app/.env` as a bundled
asset. It must contain only public, non-secret values.

Development examples:

```env
# Flutter Web, Windows, or iOS simulator
API_BASE_URL=http://localhost:3000/api

# Android emulator
API_BASE_URL=http://10.0.2.2:3000/api
```

For staging and production, generate the non-secret `.env` immediately before
the Flutter build:

```env
APP_NAME=Nexoraa CleanSoft
APP_ENV=production
API_BASE_URL=https://api.example.com/api
```

Replace `api.example.com` only after the production domain is approved.
Production mobile builds must use HTTPS. A secret must never be embedded in
this file because Flutter assets can be extracted from the application.

Before the first external release, replace the single mutable `.env` workflow
with reviewed Flutter flavors such as `development`, `staging`, and
`production`, each with its own application identifier and API endpoint.

## 5. Target Runtime Topology

Only the API gateway is public. MongoDB, Redis, workers, and domain services
must stay on private networks.

```text
Flutter application
        |
        | HTTPS
        v
DNS -> WAF/rate limiting -> TLS load balancer/ingress
                              |
                              v
                         API gateway
                              |
                   private service network
                  /           |            \
         domain services   workers/jobs   internal APIs
                  \           |            /
                   managed MongoDB replica set
                   managed Redis
                   private object storage
```

Deployment should follow the repository's logical service ownership without
forcing premature operational complexity:

1. Deploy the API gateway as its own workload.
2. Deploy only implemented domain services and workers.
3. A domain package becomes an independent workload only after it has runnable
   source, health/readiness endpoints, tests, a build script, and an image.
4. Initially, logically separate modules may share a runtime where approved.
5. Split services independently when scaling, isolation, ownership, or release
   cadence provides evidence that a separate workload is needed.

Do not expose a domain service directly to the internet. All public API traffic
must pass through the gateway.

## 6. Local Development Deployment

Local development is the only complete deployment path currently supported by
the repository.

### 6.1 One-time installation

Run from the repository root:

```powershell
cd D:\flutter\nexoraa-cleansoft
pnpm install --frozen-lockfile
```

Run from the Flutter application:

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\mobile-app
flutter pub get
```

### 6.2 Start MongoDB and Redis

Run from the repository root:

```powershell
cd D:\flutter\nexoraa-cleansoft
docker compose up -d
docker compose ps
```

The root `.env` must define at least `MONGODB_PORT` and `REDIS_PORT`.
The normal local ports are `27017` and `6379`.

These containers use named volumes. Do not use `docker compose down -v`
unless local database and Redis data may be permanently deleted.

### 6.3 Start the API gateway

Run in a dedicated terminal:

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\backend\api-gateway
pnpm start:dev
```

Verify it:

```powershell
Invoke-RestMethod http://localhost:3000/api/v1/health
```

Expected fields include:

```json
{
  "status": "ok",
  "service": "api-gateway",
  "environment": "development",
  "message": "NestJS Foundation Ready"
}
```

The gateway does not currently connect to MongoDB or Redis, so its health
response proves only that the NestJS process is running.

### 6.4 Start Flutter

Run in another terminal:

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\mobile-app
flutter run
```

Choose a connected device or emulator when prompted.

### 6.5 Stop local infrastructure

Run from the repository root:

```powershell
cd D:\flutter\nexoraa-cleansoft
docker compose stop
```

## 7. Build and Artifact Strategy

Every release must be created once and promoted without rebuilding. The exact
same backend image digest that passes staging must be promoted to production.

Every artifact must record:

- Git commit SHA;
- semantic release version or release tag;
- build timestamp;
- Node.js, pnpm, Flutter, and Dart versions as applicable;
- dependency lockfile checksum;
- container image digest or mobile artifact checksum;
- test and scan results; and
- CI workflow/run identifier.

### 7.1 API gateway artifact

The current gateway production build is:

```powershell
cd D:\flutter\nexoraa-cleansoft
pnpm --filter @nexoraa/api-gateway typecheck
pnpm --filter @nexoraa/api-gateway test
pnpm --filter @nexoraa/api-gateway build
```

The compiled entry point is:

```text
apps/backend/api-gateway/dist/main.js
```

The production start command is:

```powershell
pnpm --filter @nexoraa/api-gateway start:prod
```

Before staging deployment, add a multi-stage, non-root Dockerfile for the API
gateway. The resulting runtime image must:

- install dependencies from `pnpm-lock.yaml` with `--frozen-lockfile`;
- compile in a builder stage;
- contain only production runtime dependencies and compiled output;
- run as a non-root user;
- expose port `3000`;
- use `node dist/main` as its process;
- include OCI source, revision, and version labels;
- have a read-only root filesystem where feasible; and
- contain no `.env`, source credentials, package-manager cache, or test output.

Do not use a floating `latest` tag for deployment. Publish both:

```text
api-gateway:<release-version>
api-gateway:<full-git-sha>
```

Deployment must pin the immutable image digest.

### 7.2 Future domain-service artifacts

The domain-service packages currently have no runtime source or scripts.
Before a service is added to the deployment matrix, it must provide:

- `build`, `typecheck`, `test`, and `start:prod` scripts;
- a compiled runtime entry point;
- `/health/live` and `/health/ready` behavior;
- configuration validation;
- dependency timeouts and graceful shutdown;
- a Dockerfile meeting the gateway image requirements; and
- an owner and rollback runbook.

### 7.3 Android artifact

Run from the Flutter application:

```powershell
cd D:\flutter\nexoraa-cleansoft\apps\mobile-app
flutter analyze
flutter test
flutter build appbundle --release
```

Expected Play Store artifact:

```text
apps/mobile-app/build/app/outputs/bundle/release/app-release.aab
```

Android signing credentials must be provided by the CI secret manager. The
keystore and passwords must never be committed.

### 7.4 iOS artifact

iOS release builds require a macOS runner with Xcode and approved Apple signing
credentials:

```bash
cd apps/mobile-app
flutter analyze
flutter test
flutter build ipa --release
```

Use App Store Connect/TestFlight for staged iOS distribution. Certificates,
profiles, and App Store API keys must be stored in the CI secret manager.

## 8. CI/CD Pipeline

The existing GitHub Actions workflow verifies only the repository scaffold.
Extend it into the following separate workflows before staging or production.

### 8.1 Pull-request validation

Trigger: every pull request.

Required ordered gates:

1. Check out the exact commit.
2. Install pnpm `10.13.1` and a supported Node.js 22 release.
3. Run `pnpm install --frozen-lockfile`.
4. Run `pnpm verify`.
5. Run gateway formatting check, lint, typecheck, tests, and build.
6. Install the pinned Flutter SDK.
7. Run `flutter pub get`, `flutter analyze`, and `flutter test`.
8. Run dependency, secret, license, and static-security scans.
9. Build application images without publishing them.
10. Generate a software bill of materials for each image.

No failed or skipped required gate may be treated as a pass.

### 8.2 Staging delivery

Trigger: merge to `main`, after pull-request gates pass.

Ordered steps:

1. Build the immutable backend image once.
2. Scan the final image and fail on the approved severity threshold.
3. Sign the image and publish it to the approved private registry.
4. Attach provenance, SBOM, Git SHA, and test evidence.
5. Apply reviewed infrastructure changes to staging.
6. Run backward-compatible database migrations, if any.
7. Deploy the image digest to staging.
8. Wait for readiness.
9. Run gateway health, API contract, integration, and smoke tests.
10. Run a Flutter staging build against the staging HTTPS endpoint.
11. Store deployment evidence and mark the digest as a release candidate.

### 8.3 Production delivery

Trigger: an immutable release tag or manually selected release candidate.

Production requires:

- successful staging evidence for the exact artifact digest;
- approved change record;
- approved migration and rollback plan;
- confirmed backups and a recent restore test;
- security and dependency scan approval;
- an identified release owner and incident owner; and
- explicit production approval using a protected CI environment.

Ordered production steps:

1. Verify signatures, provenance, and artifact digest.
2. Verify the production configuration and secret references.
3. Take or confirm the required pre-release backup.
4. Run only approved backward-compatible migrations.
5. Deploy a canary or small initial workload cohort.
6. Run health, readiness, synthetic, and contract checks.
7. Observe error rate, latency, saturation, and dependency health.
8. Promote gradually to the full workload.
9. Record the deployed digest, configuration version, migration version, and
   approver.
10. Continue the defined post-release monitoring window.

CI must never automatically deploy a pull request to production.

## 9. Infrastructure Strategy

The cloud provider, region, Kubernetes requirement, secret manager, managed
MongoDB/Redis providers, object storage, backup provider, observability
platform, recovery objectives, and cost limits are not approved in the current
repository. These decisions must be recorded before production infrastructure
is implemented.

### 9.1 Recommended selection rule

Use the least operationally complex managed runtime that satisfies the approved
security, scaling, networking, and recovery requirements:

- use a managed container application/service platform for the initial gateway
  if Kubernetes-specific capabilities are not required;
- use Kubernetes and the existing Helm direction only if workload count,
  portability, networking policy, scaling, or platform standards justify its
  operational cost; and
- do not implement both paths.

Once the platform decision is approved:

1. record it in an architecture decision;
2. implement all cloud resources in `infra/terraform`;
3. keep separate state and variable sets for development, staging, and
   production;
4. store remote Terraform state with encryption, locking, versioning, and
   restricted access;
5. use plan review for every infrastructure change;
6. prohibit automatic destructive production applies; and
7. use Helm only if Kubernetes is selected.

The local `docker-compose.yml` must not be reused as a production topology.

### 9.2 Production data dependencies

Production MongoDB must be a managed replica set with:

- encryption in transit and at rest;
- private network access;
- service-specific least-privilege credentials;
- automated backups;
- point-in-time recovery where required;
- monitored replication, connections, storage, and slow operations; and
- a tested restore procedure.

Production Redis must be managed or equivalently operated with:

- TLS and authentication;
- private network access;
- high availability where required;
- explicit eviction and persistence policies;
- monitored memory, connections, latency, and evictions; and
- separate policies or instances for cache and durable job use when required.

Redis must not become the system of record for financial or tenant data.

## 10. Health, Scaling, and Observability

The current `/api/v1/health` route is a basic liveness response. Before staging,
the backend must expose distinct probes:

- liveness: process is alive and not deadlocked;
- readiness: instance can safely receive traffic;
- startup: slow initialization has completed, if required.

Readiness must verify critical runtime configuration and the dependencies
needed to serve requests, without creating excessive dependency load.

Every deployed workload must emit structured logs containing at least:

- UTC timestamp;
- severity;
- environment;
- service name;
- application version and Git SHA;
- request/correlation ID; and
- safe tenant context when allowed.

Logs must not include access tokens, passwords, secrets, payment data, or
unredacted personal data.

Minimum production dashboards and alerts must cover:

- availability and health-probe failures;
- request rate, error rate, and latency percentiles;
- CPU, memory, restarts, and saturation;
- MongoDB availability, storage, connections, and replication;
- Redis availability, latency, memory, and evictions;
- queue backlog, retry count, and dead-letter growth when workers exist;
- backup failures and backup age; and
- mobile crash-free sessions and release adoption.

Autoscaling must use measured capacity and approved minimum/maximum limits. Do
not scale solely on CPU when request latency, queue depth, or connection limits
are the actual bottleneck.

## 11. Database Change Strategy

There is currently no implemented database migration system. No production
service that persists data may be released until an idempotent, versioned,
auditable migration mechanism exists.

Use expand-and-contract changes:

1. add new optional fields, collections, or indexes;
2. deploy code that can read old and new representations;
3. backfill through a resumable, rate-limited job;
4. verify tenant counts, invariants, and error rates;
5. switch reads and writes to the new representation; and
6. remove old structures only in a later release.

Migrations must:

- be safe to retry;
- record version, start/end time, result, and artifact version;
- avoid unbounded full-collection work during peak traffic;
- be tested against staging-scale data;
- define forward recovery when rollback cannot reverse a data change; and
- preserve tenant isolation.

Application rollback must never assume that a destructive schema change can be
undone.

## 12. Rollout and Rollback

Backend rollout must be rolling or canary, with zero-downtime behavior once the
platform supports multiple replicas.

Trigger rollback when an approved threshold is exceeded, including:

- health or readiness failure;
- significant increase in server errors;
- latency or saturation beyond the release threshold;
- failed synthetic or contract checks;
- authorization or tenant-isolation regression;
- migration invariant failure; or
- dependency instability caused by the release.

Backend rollback procedure:

1. stop further promotion;
2. route traffic away from unhealthy new instances;
3. redeploy the last known-good image digest;
4. preserve logs, metrics, traces, and migration evidence;
5. use the documented forward-recovery procedure for non-reversible data
   changes;
6. verify health and critical user journeys; and
7. open an incident and record the final deployed version.

Mobile binaries cannot be instantly rolled back after store distribution.
Mobile releases therefore require:

- backward-compatible APIs;
- server-side feature flags or kill switches for risky features;
- phased Play Store and App Store rollout;
- monitoring by app version; and
- halting rollout before submitting a corrected build when a regression is
  detected.

The API gateway must support at least the current and previous supported mobile
API contract throughout the mobile adoption window.

## 13. Release Verification

A backend deployment is successful only when:

- the intended immutable digest is running;
- all instances are ready;
- `GET /api/v1/health` succeeds through the public HTTPS route;
- critical API contract and synthetic tests pass;
- database migration status is verified;
- error rate and latency remain within approved thresholds;
- logs and metrics contain the expected release version;
- no secret appears in application or deployment logs; and
- rollback remains executable.

A mobile release candidate is successful only when:

- analysis and tests pass;
- the application is signed with the correct environment identity;
- it points to the correct HTTPS API endpoint;
- no secret is bundled;
- it passes smoke tests on supported real or virtual devices;
- backend compatibility is verified; and
- crash reporting and release-version telemetry are visible.

Store all release evidence with the release record. A CI job completing does
not by itself prove production readiness.

## 14. Production Readiness Gate

Production deployment is blocked until all of the following are complete:

- [ ] Cloud provider, region, runtime, network topology, and DNS are approved.
- [ ] Production cost limits and scaling guardrails are approved.
- [ ] Recovery objectives, retention, and data-residency requirements are
      approved.
- [ ] Runnable business services and workers are implemented and tested.
- [ ] Production Dockerfiles and immutable registry delivery are implemented.
- [ ] Terraform is implemented, reviewed, and validated in staging.
- [ ] Helm charts are implemented only if Kubernetes is selected.
- [ ] Managed MongoDB and Redis topology is approved and provisioned privately.
- [ ] Secret-manager integration and credential rotation are verified.
- [ ] Database migration and forward-recovery tooling is implemented.
- [ ] Liveness, readiness, graceful shutdown, and dependency timeouts exist.
- [ ] Logs, metrics, traces, dashboards, alerts, and runbooks are operational.
- [ ] Backups and a timed restore exercise are verified.
- [ ] CI includes complete backend and Flutter quality/security gates.
- [ ] CD supports signed artifacts, protected approvals, staged rollout, and
      digest-based rollback.
- [ ] TLS, WAF/rate limits, CORS, authentication, authorization, and
      tenant-isolation controls pass security review.
- [ ] Flutter flavors, Android/iOS identifiers, signing, privacy declarations,
      and store pipelines are complete.
- [ ] Load, resilience, integration, end-to-end, and security test evidence is
      approved.
- [ ] Release owner, incident owner, monitoring window, and rollback thresholds
      are recorded.

## 15. Immediate Implementation Order

The safest order for turning the current foundation into a deployable system
is:

1. Strengthen pull-request CI using the exact checks in section 8.1.
2. Add the API gateway production Dockerfile and image-security checks.
3. Add gateway readiness, graceful shutdown verification, and structured
   telemetry.
4. Select and document the approved production platform and recovery targets.
5. Implement Terraform for a fully isolated staging environment.
6. Provision staging MongoDB, Redis, secret management, registry, networking,
   observability, and backups.
7. Implement staging CD with immutable image promotion and rollback.
8. Implement one domain capability end to end before adding every service
   scaffold to the deployment matrix.
9. Implement migration tooling and verify backup restoration.
10. Add Flutter flavors, signing automation, and internal Android/TestFlight
    distribution.
11. Complete security, load, resilience, and recovery testing in staging.
12. Create production from reviewed infrastructure code and perform a
    controlled canary release only after every production gate is satisfied.

This order preserves the current monorepo structure while avoiding claims that
the existing placeholder infrastructure is production-ready.
