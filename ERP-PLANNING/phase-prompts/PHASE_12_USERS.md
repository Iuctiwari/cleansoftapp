# PHASE 12 — USER MANAGEMENT IMPLEMENTATION PROMPT

## Phase Information

- Phase Number: 12.
- Phase Name: User Management.
- Module: Users, employee profiles, access assignments, and invitations.
- Status: Implementation prompt.
- Completion Report: `ERP-PLANNING/phase-completions/PHASE_12_USER_MANAGEMENT_COMPLETION.md`.

## Role

- Act as a Senior Enterprise Software Architect and Lead Full Stack Engineer.
- Implement a secure, scalable, production-ready User Management module.
- Treat the repository as the authoritative source of current project state.
- Preserve unrelated and previously completed work.
- Implement only the work authorized by Phase 12.
- Stop immediately after completing this phase.

## Module Context

- Authentication determines who the user is.
- Multi-Tenancy determines which organization the user belongs to.
- Branch Management determines where the user operates.
- User Management determines what the user can access and perform.
- Every user belongs to exactly one tenant.
- Every user can belong to one or more branches.
- Every primary branch must be one of the assigned branches.
- Every role and permission assignment must remain tenant-safe.
- Downstream modules consume user identity and authorization context.

## Objective

- Implement user registration, employee profiles, self-profile management, and lifecycle.
- Implement roles, permissions, branches, departments, designations, and authorization context.
- Implement secure invitations, password-initialization integration, search, filtering, and auditing.
- Enforce tenant isolation, branch isolation, least privilege, and escalation prevention.
- Deliver APIs, events, jobs, frontend workflows, tests, documentation, and completion evidence.

## Business Purpose

- Allow tenant administrators to create and manage employees and system users.
- Assign each user an approved role and effective permissions.
- Assign each user to one or more authorized branches.
- Restrict every user to required data and operations.
- Support controlled invitation and account activation.
- Support auditable user and access changes.
- Provide reliable authorization context to every ERP module.

## Mandatory Reading

- Read all authoritative product, business, target-user, feature, architecture, technology, service, module, database, domain, API, event, tenancy, RBAC, security, coding, naming, and directory documents under `ERP-PLANNING/`.
- Read the root, docs, apps, packages, and every touched-directory README.
- Read every README in directories touched by this phase.
- Read Authentication, Multi-Tenancy, and Branch Management prompts.
- Read their corresponding completion reports.
- Read applicable Architecture Decision Records.
- Read existing authentication, authorization, tenant, branch, event, and test contracts.
- Inspect the repository tree.
- Inspect Git status.
- Inspect existing User and RBAC work.

## Dependencies

### Authentication

- Verify authenticated identity.
- Verify credential and session ownership.
- Verify account activation support.
- Verify password-initialization or reset contracts.
- Verify session revocation support.
- Verify trusted tenant and user claims.

### Multi-Tenancy

- Verify tenant identity.
- Verify tenant lifecycle status.
- Verify user-count entitlements.
- Verify tenant ownership validation.
- Verify tenant settings and defaults.
- Verify tenant isolation.

### Branch Management

- Verify branch identity.
- Verify branch lifecycle status.
- Verify branch ownership.
- Verify branch-context validation.
- Verify default-branch behavior.
- Verify branch events.

### Platform

- Verify MongoDB connectivity.
- Verify API versioning.
- Verify common validation and errors.
- Verify structured logging.
- Verify health and readiness behavior.
- Verify event and job infrastructure.
- Verify testing and build commands.

### Dependency Rules

- Verify completion reports against repository evidence.
- Run critical dependency tests before implementation.
- Repair only minimal safe dependency defects.
- Document every dependency repair.
- Do not duplicate Authentication or Branch functionality.
- Escalate missing security or ownership decisions.

## Scope

- User registration, employee profiles, self-profile updates, and server-generated employee codes.
- Role, permission, approved override, branch, primary-branch, department, and designation assignments.
- User activation, suspension, reactivation, deactivation, and retained history.
- Invitation creation, resend, cancellation, acceptance, and password-initialization integration.
- Search, filtering, sorting, authorization context, auditing, events, and required jobs.
- Approved Flutter workflows, testing, documentation, and completion evidence.

## Out of Scope

- Authentication credentials, password hashing, sessions, and token ownership.
- Tenant, Branch, Customer, Service, Order, Payment, Expense, Report, and Dashboard implementation.
- Payroll, attendance, scheduling, recruitment, performance reviews, and full HR management.
- Notification delivery infrastructure and file-storage implementation.
- Physical deletion, cross-tenant transfer, and unapproved custom role systems.

## Architecture Requirements

- Use the approved User owning service or module.
- Use `apps/user-service/` when supported by current architecture.
- Do not create a competing user service.
- Keep Authentication credential ownership separate.
- Keep controllers thin.
- Keep user invariants in domain or application services.
- Keep persistence behind repositories.
- Keep shared packages domain-neutral.
- Do not access another service's private collections.
- Use versioned API contracts.
- Use versioned event contracts.
- Use versioned job contracts.
- Use optimistic concurrency.
- Use idempotency for retryable commands.
- Use outbox and inbox patterns.
- Record material decisions in ADRs.

## Data Ownership

- User Management owns employee identity and profile.
- User Management owns employee code.
- User Management owns department and designation references or approved values.
- User Management owns role assignments.
- User Management owns permission assignments.
- User Management owns branch assignments.
- User Management owns invitation records.
- Authentication owns credentials.
- Authentication owns passwords.
- Authentication owns sessions.
- Tenant Management owns tenant identity and entitlements.
- Branch Management owns branch identity and lifecycle.
- RBAC policy owns canonical permission definitions.
- Notification Service owns delivery.
- Audit Service owns audit records.
- File Storage owns profile-photo files when available.

## User Lifecycle

- Support `INVITED` or approved equivalent.
- Support `PENDING_ACTIVATION`.
- Support `ACTIVE`.
- Support `SUSPENDED`.
- Support `INACTIVE` or `DEACTIVATED`.
- Define every allowed transition.
- Reject undocumented transitions.
- Require permission for transitions.
- Require a reason for suspension.
- Require a reason for deactivation.
- Record actor and timestamp.
- Record correlation context.
- Publish one event per committed transition.
- Revoke or restrict sessions after suspension or deactivation.
- Preserve historical user references.
- Prevent general updates from changing status.

## User Registration

- Authenticate the administrator.
- Resolve trusted tenant context.
- Authorize user creation.
- Verify tenant status.
- Verify user-count entitlement.
- Validate employee details.
- Normalize email and mobile number.
- Generate employee code on the server.
- Prevent duplicate creation under retries.
- Validate role assignment.
- Validate branch assignments.
- Validate primary branch.
- Create the user profile.
- Create initial permission assignment.
- Create an invitation when required.
- Submit password initialization to Authentication.
- Record audit context.
- Publish user-created event.

## Employee Profile

- Require first name.
- Require last name.
- Derive full name consistently.
- Support optional preferred name when approved.
- Support email.
- Support mobile number.
- Support profile-photo reference.
- Support optional date of birth.
- Support optional gender using approved values.
- Support department.
- Support designation.
- Support employee start date when approved.
- Support non-sensitive notes only when approved.
- Keep tenant ownership immutable.
- Keep employee code immutable after creation.
- Minimize personal information.

## Self-Profile

- Allow users to view their own profile.
- Allow approved self-service field updates.
- Prevent self-service role changes.
- Prevent self-service permission changes.
- Prevent self-service branch changes.
- Prevent self-service status changes.
- Prevent self-service employee-code changes.
- Require re-verification for sensitive identity changes when established.

## Role Assignment

- Reference an approved role.
- Verify role belongs to the same tenant or approved system scope.
- Prevent assignment above the administrator's authority.
- Prevent self-escalation.
- Prevent protected-role assignment without protected authority.
- Record old and new role.
- Record assigning actor.
- Publish role-assigned event.
- Refresh effective authorization.

## Permission Assignment

- Use canonical permission identifiers.
- Validate every permission.
- Apply least privilege.
- Support role-derived permissions.
- Support explicit user overrides only when approved.
- Distinguish grants from denials when supported.
- Support effective date.
- Support optional expiry date.
- Prevent permission escalation.
- Prevent users from granting permissions they do not control.
- Record changes and actor.
- Refresh permission cache.
- Publish permissions-updated event.

## Branch Assignment

- Assign one or more branches.
- Verify every branch belongs to the tenant.
- Verify every branch is eligible.
- Require primary branch to be assigned.
- Support primary branch changes.
- Prevent unauthorized cross-branch assignment.
- Remove inaccessible current branch context after assignment changes.
- Preserve historical actor references.
- Publish branches-assigned event.
- Refresh authorization context.

## Department and Designation

- Support approved department values or references.
- Support approved designation values or references.
- Validate tenant ownership for referenced records.
- Prevent arbitrary unbounded values when catalogs exist.
- Do not implement a full HR taxonomy without approval.
- Audit department and designation changes.

## User Invitations

- Create cryptographically secure invitation tokens.
- Store only a token hash.
- Never store a plaintext invitation token.
- Use single-use invitations.
- Set a bounded expiry.
- Bind the invitation to tenant, user, and intended email.
- Prevent acceptance after expiry.
- Prevent acceptance after cancellation.
- Prevent invitation reuse.
- Support safe resend with token rotation.
- Rate-limit invitation creation and resend.
- Submit delivery through Notification Service.
- Do not claim delivery when only submission succeeded.
- Record acceptance through Authentication integration.

## Password Initialization

- Delegate credential creation to Authentication.
- Never store password values in User Management.
- Never log password values.
- Use one-time initialization or invitation contracts.
- Require secure expiry.
- Revoke initialization tokens after use.
- Prevent administrators from learning user passwords.

## User Search and Filtering

- Use bounded pagination.
- Search only allowlisted normalized fields.
- Support employee-code search.
- Support safe name search.
- Support safe email search when authorized.
- Filter by status.
- Filter by role.
- Filter by branch.
- Filter by department.
- Filter by designation.
- Sort only by allowlisted fields.
- Apply tenant and branch visibility before counts.
- Avoid unsafe regular expressions.
- Return summary projections only.

## MongoDB Collections

### `users`

- Store one authoritative profile per tenant user.
- Store opaque user identifier.
- Store tenant identifier.
- Store employee code.
- Store first name.
- Store last name.
- Store derived full name.
- Store normalized email.
- Store normalized mobile number.
- Store profile-photo reference.
- Store optional date of birth.
- Store optional gender.
- Store department.
- Store designation.
- Store role identifier or assignment reference.
- Store assigned branch identifiers.
- Store primary branch identifier.
- Store lifecycle status.
- Store status reason and timestamp.
- Store last-login projection only when supplied by Authentication.
- Store created-by and updated-by identifiers.
- Store created and updated timestamps.
- Store optimistic-concurrency version.

### `users` Invariants

- Require immutable tenant identifier.
- Require tenant-unique employee code.
- Require tenant-unique normalized email when policy requires it.
- Require first and last name.
- Require valid status.
- Require every assigned branch to belong to tenant.
- Require primary branch to appear in assigned branches.
- Require role to be valid for tenant.
- Keep credential fields out of this collection.
- Prevent physical deletion after historical use.

### `users` Indexes

- Unique index on tenant and employee code.
- Unique or policy-approved index on tenant and normalized email.
- Lookup index on tenant and user identifier.
- List index on tenant and status.
- Role index on tenant and role identifier.
- Branch index on tenant and assigned branches.
- Department index on tenant and department.
- Search index on tenant and normalized name.
- Pagination index on tenant and created timestamp.
- Pagination index on tenant and updated timestamp.

### `userPermissions`

- Store one current assignment document per user unless approved otherwise.
- Store opaque assignment identifier.
- Store tenant identifier.
- Store user identifier.
- Store role identifier.
- Store canonical permission list.
- Store allowed modules when part of approved policy.
- Store allowed actions when part of approved policy.
- Store explicit grants when approved.
- Store explicit denials when approved.
- Store effective date.
- Store optional expiry date.
- Store assignment version.
- Store created-by and updated-by identifiers.
- Store created and updated timestamps.
- Store optimistic-concurrency version.

### `userPermissions` Invariants

- Match assignment tenant to user tenant.
- Validate role and permission identifiers.
- Prevent unknown modules and actions.
- Prevent invalid effective periods.
- Prevent expired permissions from remaining effective.
- Prevent unauthorized privilege escalation.
- Keep one authoritative effective assignment model.

### `userPermissions` Indexes

- Unique index on tenant and user identifier.
- Lookup index on tenant, user, and effective date.
- Expiry index on tenant and expiry date.
- Role index on tenant and role identifier.

### `userInvitations`

- Store opaque invitation identifier.
- Store tenant identifier.
- Store user identifier.
- Store intended normalized email.
- Store invitation-token hash.
- Store invitation status.
- Store expiry date.
- Store sent timestamp.
- Store resend count.
- Store accepted timestamp.
- Store cancelled timestamp.
- Store created-by identifier.
- Store created timestamp.
- Store optimistic-concurrency version.

### `userInvitations` Invariants

- Match invitation tenant to user tenant.
- Store token hash only.
- Make active token hash unique.
- Allow one effective pending invitation per user.
- Reject expired invitations.
- Reject cancelled invitations.
- Reject consumed invitations.
- Rotate tokens on resend.
- Apply automatic expiry cleanup only to safe invitation records.

### `userInvitations` Indexes

- Unique index on active token hash.
- Lookup index on tenant and user identifier.
- Status index on tenant and invitation status.
- Expiry TTL or cleanup index where safe.
- Email lookup index on tenant and normalized email.

## Collection Boundaries

- Use only `users`, `userPermissions`, and `userInvitations` as User domain collections.
- Reuse established role and permission catalogs.
- Do not duplicate Authentication credentials.
- Do not duplicate Branch records.
- Use shared outbox, inbox, audit, and idempotency collections only through platform patterns.

## API Standards

- Follow the approved API version prefix.
- Require authentication except invitation acceptance where approved.
- Resolve tenant from trusted context.
- Apply RBAC to every administrative endpoint.
- Apply branch visibility before returning data.
- Validate path, query, and body values.
- Use stable machine-readable errors.
- Use bounded pagination.
- Use allowlisted search, filters, and sorting.
- Use expected versions for updates.
- Use idempotency for high-impact commands.
- Audit access-control mutations.
- Hide cross-tenant resource existence.
- Register static routes before `:userId` routes.

## User APIs

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/users` | Create a tenant user with profile, assignments, and optional invitation. |
| `GET` | `/users` | List visible users with pagination, search, filters, and sorting. |
| `GET` | `/users/me` | Return the authenticated user's profile and effective access summary. |
| `PATCH` | `/users/me` | Update only approved self-service profile fields. |
| `GET` | `/users/:userId` | Return authorized user details, version, assignments, and allowed actions. |
| `PUT/PATCH` | `/users/:userId` | Update mutable employee profile fields with expected version. |
| `PATCH` | `/users/:userId/activate` | Activate an eligible user with version and idempotency checks. |
| `PATCH` | `/users/:userId/suspend` | Suspend a user with expected version, idempotency, and reason. |
| `PATCH` | `/users/:userId/reactivate` | Reactivate a suspended user when policy permits. |
| `PATCH` | `/users/:userId/deactivate` | Deactivate a user while preserving historical references. |
| `GET` | `/users/:userId/role` | Return the current authorized role summary. |
| `PATCH` | `/users/:userId/role` | Assign or replace an authorized role and refresh access. |
| `GET` | `/users/:userId/permissions` | Return role-derived, direct, and effective permissions when authorized. |
| `PATCH` | `/users/:userId/permissions` | Replace approved user permission overrides with expected version. |
| `POST` | `/users/:userId/permissions/reset` | Remove direct overrides and restore role-derived permissions. |
| `GET` | `/users/:userId/branches` | Return authorized branch assignments and primary branch. |
| `PATCH` | `/users/:userId/branches` | Replace validated branch assignments and primary branch. |
| `PATCH` | `/users/:userId/primary-branch` | Change primary branch to an assigned eligible branch. |
| `PATCH` | `/users/:userId/department` | Update approved department assignment. |
| `PATCH` | `/users/:userId/designation` | Update approved designation assignment. |
| `POST` | `/users/invite` | Create a user and single-use invitation through an idempotent command. |
| `GET` | `/users/:userId/invitation` | Return safe invitation status without exposing the token. |
| `POST` | `/users/:userId/invitation/resend` | Rotate and resend a pending invitation with rate limiting. |
| `DELETE` | `/users/:userId/invitation` | Cancel a pending invitation. |
| `POST` | `/user-invitations/accept` | Validate a one-time invitation and delegate credential activation. |

## API Rules

- Choose `PUT` or `PATCH` semantics consistently.
- Require expected versions on assignment and status mutations.
- Require idempotency for create, invite, and lifecycle commands.
- Return effective permissions without exposing internal policy data.
- Never return invitation tokens or token hashes.
- Never return password or credential fields.
- Keep invitation acceptance responses resistant to account enumeration.
- Delegate session issuance to Authentication.

## API Errors

- Cover validation, authentication, authorization, not-found, tenant, user-status, and lifecycle failures.
- Cover user limits, duplicate identifiers, invalid roles, permissions, branches, and primary branches.
- Cover privilege escalation, invalid or expired invitations, concurrency, idempotency, and dependencies.

## Validation Rules

- Require first name.
- Require last name.
- Trim and bound names.
- Derive full name consistently.
- Generate employee code on the server.
- Make employee code tenant-unique.
- Normalize email.
- Enforce tenant email uniqueness when required.
- Validate mobile number.
- Require an existing tenant.
- Enforce tenant user limits.
- Validate every assigned branch.
- Require all assigned branches in the same tenant.
- Require primary branch among assigned branches.
- Validate role.
- Validate every permission.
- Validate department.
- Validate designation.
- Validate lifecycle status.
- Validate invitation expiry.
- Reject stale versions.
- Reject unsupported fields.

## RBAC Requirements

- Define permissions for user view, create, update, activate, suspend, and deactivate operations.
- Define permissions for role view or assignment and permission view or assignment.
- Define permissions for branch, department, designation, and self-profile updates.
- Define permissions for invitation creation, resend, cancellation, and status viewing.
- Use approved permission naming.
- Apply deny-by-default authorization.
- Prevent actors from granting authority they do not possess.
- Keep backend authorization authoritative.

## Privilege-Escalation Rules

- Prevent users from changing their own role.
- Prevent users from changing their own permissions.
- Prevent users from adding themselves to unauthorized branches.
- Prevent assignment of a protected role without protected authority.
- Prevent assignment above the actor's role ceiling.
- Prevent direct permission grants above the actor's delegation scope.
- Prevent stale authorization caches after changes.
- Revoke affected sessions after critical access reductions.
- Audit every privileged assignment.

## Security Requirements

- Enforce tenant ownership, branch visibility, RBAC, and deny-by-default access.
- Prevent cross-tenant access, cross-branch access, identifier tampering, and privilege escalation.
- Prevent mass assignment, NoSQL injection, unsafe queries, stored XSS, and account enumeration.
- Minimize personal data, redact logs, and rate-limit invitations and sensitive mutations.
- Hash invitation tokens, compare them safely, and never store credentials or plaintext tokens.
- Audit every privileged profile, assignment, invitation, and lifecycle change.

## Integration Requirements

- Authentication: own credentials, activation, password initialization, sessions, revocation, and last-login facts.
- Multi-Tenancy: validate tenant identity, status, settings, and user-count entitlements.
- Branch Management: validate branches, branch status, and primary or assigned branch context.
- Customer Management: consume user identity and permissions without implementing customers.
- Service Management: consume user identity and permissions without implementing services.
- Order Management: consume actor and authorization context without implementing orders.
- Payment Management: consume privileged actor context without implementing payments.
- Expense Management: consume actor and branch context without implementing expenses.
- Reports and Dashboard: consume filtered user context without implementing reporting.
- Notification Service: deliver invitations and reminders without owning invitation state.
- Audit Service: record profile, role, permission, branch, status, and invitation changes.
- Settings: provide approved tenant policy without allowing weaker user overrides.

## Domain Events

- Publish user-created event.
- Publish user-profile-updated event.
- Publish user-role-assigned event.
- Publish user-permissions-updated event.
- Publish user-branches-assigned event.
- Publish user-primary-branch-changed event.
- Publish user-department-changed event.
- Publish user-designation-changed event.
- Publish user-invited event.
- Publish invitation-accepted event.
- Publish invitation-cancelled event.
- Publish user-activated event.
- Publish user-suspended event.
- Publish user-reactivated event.
- Publish user-deactivated event.
- Use the established event envelope.
- Include tenant, user, event, version, time, correlation, and causation data.
- Exclude credentials, plaintext tokens, and unnecessary personal data.
- Publish through the outbox pattern.
- Require idempotent consumers.

## Background Jobs

- Invitation delivery: submit pending invitations through Notification Service.
- Invitation reminders: notify eligible pending users without creating duplicate sends.
- Invitation expiry: mark expired invitations and prevent later acceptance.
- Permission expiry: remove expired direct permissions and refresh effective access.
- Permission cache refresh: invalidate authorization state after assignment changes.
- Role synchronization: reconcile approved role changes without inventing permissions.
- Inactive user review: report candidates without deleting historical users.
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
- Use outbox and inbox.
- Support graceful shutdown.
- Support health and readiness checks.
- Avoid direct cross-service database access.

## Flutter Requirements

- Build a user list.
- Build user search and filters.
- Build user registration.
- Build employee profile details.
- Build employee profile editing.
- Build self-profile editing.
- Build role assignment.
- Build permission assignment.
- Build branch assignment.
- Build primary-branch selection.
- Build department and designation updates.
- Build invitation creation and status.
- Build invitation resend and cancellation.
- Build lifecycle actions.
- Show effective access summaries.
- Show loading and empty states.
- Show validation and forbidden states.
- Show conflicts and stale data.
- Show retryable and terminal errors.
- Clear authorization caches after access changes.
- Follow Material 3.
- Follow accessibility standards.
- Keep backend authorization authoritative.

## Performance Requirements

- Paginate every user list.
- Bound page size.
- Use tenant-scoped indexes.
- Use projections for list responses.
- Avoid unbounded regular expressions.
- Bound filters and sorting.
- Cache permissions only with safe invalidation.
- Measure user creation.
- Measure user lookup.
- Measure user search.
- Measure branch-filtered listing.
- Measure permission resolution.
- Measure invitation lookup.
- Test concurrent user creation.
- Test high-volume permission resolution.
- Record dataset, environment, and actual results.

## Reliability Requirements

- Prevent duplicate users under retries.
- Prevent duplicate active invitations.
- Preserve role and permission consistency.
- Recover failed event publication.
- Revoke stale authorization after access reductions.
- Make jobs idempotent.
- Report dependency failures honestly.
- Avoid inconsistent success responses.
- Support graceful recovery.

## Observability Requirements

- Log user operations safely.
- Emit creation metrics.
- Emit invitation metrics.
- Emit lifecycle metrics.
- Emit permission-resolution metrics.
- Emit authorization-denial metrics.
- Emit dependency-failure metrics.
- Emit job-retry metrics.
- Emit event-lag metrics.
- Trace cross-service calls.
- Alert on repeated permission-refresh failures.
- Alert on invitation backlog.
- Document recovery actions.

## Unit Tests

- Test creation, employee-code generation, profile validation, and duplicate detection.
- Test role, permission, branch, primary-branch, department, and designation assignments.
- Test lifecycle, invitations, idempotency, concurrency, and privilege-escalation rules.

## Persistence Tests

- Test tenant queries, unique codes, email policy, assignments, invitations, indexes, and retained users.
- Test concurrent creation, invitation rotation, permission expiry, and version conflicts.

## API Tests

- Test every endpoint for success, validation, authentication, authorization, tenant, branch, and not-found cases.
- Test lifecycle, assignments, invitations, conflicts, idempotency, dependencies, pagination, filters, and errors.

## Integration Tests

- Test Authentication, Multi-Tenancy, Branch Management, Notification, Audit, outbox, and permission-cache integration.
- Test invitation acceptance, credential initialization, session revocation, and authorization refresh.

## Security Tests

- Test tenant and branch isolation, identifier tampering, RBAC, escalation, self-escalation, and mass assignment.
- Test injection, unsafe queries, XSS, token theft, token reuse, enumeration, rate limits, and concurrency races.

## Performance Tests

- Test user creation.
- Test user search and filtering.
- Test bulk user retrieval.
- Test permission resolution.
- Test branch assignment lookup.
- Test invitation processing.
- Test multi-user scalability.
- Record measured results.

## End-to-End Tests

- Create a user with role and branches.
- Generate employee code.
- Create and deliver an invitation.
- Accept the invitation through Authentication.
- Activate the account.
- Update the employee profile.
- Change role and permissions.
- Change branch assignments and primary branch.
- Suspend and reactivate the user.
- Deactivate the user.
- Prevent unauthorized access after access reduction.
- Reject cross-tenant and cross-branch access.
- Preserve historical user references.

## Quality Gates

- Run formatting, linting, type checking, builds, root checks, and every required test category.
- Do not weaken rules, skip required checks, or misreport failed or unavailable validation.

## Documentation Requirements

- Document User architecture.
- Document service ownership.
- Document lifecycle transitions.
- Document tenant and branch isolation.
- Document role and permission resolution.
- Document privilege-escalation controls.
- Document branch assignments.
- Document invitation security.
- Document collections and indexes.
- Document APIs and errors.
- Document events and jobs.
- Document Authentication integration.
- Document security tests.
- Document performance results.
- Document frontend workflows.
- Document operator recovery.
- Record ADRs.
- Update the completion report.
- Describe implemented behavior only.
- Use repository-relative paths.
- Include no secrets or plaintext tokens.

## Implementation Sequence

1. Confirm Phase 12 scope.
2. Inspect Git status.
3. Inspect existing User and RBAC work.
4. Read mandatory sources.
5. Verify dependencies.
6. Confirm service ownership.
7. Define lifecycle.
8. Define role and permission rules.
9. Define branch-assignment rules.
10. Define invitation security.
11. Define collections and indexes.
12. Define APIs, events, and jobs.
13. Implement domain rules.
14. Implement persistence.
15. Implement user creation.
16. Implement profiles.
17. Implement roles and permissions.
18. Implement branch assignments.
19. Implement department and designation.
20. Implement invitations.
21. Implement lifecycle commands.
22. Implement security and RBAC.
23. Implement audit and events.
24. Implement approved jobs.
25. Implement approved Flutter workflows.
26. Implement all tests.
27. Run quality gates.
28. Review scope and security.
29. Update documentation.
30. Update the completion report.
31. Stop without starting another phase.

## Deliverables

### Backend

- User owning module or service.
- Employee profile management.
- User lifecycle.
- Employee-code generation.
- Role and permission assignments.
- Branch and primary-branch assignments.
- Department and designation assignments.
- Invitation management.
- Authorization-context resolution.
- Tenant, branch, and RBAC enforcement.
- Complete REST APIs.
- Domain events.
- Required background jobs.
- Observability and recovery.

### MongoDB

- `users`.
- `userPermissions`.
- `userInvitations`.
- Required tenant-safe indexes.
- Required uniqueness rules.
- Concurrency metadata.
- Invitation security.
- Persistence tests.

### Frontend

- User list and registration.
- Profile and self-profile workflows.
- Role and permission workflows.
- Branch-assignment workflows.
- Department and designation workflows.
- Invitation workflows.
- Lifecycle workflows.
- Accessible loading and error states.

### Documentation

- Architecture guide.
- Collection guide.
- API guide.
- RBAC and security guide.
- Invitation guide.
- Event and job guide.
- Operator guide.
- ADRs.
- Phase completion report.

## Acceptance Criteria

### Functional

- [ ] Authorized administrators can create users.
- [ ] Employee codes are tenant-unique.
- [ ] Employee profiles can be managed.
- [ ] Roles can be assigned safely.
- [ ] Permissions can be assigned safely.
- [ ] Branch assignments work correctly.
- [ ] Primary branches remain assigned.
- [ ] Departments and designations can be updated.
- [ ] Invitations are single-use and expire safely.
- [ ] Activation, suspension, reactivation, and deactivation work.
- [ ] Historical user references are retained.

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
- [ ] Branch visibility is enforced.
- [ ] RBAC is enforced.
- [ ] Cross-tenant access is prevented.
- [ ] Unauthorized cross-branch access is prevented.
- [ ] Self-escalation is prevented.
- [ ] Unauthorized role assignment is prevented.
- [ ] Unauthorized permission grants are prevented.
- [ ] Invitation tokens are hashed and single-use.
- [ ] Credentials remain outside User Management.
- [ ] Sensitive data is redacted.
- [ ] Security tests pass.

### Data

- [ ] `users` is authoritative for employee profiles.
- [ ] `userPermissions` is authoritative for user access assignments.
- [ ] `userInvitations` is authoritative for invitation state.
- [ ] Every assignment matches its user tenant.
- [ ] Every branch assignment belongs to the tenant.
- [ ] Required indexes support queries.
- [ ] Concurrent creation preserves user limits and uniqueness.

### Integration

- [ ] Authentication owns credentials and sessions.
- [ ] Multi-Tenancy supplies tenant status and limits.
- [ ] Branch Management validates assigned branches.
- [ ] Notification delivery uses the approved integration.
- [ ] Audit evidence exists for material changes.
- [ ] Events use the approved reliable pattern.
- [ ] Downstream modules are not implemented.

### Frontend

- [ ] Approved User workflows are complete.
- [ ] Only authorized access controls are editable.
- [ ] Access changes refresh stale authorization state.
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
- [ ] No secrets or plaintext tokens remain.
- [ ] No out-of-scope work remains.

## Completion Instructions

1. Review the final diff.
2. Confirm User-only scope.
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
13. Update `ERP-PLANNING/phase-completions/PHASE_12_USER_MANAGEMENT_COMPLETION.md`.
14. Confirm no downstream module was implemented.
15. Stop execution.

Do not start another phase.
