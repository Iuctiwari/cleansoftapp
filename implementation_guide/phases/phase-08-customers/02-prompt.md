
Implement the **Customer Management** module for the Nexoraa CleanSoft NestJS + MongoDB backend exactly according to the provided Phase 13 implementation specification. Follow the document completely and do not change the architecture, scope, APIs, collections, business rules, or implementation sequence.

Requirements:

- Implement the module as a production-ready, standalone NestJS module following the existing project architecture, coding standards, SOLID principles, Clean Architecture, and existing module structure.
- Preserve all existing functionality of Authentication, Multi-Tenancy, Branch Management, User Management, RBAC, JWT Authentication, Audit Logging, Validation, Exception Filters, Response Interceptors, and all existing modules. Do not modify or break any existing functionality.
- Implement only the functionality defined in this phase. Do not implement any deferred features or any other modules.

Build the module exactly as specified:

1. Create all four collections:
   - customers
   - customerAddresses
   - customerNotes
   - customerLoyalty

2. Follow the defined source-of-truth architecture:
   - customerAddresses is the authoritative source for customer addresses.
   - customers.defaultAddress is only a synchronized snapshot of the default address.
   - customerLoyalty is the authoritative source for loyalty information.
   - customers.loyaltyPoints is only a synchronized snapshot of availablePoints.
   - Keep all snapshot fields synchronized automatically whenever the source data changes.

3. Implement exactly these eight REST APIs and no additional APIs:
   - POST /customers
   - GET /customers/:customerId
   - PUT /customers/:customerId
   - GET /customers
   - GET /customers/search
   - PATCH /customers/:customerId/loyalty
   - PATCH /customers/:customerId/archive
   - PATCH /customers/:customerId/restore

4. Ensure every API follows:
   - JWT Authentication
   - RBAC Authorization
   - Tenant Isolation
   - Branch Isolation
   - Request Validation
   - Standard Response Format
   - Existing Exception Handling
   - Audit Logging

5. Implement all validation rules exactly as defined:
   - Required fields
   - Tenant-unique customerCode
   - Tenant-unique mobile number
   - Email validation
   - Branch validation
   - Loyalty validation
   - Communication preference validation
   - Address validation
   - Duplicate prevention

6. Implement all security rules exactly as defined:
   - Tenant isolation
   - Branch access validation
   - RBAC
   - Soft archive
   - Restore
   - Audit logging
   - Duplicate protection

7. Implement schema-only support for:
   - customerAddresses
   - customerNotes

These collections must exist and be fully linked but must not expose standalone APIs in this phase. They should only be accessed through the Customer APIs as defined in the specification.

8. Implement all required integrations:
   - Authentication
   - Multi-Tenancy
   - Branch Management
   - User Management
   - Audit Service
   - Settings

Provide read-only integration support for:
   - Orders
   - Payments
   - Services
   - Notifications
   - Reports
   - Dashboard
   - Search

Do not implement those modules.

9. Implement all required background jobs:
   - Welcome notification
   - Birthday reminders
   - Anniversary reminders
   - Loyalty recalculation
   - Inactivity detection
   - Data synchronization
   - Analytics feed
   - Duplicate detection

These jobs must remain internal and must not expose additional APIs.

10. Follow the implementation sequence exactly:
   - Build collections
   - Implement registration
   - Profile management
   - Contact management
   - Classification
   - Status management
   - Loyalty management
   - Notes integration
   - Communication preferences
   - Search
   - Validation
   - Security
   - Audit logging
   - Background jobs
   - Integrations
   - Testing

11. Implement comprehensive testing including:
   - Unit Tests
   - Integration Tests
   - Security Tests
   - Performance Tests

12. The implementation is complete only when all acceptance criteria defined in the specification are satisfied.

Acceptance requirements:
- Registration works with required validations.
- Tenant-unique customerCode and mobile are enforced.
- Duplicate customers are prevented.
- Profile retrieval and update work correctly.
- Address synchronization works correctly.
- Loyalty synchronization works correctly.
- Search is tenant-aware, branch-aware, paginated, sortable, and filterable.
- Audit logs are generated for every required operation.
- Archive and Restore preserve history.
- RBAC and tenant isolation are enforced on every endpoint.
- All required integrations function correctly.
- All tests pass successfully.

Important:
- Do not add extra collections.
- Do not add extra APIs.
- Do not change the project architecture.
- Do not modify existing modules except where integration is required.
- Do not implement deferred features.
- Do not start any subsequent phase after completing this module.
- Ensure the module compiles without TypeScript errors, integrates seamlessly into the existing codebase, and is production-ready.
```


## Security

### Role-Based Access Control

| API                          | Owner | Branch Manager     Staff              |
|-------------------------------|:-----:|:---------------:|:-------------------:|
| POST /customers               |  ✅   |       ✅        |         ❌          |
| GET /customers/:id            |  ✅   |       ✅        | ✅ (limited fields) |
| PUT /customers/:id            |  ✅   |       ✅        |         ❌          |
| GET /customers                |  ✅   |       ✅        | ✅ (limited fields) |
| GET /customers/search         |  ✅   |       ✅        | ✅ (limited fields) |
| PATCH /:id/loyalty            |  ✅   |       ✅        |         ❌          |
| PATCH /:id/archive            |  ✅   |       ✅        |         ❌          |
| PATCH /:id/restore            |  ✅   |       ✅        |         ❌          |

- Staff read access returns only name, mobile, and order-relevant notes — never full 
  profile, loyalty, or address data.
- Branch Manager access is further restricted to customers within their assigned 
  branch(es); Owner has tenant-wide access.
- Cashier role has no access to this module.

### General Rules
- Tenant isolation and branch-level access control enforced on every operation.
- Archive instead of delete; archived ≠ deleted; restore is logged.
- Audit log on create, update, loyalty change, archive, restore — capturing acting user.
- Duplicate creation blocked via pre-insert uniqueness check (code + mobile).