# PHASE 11 — BRANCH MANAGEMENT IMPLEMENTATION PROMPT

## Phase Information

- Phase Number: 11.
- Phase Name: Branch Management.
- Module: Branch Management.
- Status: Implementation prompt.
- Scope: One tenant and its physical or operational branches.
- Completion Report: `ERP-PLANNING/phase-completions/PHASE_11_BRANCH_MANAGEMENT_COMPLETION.md`.

## Role

- Act as a Senior Enterprise Software Architect and Lead Full Stack Engineer.
- Implement a secure, scalable, production-ready Branch Management module.
- Treat the repository as the authoritative source of current project state.
- Preserve all unrelated and previously completed work.
- Implement only the work authorized by this phase.
- Stop immediately after completing Phase 11.

## Module Context

- Authentication identifies the user.
- Multi-Tenancy identifies the organization.
- Branch Management identifies the operating location.
- Every branch belongs to exactly one tenant.
- A branch can never belong to multiple tenants.
- A branch can never be transferred between tenants.
- Downstream business records must reference a valid tenant branch.
- Branch Management owns branch identity and operating context.
- Branch Management does not own downstream business transactions.

## Objective

- Implement branch creation and registration.
- Implement branch profile management.
- Implement branch address management.
- Implement branch contact management.
- Implement working-hours management.
- Implement branch manager assignment.
- Implement branch lifecycle management.
- Implement default-branch management.
- Implement branch configuration management.
- Implement branch-context validation.
- Implement tenant and branch isolation.
- Implement RBAC enforcement.
- Implement required APIs and events.
- Implement required background jobs.
- Implement approved frontend workflows.
- Implement complete testing and documentation.

## Business Purpose

- Allow a tenant to operate one or more locations.
- Maintain centralized tenant ownership.
- Allow branch-level operational independence.
- Provide a stable branch identity for all operational modules.
- Prevent unauthorized cross-tenant access.
- Prevent unauthorized cross-branch access.
- Support subscription-aware branch limits.
- Support auditable branch administration.

## Mandatory Reading

- Read `ERP-PLANNING/PROJECT_BIBLE.md`.
- Read `ERP-PLANNING/SOFTWARE_IDEA.md`.
- Read `ERP-PLANNING/BUSINESS_REQUIREMENTS.md`.
- Read `ERP-PLANNING/BUSINESS_GOALS.md`.
- Read `ERP-PLANNING/TARGET_USERS.md`.
- Read `ERP-PLANNING/FEATURE_LIST.md`.
- Read `ERP-PLANNING/SYSTEM_ARCHITECTURE.md`.
- Read `ERP-PLANNING/TECH_STACK.md`.
- Read `ERP-PLANNING/MICROSERVICES.md`.
- Read `ERP-PLANNING/MODULE_BREAKDOWN.md`.
- Read `ERP-PLANNING/DATABASE_DESIGN.md`.
- Read `ERP-PLANNING/DOMAIN_MODEL.md`.
- Read `ERP-PLANNING/ENTITY_RELATIONSHIP.md`.
- Read `ERP-PLANNING/API_DESIGN.md`.
- Read `ERP-PLANNING/EVENT_ARCHITECTURE.md`.
- Read `ERP-PLANNING/MULTI_TENANCY.md`.
- Read `ERP-PLANNING/RBAC.md`.
- Read `ERP-PLANNING/SECURITY_ARCHITECTURE.md`.
- Read `ERP-PLANNING/CODING_GUIDELINES.md`.
- Read `ERP-PLANNING/NAMING_CONVENTIONS.md`.
- Read `ERP-PLANNING/DIRECTORY_GUIDE.md`.
- Read the root `README.md`.
- Read `docs/README.md`.
- Read `apps/README.md`.
- Read `packages/README.md`.
- Read every README in directories touched by this phase.
- Read Authentication and Multi-Tenancy prompts.
- Read Authentication and Multi-Tenancy completion reports.
- Read applicable Architecture Decision Records.
- Read relevant API, event, job, persistence, and test contracts.
- Inspect the current repository tree.
- Inspect the current Git status.
- Inspect all existing Branch-related work.

## Dependency Requirements

### Authentication

- Verify authenticated user identity.
- Verify active session or token validation.
- Verify tenant-context propagation.
- Verify stable user identifiers.
- Verify role and permission integration.
- Verify request-correlation support.

### Multi-Tenancy

- Verify tenant identity.
- Verify tenant lifecycle status.
- Verify tenant ownership validation.
- Verify subscription and branch limits.
- Verify tenant settings and defaults.
- Verify tenant-context resolution.
- Verify tenant-isolation standards.

### Platform

- Verify MongoDB connectivity.
- Verify configuration validation.
- Verify API versioning conventions.
- Verify common error handling.
- Verify structured logging.
- Verify health and readiness support.
- Verify testing and build commands.

### Dependency Rules

- Verify completion reports against repository evidence.
- Run critical dependency tests before implementation.
- Do not trust stale documentation over verified behavior.
- Repair only a minimal dependency defect when necessary.
- Document every dependency repair.
- Do not hide missing predecessor work inside this phase.
- Escalate missing security or ownership decisions.

## Scope

- Branch registration.
- Branch creation.
- Branch-code generation.
- Branch profile updates.
- Branch type management.
- Branch address updates.
- Branch contact updates.
- Working-hours updates.
- Branch manager assignment.
- Branch manager replacement.
- Branch manager removal.
- Branch activation.
- Branch suspension.
- Branch reactivation.
- Branch deactivation.
- Default-branch designation.
- Branch configuration.
- Tenant branch-limit enforcement.
- Branch-context validation.
- Branch-level access control.
- RBAC integration.
- Audit integration.
- Domain events.
- Required background jobs.
- Flutter web administration.
- Approved Flutter mobile workflows.
- Testing and documentation.

## Out of Scope

- Customer Management.
- Service Management.
- Order Management.
- Payment Management.
- Expense Management.
- Inventory Management.
- Reporting implementation.
- Dashboard implementation.
- Payroll.
- Attendance.
- Employee scheduling.
- Route optimization.
- Geocoding.
- Location tracking.
- Tax calculation.
- Notification delivery infrastructure.
- Tenant subscription implementation.
- Physical deletion of historical branches.
- Cross-tenant branch transfer.
- Downstream module implementation.
- Unapproved business rules.

## Architecture Requirements

- Use the approved Branch owning service or module.
- Use `apps/backend/branch-service/` only when current architecture supports it.
- Do not create a competing service.
- Keep controllers thin.
- Keep business invariants in domain or application services.
- Keep persistence behind repositories or adapters.
- Keep shared packages domain-neutral.
- Do not access another service's private collections.
- Use versioned API contracts.
- Use versioned event contracts.
- Use versioned job contracts.
- Use optimistic concurrency.
- Use idempotency for retryable commands.
- Use outbox and inbox patterns for cross-service effects.
- Record material architecture changes in ADRs.

## Data Ownership

- Branch Management owns branch identity.
- Branch Management owns branch lifecycle.
- Branch Management owns branch profile.
- Branch Management owns branch address.
- Branch Management owns branch contact data.
- Branch Management owns branch working hours.
- Branch Management owns branch manager reference.
- Branch Management owns default designation.
- Branch Management owns branch configuration.
- Tenant Management owns tenant identity.
- Tenant Management owns subscriptions and entitlements.
- User Management owns users, roles, and assignments.
- Audit Service owns audit records.
- Notification Service owns notification delivery.
- Downstream services own their business records.

## Branch Lifecycle

- Support `DRAFT` or the approved equivalent.
- Support `ACTIVE`.
- Support `SUSPENDED`.
- Support `INACTIVE` or `DEACTIVATED`.
- Define every allowed transition.
- Reject every undocumented transition.
- Require permission for every transition.
- Require a reason for suspension.
- Require a reason for deactivation.
- Record the actor for every transition.
- Record the transition timestamp.
- Record correlation context.
- Publish one event per committed transition.
- Keep suspended and deactivated branches.
- Never physically delete referenced branches.
- Prevent general updates from changing status.

## Default Branch Rules

- Allow no more than one default branch per tenant.
- Require one default when tenant policy requires it.
- Make the first eligible branch default when required.
- Allow only an active branch to become default.
- Apply default changes atomically.
- Make repeated default selection idempotent.
- Prevent concurrent requests from creating two defaults.
- Require replacement before disabling the default when necessary.

## Branch Registration

- Authenticate the requesting user.
- Resolve trusted tenant context.
- Authorize branch creation.
- Verify tenant status.
- Verify subscription branch limits.
- Validate branch information.
- Generate the branch code on the server.
- Prevent duplicate creation under retries.
- Create the branch.
- Initialize branch configuration.
- Assign an optional eligible manager.
- Set the default branch when required.
- Record audit context.
- Publish the branch-created event.

## Branch Profile

- Require a branch name.
- Support an optional display name.
- Support an approved branch type.
- Support an optional description.
- Support a valid time zone.
- Support an approved locale.
- Support an approved language.
- Support currency only when branch override is permitted.
- Keep tenant ownership immutable.
- Keep branch code immutable after creation.

## Branch Address

- Support address line one.
- Support address line two.
- Support locality or city.
- Support state, province, or region.
- Support postal code.
- Support ISO country code.
- Support an optional landmark.
- Support international formats.
- Do not require geolocation.
- Protect address fields from unsafe content.

## Branch Contact

- Support primary email.
- Support primary telephone number.
- Support optional alternate telephone number.
- Support only approved public contact channels.
- Normalize email values.
- Normalize telephone values.
- Bound every contact field.
- Redact contact values from logs.

## Working Hours

- Support a seven-day schedule.
- Support closed days.
- Support approved daily intervals.
- Support multiple intervals when approved.
- Support overnight intervals only when approved.
- Require a valid time zone.
- Reject invalid time formats.
- Reject overlapping intervals.
- Reject duplicate day definitions.
- Reject intervals on closed days.
- Do not implement employee shifts.
- Do not implement attendance.

## Branch Manager

- Reference an existing user.
- Verify the user belongs to the same tenant.
- Verify the user is active.
- Verify the user is eligible to manage the branch.
- Verify required role or permission.
- Prevent cross-tenant assignment.
- Support manager replacement.
- Support manager removal when policy permits it.
- Record the assigning actor.
- Record the assignment timestamp.
- Publish manager-change events.
- Do not modify the user record directly.

## Branch Configuration

- Initialize configuration during branch creation.
- Support order prefix.
- Support invoice prefix.
- Support receipt prefix.
- Support approved tax-setting references.
- Support working-hours settings in one authoritative location.
- Support notification preferences.
- Support printing preferences.
- Support default language.
- Support default currency.
- Support approved feature overrides.
- Inherit tenant defaults where required.
- Permit only allowlisted overrides.
- Prevent branch overrides from weakening tenant policy.
- Prevent unavailable features from being enabled.
- Validate prefixes.
- Do not store secrets.

## Branch Context

- Include trusted tenant identifier.
- Include branch identifier.
- Include branch status.
- Include user branch access.
- Include permission scope.
- Include correlation context.
- Reject a branch outside the tenant.
- Reject an inaccessible branch.
- Reject suspended branches for new operational writes.
- Reject inactive branches for new operational writes.
- Define historical read access.
- Clear branch-scoped client caches after switching.
- Never trust a body tenant identifier.
- Never trust a query tenant identifier.

## MongoDB Collections

### `branches`

- Store one authoritative document per branch.
- Store an opaque branch identifier.
- Store tenant identifier.
- Store server-generated branch code.
- Store branch name.
- Store optional display name.
- Store branch type.
- Store optional description.
- Store lifecycle status.
- Store status reason.
- Store status-change metadata.
- Store default-branch designation.
- Store manager user identifier.
- Store manager-assignment metadata.
- Store contact information.
- Store address information.
- Store time zone.
- Store locale.
- Store language.
- Store currency when permitted.
- Store working hours in the approved canonical location.
- Store created-by and updated-by identifiers.
- Store created and updated timestamps.
- Store optimistic-concurrency version.

### `branches` Invariants

- Require tenant identifier.
- Keep tenant identifier immutable.
- Require branch code.
- Keep branch code immutable.
- Make branch code unique within tenant.
- Require valid lifecycle status.
- Keep manager within tenant.
- Keep at most one tenant default.
- Prevent physical deletion after operational use.

### `branches` Indexes

- Unique index on tenant and branch code.
- Lookup index on tenant and branch identifier.
- List index on tenant and status.
- Default lookup index on tenant and default designation.
- Search index on tenant and normalized branch name.
- Manager index on tenant and manager identifier.
- Pagination index on tenant and created timestamp.
- Pagination index on tenant and updated timestamp.

### `branchConfigurations`

- Store one current configuration per branch.
- Store an opaque configuration identifier.
- Store tenant identifier.
- Store branch identifier.
- Store configuration version.
- Store order prefix.
- Store invoice prefix.
- Store receipt prefix.
- Store approved tax-setting references.
- Store working hours only when canonical here.
- Store notification preferences.
- Store printing preferences.
- Store default language.
- Store default currency.
- Store approved feature overrides.
- Store inheritance indicators.
- Store override indicators.
- Store created-by and updated-by identifiers.
- Store created and updated timestamps.
- Store optimistic-concurrency version.

### `branchConfigurations` Invariants

- Require tenant identifier.
- Require branch identifier.
- Match configuration tenant to branch tenant.
- Allow one current configuration per branch.
- Reject protected setting overrides.
- Reject unavailable feature overrides.
- Reject secrets.
- Keep configuration after branch deactivation.

### `branchConfigurations` Indexes

- Unique index on tenant and branch identifier.
- Lookup index on tenant and branch identifier.
- Reconciliation index on tenant and updated timestamp.
- Add prefix uniqueness only when business rules require it.

## API Standards

- Follow the approved API version prefix.
- Require authentication.
- Resolve tenant context from trusted identity.
- Apply RBAC to every endpoint.
- Apply branch access to every endpoint.
- Validate path parameters.
- Validate query parameters.
- Validate request bodies.
- Use stable machine-readable errors.
- Return correlation information.
- Use bounded pagination.
- Use allowlisted filters and sorting.
- Use optimistic concurrency for updates.
- Use idempotency for high-impact commands.
- Audit material mutations.
- Hide cross-tenant resource existence.
- Register static routes before `:branchId` routes.

## Branch APIs

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/branches` | Create a branch and initialize configuration; require create permission and idempotency. |
| `GET` | `/branches` | List visible branches with bounded pagination, filters, search, and sorting. |
| `GET` | `/branches/accessible` | List minimal branch choices available to the current user; omit if the main list safely covers this. |
| `GET` | `/branches/current` | Return trusted current branch context without accepting an arbitrary branch ID. |
| `GET` | `/branches/default` | Return the visible tenant default branch. |
| `GET` | `/branches/:branchId` | Return authorized branch details, version, and permitted actions. |
| `PUT/PATCH` | `/branches/:branchId` | Update mutable profile fields with update permission and expected version. |
| `GET` | `/branches/:branchId/contact` | Return authorized contact information. |
| `PUT` | `/branches/:branchId/contact` | Update validated contact information with expected version. |
| `GET` | `/branches/:branchId/address` | Return authorized address information. |
| `PUT` | `/branches/:branchId/address` | Update validated address information with expected version. |
| `GET` | `/branches/:branchId/working-hours` | Return canonical working hours and time zone. |
| `PUT` | `/branches/:branchId/working-hours` | Update validated working hours and publish an event. |
| `GET` | `/branches/:branchId/configuration` | Return effective, inherited, and overridden settings. |
| `PUT/PATCH` | `/branches/:branchId/configuration` | Update allowlisted settings with expected version. |
| `POST` | `/branches/:branchId/configuration/reset` | Reset selected overrides to tenant defaults. |
| `GET` | `/branches/:branchId/manager` | Return the current authorized manager summary. |
| `PUT` | `/branches/:branchId/manager` | Assign or replace an eligible same-tenant manager. |
| `DELETE` | `/branches/:branchId/manager` | Remove the manager when policy permits it. |
| `PATCH` | `/branches/:branchId/default` | Atomically set an eligible active branch as default. |
| `PATCH` | `/branches/:branchId/activate` | Activate an eligible branch with version and idempotency checks. |
| `PATCH` | `/branches/:branchId/suspend` | Suspend a branch with version, idempotency, and reason. |
| `PATCH` | `/branches/:branchId/reactivate` | Reactivate a suspended branch; omit if activation covers this transition. |
| `PATCH` | `/branches/:branchId/deactivate` | Deactivate a branch with version, idempotency, and reason. |
| `POST` | `/branches/:branchId/select` | Select an accessible active branch through the Authentication-owned session contract. |

## API Errors

- Invalid input.
- Unauthenticated.
- Forbidden.
- Branch not found.
- Tenant inactive.
- Branch inactive.
- Branch suspended.
- Invalid lifecycle transition.
- Branch limit exceeded.
- Duplicate branch code.
- Invalid manager.
- Cross-tenant manager.
- Invalid working hours.
- Invalid configuration.
- Default-branch conflict.
- Concurrency conflict.
- Idempotency conflict.
- Dependency unavailable.

## Validation Rules

- Require branch name.
- Trim and bound branch name.
- Generate branch code on the server.
- Make branch code tenant-unique.
- Require an existing tenant.
- Require an operational tenant.
- Enforce subscription branch limits.
- Prevent concurrent limit bypass.
- Require an approved branch type.
- Validate email.
- Validate telephone values.
- Validate country code.
- Validate address fields.
- Validate time zone.
- Validate working-hours intervals.
- Reject overlapping intervals.
- Require same-tenant manager.
- Require active manager.
- Require eligible manager role.
- Allow one default branch.
- Require active default branch.
- Validate configuration keys.
- Validate prefixes.
- Validate language and currency.
- Reject secrets.
- Reject stale versions.
- Reject invalid transitions.

## RBAC Requirements

- Define branch-view permission.
- Define branch-create permission.
- Define branch-update permission.
- Define contact-update permission.
- Define address-update permission.
- Define working-hours-update permission.
- Define configuration-view permission.
- Define configuration-update permission.
- Define manager-assign permission.
- Define default-branch-update permission.
- Define branch-activate permission.
- Define branch-suspend permission.
- Define branch-deactivate permission.
- Define branch-select permission.
- Use approved permission naming conventions.
- Apply deny-by-default authorization.
- Keep backend authorization authoritative.

## Security Requirements

- Enforce tenant ownership on every operation.
- Enforce branch access on every operation.
- Prevent cross-tenant access.
- Prevent unauthorized cross-branch access.
- Prevent tenant identifier tampering.
- Prevent branch identifier tampering.
- Prevent manager identifier tampering.
- Prevent mass assignment.
- Prevent NoSQL injection.
- Prevent unsafe filtering and sorting.
- Prevent stored cross-site scripting.
- Rate-limit sensitive mutations.
- Redact sensitive values from logs.
- Minimize returned contact data.
- Use opaque identifiers.
- Protect default-branch concurrency.
- Protect branch-limit concurrency.
- Require idempotency for high-impact actions.
- Audit every material change.
- Store no credentials or secrets.

## Integration Requirements

- Authentication: consume trusted user and tenant context, validate branch context, and delegate session ownership.
- Multi-Tenancy: validate tenant identity, status, branch limits, defaults, and initial branch creation.
- User Management: validate manager identity, membership, status, and eligibility without direct collection access.
- Customer Management: provide stable branch identity and validation without implementing customers.
- Service Management: provide branch identity and configuration events without implementing services.
- Order Management: provide branch identity and lifecycle events without implementing orders.
- Payment Management: preserve historical branch references without implementing payments.
- Expense Management: preserve historical branch references without implementing expenses.
- Reports and Dashboard: publish branch events without implementing projections or dashboards.
- Notification Service: submit approved manager and lifecycle events without implementing delivery.
- Audit Service: audit creation, profile, address, contact, hours, configuration, manager, default, and lifecycle changes.

## Domain Events

- Publish created, profile-updated, contact-updated, address-updated, and working-hours-updated events.
- Publish configuration-updated, manager-assigned, manager-replaced, and manager-removed events.
- Publish default-changed, activated, suspended, reactivated, and deactivated events.
- Use the established envelope with tenant, branch, event, version, time, correlation, and causation data.
- Exclude sensitive payload data, publish through outbox, and require idempotent consumers.

## Background Jobs

- Configuration reconciliation: refresh effective settings in bounded, idempotent, resumable batches.
- Lifecycle processing: retry approved asynchronous effects without changing committed branch state.
- Working-hours refresh: refresh approved derived caches without creating employee schedules.
- Manager notification: submit deduplicated requests without implementing notification delivery.
- Every job must define ownership, version, idempotency, retry, backoff, concurrency, dead-letter, monitoring, and recovery.

## Backend Requirements

- Use strict TypeScript.
- Use approved NestJS patterns.
- Use validated DTO boundaries.
- Use tenant-aware repositories.
- Use stable error codes.
- Use UTC timestamps.
- Use structured redacted logs.
- Use correlation identifiers.
- Use optimistic concurrency.
- Use idempotency.
- Use outbox and inbox patterns.
- Support graceful shutdown.
- Support health and readiness checks.
- Avoid direct cross-service database access.

## Flutter Requirements

- Build a branch list.
- Build branch search and filters.
- Build branch registration.
- Build branch details.
- Build profile editing.
- Build contact editing.
- Build address editing.
- Build working-hours editing.
- Build configuration editing.
- Build manager assignment.
- Build default-branch selection.
- Build lifecycle actions.
- Build current-branch selection when approved.
- Show loading states.
- Show empty states.
- Show validation errors.
- Show forbidden states.
- Show conflict states.
- Show retryable errors.
- Show terminal errors.
- Clear caches after branch switching.
- Follow Material 3.
- Follow accessibility standards.
- Keep server authorization authoritative.

## Performance Requirements

- Paginate every branch list.
- Bound every page size.
- Use tenant-scoped indexes.
- Use projections for list responses.
- Avoid unbounded regular expressions.
- Avoid collection scans.
- Bound filters and sorting.
- Measure branch creation.
- Measure branch lookup.
- Measure branch listing.
- Measure default lookup.
- Measure accessible-branch lookup.
- Measure configuration retrieval.
- Test concurrent branch creation.
- Test concurrent default changes.
- Record dataset and environment.
- Record actual results.

## Reliability Requirements

- Prevent duplicate branches under retries.
- Prevent duplicate configurations.
- Preserve default-branch invariants.
- Recover failed event publication.
- Make jobs idempotent.
- Report dependency failures honestly.
- Avoid inconsistent success responses.
- Support graceful recovery.

## Observability Requirements

- Log branch operations safely.
- Emit creation metrics.
- Emit lifecycle metrics.
- Emit authorization-denial metrics.
- Emit dependency-failure metrics.
- Emit job-retry metrics.
- Emit event-lag metrics.
- Trace cross-service calls.
- Alert on default invariant violations.
- Alert on repeated reconciliation failures.
- Document recovery actions.

## Unit Tests

- Test creation, code generation, collisions, profile, address, contact, and working-hours validation.
- Test configuration, manager eligibility, lifecycle, defaults, branch limits, permissions, and errors.
- Test idempotency and optimistic concurrency.

## Persistence Tests

- Test tenant queries, unique codes, one default, configuration consistency, indexes, and retained branches.
- Test concurrent creation, concurrent default changes, and version conflicts.

## API Tests

- Test every endpoint for success, validation, authentication, authorization, tenant, branch, and not-found cases.
- Test transitions, conflicts, idempotency, dependency failures, pagination, filtering, sorting, and stable errors.

## Integration Tests

- Test Authentication context, tenant validation, tenant status, branch limits, and configuration initialization.
- Test manager validation, branch selection, outbox, audit, notification submission, and reconciliation.

## Security Tests

- Test tenant and branch isolation, identifier tampering, RBAC, escalation, and mass assignment.
- Test NoSQL injection, unsafe queries, stored XSS, rate limits, leakage, and concurrency races.

## End-to-End Tests

- Test first and additional branch creation, configuration initialization, default designation, and branch limits.
- Test profile, contact, address, hours, configuration, manager, and accessible branch selection.
- Test activation, suspension, reactivation, deactivation, invalid transitions, isolation, and history.

## Quality Gates

- Run formatting, linting, type checking, builds, root checks, and every required test category.
- Do not weaken rules, skip required checks, or misreport failed or unavailable validation.

## Documentation Requirements

- Document Branch architecture.
- Document service ownership.
- Document lifecycle transitions.
- Document branch context.
- Document tenant isolation.
- Document branch isolation.
- Document default-branch rules.
- Document branch-code generation.
- Document manager assignment.
- Document configuration inheritance.
- Document collections.
- Document indexes.
- Document APIs.
- Document errors.
- Document events.
- Document jobs.
- Document RBAC.
- Document security.
- Document performance results.
- Document frontend workflows.
- Document operator recovery.
- Record ADRs.
- Update the completion report.
- Describe implemented behavior only.
- Use repository-relative paths.
- Include no secrets.

## Implementation Sequence

1. Confirm Phase 11 scope.
2. Inspect Git status.
3. Inspect existing Branch work.
4. Read mandatory sources.
5. Verify dependencies.
6. Confirm service ownership.
7. Define lifecycle.
8. Define permissions.
9. Define branch context.
10. Define collections and indexes.
11. Define APIs.
12. Define events and jobs.
13. Implement domain rules.
14. Implement persistence.
15. Implement branch creation.
16. Implement configuration initialization.
17. Implement profile management.
18. Implement contact and address.
19. Implement working hours.
20. Implement manager assignment.
21. Implement default-branch management.
22. Implement lifecycle commands.
23. Implement security and RBAC.
24. Implement audit and events.
25. Implement approved jobs.
26. Implement approved Flutter workflows.
27. Implement all tests.
28. Run quality gates.
29. Review scope and security.
30. Update documentation.
31. Update the completion report.
32. Stop without starting another phase.

## Deliverables

### Backend

- Branch owning module or service.
- Branch lifecycle.
- Branch validation.
- Branch-code generation.
- Profile management.
- Address management.
- Contact management.
- Working-hours management.
- Manager assignment.
- Default-branch management.
- Configuration management.
- Tenant and RBAC enforcement.
- Complete REST APIs.
- Domain events.
- Required background jobs.
- Observability and recovery.

### MongoDB

- `branches`.
- `branchConfigurations`.
- Required tenant-safe indexes.
- Required uniqueness rules.
- Default-branch invariant.
- Concurrency metadata.
- Persistence tests.

### Frontend

- Branch list.
- Branch registration.
- Branch details.
- Branch editing workflows.
- Manager workflow.
- Default-branch workflow.
- Lifecycle workflows.
- Branch selection when approved.
- Accessible error and loading states.

### Documentation

- Architecture guide.
- Collection guide.
- API guide.
- Security guide.
- RBAC guide.
- Event and job guide.
- Operator guide.
- ADRs.
- Phase completion report.

## Acceptance Criteria

### Functional

- [ ] Authorized users can create branches.
- [ ] Branch limits are enforced.
- [ ] Branch codes are tenant-unique.
- [ ] Branch profiles can be updated.
- [ ] Addresses can be updated.
- [ ] Contacts can be updated.
- [ ] Working hours can be updated.
- [ ] Configurations initialize automatically.
- [ ] Configuration overrides follow tenant policy.
- [ ] Eligible managers can be assigned.
- [ ] Lifecycle transitions follow documented rules.
- [ ] Default-branch invariants are preserved.
- [ ] Historical branches are retained.

### API

- [ ] Every approved endpoint is implemented.
- [ ] Every endpoint is versioned.
- [ ] Every endpoint is validated.
- [ ] Every endpoint is authorized.
- [ ] Every endpoint is documented.
- [ ] Lists use bounded pagination.
- [ ] Updates enforce concurrency.
- [ ] High-impact commands enforce idempotency.
- [ ] Stable errors are returned.

### Security

- [ ] Tenant ownership is enforced.
- [ ] Branch access is enforced.
- [ ] Cross-tenant access is prevented.
- [ ] Unauthorized cross-branch access is prevented.
- [ ] Manager assignment cannot cross tenants.
- [ ] Branch selection validates access.
- [ ] Security tests pass.
- [ ] Sensitive data is redacted.

### Data

- [ ] `branches` is authoritative for branch identity.
- [ ] `branchConfigurations` is authoritative for overrides.
- [ ] Every configuration matches its branch tenant.
- [ ] Required indexes support queries.
- [ ] Concurrent creation preserves branch limits.
- [ ] Concurrent default changes preserve one default.

### Integration

- [ ] Authentication supplies trusted context.
- [ ] Multi-Tenancy supplies ownership and limits.
- [ ] User Management validates managers.
- [ ] Audit evidence exists.
- [ ] Events use the approved reliable pattern.
- [ ] Downstream contracts are documented.
- [ ] Downstream modules are not implemented.

### Frontend

- [ ] Approved Branch workflows are complete.
- [ ] Only accessible branches are selectable.
- [ ] Branch switching clears stale state.
- [ ] Accessibility requirements pass.
- [ ] Error and loading states are handled.
- [ ] Backend authorization remains authoritative.

### Quality

- [ ] Formatting passes.
- [ ] Linting passes.
- [ ] Type checking passes.
- [ ] Required tests pass.
- [ ] Security checks pass.
- [ ] Builds pass.
- [ ] Documentation matches behavior.
- [ ] ADRs record material decisions.
- [ ] No placeholders remain.
- [ ] No secrets remain.
- [ ] No out-of-scope work remains.

## Completion Instructions

1. Review the final diff.
2. Confirm Branch-only scope.
3. Map acceptance criteria to evidence.
4. Run all required checks.
5. Record exact commands and outcomes.
6. Report failed or unavailable checks honestly.
7. List every created file.
8. List every modified file.
9. Record decisions and assumptions.
10. Record migrations and index changes.
11. Record security and performance evidence.
12. Record limitations and pending work.
13. Update `ERP-PLANNING/phase-completions/PHASE_11_BRANCH_MANAGEMENT_COMPLETION.md`.
14. Confirm no downstream module was implemented.
15. Stop execution.

Do not start another phase.
