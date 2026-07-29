# Phase 13 Plan — Expenses and Cash Registers

## Scope

Expense categories/records/evidence/corrections and branch register open, cash movements, expected/actual calculation, variance, close/reopen, reconciliation, events, and reports inputs.

## Contracts

- **Consumes:** Branch/User/Tenant settings, `SVC-PAYMENT-003`, Payment events, `SVC-FILE-001/002`, `SVC-AUDIT-001`.
- **Produces:** `SVC-EXPENSE-001`, `SVC-EXPENSE-002`, `SVC-EXPENSE-003`, `EVT-EXPENSE-RECORDED-001`, `EVT-REGISTER-CLOSED-001`.

## Acceptance criteria

1. `FR-EXPENSE-01`: at most one register per branch/business date.
2. `FR-EXPENSE-02`: authorized expense/category/evidence lifecycle is scoped.
3. `FR-EXPENSE-03`: all defined cash sources reconcile to expected/actual/variance.
4. `FR-EXPENSE-04`: non-zero variance explanation and governed correction/reopen are enforced.
5. `FR-EXPENSE-05`: reports derive from authoritative records and expose drift.

## Out

Payment ownership, general ledger/accounting suite, payroll, invented cutoff/reopen policy.
