# PHASE 14 — SERVICE MANAGEMENT IMPLEMENTATION PROMPT

## Phase Information

- Phase Number: 14.
- Phase Name: Service Management.
- Module: Service Management.
- Scope: Tenant services and branch availability.
- Status: Implementation prompt.

## Role

- Implement the Nexoraa CleanSoft Service Management module.
- Use only the requirements defined in this prompt.
- Preserve existing Authentication functionality.
- Preserve existing Multi-Tenancy functionality.
- Preserve existing Branch Management functionality.
- Preserve existing User Management functionality.
- Preserve existing Customer Management functionality.
- Do not implement unrelated modules.
- Stop after completing Service Management.

## Overall Purpose

- Manage all services offered by a tenant.
- Manage services across one or more branches.
- Act as the ERP service catalog.
- Allow businesses to define services.
- Allow businesses to organize services.
- Allow businesses to price services.
- Allow businesses to configure services.
- Provide services for customer order creation.
- Support future pricing and billing.
- Support future reports.
- Support future business analytics.

## Service Management Position

- Authentication determines who the user is.
- Multi-Tenancy identifies which organization owns the data.
- Branch Management defines where operations occur.
- User Management controls who can perform actions.
- Customer Management identifies who receives the service.
- Service Management defines what service is provided.
- Every service belongs to a tenant.
- A service can be assigned to one or more branches.
- Every order selects one or more services.
- Orders store pricing snapshots for historical accuracy.

## Core Responsibilities

- Service Creation.
- Service Profile Management.
- Service Category Management.
- Service Pricing Management.
- Service Status Management.
- Service Availability Management.
- Service Duration Management.
- Service Tax Configuration.
- Service Discount Configuration.
- Service Branch Assignment.
- Service Search and Filtering.
- Service Import and Export.
- Service Archive and Restore.
- Service Audit Management.

## Responsibility Boundaries

- Manage service records only.
- Manage service categories only.
- Manage service pricing only.
- Manage service availability only.
- Manage service status only.
- Reference Authentication without replacing it.
- Reference Multi-Tenancy without replacing it.
- Reference Branch Management without replacing it.
- Reference User Management without replacing it.
- Reference Customer Management without replacing it.
- Integrate with downstream modules without implementing them.
- Preserve historical service and pricing information.
- Preserve archived services.

## Functional Areas

### 1. Service Registration

- Create a new service.
- Require service name.
- Generate or assign a service code.
- Keep service code unique within tenant.
- Validate service details.
- Assign a category.
- Define base price.
- Define tax configuration.
- Define discount rules.
- Define processing time.
- Assign one or more branches.
- Set service status.

### 2. Service Profile Management

- View service details.
- Update service details.
- Maintain service name.
- Maintain description.
- Maintain category.
- Maintain base price.
- Maintain tax configuration.
- Maintain discount rules.
- Maintain processing time.
- Maintain estimated delivery time.
- Maintain service status.
- Maintain branch availability.
- Maintain display order.
- Preserve created and updated information.

### 3. Service Category Management

- Create service categories.
- Maintain category code.
- Maintain category name.
- Maintain category description.
- Maintain parent category.
- Maintain display order.
- Maintain category status.
- Validate that assigned category exists.
- Support category hierarchy updates.
- Support category filtering.

### 4. Service Pricing

- Maintain service base price.
- Maintain branch-specific pricing.
- Maintain discount price.
- Maintain tax percentage.
- Maintain effective date.
- Maintain expiry date.
- Maintain pricing status.
- Prevent negative base price.
- Preserve pricing history.
- Support scheduled price activation.
- Support scheduled price expiry.
- Support order pricing snapshots.

### 5. Service Duration and Processing Time

- Maintain processing time.
- Maintain estimated delivery time.
- Validate processing time.
- Store duration with the service.
- Make duration available for order selection.
- Preserve duration updates.

### 6. Service Availability

- Maintain service availability.
- Maintain service status.
- Make active services selectable.
- Keep archived services unavailable for new selection.
- Preserve archived service history.
- Support service cache refresh.

### 7. Branch-Wise Service Assignment

- Assign a service to one or more branches.
- Validate every assigned branch.
- Require assigned branches to belong to the same tenant.
- Maintain branch availability.
- Support branch-specific service retrieval.
- Support branch synchronization.
- Preserve branch assignment changes.

### 8. Tax and Discount Configuration

- Maintain service tax configuration.
- Maintain tax percentage.
- Validate configured tax limits.
- Maintain service discount rules.
- Maintain branch pricing discount price.
- Preserve tax configuration.
- Preserve discount configuration.
- Make pricing configuration available for order snapshots.

### 9. Service Status Management

- Maintain service status.
- Validate status values.
- Support active services.
- Support archived services.
- Restore archived services.
- Prevent physical deletion when referenced by active orders.
- Preserve status history.
- Apply soft delete protection.

### 10. Service Search and Filtering

- Search services.
- Filter services.
- Sort services.
- Paginate services.
- Filter by category.
- Filter by branch availability.
- Filter by status.
- Keep search tenant-scoped.
- Keep retrieval branch-specific when required.
- Support search index synchronization.

### 11. MongoDB Collections

- Implement the `services` collection.
- Implement the `serviceCategories` collection.
- Implement the `servicePricing` collection.
- Keep every record connected to the correct tenant.
- Keep branch pricing connected to the correct branch.
- Keep pricing connected to the correct service.
- Preserve pricing history.

### 12. REST APIs

- Implement service creation.
- Implement service retrieval.
- Implement service updates.
- Implement service listing.
- Implement category creation.
- Implement pricing updates.
- Implement branch assignment.
- Implement service archive.
- Implement service restore.
- Do not add APIs outside the listed API scope.

### 13. Validation Rules

- Validate required service name.
- Validate tenant-unique service code.
- Validate category existence.
- Prevent negative base price.
- Validate processing time.
- Validate tax percentage limits.
- Validate branch ownership.
- Validate service status.
- Prevent deletion when referenced by active orders.

### 14. Security

- Enforce tenant-level isolation.
- Enforce branch-level service availability.
- Apply RBAC validation.
- Secure pricing updates.
- Audit service changes.
- Protect archived services.
- Prevent duplicate service codes.

### 15. Background Jobs

- Support scheduled price activation.
- Support scheduled price expiry.
- Support branch synchronization.
- Support service cache refresh.
- Support category hierarchy update.
- Support service analytics aggregation.
- Support popular service calculation.
- Support search index synchronization.

### 16. Integrations

- Integrate with Authentication.
- Integrate with Multi-Tenancy.
- Integrate with Branch Management.
- Integrate with User Management.
- Integrate with Customer Management.
- Integrate with Order Management.
- Integrate with Payment Management.
- Integrate with Reports.
- Integrate with Dashboard.
- Integrate with Search.
- Integrate with Notification Service.
- Integrate with Audit Service.
- Integrate with Settings.

### 17. Testing

- Implement service unit tests.
- Implement service integration tests.
- Implement service security tests.
- Implement service performance tests.
- Test service creation.
- Test service updates.
- Test categories.
- Test pricing.
- Test taxes.
- Test branch assignment.

### 18. Acceptance Criteria

- Verify service creation.
- Verify category management.
- Verify branch availability.
- Verify pricing and tax configuration.
- Verify historical pricing snapshots.
- Verify search and filtering.
- Verify pagination.
- Verify tenant isolation.
- Verify branch isolation.
- Verify listed integrations.
- Verify soft deletion.
- Verify all required tests.

## Business Workflow

### Step 1 — Service Creation

- Tenant administrator creates a new service.
- The service belongs to the current tenant.
- The service starts with defined service details.

### Step 2 — Service Validation

- Validate service name.
- Validate service code.
- Validate category.
- Validate base price.
- Validate processing time.
- Validate tax percentage.
- Validate assigned branches.
- Validate status.

### Step 3 — Service Code

- Generate a service code.
- Keep the service code unique within tenant.
- Prevent duplicate service codes.
- Store the code with the service.

### Step 4 — Category Assignment

- Assign an existing category.
- Validate that the category exists.
- Keep the category in the same tenant.
- Store the category reference with the service.

### Step 5 — Price and Tax

- Define base price.
- Define discount rules.
- Define tax configuration.
- Prevent negative base price.
- Validate tax limits.
- Preserve pricing history.

### Step 6 — Processing Duration

- Configure processing time.
- Configure estimated delivery time.
- Validate processing time.
- Store duration with the service.

### Step 7 — Branch Assignment

- Assign one or more branches.
- Validate each branch.
- Keep branches within the same tenant.
- Store branch availability.

### Step 8 — Service Activation

- Set the service to an active status.
- Validate service status.
- Make the service available in assigned branches.
- Preserve status changes.

### Step 9 — Order Selection

- Make active services available for customer orders.
- Limit availability to assigned branches.
- Provide service details for order selection.

### Step 10 — Pricing Snapshot

- Make price information available to orders.
- Make tax information available to orders.
- Make discount information available to orders.
- Preserve pricing snapshots in orders.
- Preserve historical accuracy.

## Database Collections

### `services`

#### Purpose

- Store master information for every tenant service.
- Act as the primary service record.
- Keep services tenant-scoped.
- Keep branch availability with the service.

#### Fields

- Tenant ID.
- Service Code.
- Service Name.
- Description.
- Category ID.
- Base Price.
- Tax Configuration.
- Discount Rules.
- Processing Time.
- Estimated Delivery Time.
- Service Status.
- Branch Availability.
- Display Order.
- CreatedBy.
- UpdatedBy.
- CreatedAt.
- UpdatedAt.

#### Requirements

- Require tenant ownership.
- Require service name.
- Keep service code unique within tenant.
- Validate category.
- Prevent negative base price.
- Validate tax configuration.
- Validate discount rules.
- Validate processing time.
- Validate branch availability.
- Validate service status.
- Preserve audit information.
- Preserve archived services.

### `serviceCategories`

#### Purpose

- Store service categories.
- Organize tenant services.
- Support category hierarchy.
- Support category filtering.

#### Fields

- Tenant ID.
- Category Code.
- Category Name.
- Description.
- Parent Category.
- Display Order.
- Status.

#### Requirements

- Require tenant ownership.
- Maintain category code.
- Maintain category name.
- Maintain description.
- Maintain parent category.
- Maintain display order.
- Validate category status.
- Make categories available for service assignment.

### `servicePricing`

#### Purpose

- Store branch-specific pricing.
- Store service pricing history.
- Keep pricing linked to tenant, branch, and service.
- Support effective and expiring prices.

#### Fields

- Tenant ID.
- Branch ID.
- Service ID.
- Base Price.
- Discount Price.
- Tax Percentage.
- Effective Date.
- Expiry Date.
- Status.

#### Requirements

- Require tenant ownership.
- Require a valid branch.
- Require a valid service.
- Keep branch within the tenant.
- Keep service within the tenant.
- Prevent negative base price.
- Validate discount price.
- Validate tax percentage.
- Maintain effective date.
- Maintain expiry date.
- Maintain pricing status.
- Preserve pricing history.

## Collection Relationships

- Link every service to one tenant.
- Link every category to one tenant.
- Link every pricing record to one tenant.
- Link every pricing record to one branch.
- Link every pricing record to one service.
- Link every service to an existing category.
- Link branch availability to valid tenant branches.
- Preserve archived service references.
- Preserve historical pricing records.

## REST APIs

### Create Service

- Method: `POST`.
- Path: `/services`.
- Purpose: Create a new service.
- Validate tenant ownership.
- Validate required service name.
- Validate service code uniqueness.
- Validate category.
- Validate base price.
- Validate processing time.
- Validate tax configuration.
- Validate assigned branches.

### Get Service

- Method: `GET`.
- Path: `/services/:serviceId`.
- Purpose: Return complete service details.
- Validate service identity.
- Validate tenant ownership.
- Apply branch availability.
- Apply RBAC.
- Return authorized service information.

### Update Service

- Method: `PUT`.
- Path: `/services/:serviceId`.
- Purpose: Update service information.
- Validate service identity.
- Validate tenant ownership.
- Apply RBAC.
- Validate updated service values.
- Preserve service history.

### List Services

- Method: `GET`.
- Path: `/services`.
- Purpose: Return paginated services.
- Support pagination.
- Support filtering.
- Support sorting.
- Support searching.
- Support category filtering.
- Support branch-specific retrieval.
- Enforce tenant isolation.

### Create Category

- Method: `POST`.
- Path: `/services/categories`.
- Purpose: Create a new service category.
- Validate tenant ownership.
- Validate category information.
- Maintain category hierarchy.
- Maintain display order.
- Validate category status.

### Update Pricing

- Method: `PATCH`.
- Path: `/services/:serviceId/pricing`.
- Purpose: Update service pricing.
- Validate tenant ownership.
- Validate branch ownership.
- Validate service identity.
- Prevent negative base price.
- Validate discount price.
- Validate tax percentage.
- Maintain effective and expiry dates.
- Preserve pricing history.

### Assign Branches

- Method: `PATCH`.
- Path: `/services/:serviceId/branches`.
- Purpose: Assign one or more branches.
- Validate tenant ownership.
- Validate service identity.
- Validate every branch.
- Keep branches in the same tenant.
- Maintain branch availability.

### Archive Service

- Method: `PATCH`.
- Path: `/services/:serviceId/archive`.
- Purpose: Soft archive a service.
- Validate service identity.
- Validate tenant ownership.
- Apply RBAC.
- Prevent physical deletion.
- Preserve historical order integrity.
- Preserve service information.

### Restore Service

- Method: `PATCH`.
- Path: `/services/:serviceId/restore`.
- Purpose: Restore an archived service.
- Validate service identity.
- Validate tenant ownership.
- Apply RBAC.
- Restore service availability by valid status.
- Preserve archive and restore history.

## API Limit

- Implement only the nine listed Service APIs.
- Do not add category update, category delete, pricing history, import, export, or additional status APIs.
- Keep unlisted work within the listed API scope.

## Validation Rules

- Require and validate service name during creation and updates.
- Require service code, keep it tenant-unique, and prevent duplicates.
- Require an existing category before service creation or category changes.
- Prevent negative base price during service creation and pricing updates.
- Validate processing time during creation and updates.
- Keep tax percentage within configured limits.
- Require every assigned branch to belong to the tenant.
- Validate service, pricing, and category status values.
- Archive instead of deleting services referenced by active orders.

## Security Requirements

- Enforce tenant isolation for service access, updates, lists, and search.
- Enforce branch ownership and branch-level service availability.
- Apply RBAC to create, view, update, pricing, assignment, archive, and restore operations.
- Secure pricing updates through ownership, RBAC, price, tax, and history validation.
- Audit service, category, pricing, branch, archive, restore, and acting-user changes.
- Archive instead of deleting and preserve historical order integrity.
- Keep service codes tenant-unique and prevent duplicates.

## Integrations

- Authentication: use authenticated user, tenant, and acting-user context.
- Multi-Tenancy: validate ownership and isolate services, codes, categories, and pricing.
- Branch Management: validate branches, availability, assignments, and synchronization.
- User Management: use authorized identity, RBAC, CreatedBy, and UpdatedBy.
- Customer Management: make services available without implementing customers.
- Order Management: provide active services, pricing, snapshots, and historical integrity.
- Payment Management: provide service pricing information without implementing payments.
- Reports: provide revenue, popularity, and operational service data.
- Dashboard: provide service data for listed analytics without implementing dashboards.
- Search: support service search, category filters, branches, and index synchronization.
- Notification Service: use the listed integration without implementing delivery.
- Audit Service: audit service, category, pricing, branch, archive, and restore changes.
- Settings: use configured tax limits and listed settings.

## Background Jobs

- Scheduled activation: activate pricing on its effective date and preserve history.
- Scheduled expiry: expire pricing on its expiry date and preserve history.
- Branch synchronization: preserve tenant ownership and service availability.
- Cache refresh: preserve tenant isolation and branch availability.
- Category hierarchy update: preserve parent category and display order.
- Analytics aggregation: use service data only for the listed process and integrations.
- Popular service calculation: provide data for listed Reports and Dashboard integrations.
- Search synchronization: preserve tenant, branch, and category scope.

## Testing Requirements

### Unit Tests

- Test service creation.
- Test required service name.
- Test unique service code.
- Test service updates.
- Test category management.
- Test category existence.
- Test price validation.
- Test negative price prevention.
- Test tax percentage validation.
- Test processing time.
- Test branch assignment.
- Test status validation.
- Test archive and restore.

### Integration Tests

- Test tenant validation.
- Test tenant isolation.
- Test branch validation.
- Test branch availability.
- Test Order Management integration.
- Test pricing integration.
- Test Search integration.
- Test Audit Service integration.
- Test Settings integration.

### Security Tests

- Test tenant isolation.
- Test branch isolation.
- Test unauthorized service access.
- Test unauthorized service modification.
- Test unauthorized pricing updates.
- Test duplicate service prevention.
- Test RBAC validation.
- Test soft delete protection.
- Test active order deletion prevention.

### Performance Tests

- Test service creation.
- Test service listing.
- Test service search.
- Test category filtering.
- Test branch-specific service retrieval.
- Test bulk service loading.
- Verify pagination performance.
- Verify search performance.

## Implementation Sequence

1. Confirm Phase 14 Service Management scope.
2. Review the listed module purpose.
3. Review the listed responsibilities.
4. Review the listed functional areas.
5. Review the business workflow.
6. Implement `services`.
7. Implement `serviceCategories`.
8. Implement `servicePricing`.
9. Implement Service Registration.
10. Implement Service Profile Management.
11. Implement Service Category Management.
12. Implement Service Pricing.
13. Implement Service Duration.
14. Implement Service Availability.
15. Implement Branch Service Assignment.
16. Implement Tax and Discount Configuration.
17. Implement Service Status Management.
18. Implement Service Search and Filtering.
19. Implement the nine listed APIs.
20. Implement the listed validation rules.
21. Implement the listed security controls.
22. Implement the listed background jobs.
23. Implement the listed integrations.
24. Implement the listed tests.
25. Verify the acceptance criteria.
26. Update Service Management documentation.
27. Record completion evidence.
28. Stop without starting another phase.

## Deliverables

### Service Features

- Service Creation.
- Service Profile Management.
- Service Category Management.
- Service Pricing Management.
- Service Status Management.
- Service Availability Management.
- Service Duration Management.
- Service Tax Configuration.
- Service Discount Configuration.
- Service Branch Assignment.
- Service Search and Filtering.
- Service Import and Export.
- Service Archive and Restore.
- Service Audit Management.

### Collections

- `services`.
- `serviceCategories`.
- `servicePricing`.

### APIs

- `POST /services`.
- `GET /services/:serviceId`.
- `PUT /services/:serviceId`.
- `GET /services`.
- `POST /services/categories`.
- `PATCH /services/:serviceId/pricing`.
- `PATCH /services/:serviceId/branches`.
- `PATCH /services/:serviceId/archive`.
- `PATCH /services/:serviceId/restore`.

### Tests

- Service unit tests.
- Service integration tests.
- Service security tests.
- Service performance tests.

### Documentation

- Service module documentation.
- Collection documentation.
- API documentation.
- Validation documentation.
- Security documentation.
- Integration documentation.
- Testing documentation.
- Completion evidence.

## Acceptance Criteria

### Service Creation

- [ ] Services can be created successfully.
- [ ] Service name is validated.
- [ ] Service code is tenant-unique.
- [ ] Category exists.
- [ ] Base price is valid.
- [ ] Processing time is valid.
- [ ] Tax percentage is valid.
- [ ] Assigned branches are valid.

### Categories

- [ ] Service categories can be created.
- [ ] Category codes are maintained.
- [ ] Category names are maintained.
- [ ] Parent categories are maintained.
- [ ] Display order is maintained.
- [ ] Category status is maintained.

### Pricing and Tax

- [ ] Base pricing is maintained.
- [ ] Branch-specific pricing is maintained.
- [ ] Discount pricing is maintained.
- [ ] Tax configuration is maintained.
- [ ] Effective dates are maintained.
- [ ] Expiry dates are maintained.
- [ ] Pricing history is preserved.
- [ ] Negative prices are prevented.

### Branch Availability

- [ ] Services can be assigned to branches.
- [ ] Assigned branches belong to the tenant.
- [ ] Branch-specific availability is supported.
- [ ] Branch-specific retrieval works.
- [ ] Branch synchronization is supported.

### Service Status

- [ ] Service status is maintained.
- [ ] Services can be archived.
- [ ] Archived services can be restored.
- [ ] Soft deletion preserves service history.
- [ ] Active order references are protected.

### Search

- [ ] Service search works.
- [ ] Service filtering works.
- [ ] Category filtering works.
- [ ] Branch filtering works.
- [ ] Sorting works.
- [ ] Pagination works.
- [ ] Bulk loading is tested.

### Security

- [ ] Tenant isolation is enforced.
- [ ] Branch availability is enforced.
- [ ] Unauthorized modifications are prevented.
- [ ] Pricing updates are secured.
- [ ] RBAC validation is enforced.
- [ ] Service changes are audited.
- [ ] Duplicate service codes are prevented.

### Integrations

- [ ] Authentication integration works.
- [ ] Multi-Tenancy integration works.
- [ ] Branch Management integration works.
- [ ] User Management integration works.
- [ ] Customer Management integration works.
- [ ] Order Management integration works.
- [ ] Payment Management integration works.
- [ ] Reports integration works.
- [ ] Dashboard integration works.
- [ ] Search integration works.
- [ ] Notification Service integration works.
- [ ] Audit Service integration works.
- [ ] Settings integration works.

### Historical Integrity

- [ ] Orders can store service pricing snapshots.
- [ ] Historical pricing remains available.
- [ ] Archived services remain available for historical references.
- [ ] Completed order integrity is preserved.

### Testing

- [ ] Unit tests pass.
- [ ] Integration tests pass.
- [ ] Security tests pass.
- [ ] Performance tests pass.
- [ ] Validation tests pass.
- [ ] Search tests pass.
- [ ] Branch availability tests pass.

## Completion Instructions

1. Verify every listed responsibility.
2. Verify every listed functional area.
3. Verify the business workflow.
4. Verify all three collections.
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
19. Update the corresponding Service Management completion report.
20. Stop execution.

Do not start another phase.
