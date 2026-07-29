# Nexoraa CleanSoft Implementation Guide

## Structure

1. [Plan](01_plan/) — product truth: vision, scope, personas, journeys, stable requirements, NFRs, modules, glossary, assumptions/risks, and open questions.
2. [Architecture](architecture/00-MASTER-PLAN.md) — engineering truth: ADRs, contracts, APIs, data ownership, dependency graph, quality, observability, and state rollup.
3. [Phases](phases/) — dependency-ordered build truth: one plan, self-contained build brief, and live status per phase.

## Rules

- Cite stable IDs; do not replace them with paraphrased requirements.
- Contracts precede implementation.
- `architecture/DECISIONS.md` and `architecture/AUDIT-LOG.md` are append-only.
- Each phase `04-status.md` is the status source of truth.
- Create a phase `03-audit.md` only after real business logic exists.
- Unresolved product decisions remain `OQ-*`; assumptions remain `A-*`; risks remain `R-*`.
- No legacy completion claim overrides current repository/runtime evidence.

## Current state

All documentation phases are planned; no implementation is claimed complete. See [PROJECT_STATE.md](architecture/PROJECT_STATE.md).

## Migration provenance

Existing details were migrated from `ERP-PLANNING`, `docs`, module prompts, audits, and repository evidence. Originals remain available while retirement/archival policy `OQ-34` is unresolved. See [MIGRATION-SOURCE-MAP.md](MIGRATION-SOURCE-MAP.md).

