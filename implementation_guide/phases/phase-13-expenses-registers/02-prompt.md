# Phase 13 — Expense Management and Cash Registers Implementation Prompt

## Phase Information

- **Phase number:** 13
- **Phase name:** Expense Management and Cash Registers
- **Primary backend owner:** `apps/backend/expense-service`
- **Status:** Implementation prompt
- **Functional requirements:** `FR-EXPENSE-01` through `FR-EXPENSE-05`
- **Service contracts:** `SVC-EXPENSE-001`, `SVC-EXPENSE-002`, `SVC-EXPENSE-003`
- **Published events:** `EVT-EXPENSE-RECORDED-001`, `EVT-REGISTER-CLOSED-001`

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 13. Work from the repository root and execute this prompt end to end.

The repository is the source of truth. Before changing files, read the mandatory material, inspect the current implementation and tests, review `git status`, and preserve unrelated work. Reconcile this prompt with newer accepted architecture decisions and tested behavior. When prose conflicts, prefer accepted ADRs, versioned contracts, executable tests, and the narrowest interpretation that satisfies this phase.

Implement only Expense Management and Cash Registers. Do not begin another phase. Do not implement unrelated ERP modules.

Do not guess unresolved financial policy. Business-date cutoff, overnight operation, register reopen authority, approval thresholds, and currency-change behavior remain governed by `OQ-9`, `OQ-10`, and related accepted decisions. If a required policy is unresolved, implement a configurable deny-by-default boundary, return a stable `unresolved_financial_policy` or `approval_required` error where appropriate, document the limitation, and avoid embedding a speculative rule.

## Mandatory Reading

Read these files completely before implementation:

- `implementation_guide/README.md`
- `implementation_guide/architecture/00-ARCHITECTURE.md`
- `implementation_guide/architecture/00-MASTER-PLAN.md`
- `implementation_guide/architecture/API-CONTRACTS.md`
- `implementation_guide/architecture/AUDIT-LOG.md`
- `implementation_guide/architecture/CODING-STANDARDS.md`
- `implementation_guide/architecture/CONTRACTS.md`
- `implementation_guide/architecture/DATA-MODEL.md`
- `implementation_guide/architecture/DECISIONS.md`
- `implementation_guide/architecture/DEPENDENCY-GRAPH.md`
- `implementation_guide/architecture/OBSERVABILITY.md`
- `implementation_guide/architecture/PROJECT_STATE.md`
- `implementation_guide/architecture/TESTING-STRATEGY.md`
- `implementation_guide/01_plan/05_Functional_Requirements.md`
- `implementation_guide/01_plan/06_NonFunctional_Requirements.md`
- `implementation_guide/01_plan/08_Project_Glossary.md`
- `implementation_guide/01_plan/10_Open_Questions.md`
- `implementation_guide/phases/phase-13-expenses-registers/01-plan.md`
- Completion reports, contracts, schemas, tests, and ADRs from all direct dependency phases
- Every README in a directory touched by this phase
- The current repository tree, package manifests, environment examples, and `git status`

Also inspect the actual source and tests for Authentication, Tenant, Branch, User/RBAC, File Storage, Payment, Audit, Notifications, Reports, Dashboard, Search, and Settings integrations. Do not trust a completion report when the implementation or tests disagree.

## Overall Purpose

Build the operational cost-management and branch cash-reconciliation system for Nexoraa CleanSoft.

The module must:

- Record, classify, track, approve, pay, correct, archive, and report business expenses.
- Preserve receipts and supporting-document references.
- Associate expenses with the authenticated tenant and the correct branch.
- Support department, employee, vendor, and business-activity attribution when authoritative references exist.
- Maintain a complete, auditable expense history.
- Reconcile one branch cash register per approved tenant-local business date.
- Derive expected cash from authoritative, deduplicated cash movements.
- Record actual cash and expose variance without hiding reconciliation drift.
- Feed Reports, Dashboard, Search, Notifications, and Audit through owned APIs and versioned events.

Authentication determines who records, submits, approves, rejects, pays, corrects, or archives an expense. Multi-Tenancy determines which organization owns it. Branch Management determines where the expense and register activity occurred. User Management and RBAC determine permitted actions. Payment Management remains authoritative for settlement facts. Expense Management owns expense facts and branch register reconciliation.

## Dependencies

Verify the following capabilities before feature implementation:

- Authenticated actor context and stable user identity.
- Tenant context and strict tenant isolation.
- Branch context, tenant ownership validation, and branch access.
- User/RBAC permissions and approval authorization.
- Tenant currency and branch/tenant timezone settings.
- File upload/reference contracts from `SVC-FILE-001` and `SVC-FILE-002`.
- Audit recording through `SVC-AUDIT-001`.
- Payment lookup or settlement contract `SVC-PAYMENT-003`.
- Versioned Payment events, including recorded and corrected cash effects.
- Shared error, pagination, correlation, idempotency, outbox/inbox, and optimistic-concurrency conventions.

If a dependency is incomplete, repair only the minimum defect necessary for Phase 13, document why it was required, and rerun the dependency’s affected tests. Do not broaden the repair into unrelated feature work.

## Responsibility Boundaries

### This Module Owns

- Expense categories.
- Expense master records and lifecycle.
- Expense approval history.
- Expense evidence metadata or references.
- Expense payment-tracking projection/reference, not payment execution.
- Expense correction and archive history.
- Vendor data only if the repository confirms Expense is its authoritative owner.
- Branch cash registers.
- Append-only cash movements.
- Expected, actual, and variance calculations.
- Register close snapshots, governed reopen history, and reconciliation evidence.

### This Module Does Not Own

- Authentication, memberships, tenant, branch, department, or employee master data.
- Payment capture, refund execution, gateway credentials, or settlement mutation.
- File binary storage or unrestricted file serving.
- Accounting ledgers, payroll, tax filing, procurement, or inventory.
- Reports, dashboards, search indexes, or notification delivery.
- A guessed business-date cutoff, approval threshold, budget-enforcement policy, or reopen policy.

Use service contracts and versioned events across ownership boundaries. Never read or write another service’s private MongoDB collections.

## Core Responsibilities

- Expense recording.
- Expense category management.
- Vendor association and permitted vendor management.
- Expense approval workflow.
- Expense status management.
- Expense payment tracking.
- Receipt and attachment management.
- Branch, department, employee, and business-activity allocation.
- Expense search, filtering, sorting, and pagination.
- Expense reporting inputs.
- Expense audit management.
- Expense archive and additive correction.
- Cash-register open, current-register lookup, movement recording, close, reopen, and reconciliation.
- Idempotent processing of authoritative payment, refund, correction, and expense cash effects.

## Business Workflows

### Expense Workflow

1. An authorized employee or manager records an expense.
2. The service resolves authenticated tenant, actor, and branch context.
3. The service validates category, amount, currency, business date, optional vendor, employee, department, and activity references.
4. Supporting receipt or document references are validated and attached.
5. The expense remains editable in an allowed pre-final state.
6. When approval is required, the expense is submitted for review.
7. An authorized approver approves or rejects it with remarks.
8. Payment status is updated only from an authorized command or authoritative Payment fact.
9. A finalized expense publishes its versioned event and contributes a deduplicated cash effect when the payment source is cash.
10. Reports, Dashboard, Search, Notifications, and Audit consume the owned record or event.
11. Finalized history is never silently overwritten; corrections are additive and linked to the original.

### Cash-Register Workflow

1. An authorized cashier opens the register for a branch and approved business date.
2. The service enforces at most one register for each `{ tenantId, branchId, businessDate }`.
3. Opening the same logical register with the same idempotency identity returns the existing result safely.
4. Authoritative cash receipts, refunds, corrected payment effects, and finalized cash expenses create deduplicated source movements.
5. Authorized additions and withdrawals are recorded as append-only manual movements with a reason.
6. Expected cash is calculated from the immutable movement stream.
7. At close, the user supplies actual cash, never client-computed expected cash.
8. The server recalculates expected cash from authoritative movements in a consistent transaction/snapshot.
9. Variance is stored as `actualCashMinor - expectedCashMinor`.
10. A non-zero variance requires an explanation and may require configured approval.
11. Close creates immutable close evidence and publishes `EVT-REGISTER-CLOSED-001`.
12. Reopen or correction preserves the original close snapshot and appends governed history.

## Financial Rules

- Represent all money in integer minor units.
- Store and validate currency on every financial aggregate and movement.
- Reject mixed-currency arithmetic.
- Use the approved tenant currency policy; do not invent currency conversion.
- Use UTC instants for timestamps.
- Derive business date using the approved branch/tenant timezone policy.
- Do not accept a client timestamp or date as authoritative without validation.
- Expense amount must be greater than zero.
- Tax, when supported by an accepted contract, must be non-negative and total must be calculated server-side.
- Finalized expense and register records are immutable historical truth.
- Corrections, refunds, reversals, and reopen actions are additive.
- Cash movements are append-only or reversed by a linked additive movement.
- File evidence is a reference to File Storage; this service must not duplicate binary ownership.

Expected cash must be calculated from approved classifications:

```text
expected cash =
  opening cash
  + cash receipts
  + manual additions
  - cash refunds
  - finalized cash expenses
  - manual withdrawals
```

Do not allow clients to supply or override expected cash. Preserve each included source effect so the calculation can be explained and reproduced.

## Data Model

Follow `DATA-MODEL.md` and accepted migration/contract conventions. Add schema versioning, timestamps, optimistic concurrency, audit fields, tenant-first indexes, and soft-archive fields where established by repository standards.

### `expenseCategories`

Required baseline fields:

- `_id`
- `tenantId`
- `code`
- `name`
- `description?`
- `budgetLimitMinor?`
- `currency?`
- `requiresEvidence`
- `status`
- `createdBy`
- `updatedBy`
- `createdAt`
- `updatedAt`
- `version`

Required indexes and behavior:

- Unique `{ tenantId, code }`.
- Tenant-first status/list index.
- Category names and codes are normalized according to repository conventions.
- Categories referenced by finalized expenses cannot be hard-deleted.
- Budget limits are tracking inputs unless an accepted policy explicitly authorizes hard enforcement.

### `expenses`

Required baseline fields:

- `_id`
- `tenantId`
- `branchId`
- `expenseNumber`
- `categoryId`
- `vendorId?`
- `employeeId?`
- `departmentId?`
- `businessActivityId?`
- `expenseDate`
- `businessDate`
- `amountMinor`
- `taxAmountMinor?`
- `totalAmountMinor`
- `currency`
- `paymentMethod?`
- `paymentSource`
- `paymentReferenceId?`
- `paymentStatus`
- `approvalStatus`
- `status`
- `description`
- `notes?`
- `evidenceFileIds`
- `correctionOf?`
- `archiveReason?`
- `createdBy`
- `updatedBy`
- `createdAt`
- `updatedAt`
- `version`

Required indexes and behavior:

- Unique tenant-scoped expense number using the repository’s approved numbering scope.
- `{ tenantId, branchId, businessDate, status }`.
- `{ tenantId, categoryId, businessDate }`.
- Tenant-first indexes for approved filters, payment status, approval status, vendor, employee, and archive state.
- Finalized records use additive correction instead of destructive update.
- Archive is soft and authorized; archive never removes audit or correction history.

### `vendors`

Implement this collection only if repository ownership review confirms Expense Management owns vendor master data. Otherwise, store an opaque validated vendor reference and use the authoritative vendor service contract.

Baseline fields when locally owned:

- `_id`
- `tenantId`
- `code`
- `name`
- `contactPerson?`
- `mobileNumber?`
- `email?`
- `address?`
- `taxRegistrationNumber?`
- `paymentTerms?`
- `status`
- audit timestamps and version

Protect contact and tax data, normalize searchable fields, and prohibit cross-tenant references. Do not build procurement or supplier-accounting scope.

### `expenseAttachments`

Use a separate collection only when repository patterns require attachment history beyond `evidenceFileIds`. Otherwise, model the same information through owned metadata and File Storage references without duplicating binary data.

Baseline fields:

- `_id`
- `tenantId`
- `branchId`
- `expenseId`
- `fileId`
- `fileName`
- `fileType`
- `uploadedBy`
- `uploadedAt`
- `status`

Enforce unique attachment identity as appropriate, validate file ownership and allowed type/size through File Storage, and preserve evidence required by finalized expenses.

### `expenseApprovals`

Use an append-only approval-history collection or the repository’s accepted generic approval mechanism.

Baseline fields:

- `_id`
- `tenantId`
- `branchId`
- `expenseId`
- `actorId`
- `previousStatus`
- `newStatus`
- `decision`
- `remarks?`
- `decidedAt`
- `policyVersion?`
- `createdAt`

Never overwrite approval history. Prevent self-approval when configured policy forbids it. Do not invent approval thresholds.

### `cashRegisters`

Required baseline fields:

- `_id`
- `tenantId`
- `branchId`
- `businessDate`
- `status`
- `openedBy`
- `openedAt`
- `openingCashMinor`
- `currency`
- `expectedCashMinor`
- `actualCashMinor?`
- `varianceMinor?`
- `varianceReason?`
- `closedBy?`
- `closedAt?`
- `closeSnapshot?`
- `reopenHistory`
- `createdAt`
- `updatedAt`
- `version`

Required indexes and behavior:

- Unique `{ tenantId, branchId, businessDate }`.
- `{ tenantId, branchId, status }`.
- Close snapshot contains the calculation inputs, movement/checkpoint identity, expected cash, actual cash, variance, actor, time, and policy/contract version.
- Original close evidence remains immutable after reopen.

### `cashMovements`

Required baseline fields:

- `_id`
- `tenantId`
- `branchId`
- `registerId`
- `businessDate`
- `type`
- `sourceType`
- `sourceId`
- `sourceVersion?`
- `effectKey`
- `amountMinor`
- `currency`
- `reason?`
- `reversalOf?`
- `createdBy`
- `createdAt`

Required indexes and behavior:

- Unique source effect identity for authoritative or idempotent effects.
- `{ tenantId, registerId, createdAt }`.
- Append-only storage.
- An out-of-order older source version cannot replace a newer effect.
- Correction produces a compensating/replacement effect according to the versioned event contract.

## Expense Status and Approval Rules

Define explicit enums and a tested transition matrix. Reconcile exact names with existing shared contracts.

At minimum, distinguish:

- Draft or recorded.
- Submitted or pending approval.
- Approved.
- Rejected.
- Paid or settled where represented by the expense lifecycle.
- Finalized.
- Archived.
- Corrected or reversed.

Also distinguish payment status from approval status and record status. Do not overload one field for all three concerns.

Rules:

- Only permitted pre-final fields may change before approval.
- Submission validates all required evidence and references.
- Approval and rejection require an authorized actor and append approval history.
- Rejection requires remarks.
- Final approval locks protected financial fields.
- An approved/finalized expense cannot be modified unless an authorized reopen/correction path is explicitly available.
- Payment status must be based on an authorized command or authoritative Payment integration.
- Every financial or lifecycle transition emits audit evidence.

## REST APIs

Implement the canonical repository routes below. Use the established `/api/v1` gateway prefix where applicable, typed DTOs, stable error envelopes, bounded pagination, filtering, sorting, correlation IDs, idempotency, and optimistic concurrency.

### Expense APIs

- `POST /expenses` — create an expense.
- `GET /expenses` — list tenant/branch-scoped expenses.
- `GET /expenses/:expenseId` — get complete authorized expense details and actions.
- `PATCH /expenses/:expenseId` — update permitted pre-final fields with version checking.
- `PATCH /expenses/:expenseId/submit` — submit an expense for approval.
- `PATCH /expenses/:expenseId/approve` — approve a pending expense.
- `PATCH /expenses/:expenseId/reject` — reject a pending expense with remarks.
- `POST /expenses/:expenseId/correct` — create an additive linked correction with reason and required approval.
- `POST /expenses/:expenseId/attachments` — attach validated receipt/supporting-document references.
- `PATCH /expenses/:expenseId/archive` — soft-archive an eligible expense.

If the established API contract uses a different HTTP verb for an existing route, retain backward compatibility and document the canonical choice. Do not introduce duplicate semantics under multiple unversioned routes.

`GET /expenses` must support bounded, indexed filters for:

- Branch.
- Business/expense date range.
- Category.
- Vendor.
- Employee.
- Department.
- Payment status.
- Approval status.
- Expense status.
- Archive state.
- Exact expense number and approved safe search fields.

### Expense Category APIs

- `POST /expense-categories` — create a tenant-scoped category.
- `GET /expense-categories` — list authorized active or filtered categories.
- `GET /expense-categories/:categoryId` — get an authorized category.
- `PATCH /expense-categories/:categoryId` — update permitted fields with version checking.
- `PATCH /expense-categories/:categoryId/archive` — soft-archive an unused/eligible category.

### Vendor APIs

Add vendor CRUD/list routes only when Expense Management is confirmed as the authoritative vendor owner. Otherwise, do not duplicate the vendor master; implement only reference validation through the owning contract.

### Cash-Register APIs

- `POST /cash-registers/open` — open or idempotently return the branch/date register.
- `GET /cash-registers/current` — return the authorized current register for a branch.
- `GET /cash-registers/:registerId` — return register, movements, close evidence, and reconciliation.
- `POST /cash-registers/:registerId/movements` — append an authorized addition or withdrawal.
- `POST /cash-registers/:registerId/close` — recalculate and close using supplied actual cash and version.
- `POST /cash-registers/:registerId/reopen` — append a governed reopen action without destroying close history.

Do not expose a route that allows clients to create authoritative payment/refund movements directly.

## Validation Rules

- Require authenticated tenant and actor context.
- Validate branch belongs to the tenant and actor has branch access.
- Validate category exists, belongs to the tenant, and is active for new use.
- Validate vendor, employee, department, and activity references through authoritative contracts when provided.
- Require positive expense amounts and non-negative tax.
- Calculate total server-side and validate currency.
- Reject unsupported payment, approval, expense, category, register, and movement statuses.
- Validate expense date and business date using configured policy.
- Reject a future expense date unless an accepted setting explicitly permits it.
- Validate receipt file ownership, type, size, state, and purpose.
- Require evidence when the category or policy requires it.
- Require remarks for rejection, correction, archive, manual register movement, non-zero variance, and reopen as applicable.
- Require optimistic version on protected updates and lifecycle commands.
- Enforce idempotency on create/open/submit/approve/close and event-consumer effects where retry could duplicate a financial fact.
- Reject stale versions with the established conflict error.
- Prevent edits to protected fields after final approval.
- Prevent hard deletion of financial records and evidence.

Use stable machine-readable errors including, where applicable:

- `expense_not_found`
- `expense_finalized`
- `invalid_expense_transition`
- `category_not_found`
- `category_inactive`
- `vendor_not_found`
- `evidence_required`
- `currency_mismatch`
- `approval_required`
- `register_already_exists`
- `register_not_open`
- `business_date_mismatch`
- `variance_reason_required`
- `version_conflict`
- `unresolved_financial_policy`

Unauthorized and cross-tenant resources must not be distinguishable through error detail.

## Security Requirements

- Enforce tenant isolation in every command, query, repository filter, index, event, cache key, job, and log.
- Enforce branch access before reading or mutating branch-scoped records.
- Apply deny-by-default RBAC for create, update, submit, approve, reject, pay-status update, correct, archive, register open, manual movement, close, and reopen.
- Validate approval authorization independently of UI state.
- Prevent unauthorized self-approval where policy requires separation of duties.
- Never trust tenant, actor, totals, expected cash, approval, or payment settlement from client-controlled fields.
- Audit every financial and lifecycle mutation with before/after-safe metadata, reason, actor, tenant, branch, correlation, and source identity.
- Redact receipt URLs, personal data, tax identifiers, descriptions, notes, and financial details from logs unless explicitly safe and necessary.
- Use signed/authorized File Storage access instead of public evidence URLs.
- Use soft archive and additive correction; do not implement destructive financial deletion.
- Protect against mass assignment, NoSQL injection, unbounded queries, duplicate event delivery, replayed commands, race conditions, and stale writes.
- Include authorization facets in events/projections without leaking unnecessary personal or financial content.

## Event and Integration Requirements

### Consume

- Payment recorded events.
- Payment corrected/refunded events.
- Relevant branch, user, membership, category/settings, and file-state events where established.

Consumers must use durable inbox/idempotency records, validate contract version, preserve correlation and causation IDs, tolerate compatible evolution, and handle out-of-order delivery safely.

### Publish

#### `EVT-EXPENSE-RECORDED-001`

Include only the approved versioned contract fields:

- Event and schema identity.
- Tenant and branch.
- Expense identity and version.
- Category identity.
- Money and currency.
- Payment source.
- Business date.
- Lifecycle state.
- Correlation, causation, actor, and occurrence time.

#### `EVT-REGISTER-CLOSED-001`

Include only the approved versioned contract fields:

- Event and schema identity.
- Tenant, branch, register, and business date.
- Expected, actual, and variance money.
- Close version/checkpoint.
- Whether a governed variance exists.
- Correlation, causation, actor, and occurrence time.

Publish transactionally through the outbox. Never publish an event for a database state that did not commit.

### Integrate With

- Authentication for actor identity.
- Multi-Tenancy for ownership and isolation.
- Branch Management for location and access.
- User Management/RBAC for permissions and approval.
- File Storage for receipts and supporting documents.
- Payment Management for settlement and authoritative cash facts.
- Reports and Dashboard for expense, profitability, branch-performance, and register inputs.
- Notifications for pending approval, approval result, reminders, and variance alerts.
- Search for minimal authorized expense projections.
- Audit Service for immutable evidence.
- Settings for currency, timezone, evidence, and explicitly approved policy.

## Background Jobs

Implement jobs only when supported by an accepted contract and an owning worker:

- Expense approval reminders.
- Pending-approval notifications.
- Budget-utilization calculations.
- Monthly expense summaries.
- Expense analytics aggregation.
- Receipt metadata/processing orchestration through File Storage.
- Search projection synchronization or recovery.
- Audit/outbox delivery recovery.
- Cash-register reconciliation drift detection.

Every job must be tenant-aware, idempotent, retryable with bounded backoff, observable, and safe under concurrent execution. Jobs must not invent approval decisions, mutate Payment facts, or silently repair financial drift. Drift must be surfaced for governed resolution.

## Observability Requirements

- Emit structured, redacted logs with correlation and causation IDs.
- Record metrics for expense create/submit/approve/reject/correct, register open/close/reopen, consumer lag, duplicate suppression, failures, and reconciliation drift.
- Trace cross-service calls and event processing without exposing sensitive descriptions, evidence, or tokens.
- Alert on repeated event failures, outbox/inbox backlog, unexpected register variance, source-effect conflicts, and report/source drift.
- Provide health and readiness checks for MongoDB, event/job infrastructure, and required dependency connectivity according to repository standards.

## Performance Requirements

- Use tenant-first compound indexes that match verified query shapes.
- Use bounded cursor/page pagination and stable sorting.
- Avoid unbounded attachment, approval, movement, or history expansion.
- Calculate register totals with a consistent indexed movement query or approved maintained aggregate that can be independently reconciled.
- Define representative workloads for expense creation, filtered listing, search, bulk event ingestion, attachment retrieval, register close, and financial-report inputs.
- Measure latency, throughput, query plans, concurrency behavior, and resource use.
- Do not claim performance from code inspection alone.
- Never trade correctness, auditability, or isolation for benchmark results.

## Testing Requirements

### Unit Tests

- Expense creation and server-side total calculation.
- Expense update and protected-field rules.
- Category and optional vendor validation.
- Evidence requirement and attachment validation.
- Status and approval transition matrix.
- Submission, approval, rejection, archive, and additive correction.
- Business-date and currency validation.
- Expected-cash formula.
- Variance calculation and reason requirement.
- Register open, movement, close, reopen-history preservation.
- Payment-event classification, deduplication, correction, and out-of-order handling.

### Integration Tests

- Authentication and actor context.
- Tenant and branch validation.
- User/RBAC and approval authorization.
- File Storage receipt references.
- Payment facts and cash movement projection.
- Notification event/output.
- Report and Dashboard data contracts.
- Search projection contract.
- Audit and outbox/inbox behavior.
- MongoDB unique constraints and transaction/session behavior.

### Security Tests

- Cross-tenant reads, writes, identifiers, filters, and event injection.
- Cross-branch access.
- Unauthorized expense modification.
- Unauthorized submit, approval, rejection, correction, archive, close, and reopen.
- Self-approval policy enforcement when configured.
- Mass-assignment and NoSQL injection attempts.
- Receipt/file access authorization.
- Replay and duplicate command/event prevention.
- Stale-version and close-race behavior.
- Audit integrity and sensitive-log redaction.

### Performance and Reliability Tests

- Expense creation under representative concurrency.
- Paginated/filterable expense listing.
- Expense search using approved indexed fields.
- Bulk expense/event processing.
- Attachment metadata retrieval.
- Register movement ingestion and close calculation at representative scale.
- Financial-report data generation.
- Dependency timeout, retry, circuit/failure, and recovery behavior.
- Outbox/inbox retry and poison-message handling.

At minimum, run format, lint, type-check, unit, integration, security, and build commands for every touched workspace plus relevant repository gates. Do not disable rules, weaken types, skip failing tests, or report unavailable tests as passed.

## Implementation Sequence

1. Read all mandatory sources and create a private checklist mapped to acceptance criteria.
2. Inspect the repository, current implementation, dependency completion evidence, and uncommitted changes.
3. Confirm service ownership, API/event contracts, enums, failure modes, and unresolved-policy boundaries.
4. Verify critical dependency behavior and tests.
5. Implement or migrate expense categories and expense persistence with tenant-first indexes.
6. Implement vendor reference handling and only the ownership-confirmed vendor scope.
7. Implement attachment metadata/File Storage integration.
8. Implement explicit expense, approval, payment, archive, and correction state machines.
9. Implement the canonical expense and category APIs.
10. Implement cash-register and append-only movement persistence.
11. Implement idempotent payment/refund/expense source-effect consumers.
12. Implement server-authoritative expected cash, close snapshot, variance, and governed reopen history.
13. Implement APIs `SVC-EXPENSE-001` through `SVC-EXPENSE-003`.
14. Implement transactional outbox events and durable consumers.
15. Implement audit, notifications, search/report/dashboard integration contracts, and approved background jobs.
16. Add unit, integration, security, concurrency, reliability, and performance tests.
17. Update only documentation owned by the implemented phase when execution of this prompt is authorized.
18. Run all relevant validation and inspect the final diff for scope, secrets, financial correctness, and isolation.
19. Update the Phase 13 status/completion evidence with factual results.
20. Stop without starting another phase.

## Deliverables

- Expense Service implementation with clear controller, application/domain, and repository boundaries.
- Expense-category lifecycle.
- Expense recording, validation, allocation, approval, payment tracking, archive, evidence, and additive correction.
- Ownership-correct vendor association/management.
- Branch cash-register open, movement, reconciliation, close, and governed reopen behavior.
- Versioned APIs, DTOs, error contracts, events, jobs, and migrations/indexes.
- Tenant/branch-aware RBAC and complete audit coverage.
- Reports, Dashboard, Search, Notifications, File Storage, Payment, Settings, and Audit integrations.
- Unit, integration, security, concurrency, reliability, and measured performance tests.
- Accurate module, API, event, data, operations, and completion documentation.

## Acceptance Criteria

### Expense Management

- [ ] Authorized users can record valid tenant/branch-scoped expenses.
- [ ] Expense amounts use integer minor units and totals are calculated server-side.
- [ ] Categories can be created, listed, updated, and safely archived.
- [ ] Vendor, employee, department, and activity references are ownership-validated when used.
- [ ] Receipts and supporting documents use authorized File Storage references.
- [ ] Submission, approval, rejection, payment tracking, and status transitions are explicit and enforced.
- [ ] Finalized expenses cannot be silently modified or deleted.
- [ ] Corrections are additive, linked, authorized, and audited.
- [ ] Expense history and approval history are preserved.
- [ ] Expense listing is paginated, filterable, sortable, indexed, and tenant/branch scoped.

### Cash Registers

- [ ] At most one register exists per tenant, branch, and approved business date.
- [ ] Register open is race-safe and idempotent.
- [ ] Cash movements are append-only and authoritative source effects are deduplicated.
- [ ] Payment, refund, correction, expense, addition, and withdrawal effects use approved classifications.
- [ ] Expected cash is calculated server-side from authoritative movements.
- [ ] Close accepts actual cash, recalculates expected cash, and stores immutable close evidence.
- [ ] Non-zero variance requires a reason and configured authorization.
- [ ] Reopen/correction preserves the original close and appends governed history.
- [ ] Reconciliation drift is exposed rather than hidden.

### Security and Isolation

- [ ] Tenant isolation is enforced in all APIs, persistence, events, jobs, and integrations.
- [ ] Branch access control is enforced.
- [ ] RBAC and approval authorization are deny-by-default.
- [ ] Unauthorized financial actions and direct source-effect creation are prevented.
- [ ] Sensitive data and receipt access are protected and redacted from logs.
- [ ] Every financial and lifecycle mutation produces immutable audit evidence.

### Integrations and Operations

- [ ] Payment facts integrate without transferring Payment ownership.
- [ ] File evidence integrates without transferring binary ownership.
- [ ] Reports, Dashboard, Search, Notifications, Audit, and Settings receive the approved contracts.
- [ ] Event consumers and jobs are idempotent, tenant-aware, observable, and recoverable.
- [ ] Health, readiness, metrics, tracing, and alerts cover material failure modes.

### Quality

- [ ] Unit, integration, security, concurrency, reliability, and performance tests pass.
- [ ] Format, lint, type-check, and build gates pass for every touched workspace.
- [ ] Representative performance results and query plans are recorded.
- [ ] No unresolved financial policy was guessed or hidden in code.
- [ ] No unrelated module, payment mutation, accounting ledger, payroll, or destructive financial edit was added.
- [ ] Documentation and completion evidence describe only implemented, verified behavior.

## Completion Instructions

1. Review the final diff and map every acceptance criterion to code, configuration, tests, documentation, or measured evidence.
2. Run every relevant validation command and record the exact command and outcome.
3. Never report a skipped, unavailable, or failed check as passing.
4. Record all files created, modified, moved, or deleted using exact repository-relative paths.
5. Record schema/index migrations, compatibility behavior, versioned contract changes, and rollback considerations.
6. Record architecture and security decisions, including how unresolved policy was denied or externalized.
7. Record measured performance and representative workload details.
8. Record known limitations with impact, owner or required authority, and next safe action.
9. Verify no secret, generated junk, unsafe fixture, public receipt URL, or unrelated change is included.
10. Verify Expense Service never reads or writes another service’s private database.
11. Verify no extra APIs or collections were added without an ownership and contract justification.
12. Update the matching Phase 13 status/completion document with factual evidence when executing this implementation prompt.
13. Stop after Phase 13. Do not begin Search, Reports, Dashboard, or any later phase.
