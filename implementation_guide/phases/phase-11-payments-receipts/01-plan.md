# Phase 11 Plan — Payments and Receipts

## Scope

Payment recording/verification, partial/full/split/advance/policy overpayment, idempotency, authoritative settlement, provider/manual references, refunds/corrections, immutable receipts, history/search, and financial events.

## Contracts

- **Consumes:** `SVC-ORDER-006`, `SVC-USER-002`, `SVC-TENANT-005`, `SVC-AUDIT-001`; Notification enqueue contract.
- **Produces:** `SVC-PAYMENT-001`, `SVC-PAYMENT-002`, `SVC-PAYMENT-003`, `SVC-PAYMENT-004`, `SVC-PAYMENT-005`, `EVT-PAYMENT-RECORDED-001`, `EVT-PAYMENT-CORRECTED-001`, `EVT-RECEIPT-ISSUED-001`.

## Acceptance criteria

1. `FR-PAYMENT-01`: permitted payment types/methods record against payable order.
2. `FR-PAYMENT-02`: settlement derives deterministically from authoritative facts.
3. `FR-PAYMENT-03`: retries/duplicates have one financial effect.
4. `FR-PAYMENT-04`: receipt evidence is immutable and traceable.
5. `FR-PAYMENT-05`: refund/correction is additive.
6. `FR-PAYMENT-06`: approvals/separation enforce approved policy.
7. `FR-PAYMENT-07`: history/search are scoped and credential-safe.

## Out

Invented provider/card storage, expense/register ownership, unresolved financial policy, mutable finalized payment.
