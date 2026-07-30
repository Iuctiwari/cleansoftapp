# Phase 13 — Expense Management and Cash Registers Implementation Prompt (Condensed)

## Phase Info
- **Phase:** 13 — Expense Management and Cash Registers
- **Owner:** `apps/backend/expense-service`
- **FRs:** FR-EXPENSE-01–05 | **Contracts:** SVC-EXPENSE-001–003
- **Events:** EVT-EXPENSE-RECORDED-001, EVT-REGISTER-CLOSED-001

## Execution Contract
Work from repo root. Read mandatory material, inspect current code/tests/`git status`. Repo is source of truth — prefer accepted ADRs, versioned contracts, and tests over prose when they conflict. Implement **only** Expense Management and Cash Registers — no other phases/modules.

Unresolved financial policy (business-date cutoff, overnight ops, register reopen authority, approval thresholds, currency-change behavior — governed by OQ-9/OQ-10): implement a configurable deny-by-default boundary with a stable `unresolved_financial_policy` or `approval_required` error. Never guess.

## Mandatory Reading
All architecture docs (`00-ARCHITECTURE`, `00-MASTER-PLAN`, `API-CONTRACTS`, `AUDIT-LOG`, `CODING-STANDARDS`, `CONTRACTS`, `DATA-MODEL`, `DECISIONS`, `DEPENDENCY-GRAPH`, `OBSERVABILITY`, `PROJECT_STATE`, `TESTING-STRATEGY`), plan docs (05_Functional_Requirements, 06_NonFunctional_Requirements, 08_Project_Glossary, 10_Open_Questions), `phase-13-expenses-registers/01-plan.md`, plus dependency completion reports, contracts, schemas, tests, ADRs, and READMEs in any touched directory. Verify actual source/tests (not just completion reports) for Auth, Tenant, Branch, User/RBAC, File Storage, Payment, Audit, Notifications, Reports, Dashboard, Search, Settings.

## Purpose
Build the cost-management and branch cash-reconciliation system: record/classify/approve/pay/correct/archive expenses with receipts, tenant+branch scoping, vendor/employee/department/activity attribution, full audit history; reconcile one cash register per branch per approved business date with server-derived expected cash and exposed variance; feed Reports, Dashboard, Search, Notifications, Audit via owned APIs/events.

Ownership split: Auth = who acts. Multi-tenancy = which org. Branch mgmt = where. RBAC = what's permitted. Payment = settlement facts. **Expense Management owns expense facts and register reconciliation.**

## Dependencies
Verify before building: actor identity, tenant isolation, branch context/access, RBAC/approval permissions, tenant currency + timezone settings, File Storage contracts (SVC-FILE-001/002), Audit (SVC-AUDIT-001), Payment lookup (SVC-PAYMENT-003) + versioned payment events, shared error/pagination/correlation/idempotency/outbox/concurrency conventions. Fix only the minimum defect needed for this phase, rerun affected dependency tests, don't scope-creep.

## Ownership Boundaries
**Owns:** expense categories, expense records/lifecycle/approval history/evidence refs, expense payment-tracking projection (not execution), corrections/archive history, vendor data (only if repo confirms Expense owns it), cash registers, append-only cash movements, expected/actual/variance calc, close snapshots + governed reopen history.

**Does not own:** auth/tenant/branch/department/employee masters, payment capture/refund/settlement, file binary storage, accounting/payroll/tax/procurement/inventory, reports/dashboards/search/notification delivery, any guessed policy (business-date cutoff, approval threshold, budget enforcement, reopen policy).

Cross-boundary access only via contracts/events — never read/write another service's private collections.

## Core Responsibilities
Expense recording, categories, vendor association, approval workflow, status management, payment tracking, receipts/attachments, allocation (branch/dept/employee/activity), search/filter/pagination, reporting inputs, audit, archive/correction, cash-register open/lookup/movement/close/reopen/reconciliation, idempotent processing of payment/refund/correction/expense cash effects.

## Workflows

**Expense:** record → resolve tenant/actor/branch → validate category/amount/currency/date/refs → attach evidence → editable while pre-final → submit for approval if required → approve/reject with remarks → payment status updated only via authorized command or authoritative Payment fact → finalize → publish event + deduplicated cash effect if cash → consumed by Reports/Dashboard/Search/Notifications/Audit → corrections are additive and linked, never overwrite finalized history.

**Cash Register:** cashier opens register for branch+approved business date → enforce max one register per `{tenantId, branchId, businessDate}` → same idempotency key returns existing result → authoritative cash receipts/refunds/corrected payment effects/finalized cash expenses create deduplicated movements → manual additions/withdrawals are append-only with reason → expected cash computed from movement stream → close takes actual cash only (never client-computed expected) → server recalculates expected cash in one transaction/snapshot → variance = actual − expected → non-zero variance requires explanation (+ approval if configured) → close creates immutable evidence + publishes EVT-REGISTER-CLOSED-001 → reopen preserves original snapshot, appends governed history.

## Financial Rules
- Money in integer minor units; validate currency on every aggregate/movement; reject mixed-currency arithmetic; no invented conversion.
- UTC timestamps; business date derived via approved branch/tenant timezone policy, never trusted from client.
- Expense amount > 0; tax ≥ 0; total calculated server-side.
- Finalized expense/register records are immutable; corrections/refunds/reversals/reopens are additive.
- Cash movements append-only or reversed via linked additive movement.
- File evidence = reference only, no binary duplication.

```
expected cash = opening cash + cash receipts + manual additions
                - cash refunds - finalized cash expenses - manual withdrawals
```
Clients cannot supply/override expected cash. Preserve each source effect for reproducibility.

## Data Model
Follow `DATA-MODEL.md` conventions: schema versioning, timestamps, optimistic concurrency, audit fields, tenant-first indexes, soft-archive fields.

- **expenseCategories**: `_id, tenantId, code, name, description?, budgetLimitMinor?, currency?, requiresEvidence, status, createdBy, updatedBy, createdAt, updatedAt, version`. Unique `{tenantId, code}`; tenant-first status index; referenced-by-finalized-expense categories can't hard-delete; budget limits are tracking-only unless policy authorizes enforcement.

- **expenses**: `_id, tenantId, branchId, expenseNumber, categoryId, vendorId?, employeeId?, departmentId?, businessActivityId?, expenseDate, businessDate, amountMinor, taxAmountMinor?, totalAmountMinor, currency, paymentMethod?, paymentSource, paymentReferenceId?, paymentStatus, approvalStatus, status, description, notes?, evidenceFileIds, correctionOf?, archiveReason?, createdBy, updatedBy, createdAt, updatedAt, version`. Unique tenant-scoped expenseNumber; indexes on `{tenantId,branchId,businessDate,status}`, `{tenantId,categoryId,businessDate}`, plus payment/approval/vendor/employee/archive filters. Finalized = additive correction only; archive is soft, never removes history.

- **vendors** (only if Expense confirmed as owner): `_id, tenantId, code, name, contactPerson?, mobileNumber?, email?, address?, taxRegistrationNumber?, paymentTerms?, status` + audit fields. Otherwise store an opaque validated reference via the authoritative vendor contract. No procurement scope.

- **expenseAttachments** (only if repo pattern requires history beyond `evidenceFileIds`): `_id, tenantId, branchId, expenseId, fileId, fileName, fileType, uploadedBy, uploadedAt, status`. Validate via File Storage; preserve evidence required by finalized expenses.

- **expenseApprovals** (append-only): `_id, tenantId, branchId, expenseId, actorId, previousStatus, newStatus, decision, remarks?, decidedAt, policyVersion?, createdAt`. Never overwrite; block self-approval when policy requires; no invented thresholds.

- **cashRegisters**: `_id, tenantId, branchId, businessDate, status, openedBy, openedAt, openingCashMinor, currency, expectedCashMinor, actualCashMinor?, varianceMinor?, varianceReason?, closedBy?, closedAt?, closeSnapshot?, reopenHistory, createdAt, updatedAt, version`. Unique `{tenantId,branchId,businessDate}`; index `{tenantId,branchId,status}`; closeSnapshot holds inputs/movement identity/expected/actual/variance/actor/time/policy version; original close evidence immutable after reopen.

- **cashMovements** (append-only): `_id, tenantId, branchId, registerId, businessDate, type, sourceType, sourceId, sourceVersion?, effectKey, amountMinor, currency, reason?, reversalOf?, createdBy, createdAt`. Unique source-effect identity for idempotency; index `{tenantId,registerId,createdAt}`; older out-of-order source version can't replace a newer effect; corrections use compensating/replacement effects per event contract.

## Status & Approval Rules
Distinguish (exact names per shared contracts): Draft/Recorded → Submitted/Pending → Approved/Rejected → Paid/Settled → Finalized → Archived → Corrected/Reversed. Keep payment status, approval status, and record status as separate fields — never overload one.

- Only permitted pre-final fields editable before approval.
- Submission validates required evidence/references.
- Approval/rejection require authorized actor + append history; rejection requires remarks.
- Final approval locks protected financial fields; modification after that requires an explicit reopen/correction path.
- Payment status changes only via authorized command or authoritative Payment integration.
- Every financial/lifecycle transition emits audit evidence.

## REST APIs
Use `/api/v1` prefix, typed DTOs, stable error envelopes, bounded pagination/filtering/sorting, correlation IDs, idempotency, optimistic concurrency. Preserve backward compatibility for existing verbs; no duplicate unversioned routes.

**Expenses:** `POST /expenses` · `GET /expenses` (filters: branch, date range, category, vendor, employee, department, payment/approval/expense status, archive state, expense number, approved search fields) · `GET /expenses/:id` · `PATCH /expenses/:id` · `PATCH /expenses/:id/submit` · `PATCH /expenses/:id/approve` · `PATCH /expenses/:id/reject` · `POST /expenses/:id/correct` · `POST /expenses/:id/attachments` · `PATCH /expenses/:id/archive`

**Categories:** `POST /expense-categories` · `GET /expense-categories` · `GET /expense-categories/:id` · `PATCH /expense-categories/:id` · `PATCH /expense-categories/:id/archive`

**Vendors:** CRUD only if Expense is confirmed vendor owner; otherwise reference-validation only.

**Cash Registers:** `POST /cash-registers/open` (idempotent) · `GET /cash-registers/current` · `GET /cash-registers/:id` · `POST /cash-registers/:id/movements` · `POST /cash-registers/:id/close` · `POST /cash-registers/:id/reopen`

No route may let clients create authoritative payment/refund movements directly.

## Validation Rules
Authenticated tenant/actor required; branch must belong to tenant with actor access; category must exist/be active/belong to tenant; vendor/employee/department/activity validated via authoritative contracts; amounts positive, tax ≥ 0, total computed server-side; currency validated; only supported statuses accepted; expense/business date validated per policy (no future date unless explicitly allowed); receipt files validated for ownership/type/size/state; evidence required when policy demands it; remarks required for rejection/correction/archive/manual movement/non-zero variance/reopen; optimistic version required on protected updates; idempotency enforced on create/open/submit/approve/close and retry-sensitive consumer effects; stale versions rejected; protected fields locked post-approval; no hard delete of financial records/evidence.

**Stable error codes:** `expense_not_found`, `expense_finalized`, `invalid_expense_transition`, `category_not_found`, `category_inactive`, `vendor_not_found`, `evidence_required`, `currency_mismatch`, `approval_required`, `register_already_exists`, `register_not_open`, `business_date_mismatch`, `variance_reason_required`, `version_conflict`, `unresolved_financial_policy`. Unauthorized vs. cross-tenant must be indistinguishable in error detail.

## Security
Tenant isolation everywhere (APIs, persistence, events, jobs, caches, logs); branch access enforced before any read/write; deny-by-default RBAC for every mutating action; approval authorization validated server-side, not from UI state; block unauthorized self-approval; never trust client-supplied tenant/actor/totals/expected-cash/approval/settlement values; audit every financial/lifecycle mutation with before/after-safe metadata + actor + reason + correlation; redact receipts/PII/tax IDs/descriptions from logs; signed/authorized File Storage access only, no public evidence URLs; soft archive + additive correction only; guard against mass assignment, NoSQL injection, unbounded queries, duplicate events, replay, race conditions, stale writes.

## Events & Integrations
**Consume:** payment recorded / corrected / refunded events; relevant branch/user/membership/category/file-state events. Use durable inbox/idempotency, validate contract version, preserve correlation/causation IDs, tolerate compatible evolution and out-of-order delivery.

**Publish** (transactionally via outbox — never for uncommitted state):
- `EVT-EXPENSE-RECORDED-001`: event/schema identity, tenant, branch, expense identity+version, category, money/currency, payment source, business date, lifecycle state, correlation/causation/actor/time.
- `EVT-REGISTER-CLOSED-001`: event/schema identity, tenant, branch, register, business date, expected/actual/variance money, close version/checkpoint, governed-variance flag, correlation/causation/actor/time.

**Integrate with:** Auth, Multi-Tenancy, Branch Mgmt, User/RBAC, File Storage, Payment Mgmt, Reports/Dashboard, Notifications, Search, Audit, Settings (currency/timezone/evidence/approved policy).

## Background Jobs
Only where an accepted contract/owner exists: approval reminders, pending-approval notifications, budget-utilization calc, monthly summaries, analytics aggregation, receipt metadata orchestration, search projection sync/recovery, audit/outbox recovery, register-drift detection. All jobs: tenant-aware, idempotent, retryable with bounded backoff, observable, concurrency-safe. Never invent approval decisions, mutate Payment facts, or silently repair drift — surface it instead.

## Observability
Structured redacted logs with correlation/causation IDs; metrics for create/submit/approve/reject/correct, register open/close/reopen, consumer lag, duplicate suppression, failures, reconciliation drift; tracing without leaking sensitive content; alerts on repeated event failures, outbox/inbox backlog, unexpected variance, source-effect conflicts, report drift; health/readiness checks for MongoDB, event/job infra, dependencies.

## Performance
Tenant-first compound indexes matching real query shapes; bounded cursor/page pagination with stable sort; no unbounded attachment/approval/movement expansion; register totals via consistent indexed query or independently-reconcilable maintained aggregate; measure (don't assume from code) latency/throughput/query plans/concurrency for expense creation, filtered listing, search, bulk event ingestion, attachment retrieval, register close, report inputs. Never trade correctness/auditability/isolation for benchmarks.

## Testing
**Unit:** creation + server-side totals, protected-field update rules, category/vendor validation, evidence/attachment validation, status/approval transition matrix, submit/approve/reject/archive/correction, business-date + currency validation, expected-cash formula, variance calc + reason requirement, register open/movement/close/reopen-history, payment-event classification/dedup/correction/out-of-order handling.

**Integration:** auth/actor context, tenant/branch validation, RBAC/approval, File Storage refs, payment facts + cash movement projection, notification output, Report/Dashboard contracts, Search projection, audit + outbox/inbox, MongoDB unique constraints + transactions.

**Security:** cross-tenant/cross-branch access, unauthorized mutations (submit/approve/reject/correct/archive/close/reopen), self-approval policy, mass assignment/NoSQL injection, file access authorization, replay/duplicate prevention, stale-version/close-race behavior, audit integrity, log redaction.

**Performance/Reliability:** creation under concurrency, paginated/filterable listing, indexed search, bulk processing, attachment retrieval, register movement ingestion + close at scale, report generation, dependency timeout/retry/circuit/recovery, outbox/inbox retry + poison-message handling.

Run format/lint/type-check/unit/integration/security/build for every touched workspace. Never disable rules, weaken types, skip failing tests, or misreport results.

## Implementation Sequence
1. Read sources; build acceptance checklist.
2. Inspect repo, current code, dependency evidence, uncommitted changes.
3. Confirm ownership, contracts, enums, failure modes, unresolved-policy boundaries.
4. Verify dependency behavior/tests.
5. Build expense categories + expense persistence with tenant-first indexes.
6. Build vendor reference handling (+ owned scope only if confirmed).
7. Build attachment metadata/File Storage integration.
8. Build expense/approval/payment/archive/correction state machines.
9. Build expense + category APIs.
10. Build cash-register + append-only movement persistence.
11. Build idempotent payment/refund/expense source-effect consumers.
12. Build server-authoritative expected cash, close snapshot, variance, governed reopen.
13. Build SVC-EXPENSE-001–003 APIs.
14. Build transactional outbox events + durable consumers.
15. Build audit, notifications, search/report/dashboard integrations, approved jobs.
16. Add unit/integration/security/concurrency/reliability/performance tests.
17. Update only phase-owned documentation.
18. Run all validation; review final diff for scope, secrets, correctness, isolation.
19. Update Phase 13 status/completion evidence factually.
20. Stop — do not start another phase.

## Deliverables
Expense Service (controller/application/domain/repository layering); category lifecycle; expense recording/validation/allocation/approval/payment-tracking/archive/evidence/correction; ownership-correct vendor handling; cash-register open/movement/reconciliation/close/reopen; versioned APIs/DTOs/errors/events/jobs/migrations; tenant+branch RBAC with full audit coverage; Reports/Dashboard/Search/Notifications/File Storage/Payment/Settings/Audit integrations; unit/integration/security/concurrency/reliability/performance tests; accurate documentation.

## Acceptance Criteria

**Expense Mgmt:** tenant/branch-scoped recording · minor-unit amounts, server-side totals · category CRUD + safe archive · ownership-validated vendor/employee/department/activity refs · File Storage receipts · explicit/enforced submit-approve-reject-pay-status transitions · finalized records immutable · additive/linked/audited corrections · preserved expense + approval history · paginated/filterable/sorted/indexed/scoped listing.

**Cash Registers:** one register per tenant+branch+business date · race-safe idempotent open · append-only deduplicated movements · approved classification for payment/refund/correction/expense/addition/withdrawal effects · server-side expected cash · close takes actual cash, recalculates, stores immutable evidence · non-zero variance requires reason + configured authorization · reopen preserves original close + appends governed history · drift exposed, not hidden.

**Security/Isolation:** tenant isolation everywhere · branch access enforced · deny-by-default RBAC + approval auth · no unauthorized actions or direct source-effect creation · sensitive data/log redaction · immutable audit evidence for every mutation.

**Integrations/Ops:** Payment facts integrated without owning Payment · File evidence integrated without owning binaries · approved contracts delivered to Reports/Dashboard/Search/Notifications/Audit/Settings · idempotent/tenant-aware/observable/recoverable consumers+jobs · health/readiness/metrics/tracing/alerts cover material failures.

**Quality:** all test suites pass · format/lint/type-check/build pass per workspace · representative performance results + query plans recorded · no guessed/hidden financial policy · no scope creep into unrelated modules or destructive edits · documentation reflects only implemented, verified behavior.

## Completion Instructions
1. Map every acceptance criterion to code/tests/docs/evidence in the final diff.
2. Run all relevant validation commands; record exact command + outcome.
3. Never report skipped/unavailable/failed checks as passing.
4. Record all file changes with exact repo-relative paths.
5. Record schema/index migrations, compatibility, versioned contract changes, rollback notes.
6. Record architecture/security decisions, including how unresolved policy was denied/externalized.
7. Record measured performance + representative workload details.
8. Record known limitations (impact, required authority, next safe action).
9. Verify no secrets, junk, unsafe fixtures, public receipt URLs, or unrelated changes.
10. Verify no cross-service private database access.
11. Verify no unjustified extra APIs/collections.
12. Update Phase 13 status/completion doc with factual evidence.
13. Stop after Phase 13 — do not begin Search, Reports, Dashboard, or later phases.