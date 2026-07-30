# PHASE 11 — PAYMENT MANAGEMENT IMPLEMENTATION PROMPT

## Phase Information

- Phase Number: 11.
- Phase Name: Payment Management.
- Module: Payment Management.
- Scope: Customer order payments, adjustments, refunds, receipts, reconciliation, and listed integrations.
- Status: Implementation prompt.

## Role and Boundaries

- Implement only the Nexoraa CleanSoft Payment Management module defined here, then stop.
- Preserve Authentication, Multi-Tenancy, Branch, User/RBAC, Customer, Service, Order, Cash Register, Delivery, Tenant Settings, Notification, Reporting, Dashboard, Search, Audit, and Gateway boundaries.
- Preserve the current architecture, business workflow, four collections, eight REST APIs, integrations, test categories, and document structure.
- Payment Management records financial transactions; it references but does not replace owning modules.
- Do not add unrelated modules, collections, APIs, DTO scope, or business functionality.

## Financial Source of Truth

- The immutable `payments` ledger is the financial source of truth.
- Order payment fields are cached projections only and never override Payments.
- Recalculate an Order projection from Payments whenever a write occurs or inconsistency is detected.
- Use one calculation everywhere, including APIs, jobs, reports, dashboards, receipts, reconciliation, tests, and projections.
- `paidAmountMinor = SUM(amountMinor)` for Successful `Advance`, `Partial`, and `Final` records only.
- `refundedAmountMinor = SUM(amountMinor)` for Successful `Refund` and `Adjustment` records only.
- `outstandingAmountMinor = grandTotalMinor - paidAmountMinor + refundedAmountMinor`.
- Never include `Refund` or `Adjustment` in `paidAmountMinor`.
- Use signed business meaning through `paymentType`; persist every `amountMinor` as a positive integer.
- Use integer minor currency units for every monetary field; floating-point money is forbidden.
- Currency precision and conversion rules come from Tenant Settings; do not mix currencies in one Order calculation.

## Core Responsibilities

- Collect, verify, search, reconcile, and permanently preserve Advance, Partial, Final, Refund, and Adjustment payments.
- Support enabled payment methods, gateway references, partial payments, split tender, COD, and receipts.
- Prevent duplicates, overpayments, unauthorized refunds, closed-register cash activity, and cross-tenant access while maintaining deterministic Order payment status and cached projections.
- Publish existing payment events to the listed integrations without changing integration ownership.

## Immutability and Status Rules

- Never update or delete an original payment, transaction, receipt, refund, or financial history record.
- Refunds and Adjustments always create new additive payment records linked to the affected payment and Order.
- Require a non-empty normalized `reason` for every Refund and Adjustment.
- Do not implement a `Reversed` status; represent reversals with additive Refund or Adjustment records.
- Treat any legacy `Reversed` value as read-only migration data and never create it in new workflows.
- Effective payment status is derived from the latest append-only transaction event as `Pending`, `Successful`, or `Failed`; approval status is separate, and verification appends evidence without mutating financial facts.
- `PUT /payments/:paymentId` remains for compatibility but must reject persisted-record mutation with an immutable-record conflict.

## Deterministic Order Payment Status

- Recompute amounts first from Successful Payments using the single formula.
- Apply this ordered decision tree exactly once and reuse it everywhere.
- If `outstandingAmountMinor <= 0`, status is `Paid`.
- Else if `refundedAmountMinor > 0` and `paidAmountMinor - refundedAmountMinor <= 0`, status is `Refunded`.
- Else if `refundedAmountMinor > 0`, status is `PartiallyRefunded`.
- Else if `paidAmountMinor > 0`, status is `PartiallyPaid`.
- Else if at least one relevant transaction is Pending, status is `Pending`.
- Else status is `Unpaid`.
- Cancelled is an Order lifecycle status, not a payment status.

## Business Workflow

1. Authenticate the actor and enforce tenant, branch, and RBAC context.
2. Validate Order, Customer, currency, tenant-enabled method, and Idempotency-Key.
3. Derive `businessDate` from tenant timezone and configured business-day cutoff.
4. For Cash, validate the matching branch register is open for that active `businessDate`.
5. Validate normal-payment Order state; block normal payments on Cancelled Orders.
6. Explicitly allow authorized Refund and Adjustment creation for Cancelled Orders.
7. Validate approval policy, reason, amounts, source links, and refund method rules where applicable.
8. In one database transaction, reserve tenant numbering and prevent overpayment under concurrency.
9. For split tender, validate and persist every tender atomically or persist none.
10. Persist immutable Payments and transaction details, then generate or queue the receipt.
11. Recalculate Order projections and deterministic payment status from Payments.
12. Update Cash Register reconciliation projections and complete COD settlement when applicable.
13. Emit existing audit, notification, search, report, and dashboard integration events.
14. Store the successful response against the idempotency key and return it for every retry.

## Database Collections

### `payments`

- Store tenantId, branchId, registerId when applicable, paymentNumber, paymentGroupId for split tender, Order ID, Customer ID, and sourcePaymentId when applicable.
- Store paymentType, method, amountMinor, currency, status, reason when required, transaction reference, notes, receivedBy, businessDate, paymentDate, and audit timestamps.
- Store immutable idempotency identity sufficient to enforce `{ tenantId, idempotencyKey, operation }`.
- Require the unique index `{ tenantId, paymentNumber }`; numbers may repeat across tenants.
- Require index `{ tenantId, customerId }` for customer payment history.
- Require Order, branch, businessDate, status, method, and reconciliation indexes to remain tenant-prefixed.
- Advance, Partial, and Final increase paid amount only when Successful.
- Refund and Adjustment increase refunded amount only when Successful.

### `paymentTransactions`

- Preserve gateway, COD, settlement, verification, response, and safe provider-reference details linked to Payment.
- Store tenantId, paymentId, transactionId, gateway/provider reference, status, processedAt, and reconciliation metadata.
- Keep provider references uniquely scoped where applicable and preserve every attempt.

### `paymentReceipts`

- Store tenantId, paymentId/paymentGroupId, receiptNumber, immutable artifact URL, generatedBy, generatedAt, generationVersion, and supersedesReceiptId.
- Require the unique index `{ tenantId, receiptNumber }`; numbers may repeat across tenants.
- First Successful Payment or atomic split-tender group receives a receipt.
- Regeneration creates a new immutable receipt with a new tenant-scoped receiptNumber and `supersedesReceiptId`.
- Never overwrite or reuse an earlier receipt artifact; expose the newest version while retaining the full chain.

### `refunds`

- Preserve the existing collection as refund request, approval, and processing metadata linked to source and additive Refund Payment records.
- Store tenantId, branchId, paymentId, refundPaymentId, amountMinor, currency, mandatory reason, method, requestedBy, requestedAt, approvalStatus, approvedBy, approvedAt, notes, and audit timestamps.
- Approval statuses are `NotRequired`, `Pending`, `Approved`, or `Rejected`.
- Refund financial effect exists only through a Successful additive Refund Payment.

## Validation and Business Rules

- Require existing tenant-owned Order and Customer and authorized branch access.
- Require positive safe-integer minor-unit amounts and the Order currency.
- Validate methods against Tenant Settings `paymentMethodsEnabled`.
- Require `Idempotency-Key` for Payment, Refund, and Adjustment creation.
- Scope idempotency by tenant and operation; a retry with the same canonical request returns the original successful response.
- Reject reuse of a key with a different canonical payload.
- Lock or version the Order/payment aggregate inside a MongoDB transaction, recalculate from Payments, validate amount, and commit atomically.
- Reject concurrent normal payments whose combined amount exceeds outstanding unless an existing tenant overpayment policy explicitly permits it.
- Validate cumulative Successful Refunds against refundable paid amount and apply the same concurrency protection.
- Block Advance, Partial, and Final creation on Cancelled Orders; permit authorized Refund and Adjustment transactions.
- Require mandatory reason for Refund and Adjustment and validate the linked source.
- Derive businessDate server-side; never accept createdAt as its substitute.
- Cash requires an open register for the same tenant, branch, and active businessDate.
- Reject Cash when the register is closed, absent, stale, or on another businessDate.
- Track Successful cash inflows as `cashPayments` and Successful cash Refund outflows as `cashRefunds` for register reconciliation.
- Default refunds to the original method; permit method changes only when Tenant Settings policy allows the requested method.
- Read refund approval threshold and rules from Tenant Settings.
- Above-threshold or policy-matched refunds remain Pending and have no financial effect until an authorized approver records Approved with `approvedBy` and `approvedAt`.
- Rejected approvals create no Refund Payment; approved processing remains idempotent.
- Preserve transaction-reference uniqueness where applicable.

## Split Tender and COD

- Support split tender through existing `POST /payments` with two or more tender lines and one paymentGroupId.
- Validate each method, amount, register requirement, and reference before writing.
- Sum tender amounts using minor units and apply one overpayment check against the freshly calculated outstanding amount.
- Create one immutable Payment per tender and one grouped successful response in a single transaction.
- If any tender fails, roll back numbering, Payments, projections, receipt work, and register effects.
- COD uses existing APIs and collections and is coordinated with Delivery Management.
- Require delivery assignment/state authorization and Payment/COD RBAC before recording COD.
- At delivery, record the enabled tender method, verify Cash register rules when Cash, generate a receipt, and create settlement details.
- Delivery confirmation succeeds only after the COD Payment is Successful and settlement is recorded atomically or through the existing reliable integration contract.
- Retries from Delivery use the same Idempotency-Key and return the original result.

## REST APIs

- `POST /payments`: create single/split Payment or Adjustment, require Idempotency-Key, and apply all transaction, register, COD, and concurrency rules.
- `GET /payments/:paymentId`: return tenant/branch-authorized immutable details, transactions, receipts, refunds, and approval state.
- `PUT /payments/:paymentId`: preserve the route but reject mutation because Payments are immutable.
- `GET /payments`: return tenant-scoped paginated search/filter/sort, including Order, Customer, branch, method, type, status, and businessDate filters.
- `PATCH /payments/:paymentId/verify`: idempotently verify Pending processing under RBAC without rewriting original financial facts.
- `POST /payments/:paymentId/refund`: require Idempotency-Key and reason, apply approval policy, and create the additive Refund Payment only when approved.
- `POST /payments/:paymentId/receipt`: generate or regenerate immutable, tenant-numbered receipt versions under RBAC.
- `GET /payments/order/:orderId`: return permanent ledger history, grouped split tenders, refunds, adjustments, receipts, projections, and deterministic status.
- Implement only these eight APIs; do not add payment-method, balance, transaction, receipt-retrieval, archive, adjustment-specific, split-tender-specific, or COD-specific routes.

## Integration Requirements

- Authentication supplies authenticated actor context; Multi-Tenancy enforces ownership, timezone, currency, cutoff, methods, and policy.
- Branch Management validates branch ownership; User Management/RBAC authorizes record, verify, refund, approve, receipt, COD, and history actions.
- Customer Management validates Customer; Service Management remains represented through the linked Order.
- Order Management supplies grandTotalMinor and lifecycle state; it consumes recalculated cached projections but Payments remain authoritative.
- Cash Register validates open register/businessDate and reconciles cashPayments separately from cashRefunds.
- Delivery Management coordinates authorized COD recording, receipt, settlement, and delivery confirmation.
- Tenant Settings supplies paymentMethodsEnabled, refund method-change policy, approval threshold/rules, timezone, cutoff, currency, and overpayment policy.
- Payment Gateway supplies immutable attempts and verification; Notification Management uses existing payment/refund/receipt events.
- Reports and Dashboard consume successful ledger facts and businessDate; Search synchronizes tenant-scoped payment data.
- Audit Service records creation, verification, approvals, refunds, adjustments, receipt regeneration, projection repair, COD, and reconciliation.

## Background Jobs

- Preserve verification, reminder, receipt, approved-refund, reconciliation, daily-summary, revenue-aggregation, and audit jobs.
- Jobs use businessDate and the authoritative ledger formula, are idempotent, and never mutate original financial records.
- Reconciliation detects Order projection drift and repairs projections from Payments with audit evidence.
- Receipt jobs preserve numbering/version chains; refund jobs enforce approval and register rules again at execution.

## Testing Requirements

### Unit Tests

- Test the single paid/refunded/outstanding formula, exclusion rules, minor-unit validation, and deterministic ordered payment status.
- Test enabled methods, mandatory reasons, businessDate cutoff/timezone boundaries, refund policy/approval thresholds, method changes, and Cancelled-Order exceptions.
- Test immutable records, additive Refund/Adjustment behavior, receipt regeneration, split-tender validation, and projection reconstruction.

### Integration Tests

- Test tenant-scoped paymentNumber/receiptNumber uniqueness and customer-history index behavior.
- Test Idempotency-Key success replay, payload mismatch, per-operation scope, and concurrent retries.
- Test transaction/optimistic-concurrency overpayment prevention, concurrent refunds, rollback, and projection consistency.
- Test open/closed/stale Cash registers, active businessDate, cashPayments/cashRefunds reconciliation, and refund method policy.
- Test refund approval Pending/Approved/Rejected paths and unauthorized approval.
- Test atomic split tender success/failure and mixed Cash/non-Cash tenders.
- Test COD recording, RBAC, receipt, settlement, retries, and delivery-confirmation gating.
- Test Order, Customer, Gateway, Notification, Reports, Dashboard, Search, Audit, Settings, Cash Register, and Delivery integrations.

### Security Tests

- Test tenant/branch isolation, RBAC, immutable PUT rejection, unauthorized refund/adjustment/COD, and audit coverage.
- Test Cancelled-Order normal-payment rejection while Refund and Adjustment remain authorized.

### Performance Tests

- Test high-volume concurrent payment/refund creation, listing, customer history, Order history, receipt generation, search, and reconciliation.

## Implementation Sequence

1. Preserve scope, collections, APIs, boundaries, and existing integrations.
2. Implement minor-unit schemas, tenant indexes, businessDate, idempotency, immutable ledger types, approval metadata, and receipt versions.
3. Implement authoritative calculations, deterministic status, transactional concurrency protection, projection repair, and numbering.
4. Implement validation, Cash Register, Settings, split tender, refund approval, COD, receipt, RBAC, audit, and existing events.
5. Implement the eight APIs, background jobs, complete tests, documentation, and completion evidence.
6. Verify acceptance criteria and stop without starting another phase.

## Deliverables

- Payment collection, verification, methods, Advance/Partial/Final, additive Refund/Adjustment, outstanding balance, status, receipt, history, search, reconciliation, audit, and archive behavior.
- Existing `payments`, `paymentTransactions`, `paymentReceipts`, and `refunds` collections only.
- Existing eight REST APIs only.
- Unit, integration, security, and performance tests plus module, collection, API, validation, security, integration, and completion documentation.

## Acceptance Criteria

- [ ] Payments are immutable; Refunds and Adjustments are additive records with mandatory reasons, and no new Reversed status is created.
- [ ] Verification and effective-status changes are append-only and never rewrite original financial facts.
- [ ] Successful Advance/Partial/Final alone form paidAmountMinor; Successful Refund/Adjustment alone form refundedAmountMinor; outstanding uses the single formula.
- [ ] Every monetary value uses integer minor currency units without floating-point arithmetic.
- [ ] `{ tenantId, paymentNumber }`, `{ tenantId, receiptNumber }`, and `{ tenantId, customerId }` indexes behave as specified.
- [ ] Idempotency-Key is mandatory for Payment, Refund, and Adjustment and safely replays the original successful response.
- [ ] Transactions or optimistic concurrency prevent concurrent overpayment/refund races and atomically protect split tender.
- [ ] Cancelled Orders reject normal payments but permit authorized Refunds and Adjustments.
- [ ] Payments are authoritative; Order projections and deterministic paymentStatus are rebuilt and repaired from the ledger.
- [ ] Cash validates open register and active businessDate, while reconciliation separates cashPayments and cashRefunds.
- [ ] businessDate is derived from tenant timezone/cutoff and used by APIs, jobs, reports, and reconciliation.
- [ ] Tenant-enabled methods, refund method-change policy, configurable approval threshold/status/approver/timestamp, and RBAC are enforced.
- [ ] COD recording, receipt, settlement, idempotent retry, and delivery confirmation integrate with Delivery Management under RBAC.
- [ ] Receipt regeneration issues a new tenant-scoped number/version and preserves every prior receipt.
- [ ] Unit, integration, security, performance, concurrency, numbering, idempotency, register, businessDate, method, approval, COD, split-tender, status, projection, and overpayment tests pass.
- [ ] All listed integrations work, all history remains auditable, no extra API or collection exists, and no unrelated module is implemented.

## Completion Instructions

1. Verify every responsibility, workflow step, collection, API, rule, integration, job, test category, and acceptance criterion.
2. Record test outcomes, created/modified files, limitations, migration notes for legacy Reversed data, and completion evidence.
3. Confirm exactly four collections and eight APIs, confirm no unrelated implementation, update the Payment Management completion report, and stop.

Do not start another phase.
