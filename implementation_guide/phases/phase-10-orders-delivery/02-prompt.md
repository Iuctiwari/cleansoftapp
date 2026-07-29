# PHASE 10 — ORDER MANAGEMENT IMPLEMENTATION PROMPT

## Phase Information

- Phase Number: 15.
- Phase Name: Order Management.
- Module: Order Management.
- Scope: Customer service orders and their lifecycle.
- Status: Implementation prompt.

## Role

- Implement the Nexoraa CleanSoft Order Management module.
- Use only the requirements defined in this prompt.
- Preserve existing Authentication functionality.
- Preserve existing Multi-Tenancy functionality.
- Preserve existing Branch Management functionality.
- Preserve existing User Management functionality.
- Preserve existing Customer Management functionality.
- Preserve existing Service Management functionality.
- Do not implement unrelated modules.
- Stop after completing Order Management.

## Overall Purpose

- Manage the complete lifecycle of customer service requests.
- Manage orders from creation to final delivery.
- Act as the central transaction module.
- Connect customers with services.
- Connect orders with branches.
- Connect orders with employees.
- Connect orders with payments.
- Connect orders with notifications.
- Track service progress.
- Track pricing.
- Track payments.
- Track status changes.
- Track customer communication.
- Preserve every order as an operational record.

## Order Management Position

- Authentication identifies who performs the operation.
- Multi-Tenancy identifies which organization owns the order.
- Branch Management defines where the transaction occurs.
- User Management controls who is authorized.
- Customer Management identifies who requested the service.
- Service Management defines what services are provided.
- Order Management combines these contexts into one transaction.
- Payments reference orders.
- Notifications reference orders.
- Reports reference orders.
- Dashboards reference orders.
- Search references orders.

## Core Responsibilities

- Order Creation.
- Order Profile Management.
- Order Number Generation.
- Service Line Item Management.
- Customer Association.
- Branch Assignment.
- Employee Assignment.
- Order Status Management.
- Order Workflow Management.
- Price Calculation.
- Tax and Discount Management.
- Order Notes.
- Attachments Management.
- Order History.
- Order Search and Filtering.
- Order Cancellation.
- Order Completion.
- Order Archive.
- Order Audit Management.

## Responsibility Boundaries

- Manage order records only.
- Manage order item records only.
- Manage order status history only.
- Manage order attachment records only.
- Reference customers without replacing Customer Management.
- Reference services without replacing Service Management.
- Reference employees without replacing User Management.
- Reference branches without replacing Branch Management.
- Integrate with payments without implementing Payment Management.
- Integrate with notifications without implementing Notification Management.
- Preserve historical pricing snapshots.
- Preserve immutable order history.
- Preserve completed orders.
- Preserve cancelled orders.
- Preserve archived orders.

## Functional Areas

### 1. Order Creation

- Identify or register a customer.
- Initiate a new order.
- Require at least one service.
- Capture selected services.
- Capture service pricing snapshots.
- Calculate discounts.
- Calculate taxes.
- Calculate order totals.
- Assign a branch.
- Assign a responsible employee.
- Generate an order number.
- Initialize order status.
- Store order creation information.

### 2. Order Profile Management

- View complete order details.
- Update editable order information.
- Maintain order date.
- Maintain expected delivery date.
- Maintain actual delivery date.
- Maintain order status.
- Maintain payment status.
- Maintain assigned employee.
- Maintain notes.
- Maintain attachments.
- Maintain pricing totals.
- Preserve CreatedBy and UpdatedBy.
- Preserve CreatedAt and UpdatedAt.
- Prevent unauthorized modifications.

### 3. Customer and Service Association

- Require an existing customer.
- Associate the order with the customer.
- Store a customer snapshot.
- Require one or more services.
- Associate every item with a service.
- Store a service snapshot for every item.
- Preserve customer information used by the order.
- Preserve service information used by the order.
- Use the same tenant context.
- Use the assigned branch context.

### 4. Order Item Management

- Store every selected service as an order item.
- Link every item to the order.
- Link every item to the tenant.
- Link every item to the branch.
- Store service ID.
- Store service snapshot.
- Store quantity.
- Store unit price.
- Store discount.
- Store tax.
- Store line total.
- Store processing status.
- Store item notes.
- Require quantity greater than zero.
- Prevent negative prices.

### 5. Pricing and Totals Calculation

- Calculate line totals.
- Calculate order subtotal.
- Calculate discounts.
- Calculate tax.
- Calculate grand total.
- Use service pricing snapshots.
- Prevent negative prices.
- Validate discounts.
- Follow configured tax rules.
- Preserve historical totals.
- Preserve completed order pricing.

### 6. Order Status Workflow

- Initialize order status.
- Define order workflow stages.
- Enforce valid status transitions.
- Store previous status.
- Store new status.
- Store the user making the change.
- Store status-change time.
- Store remarks.
- Preserve complete status history.
- Prevent unauthorized status changes.
- Prevent ordinary modification after completion.
- Prevent ordinary modification after cancellation.

### 7. Employee Assignment

- Assign a responsible employee.
- Change the responsible employee.
- Validate employee identity.
- Require employee to belong to the assigned branch.
- Preserve employee assignment on the order.
- Apply RBAC.
- Audit employee assignment changes.

### 8. Delivery Scheduling

- Maintain expected delivery date.
- Maintain actual delivery date.
- Support delivery reminder notifications.
- Detect overdue orders.
- Confirm customer collection or delivery.
- Preserve delivery dates.
- Preserve order status changes related to delivery.

### 9. Order Search and Filtering

- Search orders.
- Filter orders.
- Sort orders.
- Paginate orders.
- Search by available order information.
- Filter by order status.
- Filter by payment status.
- Filter by branch.
- Filter by customer.
- Keep search tenant-scoped.
- Keep search branch-scoped.
- Support search index synchronization.

### 10. MongoDB Collections

- Implement the `orders` collection.
- Implement the `orderItems` collection.
- Implement the `orderStatusHistory` collection.
- Implement the `orderAttachments` collection.
- Keep each collection linked to the correct order.
- Keep order data isolated by tenant.
- Keep order data controlled by branch.
- Preserve historical information.

### 11. REST APIs

- Implement order creation.
- Implement order retrieval.
- Implement order updates.
- Implement order listing.
- Implement status updates.
- Implement employee assignment.
- Implement order cancellation.
- Implement order completion.
- Implement order archive.
- Do not add APIs outside the listed scope.

### 12. Validation Rules

- Validate customer existence.
- Require at least one service.
- Validate tenant-unique order number.
- Validate branch ownership.
- Validate employee branch membership.
- Require positive quantities.
- Prevent negative prices.
- Validate discounts.
- Validate taxes.
- Validate status transitions.
- Protect completed orders.
- Protect cancelled orders.

### 13. Security

- Enforce tenant-level isolation.
- Enforce branch-level access control.
- Apply RBAC.
- Secure order updates.
- Audit every order change.
- Keep order history immutable.
- Apply soft delete protection.
- Prevent unauthorized status changes.

### 14. Background Jobs

- Support order confirmation notifications.
- Support order status notifications.
- Support delivery reminder notifications.
- Support overdue order detection.
- Support order analytics aggregation.
- Support search index synchronization.
- Support report data synchronization.
- Support audit log processing.

### 15. Integrations

- Integrate with Authentication.
- Integrate with Multi-Tenancy.
- Integrate with Branch Management.
- Integrate with User Management.
- Integrate with Customer Management.
- Integrate with Service Management.
- Integrate with Payment Management.
- Integrate with Notification Management.
- Integrate with Expense Management.
- Integrate with Reports.
- Integrate with Dashboard.
- Integrate with Search.
- Integrate with Audit Service.
- Integrate with Settings.

### 16. Testing

- Implement order unit tests.
- Implement order integration tests.
- Implement order security tests.
- Implement order performance tests.
- Test order creation.
- Test order items.
- Test pricing.
- Test discounts.
- Test taxes.
- Test status transitions.
- Test employee assignment.

### 17. Acceptance Criteria

- Verify order creation.
- Verify multiple services.
- Verify pricing calculations.
- Verify unique order numbers.
- Verify status workflow.
- Verify order history.
- Verify employee assignment.
- Verify listed integrations.
- Verify tenant isolation.
- Verify branch isolation.
- Verify historical snapshots.
- Verify all required tests.

## Business Workflow

1. Identify or register the customer and store the customer ID and snapshot.
2. Initiate the order with authenticated tenant, selected branch, and acting user.
3. Select and validate one or more services as order items.
4. Capture service, unit price, discount, tax, and pricing snapshots.
5. Validate and apply configured discounts and taxes.
6. Calculate line totals, subtotal, discount, tax, and grand total.
7. Validate and assign the branch and responsible branch employee.
8. Generate and store a tenant-unique order number.
9. Initialize status and create the first status-history record.
10. Submit order confirmation through Notification Management.
11. Enforce workflow stages and record every authorized transition and remark.
12. Integrate partial or full payment state without implementing Payment Management.
13. Complete the order and preserve actual delivery date, snapshots, and history.
14. Confirm customer collection or delivery and preserve final status.
15. Soft archive the order while preserving items, snapshots, status, and audit history.

## Database Collections

### `orders`

#### Purpose

- Store master information for every customer order.
- Act as the primary operational record.
- Keep orders tenant-scoped.
- Keep orders branch-scoped.
- Preserve order totals and status.

#### Fields

- Tenant ID.
- Branch ID.
- Order Number.
- Customer ID.
- Customer Snapshot.
- Order Date.
- Expected Delivery Date.
- Actual Delivery Date.
- Order Status.
- Payment Status.
- Assigned Employee.
- Notes.
- Attachments.
- Subtotal.
- Discount.
- Tax.
- Grand Total.
- CreatedBy.
- UpdatedBy.
- CreatedAt.
- UpdatedAt.

#### Requirements

- Require tenant ownership.
- Require a valid branch.
- Require a valid customer.
- Keep order number unique within tenant.
- Require at least one service.
- Validate assigned employee.
- Calculate pricing values.
- Validate order status.
- Validate payment status.
- Preserve customer snapshot.
- Preserve completed orders.
- Preserve cancelled orders.
- Preserve archived orders.

### `orderItems`

#### Purpose

- Store every service included in an order.
- Preserve selected service information.
- Preserve service pricing information.
- Track item processing status.

#### Fields

- Tenant ID.
- Branch ID.
- Order ID.
- Service ID.
- Service Snapshot.
- Quantity.
- Unit Price.
- Discount.
- Tax.
- Line Total.
- Processing Status.
- Notes.

#### Requirements

- Require tenant ownership.
- Require branch ownership.
- Require a valid order.
- Require a valid service.
- Require quantity greater than zero.
- Prevent negative unit price.
- Validate discount.
- Validate tax.
- Calculate line total.
- Preserve service snapshot.
- Preserve item notes.
- Preserve processing status.

### `orderStatusHistory`

#### Purpose

- Store complete order status history.
- Preserve every order status transition.
- Keep order history immutable.

#### Fields

- Tenant ID.
- Order ID.
- Previous Status.
- New Status.
- Changed By.
- Changed At.
- Remarks.

#### Requirements

- Require tenant ownership.
- Require a valid order.
- Store previous status.
- Store new status.
- Store acting user.
- Store change time.
- Store remarks.
- Preserve every transition.
- Prevent history modification.

### `orderAttachments`

#### Purpose

- Store files associated with an order.
- Link every attachment to the correct order.
- Preserve attachment information.

#### Fields

- Order ID.
- File Name.
- File Type.
- File URL.
- Uploaded By.
- Uploaded At.

#### Requirements

- Require a valid order.
- Store file name.
- Store file type.
- Store file URL.
- Store uploader.
- Store upload time.
- Preserve order attachment history.

## Collection Relationships

- Link every order to one tenant.
- Link every order to one branch.
- Link every order to one customer.
- Link every order item to one order.
- Link every order item to one service.
- Link every status record to one order.
- Link every attachment to one order.
- Keep item tenant and branch aligned with the order.
- Preserve customer snapshots.
- Preserve service snapshots.
- Preserve pricing snapshots.
- Preserve status history.

## REST APIs

### Create Order

- Method: `POST`.
- Path: `/orders`.
- Purpose: Create a new customer order.
- Validate customer.
- Require at least one service.
- Validate branch.
- Validate employee.
- Generate order number.
- Capture snapshots.
- Calculate totals.
- Initialize status.

### Get Order

- Method: `GET`.
- Path: `/orders/:orderId`.
- Purpose: Return complete order details.
- Validate order identity.
- Validate tenant ownership.
- Apply branch access.
- Apply RBAC.
- Return order items.
- Return status history.
- Return attachments.

### Update Order

- Method: `PUT`.
- Path: `/orders/:orderId`.
- Purpose: Update editable order information.
- Validate order identity.
- Validate tenant ownership.
- Apply branch access.
- Apply RBAC.
- Validate editable values.
- Protect completed orders.
- Protect cancelled orders.
- Preserve order history.

### List Orders

- Method: `GET`.
- Path: `/orders`.
- Purpose: Return paginated orders.
- Support pagination.
- Support filtering.
- Support sorting.
- Support searching.
- Support status filters.
- Support branch filters.
- Enforce tenant isolation.
- Enforce branch access.

### Update Order Status

- Method: `PATCH`.
- Path: `/orders/:orderId/status`.
- Purpose: Update current order status.
- Validate tenant ownership.
- Apply branch access.
- Apply RBAC.
- Validate status transition.
- Store status history.
- Preserve remarks.

### Assign Employee

- Method: `PATCH`.
- Path: `/orders/:orderId/assign`.
- Purpose: Assign or change the responsible employee.
- Validate order identity.
- Validate tenant ownership.
- Validate assigned branch.
- Validate employee branch membership.
- Apply RBAC.
- Audit assignment changes.

### Cancel Order

- Method: `PATCH`.
- Path: `/orders/:orderId/cancel`.
- Purpose: Cancel an order.
- Validate order identity.
- Validate tenant ownership.
- Apply branch access.
- Apply RBAC.
- Validate cancellation transition.
- Preserve order history.
- Prevent ordinary future modification.

### Complete Order

- Method: `PATCH`.
- Path: `/orders/:orderId/complete`.
- Purpose: Mark an order completed.
- Validate order identity.
- Validate tenant ownership.
- Apply branch access.
- Apply RBAC.
- Validate completion transition.
- Preserve pricing snapshots.
- Prevent ordinary future modification.

### Archive Order

- Method: `PATCH`.
- Path: `/orders/:orderId/archive`.
- Purpose: Soft archive an order.
- Validate order identity.
- Validate tenant ownership.
- Apply branch access.
- Apply RBAC.
- Preserve complete history.
- Preserve order items and snapshots.

## API Limit

- Implement only the nine listed Order APIs.
- Do not add order-item APIs.
- Do not add attachment APIs.
- Do not add history APIs.
- Do not add delivery APIs.
- Do not add payment APIs.
- Keep unlisted work within the listed API scope.

## Validation Rules

- Require an existing same-tenant customer and preserve its snapshot.
- Require at least one valid service and preserve service and pricing snapshots.
- Require a tenant-unique order number and prevent duplicates.
- Require the assigned branch to belong to the tenant.
- Require the assigned employee to belong to the assigned branch.
- Require every quantity to be greater than zero.
- Prevent negative unit prices, subtotals, and grand totals.
- Validate item and order discounts.
- Validate item and order taxes against configured rules.
- Enforce workflow transitions and record every valid transition.
- Block ordinary updates to completed or cancelled orders except approved administrative actions.

## Security Requirements

- Enforce tenant isolation for order access, updates, lists, and search.
- Enforce branch ownership and branch-level access.
- Apply RBAC to create, view, update, assign, transition, cancel, complete, and archive.
- Validate ownership, access, and order state before every update.
- Audit creation, updates, assignments, status, cancellation, completion, archive, and acting user.
- Keep status history and customer, service, and pricing snapshots immutable.
- Archive instead of deleting and preserve items, status, and audit history.
- Prevent unauthorized status changes and record every approved transition.

## Integrations

- Authentication: use authenticated user, tenant, and acting-user context.
- Multi-Tenancy: validate ownership, tenant isolation, and order-number uniqueness.
- Branch Management: validate branch ownership, assignment, and access.
- User Management: validate employee branch membership, RBAC, and acting user.
- Customer Management: validate and associate the customer and capture its snapshot.
- Service Management: validate services and capture service and pricing snapshots.
- Payment Management: support partial, full, and payment-status integration without implementing payments.
- Notification Management: support confirmation, status, and delivery notifications without implementing delivery.
- Expense Management: use the listed integration without implementing expenses.
- Reports: synchronize order data and history without implementing reports.
- Dashboard: provide order information without implementing dashboards.
- Search: support tenant- and branch-scoped search synchronization.
- Audit Service: audit every change and preserve immutable history.
- Settings: use configured tax and discount rules.

## Background Jobs

- Confirmation notifications: reference the correct customer and order.
- Status notifications: use status changes and reference the correct customer and order.
- Delivery reminders: use expected delivery date and reference the correct order.
- Overdue detection: use expected delivery date and current status while preserving history.
- Analytics aggregation: use order data only for the listed process and integrations.
- Search synchronization: preserve tenant and branch scope.
- Report synchronization: preserve isolation, branch access, and snapshots.
- Audit processing: preserve acting user, every order change, and immutable history.

## Testing Requirements

### Unit Tests

- Test order creation.
- Test customer validation.
- Test service validation.
- Test order items.
- Test quantity validation.
- Test pricing calculations.
- Test discount calculations.
- Test tax calculations.
- Test totals calculations.
- Test status transitions.
- Test employee assignment.
- Test cancellation.
- Test completion.
- Test archive.

### Integration Tests

- Test Customer Management integration.
- Test Service Management integration.
- Test Payment Management integration.
- Test Notification Management integration.
- Test Search integration.
- Test Reports integration.
- Test Branch Management integration.
- Test User Management integration.
- Test Audit Service integration.

### Security Tests

- Test tenant isolation.
- Test branch isolation.
- Test unauthorized order access.
- Test unauthorized order modification.
- Test unauthorized status transitions.
- Test unauthorized employee assignment.
- Test RBAC validation.
- Test order history integrity.
- Test soft delete protection.

### Performance Tests

- Test order creation performance.
- Test order retrieval.
- Test order listing with pagination.
- Test order search.
- Test bulk order processing.
- Test high-volume concurrent order creation.
- Verify search performance.
- Verify list performance.

## Implementation Sequence

1. Confirm Phase 15 Order Management scope.
2. Review the listed module purpose.
3. Review the listed responsibilities.
4. Review the listed functional areas.
5. Review the business workflow.
6. Implement `orders`.
7. Implement `orderItems`.
8. Implement `orderStatusHistory`.
9. Implement `orderAttachments`.
10. Implement Order Creation.
11. Implement Order Profile Management.
12. Implement Customer and Service Association.
13. Implement Order Item Management.
14. Implement Pricing and Totals Calculation.
15. Implement Order Status Workflow.
16. Implement Employee Assignment.
17. Implement Delivery Scheduling.
18. Implement Order Search and Filtering.
19. Implement the nine listed APIs.
20. Implement the listed validation rules.
21. Implement the listed security controls.
22. Implement the listed background jobs.
23. Implement the listed integrations.
24. Implement the listed tests.
25. Verify the acceptance criteria.
26. Update Order Management documentation.
27. Record completion evidence.
28. Stop without starting another phase.

## Deliverables

### Order Features

- Order Creation.
- Order Profile Management.
- Order Number Generation.
- Service Line Item Management.
- Customer Association.
- Branch Assignment.
- Employee Assignment.
- Order Status Management.
- Order Workflow Management.
- Price Calculation.
- Tax and Discount Management.
- Order Notes.
- Attachments Management.
- Order History.
- Order Search and Filtering.
- Order Cancellation.
- Order Completion.
- Order Archive.
- Order Audit Management.

### Collections

- `orders`.
- `orderItems`.
- `orderStatusHistory`.
- `orderAttachments`.

### APIs

- `POST /orders`.
- `GET /orders/:orderId`.
- `PUT /orders/:orderId`.
- `GET /orders`.
- `PATCH /orders/:orderId/status`.
- `PATCH /orders/:orderId/assign`.
- `PATCH /orders/:orderId/cancel`.
- `PATCH /orders/:orderId/complete`.
- `PATCH /orders/:orderId/archive`.

### Tests

- Order unit tests.
- Order integration tests.
- Order security tests.
- Order performance tests.

### Documentation

- Order module documentation.
- Collection documentation.
- API documentation.
- Validation documentation.
- Security documentation.
- Integration documentation.
- Testing documentation.
- Completion evidence.

## Acceptance Criteria

### Order Creation

- [ ] Orders can be created successfully.
- [ ] Customer existence is validated.
- [ ] At least one service is required.
- [ ] Multiple services can be added.
- [ ] Order numbers are tenant-unique.
- [ ] Branch assignment is valid.
- [ ] Employee assignment is valid.

### Pricing

- [ ] Item prices are captured.
- [ ] Service snapshots are captured.
- [ ] Quantities are positive.
- [ ] Prices are non-negative.
- [ ] Discounts are calculated correctly.
- [ ] Taxes are calculated correctly.
- [ ] Line totals are calculated correctly.
- [ ] Order totals are calculated correctly.

### Workflow

- [ ] Order status is initialized.
- [ ] Status workflow is enforced.
- [ ] Invalid status transitions are rejected.
- [ ] Every transition is recorded.
- [ ] Cancellation works.
- [ ] Completion works.
- [ ] Archive works.

### History

- [ ] Order history is maintained.
- [ ] Status history is immutable.
- [ ] Customer snapshots are preserved.
- [ ] Service snapshots are preserved.
- [ ] Pricing snapshots are preserved.
- [ ] Audit history is preserved.
- [ ] Completed orders preserve history.
- [ ] Cancelled orders preserve history.

### Employee Assignment

- [ ] Employees can be assigned.
- [ ] Assigned employees belong to the branch.
- [ ] Employee assignment changes are audited.
- [ ] Unauthorized assignments are prevented.

### Search

- [ ] Order search works.
- [ ] Order filtering works.
- [ ] Sorting works.
- [ ] Pagination works.
- [ ] Tenant scope is enforced.
- [ ] Branch scope is enforced.

### Security

- [ ] Tenant isolation is enforced.
- [ ] Branch access is enforced.
- [ ] RBAC is enforced.
- [ ] Unauthorized updates are prevented.
- [ ] Unauthorized status changes are prevented.
- [ ] Order history integrity is protected.
- [ ] Soft deletion is enforced.

### Integrations

- [ ] Authentication integration works.
- [ ] Multi-Tenancy integration works.
- [ ] Branch Management integration works.
- [ ] User Management integration works.
- [ ] Customer Management integration works.
- [ ] Service Management integration works.
- [ ] Payment Management integration works.
- [ ] Notification Management integration works.
- [ ] Expense Management integration works.
- [ ] Reports integration works.
- [ ] Dashboard integration works.
- [ ] Search integration works.
- [ ] Audit Service integration works.
- [ ] Settings integration works.

### Testing

- [ ] Unit tests pass.
- [ ] Integration tests pass.
- [ ] Security tests pass.
- [ ] Performance tests pass.
- [ ] Validation tests pass.
- [ ] Pricing tests pass.
- [ ] Workflow tests pass.
- [ ] History tests pass.

## Completion Instructions

1. Verify every listed responsibility.
2. Verify every listed functional area.
3. Verify the complete business workflow.
4. Verify all four collections.
5. Verify all nine APIs.
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
19. Update the corresponding Order Management completion report.
20. Stop execution.

Do not start another phase.
