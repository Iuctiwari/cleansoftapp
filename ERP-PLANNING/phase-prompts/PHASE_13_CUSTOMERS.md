# PHASE 13 — CUSTOMER MANAGEMENT IMPLEMENTATION PROMPT

## Phase Information

- Phase Number: 13.
- Phase Name: Customer Management.
- Module: Customer Management.
- Scope: Tenant and branch customer records.
- Status: Implementation prompt.

## Role

- Implement the Nexoraa CleanSoft Customer Management module.
- Use only the requirements defined in this prompt.
- Preserve existing Authentication functionality.
- Preserve existing Multi-Tenancy functionality.
- Preserve existing Branch Management functionality.
- Preserve existing User Management functionality.
- Do not implement unrelated modules.
- Stop after completing Customer Management.

## Overall Purpose

- Maintain a centralized customer database.
- Maintain customer data for each tenant.
- Maintain customer data for each branch.
- Act as the single source of truth for customer information.
- Store customer identity.
- Store customer communication details.
- Store customer service history.
- Store customer loyalty information.
- Store customer preferences.
- Store customer business relationships.
- Make customers available for order creation.
- Support future payment references.
- Support future report references.
- Support future notification references.
- Support future customer analytics.

## Customer Management Position

- Authentication determines who the user is.
- Multi-Tenancy identifies which organization owns the data.
- Branch Management defines where operations occur.
- User Management controls who can perform actions.
- Customer Management establishes who receives the service.
- Every customer belongs to an authenticated tenant.
- A customer can be associated with a selected branch.
- Every future order references a customer profile.
- Every future payment references a customer profile.
- Every future notification references a customer profile.
- Every future report references customer data.

## Core Responsibilities

- Customer Registration.
- Customer Profile Management.
- Customer Search.
- Customer Verification.
- Customer Classification.
- Customer Status Management.
- Customer Address Management.
- Customer Communication Preferences.
- Customer Loyalty Management.
- Customer Tag Management.
- Customer Notes.
- Customer Document Management.
- Customer History.
- Customer Merge Management.
- Customer Archive and Restore.
- Customer Import and Export.

## Responsibility Boundaries

- Manage customer records only.
- Manage customer addresses only.
- Manage customer notes only.
- Manage customer loyalty information only.
- Reference Authentication without replacing it.
- Reference Multi-Tenancy without replacing it.
- Reference Branch Management without replacing it.
- Reference User Management without replacing it.
- Integrate with downstream modules without implementing them.
- Preserve customer history.
- Preserve archived customers.
- Prevent unauthorized customer access.
- Prevent duplicate customer creation.

## Functional Areas

### 1. Customer Registration

- Register a new customer.
- Require customer name.
- Require mobile number.
- Generate or assign a customer code.
- Keep customer code unique within the tenant.
- Keep mobile number unique within the tenant.
- Link the customer to the tenant.
- Associate the customer with the selected branch when branch-specific.
- Store communication preferences.
- Store available customer details.
- Make the customer available for future orders.

### 2. Customer Profile Management

- View customer profile information.
- Update customer profile information.
- Maintain customer type.
- Maintain first name.
- Maintain last name.
- Maintain full name.
- Maintain mobile number.
- Maintain alternate mobile number.
- Maintain email.
- Maintain gender.
- Maintain date of birth.
- Maintain anniversary.
- Maintain customer status.
- Maintain tags.
- Maintain communication preferences.
- Preserve created and updated information.

### 3. Contact Information

- Store primary mobile number.
- Store alternate mobile number.
- Store email.
- Validate primary mobile number.
- Validate alternate mobile number when provided.
- Validate email format when provided.
- Use contact information for customer search.
- Use communication preferences with contact information.
- Protect customer contact data.

### 4. Address Management

- Support multiple customer addresses.
- Store address type.
- Store address line one.
- Store address line two.
- Store landmark.
- Store city.
- Store state.
- Store country.
- Store postal code.
- Support a default address.
- Validate complete address information.
- Link every address to a customer.

### 5. Customer Classification

- Maintain customer type.
- Maintain customer tags.
- Use customer type for filtering.
- Use customer tags for filtering.
- Keep classifications linked to the customer.
- Preserve classification changes in customer history.

### 6. Customer Status Management

- Maintain customer status.
- Support active customer records.
- Support archived customer records.
- Restore archived customer records.
- Prevent archived records from being treated as deleted.
- Preserve status history.
- Apply status filtering.
- Secure every status change.

### 7. Loyalty and Reward Management

- Maintain loyalty tier.
- Maintain points earned.
- Maintain points redeemed.
- Maintain available points.
- Maintain membership status.
- Maintain last updated information.
- Prevent negative loyalty points.
- Recalculate loyalty points through the listed background process.
- Preserve loyalty information with the customer.

### 8. Customer Notes and Attachments

- Store internal customer notes.
- Link notes to the customer.
- Link notes to the tenant.
- Link notes to the branch.
- Store the note creator.
- Store note creation time.
- Support customer document management.
- Keep notes protected by access controls.
- Preserve customer notes in customer history.

### 9. Communication Preferences

- Store customer communication preferences.
- Validate communication preferences.
- Apply preferences to customer notifications.
- Associate preferences with the customer profile.
- Preserve preference updates.
- Protect communication details.

### 10. Customer Search and Filtering

- Search by mobile number.
- Search by customer code.
- Search by customer name.
- Search by email.
- Filter customer records.
- Sort customer records.
- Paginate customer records.
- Keep search tenant-scoped.
- Keep search branch-scoped where required.
- Return accurate customer matches.

### 11. Customer History

- Preserve customer profile history.
- Preserve customer status history.
- Preserve customer address history.
- Preserve customer note history.
- Preserve customer loyalty history.
- Preserve customer classification history.
- Preserve customer communication preference history.
- Preserve customer archive and restore history.
- Keep history available for authorized use.

### 12. MongoDB Collections

- Implement the `customers` collection.
- Implement the `customerAddresses` collection.
- Implement the `customerNotes` collection.
- Implement the `customerLoyalty` collection.
- Keep every collection connected to the correct customer.
- Keep customer records isolated by tenant.
- Keep branch-specific records isolated by branch.

### 13. REST APIs

- Implement customer creation.
- Implement customer retrieval.
- Implement customer updates.
- Implement customer listing.
- Implement customer search.
- Implement loyalty updates.
- Implement customer archive.
- Implement customer restore.
- Do not add APIs outside the listed API scope.

### 14. Validation Rules

- Validate required customer name.
- Validate required mobile number.
- Validate tenant-unique customer code.
- Validate tenant-unique mobile number.
- Validate email format.
- Validate tenant ownership.
- Validate branch ownership.
- Validate loyalty points.
- Validate communication preferences.
- Validate address completeness.

### 15. Security

- Enforce tenant-level isolation.
- Enforce branch-level access control.
- Enforce RBAC validation.
- Protect customer data privacy.
- Audit customer changes.
- Secure customer updates.
- Protect archived records.
- Prevent duplicate customer creation.

### 16. Background Jobs

- Support customer welcome notification.
- Support birthday reminders.
- Support anniversary reminders.
- Support loyalty point recalculation.
- Support customer inactivity detection.
- Support customer data synchronization.
- Support customer analytics updates.
- Support duplicate customer detection.

### 17. Integrations

- Integrate with Authentication.
- Integrate with Multi-Tenancy.
- Integrate with Branch Management.
- Integrate with User Management.
- Integrate with Service Management.
- Integrate with Order Management.
- Integrate with Payment Management.
- Integrate with Notification Management.
- Integrate with Reports.
- Integrate with Dashboard.
- Integrate with Search.
- Integrate with Audit Service.
- Integrate with Settings.

### 18. Testing

- Implement customer unit tests.
- Implement customer integration tests.
- Implement customer security tests.
- Implement customer performance tests.
- Test customer creation.
- Test customer updates.
- Test validation.
- Test loyalty.
- Test addresses.
- Test search.

### 19. Acceptance Criteria

- Verify customer registration.
- Verify duplicate prevention.
- Verify profile updates.
- Verify multiple addresses.
- Verify loyalty information.
- Verify fast and accurate search.
- Verify preserved history.
- Verify tenant isolation.
- Verify branch isolation.
- Verify listed integrations.
- Verify all required tests.

## Business Workflow

### Step 1 — Customer Contact

- A customer visits the business.
- A customer may contact the business remotely.
- The system starts with customer identification.

### Step 2 — Existing Customer Search

- Search using mobile number.
- Search using email.
- Search using customer code.
- Search using name when needed.
- Keep the search within the authenticated tenant.

### Step 3 — Existing Customer Selection

- Use the existing profile when a match exists.
- Avoid creating a duplicate customer.
- Preserve the existing customer identity.
- Continue future work with the selected profile.

### Step 4 — New Customer Creation

- Create a profile when no customer exists.
- Validate required information.
- Assign a unique customer code.
- Store customer contact information.
- Store customer classification.

### Step 5 — Tenant Association

- Link the customer to the current tenant.
- Validate the authenticated tenant.
- Prevent association with another tenant.
- Preserve tenant ownership.

### Step 6 — Branch Association

- Associate the customer with the selected branch when branch-specific.
- Validate that the branch belongs to the tenant.
- Prevent an invalid branch association.
- Apply branch access control.

### Step 7 — Customer Details

- Store customer preferences.
- Store customer addresses.
- Store communication settings.
- Store customer tags.
- Store customer notes.
- Store loyalty information.

### Step 8 — Order Availability

- Make the customer available for order creation.
- Preserve the same customer identity.
- Prevent duplicate identity creation.

### Step 9 — Future References

- Reference the same profile from future orders.
- Reference the same profile from future payments.
- Reference the same profile from future notifications.
- Reference the same profile from future reports.

## Database Collections

### `customers`

#### Purpose

- Store the master customer information.
- Act as the primary customer record.
- Keep customer information tenant-scoped.
- Keep branch association when branch-specific.

#### Fields

- Tenant ID.
- Branch ID.
- Customer Code.
- Customer Type.
- First Name.
- Last Name.
- Full Name.
- Mobile Number.
- Alternate Mobile.
- Email.
- Gender.
- Date of Birth.
- Anniversary.
- Address.
- City.
- State.
- Country.
- Postal Code.
- Customer Status.
- Loyalty Points.
- Tags.
- Notes.
- Communication Preferences.
- CreatedBy.
- UpdatedBy.
- CreatedAt.
- UpdatedAt.

#### Requirements

- Require tenant ownership.
- Validate branch ownership.
- Require customer name.
- Require mobile number.
- Keep customer code unique within tenant.
- Keep mobile number unique within tenant.
- Validate email when present.
- Prevent negative loyalty points.
- Validate communication preferences.
- Preserve customer status.
- Preserve audit information.

### `customerAddresses`

#### Purpose

- Store multiple addresses for a customer.
- Keep each address linked to its customer.
- Support a default customer address.

#### Fields

- Customer ID.
- Address Type.
- Address Line 1.
- Address Line 2.
- Landmark.
- City.
- State.
- Country.
- Postal Code.
- Is Default.

#### Requirements

- Require a valid customer link.
- Validate address type.
- Validate complete address information.
- Support multiple customer addresses.
- Identify the default address.
- Preserve address information.

### `customerNotes`

#### Purpose

- Store internal notes about customers.
- Keep notes connected to the correct customer.
- Keep notes connected to tenant and branch context.

#### Fields

- Customer ID.
- Tenant ID.
- Branch ID.
- Note.
- Created By.
- Created At.

#### Requirements

- Require a valid customer.
- Require tenant ownership.
- Validate branch context.
- Protect internal notes.
- Preserve note creator.
- Preserve note creation time.
- Include notes in customer history.

### `customerLoyalty`

#### Purpose

- Store loyalty information.
- Store reward information.
- Keep loyalty information connected to the customer.

#### Fields

- Customer ID.
- Loyalty Tier.
- Points Earned.
- Points Redeemed.
- Available Points.
- Membership Status.
- Last Updated.

#### Requirements

- Require a valid customer.
- Prevent negative points.
- Maintain points earned.
- Maintain points redeemed.
- Maintain available points.
- Maintain loyalty tier.
- Maintain membership status.
- Maintain last updated information.

## REST APIs

### Create Customer

- Method: `POST`.
- Path: `/customers`.
- Purpose: Create a new customer.
- Validate customer name.
- Validate mobile number.
- Validate tenant ownership.
- Validate branch ownership when supplied.
- Prevent duplicate customer creation.
- Create the customer profile.

### Get Customer

- Method: `GET`.
- Path: `/customers/:customerId`.
- Purpose: Return complete customer details.
- Validate customer identity.
- Validate tenant ownership.
- Validate branch access.
- Apply RBAC.
- Return authorized customer information.

### Update Customer

- Method: `PUT`.
- Path: `/customers/:customerId`.
- Purpose: Update customer information.
- Validate customer identity.
- Validate tenant ownership.
- Validate branch access.
- Apply RBAC.
- Validate updated profile values.
- Preserve customer history.

### List Customers

- Method: `GET`.
- Path: `/customers`.
- Purpose: Return paginated customer records.
- Support pagination.
- Support filtering.
- Support sorting.
- Support searching.
- Enforce tenant isolation.
- Enforce branch access.

### Search Customer

- Method: `GET`.
- Path: `/customers/search`.
- Purpose: Search customer records.
- Search by mobile number.
- Search by customer code.
- Search by name.
- Search by email.
- Enforce tenant isolation.
- Enforce branch access.
- Return accurate matching records.

### Update Loyalty

- Method: `PATCH`.
- Path: `/customers/:customerId/loyalty`.
- Purpose: Update customer loyalty information.
- Validate customer identity.
- Validate tenant ownership.
- Validate loyalty values.
- Prevent negative points.
- Preserve loyalty information.

### Archive Customer

- Method: `PATCH`.
- Path: `/customers/:customerId/archive`.
- Purpose: Soft archive a customer.
- Validate customer identity.
- Validate tenant ownership.
- Apply branch access control.
- Apply RBAC.
- Preserve customer information.
- Preserve customer history.

### Restore Customer

- Method: `PATCH`.
- Path: `/customers/:customerId/restore`.
- Purpose: Restore an archived customer.
- Validate customer identity.
- Validate tenant ownership.
- Apply branch access control.
- Apply RBAC.
- Restore the customer profile.
- Preserve archive and restore history.

## API Limit

- Implement only the eight listed Customer APIs.
- Do not add address, note, document, merge, import, export, history, or communication-preference APIs.
- Keep unlisted operations within the listed profile scope only when applicable.

## Validation Rules

- Require and validate customer name before creation or update.
- Require and validate mobile number and keep it unique within the tenant.
- Require customer code, keep it tenant-unique, and support search by it.
- Validate email format when provided and support search by it.
- Require customer ownership by the authenticated tenant.
- Require every selected branch to belong to the authenticated tenant.
- Prevent negative earned, redeemed, and available loyalty points.
- Validate and store communication preferences.
- Validate complete customer address and default-address information.

## Security Requirements

- Enforce tenant isolation for access, updates, lists, and search.
- Enforce branch ownership and branch-level access.
- Apply RBAC to create, view, update, loyalty, archive, and restore operations.
- Protect contact, address, note, loyalty, and other customer data.
- Audit creation, updates, loyalty changes, archive, restore, and acting user.
- Validate ownership and authorization before every update.
- Archive instead of deleting and preserve archive or restore history.
- Prevent duplicate codes and mobile numbers and support duplicate detection and merge management.

## Integrations

- Authentication: use authenticated user and tenant context and preserve the acting user.
- Multi-Tenancy: validate ownership, isolation, customer-code uniqueness, and mobile uniqueness.
- Branch Management: validate branch ownership, association, and access.
- User Management: use authorized identity, RBAC, CreatedBy, and UpdatedBy.
- Service Management: make customer information available without implementing services.
- Order Management: make profiles available and preserve the same customer reference.
- Payment Management: preserve the same customer reference without implementing payments.
- Notification Management: use preferences for welcome, birthday, and anniversary notifications.
- Reports: make customer data and history available without implementing reports.
- Dashboard: make customer information available without implementing dashboards.
- Search: support listed fields with tenant and branch scope.
- Audit Service: audit customer, loyalty, archive, and restore changes.
- Settings: use listed settings and communication preferences.

## Background Jobs

- Customer welcome notification: use Notification Management and communication preferences.
- Birthday reminders: use date of birth and communication preferences.
- Anniversary reminders: use anniversary information and communication preferences.
- Loyalty recalculation: update earned, redeemed, available, and last-updated information without negative points.
- Inactivity detection: use customer history and preserve records.
- Data synchronization: preserve tenant isolation and branch access.
- Analytics updates: protect customer privacy and remain within the listed process.
- Duplicate detection: use mobile, email, and code and preserve history during merge management.

## Testing Requirements

### Unit Tests

- Test customer creation.
- Test required customer name.
- Test required mobile number.
- Test tenant-unique customer code.
- Test tenant-unique mobile number.
- Test email validation.
- Test customer updates.
- Test loyalty calculations.
- Test negative loyalty prevention.
- Test address management.
- Test customer search.
- Test customer archive.
- Test customer restore.

### Integration Tests

- Test tenant validation.
- Test tenant ownership.
- Test branch validation.
- Test branch access.
- Test Order Management integration.
- Test Payment Management integration.
- Test Notification Management integration.
- Test listed Search integration.
- Test Audit Service integration.

### Security Tests

- Test tenant isolation.
- Test branch isolation.
- Test unauthorized customer access.
- Test unauthorized customer updates.
- Test duplicate customer prevention.
- Test RBAC validation.
- Test customer data privacy.
- Test archive protection.
- Test restore authorization.

### Performance Tests

- Test customer creation.
- Test customer search.
- Test customer filtering.
- Test bulk customer retrieval.
- Test customer history loading.
- Record customer search results.
- Verify fast and accurate search.

## Implementation Sequence

1. Confirm Phase 13 Customer Management scope.
2. Review the listed module purpose.
3. Review the listed responsibilities.
4. Review the listed functional areas.
5. Review the business workflow.
6. Implement `customers`.
7. Implement `customerAddresses`.
8. Implement `customerNotes`.
9. Implement `customerLoyalty`.
10. Implement Customer Registration.
11. Implement Customer Profile Management.
12. Implement Contact Information.
13. Implement Address Management.
14. Implement Customer Classification.
15. Implement Customer Status Management.
16. Implement Loyalty and Reward Management.
17. Implement Customer Notes and Attachments.
18. Implement Communication Preferences.
19. Implement Customer Search and Filtering.
20. Implement Customer History.
21. Implement the eight listed APIs.
22. Implement the listed validation rules.
23. Implement the listed security controls.
24. Implement the listed background jobs.
25. Implement the listed integrations.
26. Implement the listed tests.
27. Verify the acceptance criteria.
28. Update Customer Management documentation.
29. Record completion evidence.
30. Stop without starting another phase.

## Deliverables

### Customer Features

- Customer Registration.
- Customer Profile Management.
- Customer Search.
- Customer Verification.
- Customer Classification.
- Customer Status Management.
- Customer Address Management.
- Customer Communication Preferences.
- Customer Loyalty Management.
- Customer Tag Management.
- Customer Notes.
- Customer Document Management.
- Customer History.
- Customer Merge Management.
- Customer Archive and Restore.
- Customer Import and Export.

### Collections

- `customers`.
- `customerAddresses`.
- `customerNotes`.
- `customerLoyalty`.

### APIs

- `POST /customers`.
- `GET /customers/:customerId`.
- `PUT /customers/:customerId`.
- `GET /customers`.
- `GET /customers/search`.
- `PATCH /customers/:customerId/loyalty`.
- `PATCH /customers/:customerId/archive`.
- `PATCH /customers/:customerId/restore`.

### Tests

- Customer unit tests.
- Customer integration tests.
- Customer security tests.
- Customer performance tests.

### Documentation

- Customer module documentation.
- Collection documentation.
- API documentation.
- Validation documentation.
- Security documentation.
- Integration documentation.
- Testing documentation.
- Completion evidence.

## Acceptance Criteria

### Customer Registration

- [ ] Customers can be registered successfully.
- [ ] Customer name is validated.
- [ ] Mobile number is validated.
- [ ] Customer code is tenant-unique.
- [ ] Mobile number is tenant-unique.
- [ ] Duplicate customers are prevented.

### Customer Profiles

- [ ] Customer profiles can be retrieved.
- [ ] Customer profiles can be updated.
- [ ] Customer classifications are maintained.
- [ ] Customer status is maintained.
- [ ] Communication preferences are maintained.
- [ ] Customer tags are maintained.
- [ ] Customer notes are maintained.

### Customer Addresses

- [ ] Multiple addresses are supported.
- [ ] Address information is complete.
- [ ] Default address information is maintained.
- [ ] Addresses remain linked to the customer.

### Customer Loyalty

- [ ] Loyalty information is maintained.
- [ ] Loyalty tiers are maintained.
- [ ] Points earned are maintained.
- [ ] Points redeemed are maintained.
- [ ] Available points are maintained.
- [ ] Loyalty points cannot be negative.

### Customer Search

- [ ] Search supports mobile number.
- [ ] Search supports customer code.
- [ ] Search supports name.
- [ ] Search supports email.
- [ ] Filtering works.
- [ ] Sorting works.
- [ ] Pagination works.
- [ ] Search is fast and accurate.

### Customer History

- [ ] Customer history is preserved.
- [ ] Profile history is preserved.
- [ ] Address history is preserved.
- [ ] Loyalty history is preserved.
- [ ] Status history is preserved.
- [ ] Archive and restore history is preserved.

### Security

- [ ] Tenant isolation is enforced.
- [ ] Branch isolation is enforced.
- [ ] Unauthorized customer access is prevented.
- [ ] RBAC validation is enforced.
- [ ] Customer data privacy is protected.
- [ ] Customer changes are audited.
- [ ] Soft delete protection is enforced.

### Integrations

- [ ] Authentication integration works.
- [ ] Multi-Tenancy integration works.
- [ ] Branch Management integration works.
- [ ] User Management integration works.
- [ ] Service Management integration works.
- [ ] Order Management integration works.
- [ ] Payment Management integration works.
- [ ] Notification Management integration works.
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
- [ ] Customer search tests pass.
- [ ] Customer history tests pass.

## Completion Instructions

1. Verify every listed responsibility.
2. Verify every listed functional area.
3. Verify the business workflow.
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
19. Update the corresponding Customer Management completion report.
20. Stop execution.

Do not start another phase.
