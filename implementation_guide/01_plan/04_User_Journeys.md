# User Journeys

Each journey cites the stable functional requirements defined in `05_Functional_Requirements.md`.

## J-01 — Tenant onboarding

1. An eligible Owner verifies identity (`FR-AUTH-01`).
2. The Owner supplies required business and plan information (`FR-TENANT-01`).
3. The system validates plan eligibility and limits (`FR-TENANT-03`).
4. Tenant, first branch, Owner membership, and defaults are coordinated (`FR-TENANT-02`, `FR-BRANCH-01`, `FR-USER-01`).
5. The tenant becomes Active only after the coordinated process succeeds (`FR-TENANT-02`).
6. The Owner continues into tenant configuration (`FR-SETTINGS-01`).
7. Failure leaves no partially Active workspace and provides a recoverable state (`FR-TENANT-02`, `FR-AUDIT-01`).

## J-02 — Staff invitation and activation

1. An authorized Owner or Branch Manager chooses branches, role, and permissions within their ceiling (`FR-USER-01`, `FR-USER-03`).
2. The system checks tenant limits and privilege-escalation rules (`FR-TENANT-03`, `FR-USER-03`).
3. A single-use, expiring invitation is issued (`FR-USER-02`).
4. The recipient accepts it, establishes a permanent credential, and activates membership (`FR-USER-02`, `FR-AUTH-04`).
5. The temporary credential becomes unusable and authorization state refreshes (`FR-AUTH-02`, `FR-USER-04`).
6. Every access change is audited (`FR-AUDIT-01`).

## J-03 — Customer intake and order creation

1. Cashier or staff searches the current tenant before creating a customer (`FR-CUSTOMER-01`).
2. They select an existing customer, create a new profile, or use approved walk-in handling (`FR-CUSTOMER-02`).
3. They choose branch-available services and item categories (`FR-CATALOG-01`, `FR-CATALOG-03`).
4. They enter quantities, notes, expected completion, and assignments (`FR-ORDER-01`).
5. The server validates authorization and calculates authoritative prices, tax, discounts, and totals (`FR-ORDER-02`).
6. The order stores catalog and customer snapshots (`FR-ORDER-02`).
7. A unique scoped order number is committed with audit/event obligations (`FR-ORDER-03`, `FR-AUDIT-01`).
8. A notification is created without controlling order success (`FR-NOTIFY-01`, `FR-NOTIFY-03`).

## J-04 — Order processing and exception recovery

1. Assigned staff see only authorized work (`FR-ORDER-04`, `FR-USER-03`).
2. The system validates each proposed state transition (`FR-ORDER-04`).
3. A successful transition records prior state, next state, actor, time, and notes (`FR-ORDER-04`).
4. A concurrency conflict rejects the stale update rather than overwriting it (`FR-ORDER-05`).
5. Cancellation requires a reason and triggers downstream correction facts (`FR-ORDER-05`).
6. Notification, report, search, and audit projections update idempotently (`FR-NOTIFY-01`, `FR-REPORT-01`, `FR-SEARCH-01`, `FR-AUDIT-01`).

## J-05 — Payment, refund, and receipt

1. The Cashier opens an authorized order and sees authoritative outstanding balance (`FR-PAYMENT-01`).
2. The Cashier records one or more permitted payment components (`FR-PAYMENT-01`, `FR-PAYMENT-02`).
3. Idempotency prevents a retry from creating a second financial effect (`FR-PAYMENT-03`).
4. The system derives settlement state and produces receipt evidence (`FR-PAYMENT-02`, `FR-PAYMENT-04`).
5. A refund or correction references the original transaction and creates a new additive record (`FR-PAYMENT-05`).
6. Customer/order balances, cash-register inputs, reports, and audit evidence reconcile (`FR-CUSTOMER-04`, `FR-EXPENSE-03`, `FR-REPORT-02`, `FR-AUDIT-01`).

## J-06 — Pickup or delivery completion

1. Authorized staff select an assigned ready order (`FR-DELIVERY-01`).
2. The system checks tenant policy for outstanding balance (`FR-DELIVERY-02`).
3. Staff record receiver and required proof (`FR-DELIVERY-03`, `FR-FILE-01`).
4. The order completes through the same governed lifecycle (`FR-DELIVERY-01`, `FR-ORDER-04`).
5. Customer notification and audit evidence are emitted independently (`FR-NOTIFY-01`, `FR-AUDIT-01`).

## J-07 — Branch cash close and discrepancy

1. The Cashier opens the branch register for the tenant-local business date (`FR-EXPENSE-01`).
2. Cash payments, refunds, expenses, additions, and withdrawals contribute to expected cash (`FR-EXPENSE-02`, `FR-EXPENSE-03`).
3. The Cashier enters actual cash without being allowed to alter source transactions (`FR-EXPENSE-03`).
4. The system calculates variance (`FR-EXPENSE-03`).
5. Non-zero variance requires an explanation and approved escalation (`FR-EXPENSE-04`).
6. Closing evidence becomes immutable and auditable; reopening follows a separate governed correction (`FR-EXPENSE-04`, `FR-AUDIT-02`).

## J-08 — Owner reporting and investigation

1. The Owner selects an allowed tenant/branch/date scope (`FR-REPORT-01`).
2. The dashboard shows role-appropriate KPIs and freshness (`FR-DASHBOARD-01`, `FR-DASHBOARD-02`).
3. Reports derive from immutable transaction snapshots and projections (`FR-REPORT-02`).
4. CSV export becomes asynchronous when size/date range exceeds the synchronous budget (`FR-REPORT-03`).
5. Every figure can be traced to authorized source records (`FR-REPORT-04`).
6. The Owner reviews separately authorized immutable audit evidence (`FR-AUDIT-03`).

## J-09 — Mobile connectivity loss and retry

1. The app identifies a network failure and shows an explicit offline/retry state (`FR-MOBILE-03`).
2. Read-only bounded cache may display safe previously authorized data with freshness context (`FR-MOBILE-03`).
3. Authoritative financial operations do not silently complete offline (`FR-MOBILE-03`, `FR-PAYMENT-03`).
4. A retry reuses the appropriate idempotency identity (`FR-PLATFORM-04`).
5. Authorization or tenant changes invalidate unsafe cached access (`FR-MOBILE-02`, `FR-USER-04`).

## J-10 — Support incident

1. Operations receives a correlated alert (`FR-PLATFORM-05`).
2. Approved support access is time-bound and least-privilege (`FR-PLATFORM-06`).
3. Logs exclude secrets and unnecessary personal data (`FR-PLATFORM-05`).
4. Recovery uses documented replay, rebuild, restore, or rollback paths (`FR-JOB-03`, `FR-REPORT-05`, `FR-SEARCH-03`).
5. Support actions and outcomes are audited (`FR-AUDIT-01`).

