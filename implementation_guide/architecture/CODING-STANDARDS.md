# Coding Standards

## Authority

These standards migrate Phase 2 development rules and detailed module-prompt conventions. They constrain future implementation; they do not authorize code changes.

## Module structure

- One logical owner per domain; no direct reads/writes of another owner's private collections.
- Transport/controller code is thin: parse, authenticate, authorize, call domain contract, map result.
- Domain rules are framework-light and independently testable.
- Persistence adapters enforce tenant/branch scope and optimistic concurrency.
- Provider adapters implement internal contracts and never leak provider payloads into domain models.
- Shared packages contain technical primitives/contracts only, not shared mutable domain ownership.

## Type and validation

- Strict TypeScript and Dart analysis.
- No `any`/dynamic escape without narrow documented boundary and test.
- Validate every inbound request, internal message, event, job, provider callback, and configuration source.
- Use allowlisted update DTOs; never spread request bodies into persistence.
- IDs and client selectors are data, never authorization proof.
- Return typed results/errors; do not swallow errors or use hidden fallback.

## Tenant and branch scope

- Tenant identity is derived from verified context and immutable in domain records.
- Branch-owned access always includes tenant + authorized branch.
- Repository methods require explicit scope; unscoped domain query APIs are prohibited.
- Cache keys, queues, jobs, events, files, telemetry, exports, and projections include scope.
- Tests must include cross-tenant and cross-branch negative cases.

## Financial and numerical rules

- Currency: integer minor units plus ISO code.
- Quantity/percentage: fixed precision type with explicit scale.
- Rounding only at approved boundaries; no binary floating-point money.
- Server calculates totals; clients display returned truth.
- Store transaction snapshots.
- Finalized financial facts are immutable; correction/refund/reversal is additive.
- Every harmful duplicate supports idempotency.

## Time

- Store instants in UTC.
- Calculate business dates with approved tenant/branch timezone.
- Expiry and scheduled logic use injectable/deterministic clocks.
- APIs emit ISO-8601 UTC plus business-date/timezone fields where interpretation requires them.

## API and contracts

- Follow `API-CONTRACTS.md`, `CONTRACTS.md`, and `ADR-016`.
- Stable error codes/categories; internal details never cross the public boundary.
- Lists are bounded and use filter/sort allowlists.
- Concurrency-sensitive mutation requires expected version.
- Contract change updates contracts, consumers, compatibility tests, ADR when material, and phase status in the same change.

## Events and jobs

- Events are completed facts, past tense, minimal, versioned, and contain standard envelope.
- Write outbox with domain transaction.
- Consumers deduplicate, tolerate additive fields, and own retry/DLQ policy.
- Jobs are typed/versioned/idempotent and include scope/correlation.
- No infinite retry; replay is authorized and audited.

## Security

- Deny by default and reauthorize in owning service.
- Secrets only through validated configuration/secret manager.
- Password/OTP/token material is hashed/securely stored and never logged.
- Redact PII/restricted data in logs, errors, events, and provider metadata.
- Rate limit sensitive operations.
- Private files only; validate purpose, type, extension, size, metadata, and scan state.

## Naming

- Domain language follows `../01_plan/08_Project_Glossary.md`.
- Type/class names: PascalCase; functions/variables: lower camel case; constants: established language convention.
- Contract identifiers (`FR-*`, `SVC-*`, `EVT-*`, `ADR-*`, `OQ-*`, `A-*`, `R-*`) are copied exactly.
- Collections are plural lower camel case; event physical naming remains blocked by `OQ-25`.
- Boolean names express positive predicates (`isActive`, `canRefund`) and avoid ambiguous flags.

## Comments and documentation

- Comments explain invariant, risk, or non-obvious reason—not restate code.
- Public/internal contract declarations document inputs, output, errors, idempotency, versioning, and consumers.
- Material architecture change receives an append-only ADR.
- No credentials, unsafe production instructions, or unsupported completion claims in documentation.

## Quality

- Format, lint, type analysis, unit/contract/integration tests as applicable.
- No test disabling, analyzer suppression, or reduced security to make a gate pass.
- Migrations have forward/rollback/compatibility and tenant-safety review.
- A phase is not done until acceptance evidence is factual; stubs do not satisfy behavior.

