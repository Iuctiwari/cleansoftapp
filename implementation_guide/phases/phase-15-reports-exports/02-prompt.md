# Phase 15 Build Brief — Reports and Exports

## Schemas

Implement `reportFacts`/`reportRollups` with source/version uniqueness, tenant/branch/business date/timezone, immutable financial snapshot dimensions/metrics, checkpoint. Export metadata uses File/Job contracts, not public blobs.

## Routes/interfaces

Implement `/reports/:reportKey`, export create/retrieve, `SVC-REPORT-001`–`003`; consume all declared producer events.

## Rules

- Core reports cover orders, payments/refunds, expenses/registers, customer balances, branch performance, and operational status as defined by available facts.
- Use frozen transaction values; never current catalog price for history.
- Tenant/branch/role filters mandatory.
- ≤366-day synchronous query budget; large CSV async.
- Export access reauthorizes original scope and expires under `OQ-22`.
- Every figure includes lineage/checkpoint or documented source mapping.
- Rebuild/reconciliation cannot alter source.

## What not to build

No PDF, forecasting, direct domain collection joins, public download URL, guessed retention, or report definition unsupported by existing requirements.

