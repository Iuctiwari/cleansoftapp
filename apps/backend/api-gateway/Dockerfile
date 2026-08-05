# syntax=docker/dockerfile:1.7

ARG NODE_VERSION=22.13.0
ARG PNPM_VERSION=10.13.1

FROM node:${NODE_VERSION}-bookworm-slim AS base

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN npm install -g pnpm@${PNPM_VERSION}

FROM base AS pruner
WORKDIR /repo

# Copy the monorepo so Turbo can calculate the minimal workspace graph
COPY . .

# Create a pruned workspace for just the API Gateway and its internal dependencies
RUN pnpm dlx turbo@2.5.2 prune --scope=@nexoraa/api-gateway --docker

FROM base AS installer
WORKDIR /repo

# Copy dependency metadata
COPY --from=pruner /repo/out/json/ ./
COPY --from=pruner /repo/out/pnpm-lock.yaml ./pnpm-lock.yaml

# Install dependencies
RUN --mount=type=cache,id=pnpm-store,target=/pnpm/store \
    pnpm fetch --frozen-lockfile

RUN --mount=type=cache,id=pnpm-store,target=/pnpm/store \
    pnpm install --frozen-lockfile --offline

FROM installer AS builder
WORKDIR /repo

# Copy the pruned workspace source
COPY --from=pruner /repo/out/full/ ./

# Restore root files required by workspace build scripts
COPY --from=pruner /repo/scripts/run-typescript-project.mjs ./scripts/run-typescript-project.mjs
COPY --from=pruner /repo/tsconfig.base.json ./tsconfig.base.json

# Build API Gateway and required workspace packages
RUN pnpm turbo run build --filter=@nexoraa/api-gateway...

# Create a production deployment
RUN --mount=type=cache,id=pnpm-store,target=/pnpm/store \
    pnpm --filter @nexoraa/api-gateway --prod deploy --legacy /opt/app

FROM node:${NODE_VERSION}-bookworm-slim AS runner
WORKDIR /app

ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=3000

# Create non-root user
RUN groupadd --system --gid 1001 nodejs \
    && useradd --system --uid 1001 --gid nodejs nestjs

# Copy production application
COPY --from=builder --chown=nestjs:nodejs /opt/app ./

USER nestjs

EXPOSE 3000

CMD ["node", "dist/src/main.js"]