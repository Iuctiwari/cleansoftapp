# PHASE 16 — PAYMENT MANAGEMENT IMPLEMENTATION PROMPT

## Phase Information

- Phase Number: 16.
- Phase Name: Payment Management.
- Module: Payment Management.
- Scope: Customer order payments and refunds.
- Status: Implementation prompt.

## Role

- Implement the Nexoraa CleanSoft Payment Management module.
- Use only the requirements defined in this prompt.
- Preserve existing Authentication functionality.
- Preserve existing Multi-Tenancy functionality.
- Preserve existing Branch Management functionality.
- Preserve existing User Management functionality.
- Preserve existing Customer Management functionality.
- Preserve existing Service Management functionality.
- Preserve existing Order Management functionality.
- Do not implement unrelated modules.
- Stop after completing Payment Management.

## Overall Purpose

- Manage the complete financial transaction lifecycle for customer orders.
- Record every payment received against an order.
- Track every payment.
- Validate every payment.
- Reconcile every payment.
- Support multiple payment methods.
- Support partial payments.
- Support advance payments.
- Support refunds.
- Track outstanding balances.
- Generate payment receipts.
- Preserve payment history.
- Link payments to customers.
- Link payments to orders.
- Link payments to tenants.
- Link payments to branches.
- Supply financial data to listed integrations.

## Payment Management Position

- Authentication identifies who performs the transaction.
- Multi-Tenancy identifies which business owns the payment.
- Branch Management identifies where the payment is collected.
- User Management controls who can process payments.
- Customer Management identifies who makes the payment.
- Service Management identifies the services being paid for.
- Order Management identifies the business transaction.
- Payment Management records the financial transaction.
- Reports consume payment data.
- Dashboards consume payment data.
- Notifications use payment events.
- Search uses payment data.

## Core Responsibilities

- Payment Collection.
- Payment Processing.
- Payment Verification.
- Payment Method Management.
- Partial Payment Management.
- Advance Payment Management.
- Outstanding Balance Management.
- Refund Management.
- Payment Status Management.
- Receipt Generation.
- Payment History.
- Payment Search and Filtering.
- Payment Reconciliation.
- Payment Audit Management.
- Payment Archive.

## Responsibility Boundaries

- Manage payment records only.
- Manage payment transaction details only.
- Manage payment receipt records only.
- Manage refund records only.
- Reference orders without replacing Order Management.
- Reference customers without replacing Customer Management.
- Reference branches without replacing Branch Management.
- Reference users without replacing User Management.
- Integrate with gateways without replacing Payment Gateway.
- Integrate with reports without implementing Reports.
- Integrate with dashboards without implementing Dashboard.
- Preserve immutable financial history.
- Preserve archived payments.

## Functional Areas

### 1. Payment Collection

- Record payment against an order.
- Require an existing order.
- Require an existing customer.
- Require payment amount greater than zero.
- Select a valid payment method.
- Record transaction reference when applicable.
- Record payment date.
- Record currency.
- Record received-by user.
- Generate a payment number.
- Store payment notes.

### 2. Payment Processing

- Process recorded payment information.
- Validate the order.
- Validate the customer.
- Validate the tenant.
- Validate the branch.
- Validate payment amount.
- Validate payment method.
- Validate currency.
- Store payment status.
- Store payment type.
- Preserve processing information.

### 3. Payment Method Management

- Support multiple payment methods.
- Validate selected payment method.
- Store payment method.
- Store gateway details when applicable.
- Store transaction reference when applicable.
- Keep transaction reference unique where applicable.
- Use the selected method during verification.

### 4. Partial and Advance Payments

- Support partial payments.
- Support advance payments.
- Record multiple payments against one order.
- Calculate remaining balance.
- Keep accepting permitted payments until balance is cleared.
- Prevent payment above outstanding balance unless configured.
- Update order payment status.
- Preserve every payment record.

### 5. Outstanding Balance Management

- Store outstanding amount.
- Calculate outstanding balance after payment.
- Recalculate balance after additional payments.
- Recalculate balance after refunds.
- Support outstanding balance reminders.
- Keep balance linked to the order.
- Keep order payment status current.

### 6. Refund Management

- Process refunds when applicable.
- Link every refund to a payment.
- Store refund amount.
- Store refund reason.
- Store refund date.
- Store refund status.
- Store approving user.
- Store refund notes.
- Prevent refund above original payment amount.
- Secure refund authorization.
- Preserve refund history.

### 7. Receipt Management

- Generate a receipt after payment verification.
- Regenerate a receipt through the listed API.
- Link receipt to payment.
- Store receipt number.
- Store receipt URL.
- Store generating user.
- Store generation time.
- Support receipt generation background processing.
- Preserve receipt information.

### 8. Payment Status Management

- Maintain payment status.
- Validate payment status.
- Support pending payment state.
- Support verified payment state.
- Support refund-related payment state.
- Preserve payment status history through payment history.
- Update order payment status.
- Prevent unauthorized status changes.

### 9. Payment Search and Filtering

- Search payment records.
- Filter payment records.
- Sort payment records.
- Paginate payment records.
- Filter by order.
- Filter by customer.
- Filter by branch.
- Filter by payment method.
- Filter by payment status.
- Keep search tenant-scoped.
- Keep access branch-scoped.

### 10. MongoDB Collections

- Implement the `payments` collection.
- Implement the `paymentTransactions` collection.
- Implement the `paymentReceipts` collection.
- Implement the `refunds` collection.
- Link every record to the correct payment.
- Keep payment data isolated by tenant.
- Keep payment access controlled by branch.
- Preserve financial history.

### 11. REST APIs

- Implement payment recording.
- Implement payment retrieval.
- Implement payment updates.
- Implement payment listing.
- Implement payment verification.
- Implement refund processing.
- Implement receipt generation.
- Implement order payment history.
- Do not add APIs outside the listed scope.

### 12. Validation Rules

- Validate order existence.
- Validate customer existence.
- Require payment amount greater than zero.
- Validate payment against outstanding balance.
- Validate payment method.
- Validate transaction-reference uniqueness where applicable.
- Validate refund amount.
- Validate payment status.
- Validate currency.
- Protect closed or cancelled orders.

### 13. Security

- Enforce tenant-level isolation.
- Enforce branch-level access control.
- Apply RBAC.
- Secure payment recording.
- Keep payment history immutable.
- Audit every financial transaction.
- Prevent duplicate submissions.
- Secure refund authorization.

### 14. Background Jobs

- Support payment verification.
- Support payment reminder notifications.
- Support outstanding balance reminders.
- Support receipt generation.
- Support refund processing.
- Support financial reconciliation.
- Support daily payment summaries.
- Support revenue aggregation.
- Support audit log processing.

### 15. Integrations

- Integrate with Authentication.
- Integrate with Multi-Tenancy.
- Integrate with Branch Management.
- Integrate with User Management.
- Integrate with Customer Management.
- Integrate with Service Management.
- Integrate with Order Management.
- Integrate with Notification Management.
- Integrate with Reports.
- Integrate with Dashboard.
- Integrate with Search.
- Integrate with Audit Service.
- Integrate with Settings.
- Integrate with Payment Gateway.

### 16. Testing

- Implement payment unit tests.
- Implement payment integration tests.
- Implement payment security tests.
- Implement payment performance tests.
- Test payment recording.
- Test partial payments.
- Test outstanding balances.
- Test refunds.
- Test receipts.
- Test status transitions.

### 17. Acceptance Criteria

- Verify payment recording.
- Verify multiple payment methods.
- Verify partial and advance payments.
- Verify outstanding balances.
- Verify receipts.
- Verify refunds.
- Verify permanent history.
- Verify order payment status.
- Verify tenant isolation.
- Verify branch isolation.
- Verify listed integrations.
- Verify all required tests.

## Business Workflow

1. Create the customer order.
2. Calculate total payable amount.
3. Select a valid payment method.
4. Record the payment.
5. Verify the payment.
6. Generate the receipt.
7. Update order payment status.
8. Calculate remaining balance for partial payment.
9. Record additional payments until permitted balance is cleared.
10. Process refunds when applicable.
11. Preserve payment history permanently.
12. Update listed Reports and Dashboard integrations.

## Workflow Requirements

- Keep every payment linked to the correct order.
- Keep every payment linked to the correct customer.
- Keep every payment linked to the correct tenant.
- Keep every payment linked to the correct branch.
- Keep every refund linked to the original payment.
- Keep every receipt linked to its payment.
- Keep every gateway transaction linked to its payment.
- Preserve all financial records.
- Apply security at every workflow step.
- Audit every financial change.

## Database Collections

### `payments`

#### Purpose

- Store master information for every payment.
- Act as the primary payment record.
- Keep payments tenant-scoped.
- Keep payments branch-scoped.
- Link payments to orders and customers.

#### Fields

- Tenant ID.
- Branch ID.
- Payment Number.
- Order ID.
- Customer ID.
- Payment Date.
- Payment Method.
- Transaction Reference.
- Amount Paid.
- Outstanding Amount.
- Currency.
- Payment Status.
- Payment Type.
- Notes.
- Received By.
- CreatedBy.
- UpdatedBy.
- CreatedAt.
- UpdatedAt.

#### Requirements

- Require tenant ownership.
- Require valid branch.
- Require valid order.
- Require valid customer.
- Require amount greater than zero.
- Validate outstanding amount.
- Validate currency.
- Validate payment method.
- Validate payment status.
- Validate payment type.
- Preserve audit information.
- Preserve archived payments.

### `paymentTransactions`

#### Purpose

- Store gateway details.
- Store transaction-level details.
- Keep every transaction linked to a payment.
- Preserve verification information.

#### Fields

- Payment ID.
- Gateway Name.
- Transaction ID.
- Gateway Reference.
- Response Code.
- Response Message.
- Status.
- Processed At.

#### Requirements

- Require valid payment.
- Store gateway name.
- Store transaction ID.
- Store gateway reference.
- Store response code.
- Store response message.
- Store transaction status.
- Store processing time.
- Preserve transaction history.

### `paymentReceipts`

#### Purpose

- Store generated receipt information.
- Keep every receipt linked to a payment.
- Preserve receipt generation details.

#### Fields

- Payment ID.
- Receipt Number.
- Receipt URL.
- Generated By.
- Generated At.

#### Requirements

- Require valid payment.
- Store receipt number.
- Store receipt URL.
- Store generating user.
- Store generation time.
- Preserve receipt information.

### `refunds`

#### Purpose

- Store payment refund records.
- Keep every refund linked to a payment.
- Preserve refund history.

#### Fields

- Payment ID.
- Refund Amount.
- Refund Reason.
- Refund Date.
- Refund Status.
- Approved By.
- Notes.

#### Requirements

- Require valid payment.
- Require valid refund amount.
- Prevent refund above original payment amount.
- Store refund reason.
- Store refund date.
- Store refund status.
- Store approving user.
- Store refund notes.
- Preserve refund information.

## Collection Relationships

- Link every payment to one tenant.
- Link every payment to one branch.
- Link every payment to one order.
- Link every payment to one customer.
- Link every transaction to one payment.
- Link every receipt to one payment.
- Link every refund to one payment.
- Preserve payment and transaction history.
- Preserve receipt information.
- Preserve refund history.

## REST APIs

### Record Payment

- Method: `POST`.
- Path: `/payments`.
- Purpose: Record payment against an order.
- Validate order.
- Validate customer.
- Validate tenant and branch.
- Validate payment amount.
- Validate payment method.
- Validate currency.
- Prevent duplicate submission.
- Calculate outstanding balance.

### Get Payment

- Method: `GET`.
- Path: `/payments/:paymentId`.
- Purpose: Return complete payment details.
- Validate payment identity.
- Validate tenant ownership.
- Apply branch access.
- Apply RBAC.
- Return transaction details.
- Return receipt details.
- Return refund details.

### Update Payment

- Method: `PUT`.
- Path: `/payments/:paymentId`.
- Purpose: Update editable payment information where permitted.
- Validate payment identity.
- Validate tenant ownership.
- Apply branch access.
- Apply RBAC.
- Limit changes to editable information.
- Preserve payment history.

### List Payments

- Method: `GET`.
- Path: `/payments`.
- Purpose: Return paginated payment records.
- Support pagination.
- Support filtering.
- Support sorting.
- Support searching.
- Support order filters.
- Support customer filters.
- Support branch filters.
- Support status filters.
- Enforce tenant isolation.

### Verify Payment

- Method: `PATCH`.
- Path: `/payments/:paymentId/verify`.
- Purpose: Verify a pending payment.
- Validate payment identity.
- Validate tenant ownership.
- Apply branch access.
- Apply RBAC.
- Validate transaction details.
- Update payment status.
- Update order payment status.
- Trigger receipt generation.

### Process Refund

- Method: `POST`.
- Path: `/payments/:paymentId/refund`.
- Purpose: Create a refund transaction.
- Validate payment identity.
- Validate tenant ownership.
- Apply branch access.
- Apply RBAC.
- Validate refund amount.
- Secure refund authorization.
- Preserve refund history.
- Update outstanding balance when applicable.

### Generate Receipt

- Method: `POST`.
- Path: `/payments/:paymentId/receipt`.
- Purpose: Generate or regenerate a receipt.
- Validate payment identity.
- Validate tenant ownership.
- Apply branch access.
- Apply RBAC.
- Store receipt information.
- Preserve generated receipt history.

### Payment History

- Method: `GET`.
- Path: `/payments/order/:orderId`.
- Purpose: Return all payments associated with an order.
- Validate order identity.
- Validate tenant ownership.
- Apply branch access.
- Apply RBAC.
- Return permanent payment history.
- Return partial and advance payment records.
- Return refund information.

## API Limit

- Implement only the eight listed Payment APIs.
- Do not add payment-method APIs.
- Do not add outstanding-balance APIs.
- Do not add transaction APIs.
- Do not add separate receipt retrieval APIs.
- Do not add archive APIs.
- Keep unlisted work within the listed API scope.

## Validation Rules

- Require an existing order.
- Require an existing customer.
- Require payment amount greater than zero.
- Prevent payment above outstanding balance unless configured.
- Require a valid payment method.
- Keep transaction reference unique where applicable.
- Prevent refund above original payment amount.
- Require valid payment status.
- Require currency to match tenant configuration.
- Prevent new payments on closed or cancelled orders unless permitted.

## Validation Checklist

- Validate order before recording payment.
- Validate customer before recording payment.
- Validate tenant ownership.
- Validate branch ownership.
- Validate amount paid.
- Validate outstanding amount.
- Validate payment method.
- Validate transaction reference.
- Validate currency.
- Validate payment status.
- Validate payment type.
- Validate refund amount.
- Validate refund status.

## Security Requirements

- Enforce tenant isolation for payment access, updates, lists, and search.
- Enforce branch ownership and branch-level access.
- Apply RBAC to record, view, update, verify, refund, receipt, and history operations.
- Secure every payment recording operation.
- Preserve immutable payment, transaction, receipt, and refund history.
- Audit every payment, verification, receipt, refund, and financial change.
- Prevent duplicate payment submissions.
- Require authorized refund approval.

## Integration Requirements

- Authentication: use authenticated user, tenant, and acting-user context.
- Multi-Tenancy: validate tenant ownership, isolation, and currency settings.
- Branch Management: validate payment branch and branch access.
- User Management: validate received-by and approving users and apply RBAC.
- Customer Management: validate and associate the customer.
- Service Management: provide service context through the linked order.
- Order Management: validate order, payable amount, balance, and payment-status update.
- Notification Management: support payment, receipt, and reminder notifications.
- Reports: supply payment and refund data for listed reports.
- Dashboard: supply payment and revenue data for listed dashboards.
- Search: support payment search and listed synchronization.
- Audit Service: audit every financial transaction.
- Settings: provide currency and payment configuration.
- Payment Gateway: provide gateway transaction and verification details.

## Background Jobs

- Payment verification: verify pending payments and preserve transaction details.
- Payment reminders: notify customers about pending payment.
- Outstanding reminders: notify customers about remaining balances.
- Receipt generation: create or regenerate payment receipts.
- Refund processing: process authorized refunds and preserve history.
- Financial reconciliation: reconcile payments and transaction details.
- Daily summaries: prepare daily payment information for listed integrations.
- Revenue aggregation: prepare revenue information for listed integrations.
- Audit processing: preserve every financial action and acting user.

## Testing Requirements

### Unit Tests

- Test payment recording.
- Test order validation.
- Test customer validation.
- Test payment method validation.
- Test partial payment calculation.
- Test advance payment handling.
- Test outstanding balance calculation.
- Test refund calculation.
- Test receipt generation.
- Test payment status transitions.
- Test duplicate prevention.

### Integration Tests

- Test Order Management integration.
- Test Customer Management integration.
- Test Notification Management integration.
- Test Payment Gateway integration.
- Test Reports integration.
- Test Dashboard integration.
- Test Search integration.
- Test Audit Service integration.
- Test Settings integration.

### Security Tests

- Test tenant isolation.
- Test branch isolation.
- Test unauthorized payment access.
- Test unauthorized payment modification.
- Test duplicate payment prevention.
- Test refund authorization.
- Test RBAC validation.
- Test immutable payment history.
- Test closed or cancelled order protection.

### Performance Tests

- Test payment recording performance.
- Test payment listing with pagination.
- Test receipt generation.
- Test payment search.
- Test high-volume concurrent payment processing.
- Test financial report data retrieval.
- Verify list performance.
- Verify reconciliation performance.

## Implementation Sequence

1. Confirm Phase 16 Payment Management scope.
2. Review the listed module purpose.
3. Review the listed responsibilities.
4. Review the listed functional areas.
5. Review the business workflow.
6. Implement `payments`.
7. Implement `paymentTransactions`.
8. Implement `paymentReceipts`.
9. Implement `refunds`.
10. Implement Payment Collection.
11. Implement Payment Processing.
12. Implement Payment Method Management.
13. Implement Partial and Advance Payments.
14. Implement Outstanding Balance Management.
15. Implement Refund Management.
16. Implement Receipt Management.
17. Implement Payment Status Management.
18. Implement Payment Search and Filtering.
19. Implement the eight listed APIs.
20. Implement the listed validation rules.
21. Implement the listed security controls.
22. Implement the listed background jobs.
23. Implement the listed integrations.
24. Implement the listed tests.
25. Verify the acceptance criteria.
26. Update Payment Management documentation.
27. Record completion evidence.
28. Stop without starting another phase.

## Deliverables

### Payment Features

- Payment Collection.
- Payment Processing.
- Payment Verification.
- Payment Method Management.
- Partial Payment Management.
- Advance Payment Management.
- Outstanding Balance Management.
- Refund Management.
- Payment Status Management.
- Receipt Generation.
- Payment History.
- Payment Search and Filtering.
- Payment Reconciliation.
- Payment Audit Management.
- Payment Archive.

### Collections

- `payments`.
- `paymentTransactions`.
- `paymentReceipts`.
- `refunds`.

### APIs

- `POST /payments`.
- `GET /payments/:paymentId`.
- `PUT /payments/:paymentId`.
- `GET /payments`.
- `PATCH /payments/:paymentId/verify`.
- `POST /payments/:paymentId/refund`.
- `POST /payments/:paymentId/receipt`.
- `GET /payments/order/:orderId`.

### Tests

- Payment unit tests.
- Payment integration tests.
- Payment security tests.
- Payment performance tests.

### Documentation

- Payment module documentation.
- Collection documentation.
- API documentation.
- Validation documentation.
- Security documentation.
- Integration documentation.
- Testing documentation.
- Completion evidence.

## Acceptance Criteria

### Payment Recording

- [ ] Payments can be recorded successfully.
- [ ] Orders are validated.
- [ ] Customers are validated.
- [ ] Payment amounts are positive.
- [ ] Payment methods are valid.
- [ ] Duplicate submissions are prevented.
- [ ] Currency matches tenant configuration.

### Payment Types

- [ ] Multiple payment methods are supported.
- [ ] Partial payments work.
- [ ] Advance payments work.
- [ ] Additional payments can be recorded.
- [ ] Outstanding balances are calculated accurately.
- [ ] Overpayments are prevented unless configured.

### Verification and Receipts

- [ ] Pending payments can be verified.
- [ ] Payment status is maintained.
- [ ] Receipts are generated successfully.
- [ ] Receipt information is preserved.
- [ ] Order payment status updates automatically.

### Refunds

- [ ] Refunds are processed correctly.
- [ ] Refund amount is validated.
- [ ] Refunds cannot exceed original payment amount.
- [ ] Refund authorization is enforced.
- [ ] Refund history is preserved.

### History

- [ ] Payment history is preserved permanently.
- [ ] Transaction history is preserved.
- [ ] Receipt history is preserved.
- [ ] Refund history is preserved.
- [ ] Financial audit history is preserved.

### Search

- [ ] Payment listing works.
- [ ] Payment search works.
- [ ] Filtering works.
- [ ] Sorting works.
- [ ] Pagination works.
- [ ] Order payment history works.

### Security

- [ ] Tenant isolation is enforced.
- [ ] Branch access is enforced.
- [ ] RBAC is enforced.
- [ ] Unauthorized modifications are prevented.
- [ ] Duplicate submissions are prevented.
- [ ] Refund authorization is protected.
- [ ] Payment history is immutable.

### Integrations

- [ ] Authentication integration works.
- [ ] Multi-Tenancy integration works.
- [ ] Branch Management integration works.
- [ ] User Management integration works.
- [ ] Customer Management integration works.
- [ ] Service Management integration works.
- [ ] Order Management integration works.
- [ ] Notification Management integration works.
- [ ] Reports integration works.
- [ ] Dashboard integration works.
- [ ] Search integration works.
- [ ] Audit Service integration works.
- [ ] Settings integration works.
- [ ] Payment Gateway integration works.

### Testing

- [ ] Unit tests pass.
- [ ] Integration tests pass.
- [ ] Security tests pass.
- [ ] Performance tests pass.
- [ ] Validation tests pass.
- [ ] Balance tests pass.
- [ ] Refund tests pass.
- [ ] Receipt tests pass.

## Completion Instructions

1. Verify every listed responsibility.
2. Verify every listed functional area.
3. Verify the complete business workflow.
4. Verify all four collections.
5. Verify all eight APIs.
6. Verify every validation rule.
7. Verify every security requirement.
8. Verify every background job.
9. Verify every listed integration.
10. Run every listed test category.
11. Record test outcomes.
12. Record created files.
13. Record modified files.
14. Record known limitations.
15. Record completion evidence.
16. Confirm that no extra API was added.
17. Confirm that no extra collection was added.
18. Confirm that no unrelated module was implemented.
19. Update the corresponding Payment Management completion report.
20. Stop execution.

Do not start another phase.
