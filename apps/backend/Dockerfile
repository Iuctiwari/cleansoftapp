# syntax=docker/dockerfile:1.7
# =============================================================================
# Nexoraa CleanSoft — NestJS Microservice Builder
#
# Build context : repository root  (one level above apps/)
# Build arg     : SERVICE=<service-name>  (default: auth-service)
#
# Usage:
#   docker build \
#     --build-arg SERVICE=auth-service \
#     -f apps/backend/Dockerfile \
#     -t nexoraa/auth-service:latest \
#     .
#
# Stages:
#   base    — Node.js + pnpm setup
#   deps    — install all workspace dependencies (cached layer)
#   builder — compile workspace packages then the target service
#   runner  — minimal production image with only dist + prod node_modules
# =============================================================================

ARG NODE_VERSION=22-alpine
ARG PNPM_VERSION=10.13.1

# ─────────────────────────────────────────────────────────────────────────────
# Stage: base
# Installs pnpm via corepack on top of the official Node LTS Alpine image.
# Alpine is chosen for the smallest possible footprint (~50 MB base).
# ─────────────────────────────────────────────────────────────────────────────
FROM node:${NODE_VERSION} AS base
ARG PNPM_VERSION
ENV PNPM_HOME="/pnpm"
ENV PATH="${PNPM_HOME}:${PATH}"
RUN corepack enable && corepack prepare pnpm@${PNPM_VERSION} --activate
WORKDIR /app

# ─────────────────────────────────────────────────────────────────────────────
# Stage: deps
# Copies ONLY the package manifests (package.json, pnpm-workspace.yaml,
# pnpm-lock.yaml) so that the install layer is cached independently of source.
# This layer only re-runs when dependency declarations change.
# ─────────────────────────────────────────────────────────────────────────────
FROM base AS deps

# Workspace root manifests
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./

# ── Shared packages ──────────────────────────────────────────────────────────
COPY packages/common/package.json        ./packages/common/
COPY packages/config/package.json        ./packages/config/
COPY packages/constants/package.json     ./packages/constants/
COPY packages/database/package.json      ./packages/database/
COPY packages/logger/package.json        ./packages/logger/
COPY packages/shared/package.json        ./packages/shared/
COPY packages/swagger/package.json       ./packages/swagger/
COPY packages/types/package.json         ./packages/types/
COPY packages/ui/package.json            ./packages/ui/
COPY packages/utils/package.json         ./packages/utils/

# ── Backend service manifests ────────────────────────────────────────────────
COPY apps/backend/auth-service/package.json         ./apps/backend/auth-service/
COPY apps/backend/tenant-service/package.json       ./apps/backend/tenant-service/
COPY apps/backend/branch-service/package.json       ./apps/backend/branch-service/
COPY apps/backend/user-service/package.json         ./apps/backend/user-service/
COPY apps/backend/customer-service/package.json     ./apps/backend/customer-service/
COPY apps/backend/service-service/package.json      ./apps/backend/service-service/
COPY apps/backend/order-service/package.json        ./apps/backend/order-service/
COPY apps/backend/payment-service/package.json      ./apps/backend/payment-service/
COPY apps/backend/expense-service/package.json      ./apps/backend/expense-service/
COPY apps/backend/notification-service/package.json ./apps/backend/notification-service/
COPY apps/backend/scheduler-service/package.json    ./apps/backend/scheduler-service/
COPY apps/backend/report-service/package.json       ./apps/backend/report-service/
COPY apps/backend/audit-service/package.json        ./apps/backend/audit-service/
COPY apps/backend/search-service/package.json       ./apps/backend/search-service/

# Install all workspace dependencies.
# --mount=type=cache keeps the pnpm store across builds (BuildKit required).
# --frozen-lockfile ensures reproducible installs (no lock mutations).
RUN --mount=type=cache,id=nexoraa-pnpm-store,target=/pnpm/store \
    pnpm install --frozen-lockfile

# ─────────────────────────────────────────────────────────────────────────────
# Stage: builder
# Copies all source code, compiles workspace packages in dependency order,
# then compiles the target service.
# run-typescript-project.mjs gracefully handles services without src/ yet
# (emits a marker file and exits 0).
# ─────────────────────────────────────────────────────────────────────────────
FROM deps AS builder
ARG SERVICE=auth-service

# Workspace-level TypeScript config (extended by every tsconfig.json)
COPY tsconfig.base.json ./

# Build scripts — needed because stub services call
# `node ../../../scripts/run-typescript-project.mjs build`
COPY scripts/ ./scripts/

# ── Shared workspace packages (all sources) ──────────────────────────────────
COPY packages/common/     ./packages/common/
COPY packages/config/     ./packages/config/
COPY packages/constants/  ./packages/constants/
COPY packages/database/   ./packages/database/
COPY packages/logger/     ./packages/logger/
COPY packages/shared/     ./packages/shared/
COPY packages/swagger/    ./packages/swagger/
COPY packages/types/      ./packages/types/
COPY packages/ui/         ./packages/ui/
COPY packages/utils/      ./packages/utils/

# ── Target service source ─────────────────────────────────────────────────────
COPY apps/backend/${SERVICE}/ ./apps/backend/${SERVICE}/

# Build workspace packages in strict dependency order.
# Each package's build may be a no-op if it has no TypeScript source yet
# (run-typescript-project.mjs handles this gracefully).
RUN pnpm --filter @nexoraa/types       run build 2>&1
RUN pnpm --filter @nexoraa/constants   run build 2>&1
RUN pnpm --filter @nexoraa/utils       run build 2>&1
RUN pnpm --filter @nexoraa/config      run build 2>&1
RUN pnpm --filter @nexoraa/shared      run build 2>&1
RUN pnpm --filter @nexoraa/common      run build 2>&1
RUN pnpm --filter @nexoraa/database    run build 2>&1
RUN pnpm --filter @nexoraa/logger      run build 2>&1
RUN pnpm --filter @nexoraa/swagger     run build 2>&1

# Build the target service
RUN pnpm --filter @nexoraa/${SERVICE} run build

# Create a standalone deployment directory:
# - Production node_modules only (no devDependencies)
# - Workspace package dependencies resolved and included
# - Result is a self-contained deployable artefact at /deployment
RUN pnpm --filter @nexoraa/${SERVICE} deploy --legacy /deployment

# Safety: ensure dist/ is present in the deployment directory.
# pnpm deploy copies all non-ignored files; this explicit copy is a fallback
# in case the package's gitignore excluded dist/ from the deploy bundle.
RUN if [ -d "apps/backend/${SERVICE}/dist" ]; then \
      cp -r "apps/backend/${SERVICE}/dist" /deployment/dist; \
    fi

# ─────────────────────────────────────────────────────────────────────────────
# Stage: runner
# Minimal production image.  Only dist/ and production node_modules are
# present — no TypeScript toolchain, no dev dependencies, no source.
# ─────────────────────────────────────────────────────────────────────────────
FROM node:${NODE_VERSION} AS runner
ARG SERVICE=auth-service

# Runtime environment
ENV NODE_ENV=production
ENV PORT=3000

WORKDIR /app

# Create a non-root system user for running the process.
# Containers should never run as root in production.
RUN addgroup --system --gid 1001 nexoraa \
    && adduser  --system --uid 1001 \
                --ingroup nexoraa \
                --shell /sbin/nologin \
                nexoraa

# Copy the standalone deployment produced by `pnpm deploy`
COPY --from=builder --chown=nexoraa:nexoraa /deployment ./

# Drop to non-root user
USER nexoraa

# Expose the port the service listens on (overridden by PORT env var)
EXPOSE 3000

# ─── Healthcheck ──────────────────────────────────────────────────────────────
# Docker uses the liveness endpoint.
# Kubernetes should use its own readinessProbe / livenessProbe independently.
# --start-period gives the app time to connect to databases before failing.
HEALTHCHECK \
    --interval=30s \
    --timeout=10s \
    --start-period=60s \
    --retries=3 \
    CMD wget -qO- "http://localhost:3000/api/v1/health/live" \
        > /dev/null 2>&1 || exit 1

# Start the compiled entry point.
# dist/main.js is the default output of tsc for all NestJS services in this repo.
CMD ["node", "dist/main.js"]
