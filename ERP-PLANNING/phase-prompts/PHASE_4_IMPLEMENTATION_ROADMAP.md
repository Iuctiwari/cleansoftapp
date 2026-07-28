# PHASE 04 – IMPLEMENTATION ROADMAP

# Nexoraa CleanSoft ERP – Delivery Sequence and Release Roadmap

## Document Control

| Field | Value |
|---|---|
| Document type | Actual implementation roadmap |
| Product | Nexoraa CleanSoft ERP |
| Phase | 04 – Implementation Roadmap |
| Version | 1.0 |
| Date | 27 July 2026 |
| Status | Ready for roadmap audit |
| Planning baseline | Phase 01 Software Idea |
| Architecture baseline | Phase 02 System Planning |
| Audit baseline | Phase 03 Plan Audit |
| Implementation state | No product implementation is performed here |

# Implementation Roadmap

## 1. Roadmap Overview

The roadmap defines how Nexoraa CleanSoft moves from planning to production. It organizes work into controlled phases. It connects business goals, architecture, implementation, testing, deployment, and release.

### Purpose

- Define one ERP delivery direction; Convert the system plan into phases; Connect business goals to delivery.
- Make dependencies, gates, risks, and ownership visible; Block modules until foundations are ready.

### Project Objectives

- Deliver a secure multi-tenant ERP; Support tenant-wide and branch-scoped operations.
- Complete the customer-to-delivery flow; Maintain accurate operational and financial records.
- Provide web and mobile experiences; Provide reports, dashboards, search, settings, and audit.
- Reach production through verified quality and release gates.

### Development Strategy

- Use phase-by-phase implementation; Complete planning controls before technical work.
- Build shared platform capabilities before business modules; Implement modules in dependency order.
- Allow parallel work only with stable dependencies; Apply security and isolation in every phase.
- Apply audit and testing in every phase; Finish with factual completion evidence.

### Implementation Approach

- Give each module one owner; Keep each phase focused on one objective.
- Define entry criteria and deliverables before implementation.
- Define exit criteria before approval; Use canonical architecture and planning sources.
- Reuse technical foundations without sharing domain logic; Stop work when upstream gates fail.

### Roadmap Outcomes

- One Phase 00–25 sequence; Five controlled delivery waves.
- Clear dependencies; Required quality, security, data, and release gates.
- Secure tenant onboarding; Complete multi-branch operational and financial capability.
- Reporting, search, audit, production deployment, and operational readiness.

### Roadmap Governance

The Phase 00–25 names in this document are canonical. Older conflicting phase descriptions are superseded. Completion reports must align with this catalogue. No implementation phase starts before its entry gate passes.

## 2. Project Phases

The project phases group the detailed Phase 00–25 sequence into business-friendly delivery stages.

### Foundation Setup

Purpose:

- Prepare the repository and technical platform.
- Standardize backend, Flutter, data, queue, logging, and configuration foundations.

Includes:

- Repository foundation.
- Planning and architecture approval.
- Platform setup.
- Shared technical packages.
- Local development services.
- CI quality foundations.

Completion:

- All foundations build.
- Local setup is repeatable.
- Security defaults are active.
- Planning gates are approved.

### Authentication

Purpose:

- Establish trusted identity and session control.

Includes:

- Tenant-user login.
- Platform login.
- Password security.
- Access and refresh sessions.
- Logout and revocation.
- OTP and password reset.
- Lockout and abuse protection.

Completion:

- Session lifecycle passes.
- Token replay is blocked.
- Reset revokes sessions.
- Platform access stays separate.

### Multi-Tenancy

Purpose:

- Create secure tenant identity and isolation.

Includes:

- Tenant onboarding.
- Tenant lifecycle.
- Subscription plans.
- Feature entitlements.
- Business settings foundation.
- Tenant context.
- Tenant-wide storage isolation.

Completion:

- Two-tenant isolation passes.
- Suspended tenants lose business access.
- Entitlements enforce limits.
- Client tenant values are never trusted.

### Branch and User Management

Purpose:

- Establish branch structure and controlled staff access.

Includes:

- Branch lifecycle.
- Branch assignment.
- Staff profiles.
- Invitations.
- Roles.
- Permissions.
- Custom-role entitlement.
- Last-Owner protection.

Completion:

- Branch isolation passes.
- Permission matrix passes.
- Invitation replay fails.
- Privilege escalation is blocked.

### Customer Management

Purpose:

- Create the tenant customer foundation.

Includes:

- Customer profiles.
- Walk-in customers.
- Customer types.
- Contact details.
- Search attributes.
- Order-history projection.
- Payment-history projection.
- Outstanding-balance projection.

Completion:

- Customer isolation passes.
- Walk-in workflow passes.
- Protected aggregates cannot be edited.
- Customer summaries reconcile.

### Service Management

Purpose:

- Create the tenant service and item catalogue.

Includes:

- Services.
- Item categories.
- Pricing types.
- Unit types.
- Base prices.
- Tax defaults.
- Branch availability.
- Business-type defaults.

Completion:

- Catalog isolation passes.
- Default seeding passes.
- Branch availability passes.
- Historical pricing remains protected.

### Order Management

Purpose:

- Implement the main operational workflow.

Includes:

- Order creation.
- Item capture.
- Price snapshots.
- Totals.
- Atomic numbering.
- Status workflow.
- Assignments.
- Cancellation.
- Delivery.
- Proof of delivery.

Completion:

- Pricing calculations pass.
- Numbering concurrency passes.
- Status transitions pass.
- Assignment and delivery security pass.

### Payment Management

Purpose:

- Implement settlement and financial correction.

Includes:

- Advance payments.
- Partial payments.
- Final payments.
- Payment methods.
- Refunds.
- Adjustments.
- Reversals.
- Receipts.
- Order settlement.
- Cash-payment events.

Completion:

- Duplicate payment is safe.
- Split payment reconciles.
- Refund eligibility passes.
- Receipts remain unique and traceable.

### Reports and Dashboard

Purpose:

- Provide trusted business visibility.

Includes:

- Sales reports.
- Payment reports.
- Expense reports.
- Cash-flow reports.
- Order reports.
- Outstanding reports.
- Role-aware dashboard.
- Branch-aware KPIs.
- CSV export.

Completion:

- Report totals match source records.
- Branch filters are secure.
- Dashboard KPIs match reports.
- Large exports run asynchronously.

### Testing and Deployment

Purpose:

- Prove quality and prepare production release.

Includes:

- Full test suite.
- Security hardening.
- Performance validation.
- Recovery validation.
- Staging deployment.
- Production topology.
- Release approval.
- Operational handover.

Completion:

- No blocking defect remains.
- Isolation and financial tests pass.
- Rollback and recovery are proven.
- Production readiness is approved.

### Supporting Module Streams

The following streams run at their planned dependency points:

- Notifications.
- Expenses and cash registers.
- Search.
- Settings.
- Audit.
- File storage.
- Background jobs.
- Observability.

## 3. Phase Dependencies

### Prerequisites for Each Phase

Every phase requires:

- Approved upstream phases.
- Approved module prompt.
- Assigned owner.
- Confirmed scope.
- Approved decisions.
- Ready environment.
- Ready test plan.
- Known risk review.

### Module Dependencies

- Authentication requires platform foundations.
- Tenants require authentication.
- Branches require tenants.
- Users and RBAC require authentication, tenants, and branches.
- Customers require RBAC.
- Services require RBAC.
- Orders require customers, services, users, and branches.
- Payments require orders.
- Expenses require branches, users, and payment events.
- Notifications require domain events and entitlements.
- Reports require stable domain events.
- Dashboard requires report projections.
- Search requires searchable domain events.
- Settings and audit require all critical module integrations.

### Integration Sequence

1. Establish shared contracts.
2. Implement the authoritative producer.
3. Validate the local transaction.
4. Publish the versioned event.
5. Connect idempotent consumers.
6. Add retry and dead-letter handling.
7. Add logs, metrics, and traces.
8. Run contract and failure tests.
9. Verify tenant and branch scope.
10. Record integration evidence.

### Completion Requirements

A phase is complete only when:

- Functional scope passes.
- Non-functional scope passes.
- Security checks pass.
- Isolation checks pass.
- Contract checks pass.
- Documentation is current.
- Completion evidence is factual.
- Limitations are recorded.
- Downstream notes are ready.

## 4. Development Workflow

### Task Planning

- Break phases into traceable tasks.
- Give each task one owner.
- Link tasks to requirements.
- Link tasks to acceptance criteria.
- Record dependencies.
- Record risks.
- Keep tasks small enough for review.
- Avoid mixing unrelated modules.

### Git Workflow

- Use the repository’s approved package manager.
- Start from the approved base branch.
- Pull the latest reviewed changes.
- Create a scoped working branch.
- Commit logical changes.
- Keep commit messages meaningful.
- Never commit secrets.
- Preserve unrelated work.

### Branching Strategy

- Use short-lived feature branches.
- Use phase or module identifiers.
- Keep release branches controlled.
- Protect the production branch.
- Require review before merge.
- Avoid long-running divergence.
- Rebase or merge using team policy.
- Delete merged branches safely.

### Code Review Process

- Confirm scope.
- Confirm architecture alignment.
- Confirm ownership boundaries.
- Confirm tenant isolation.
- Confirm branch isolation.
- Confirm security controls.
- Confirm test coverage.
- Confirm error handling.
- Confirm observability.
- Confirm documentation.
- Confirm no secret or generated junk.

### Documentation Updates

Every implementation change updates:

- Module documentation.
- API contracts.
- Event contracts.
- Data ownership.
- Configuration.
- Environment variables.
- RBAC rules.
- Security controls.
- Test evidence.
- Completion report.

## 5. Milestones and Deliverables

### Phase Milestones

| Milestone | Included phases | Primary outcome |
|---|---|---|
| Planning approved | 00–07 | Approved plan, roadmap, and prompts |
| Secure platform | 08–12 | Platform, authentication, tenants, branches, RBAC |
| Operational MVP | 13–18 | Customers, catalog, orders, payments, notifications, cash |
| Managed ERP | 19–22 | Reports, dashboard, search, settings, audit |
| Production release | 23–25 | Hardening, deployment, and release |

### Expected Deliverables

Each phase delivers:

- Approved functionality.
- Updated contracts.
- Updated documentation.
- Automated tests.
- Security evidence.
- Isolation evidence.
- Operational signals.
- Migration notes.
- Rollback notes.
- Completion report.

### Success Criteria

- Business objective is met.
- Scope is complete.
- Acceptance criteria pass.
- Dependencies remain stable.
- No critical defect remains.
- No unauthorized access is possible.
- Financial values reconcile.
- Performance stays within target.
- Documentation matches behavior.

### Phase Completion Reports

Each report records:

- Phase name.
- Objective.
- Scope completed.
- Files created.
- Files modified.
- Decisions made.
- Tests executed.
- Results.
- Known limitations.
- Pending external actions.
- Next-phase dependencies.

## 6. Testing Strategy

### Unit Testing

- Test calculations.
- Test validation.
- Test lifecycle rules.
- Test permission decisions.
- Test mapping.
- Test retry decisions.
- Test error categories.
- Keep tests deterministic.

### Integration Testing

- Test database behavior.
- Test Redis behavior.
- Test queue behavior.
- Test service contracts.
- Test event delivery.
- Test object storage.
- Test external adapters.
- Test transaction boundaries.

### System Testing

- Test complete business journeys.
- Test tenant isolation.
- Test branch isolation.
- Test RBAC.
- Test concurrency.
- Test idempotency.
- Test resilience.
- Test reports and reconciliation.
- Test web and mobile compatibility.

### User Acceptance Testing

- Use realistic business scenarios.
- Include Owner workflows.
- Include Branch Manager workflows.
- Include Staff workflows.
- Include Cashier workflows.
- Validate terminology.
- Validate usability.
- Validate receipts and reports.
- Record approval and rejected scenarios.

### Testing Exit Gate

- Critical tests pass.
- Regression tests pass.
- No critical defect remains.
- UAT approval is recorded.
- Test evidence is stored.

## 7. Deployment Plan

### Development Environment

- Local services use synthetic data.
- Developers use isolated configuration.
- MongoDB and Redis run locally.
- Flutter clients use local gateway URLs.
- Secrets use safe local placeholders.
- Quality checks run before review.

### Staging Environment

- Staging mirrors production behavior.
- Data is synthetic or sanitized.
- Migrations run before promotion.
- Integrations use staging accounts.
- Load and recovery tests run.
- Business UAT runs.
- Release candidate is verified.

### Production Deployment

- Use immutable artifacts.
- Inject configuration at runtime.
- Run backward-compatible migrations.
- Deploy consumers before producers.
- Use controlled rolling release.
- Verify health after each step.
- Monitor business and technical signals.
- Keep rollback available.

### Release Management

- Assign a release owner.
- Freeze the release candidate.
- Record included changes.
- Record known limitations.
- Obtain product approval.
- Obtain security approval.
- Obtain operations approval.
- Publish release notes.
- Monitor the stabilization window.

## 8. Risk Management

### Potential Risks

- Scope expansion.
- Dependency delay.
- Tenant leakage.
- Branch leakage.
- Financial error.
- Duplicate processing.
- Provider outage.
- Performance failure.
- Data migration failure.
- Release rollback failure.
- Documentation drift.

### Mitigation Strategies

- Enforce phase scope.
- Block work on failed dependencies.
- Run isolation tests.
- Use deterministic finance rules.
- Use idempotency.
- Use retries and dead letters.
- Use projections for heavy reads.
- Test migrations.
- Prove rollback.
- Update documents every phase.

### Backup Plans

- Maintain database backups.
- Maintain object-storage recovery.
- Keep prior release artifacts.
- Keep rollback instructions.
- Support queue replay.
- Support projection rebuild.
- Provide provider fallback.
- Preserve manual operational procedures.

### Change Management

- Record requested change.
- Assess scope impact.
- Assess dependency impact.
- Assess security impact.
- Assess data impact.
- Approve or reject change.
- Update roadmap and prompts.
- Communicate affected milestones.
- Preserve decision history.

## 9. Timeline and Progress Tracking

### Development Timeline

The timeline is capacity-based.

Initial planning range:

- Planning Control: 2–3 sprints.
- Platform and Access: 5–7 sprints.
- Core Operations: 8–12 sprints.
- Intelligence and Governance: 4–6 sprints.
- Assurance and Release: 3–5 sprints.

Overall indicative range:

- 22–33 two-week sprints.
- 44–66 calendar weeks.
- Final duration depends on team size and external approvals.

### Sprint Planning

- Use two-week sprints.
- Select work from an approved phase.
- Confirm sprint capacity.
- Confirm dependencies.
- Define sprint goal.
- Define acceptance.
- Include testing and documentation.
- Keep unplanned work visible.

### Progress Monitoring

Track:

- Phase status.
- Sprint goal status.
- Completed acceptance criteria.
- Open defects.
- Blocked dependencies.
- Risk changes.
- Test pass rate.
- Security findings.
- Performance trend.
- Documentation status.

### Status Reporting

Weekly status includes:

- Current phase.
- Completed work.
- Next work.
- Blockers.
- Risks.
- Decisions needed.
- Test status.
- Milestone forecast.

Status values:

- Not started.
- Ready.
- In progress.
- Blocked.
- In review.
- Completed.
- Deferred.

## 10. Project Completion

### Final Validation

- Run the full regression suite.
- Run tenant-isolation tests.
- Run branch-isolation tests.
- Run financial reconciliation.
- Run security validation.
- Run performance validation.
- Run backup restoration.
- Run deployment smoke tests.
- Confirm no blocking defects.

### Documentation Review

- Review architecture.
- Review module guides.
- Review API and event contracts.
- Review data ownership.
- Review RBAC.
- Review configuration.
- Review runbooks.
- Review release notes.
- Remove stale placeholders.

### Production Readiness

- Product approval.
- Security approval.
- Operations approval.
- Support readiness.
- Monitoring readiness.
- Backup readiness.
- Recovery readiness.
- Provider readiness.
- Capacity readiness.
- Rollback readiness.

### Future Enhancement Roadmap

Post-release priorities may include:

- PDF exports.
- Additional notification channels.
- Customer portal.
- Automated subscription billing.
- Public APIs.
- Configurable workflows.
- Inventory.
- Appointments.
- Loyalty.
- Route planning.
- Advanced analytics.
- AI assistance.

Future work must:

- Pass architecture review.
- Preserve tenant isolation.
- Preserve financial integrity.
- Use approved extension contracts.
- Enter a new roadmap cycle.
---
# 11. Detailed Roadmap Principles

## 2.1 Delivery Principles

- Build foundations before domains; Build identity before tenant data; Build tenant context before branches; Build branches before branch data; Build RBAC before protected workflows.
- Build customer and catalog before orders; Build orders before payments; Build payments before cash reconciliation; Build domain events before reporting; Build projections before dashboards.
- Build hardening before deployment; Build deployment before release.
## 2.2 Architecture Principles

- API gateway is the public entry; Services own their domains; Shared packages own technical primitives; No service reads another private store; Events carry tenant context.
- Jobs carry tenant context; Cache keys carry tenant context; Branch data carries branch context; Search is derived; Reports are derived.
- Audit evidence is immutable.
## 2.3 Security Principles

- Deny access by default; Verify tenant on every request; Verify branch on branch data; Verify role and permission; Keep platform access separate.
- Minimize personal data; Redact sensitive logs; Rotate revocable sessions; Test horizontal access; Test vertical access.
## 2.4 Financial Principles

- Use integer minor units; Use deterministic rounding; Freeze transaction prices; Never silently rewrite payments; Record refunds additively.
- Reconcile every balance; Make cash variance visible; Audit corrections; Protect numbering concurrency; Require idempotency.
## 2.5 Delivery Control

- One phase has one objective; One module has one owner; Every phase has entry criteria; Every phase has exit criteria; Every phase has test evidence.
- Every phase updates documentation; Every phase records risks; Every phase stops at scope; Failed gates block downstream work; Exceptions require approval.
---
# 12. Current Roadmap Baseline

## 3.1 Completed Planning Information

Phase 01 contains the product vision. Phase 02 contains the system plan. Phase 03 contains the plan audit. Phase 03 scored readiness at 69 out of 100. Roadmap work is conditionally approved. Broad implementation is not yet approved.
## 3.2 Open Audit Blockers

- Canonical planning files are incomplete; Phase names require alignment; Traceability is missing; Architecture ADRs are missing; Threat model is missing.
- Financial policies need approval; Production topology is pending; Capacity estimates are pending.
## 3.3 Roadmap Rule

Phases 05–07 close planning-control gaps. Phase 08 starts technical implementation. Phases 09–22 build product capability. Phase 23 proves quality and security. Phase 24 prepares deployment. Phase 25 controls release.
---
# 13. Canonical Phase Catalogue

| Phase | Name | Type | Status |
|---:|---|---|---|
| 00 | Foundation | Repository foundation | Existing baseline |
| 01 | Software Idea | Product planning | Information present |
| 02 | System Planning | Architecture planning | Information present |
| 03 | Plan Audit | Planning assurance | Completed conditionally |
| 04 | Implementation Roadmap | Delivery planning | Current phase |
| 05 | Roadmap Audit | Delivery assurance | Pending |
| 06 | Implementation Prompts | Module instruction library | Pending |
| 07 | Prompt Engineering | Prompt quality assurance | Pending |
| 08 | Platform Setup | Technical implementation | Blocked by planning gates |
| 09 | Authentication | Product implementation | Pending |
| 10 | Tenants | Product implementation | Pending |
| 11 | Branches | Product implementation | Pending |
| 12 | Users and RBAC | Product implementation | Pending |
| 13 | Customers | Product implementation | Pending |
| 14 | Services and Item Categories | Product implementation | Pending |
| 15 | Orders and Delivery | Product implementation | Pending |
| 16 | Payments and Receipts | Product implementation | Pending |
| 17 | Notifications | Product implementation | Pending |
| 18 | Expenses and Cash Registers | Product implementation | Pending |
| 19 | Reports | Product implementation | Pending |
| 20 | Dashboard | Product implementation | Pending |
| 21 | Search | Product implementation | Pending |
| 22 | Settings and Audit | Product implementation | Pending |
| 23 | Testing and Hardening | Assurance | Pending |
| 24 | Deployment | Delivery | Pending |
| 25 | Release | Production readiness | Pending |
---
# 14. Delivery Waves

## 5.1 Wave A – Planning Control

Phases:
- Phase 00; Phase 01; Phase 02; Phase 03; Phase 04.
- Phase 05; Phase 06; Phase 07.
Outcome:
- Approved scope; Approved architecture; Audited roadmap; Complete prompt library; Traceable acceptance criteria.
## 5.2 Wave B – Platform and Access

Phases:
- Phase 08; Phase 09; Phase 10; Phase 11; Phase 12.
Outcome:
- Runnable platform; Trusted identity; Tenant isolation; Branch isolation; RBAC enforcement.
## 5.3 Wave C – Core Operations

Phases:
- Phase 13; Phase 14; Phase 15; Phase 16; Phase 17.
- Phase 18.
Outcome:
- Complete daily business workflow; Customer to delivery flow; Payment and cash control; Operational notifications.
## 5.4 Wave D – Intelligence and Governance

Phases:
- Phase 19; Phase 20; Phase 21; Phase 22.
Outcome:
- Reports; Dashboards; Search; Settings; Audit visibility.
## 5.5 Wave E – Assurance and Release

Phases:
- Phase 23; Phase 24; Phase 25.
Outcome:
- Tested product; Hardened platform; Deployable release; Production approval.
---
# 15. Phase 00 – Foundation

**Objective**
Establish the monorepo foundation.
## Current Evidence

- pnpm workspace exists; TurboRepo exists; Backend app folders exist; Flutter apps exist; Shared packages exist.
- Docker foundation exists; CI foundation exists.
## Remaining Checks

- Verify package-manager policy; Verify workspace scripts; Verify clean bootstrap; Verify local services; Verify environment examples.
- Verify root quality gates; Verify no secrets.
**Exit Gate**
- Scaffold verification passes; Clean setup is documented; Root commands are consistent; Foundation limitations are recorded.
---
# 16. Phase 01 – Software Idea

**Objective**
Define what the product is.
**Required Information**
- Product vision; Business problem; Target industries; Target users; Business value.
- Core workflow; SaaS model; Future direction.
**Current Status**
- Information exists in the Phase 01 file; Canonical subject files remain incomplete.
**Exit Gate**
- Product scope is approved; MVP is separated; Future scope is separated; Terminology is approved; Canonical documents are updated.
---
# 17. Phase 02 – System Planning

**Objective**
Define the system architecture.
**Required Information**
- System boundaries; Service ownership; Repository mapping; Data ownership; Communication model.
- Security model; Infrastructure plan; Testing plan; Deployment direction.
**Current Status**
- System plan exists; Architecture ADRs remain pending.
**Exit Gate**
- Ownership is approved; Trust boundaries are approved; Data boundaries are approved; Major ADRs are recorded; Architecture conflicts are resolved.
---
# 18. Phase 03 – Plan Audit

**Objective**
Audit planning quality.
**Completed Outputs**
- Readiness score; Approval boundary; Finding register; Risk review; Traceability baseline.
- Remediation gates.
**Current Result**
- Score: 69 out of 100; Status: conditional approval; Critical findings: three; High findings: seven.
**Exit Gate**
- Findings have owners; Critical gaps enter remediation; Roadmap constraints are clear; No implementation claim is made.
---
# 19. Phase 04 – Implementation Roadmap

**Objective**
Define delivery order.
**Deliverables**
- Canonical phase catalogue; Delivery waves; Phase dependencies; Parallel-work rules; Quality gates.
- Release gates; Risk controls.
**Exit Gate**
- Every module has one phase; Every phase has dependencies; Every phase has deliverables; Every phase has acceptance; Sequence is architecture-safe.
---
# 20. Phase 05 – Roadmap Audit

**Objective**
Verify this roadmap.
**Audit Areas**
- Scope coverage; Phase order; Dependency safety; Resource conflicts; Security sequencing.
- Data sequencing; Financial sequencing; Flutter sequencing; Deployment sequencing.
**Required Decisions**
- Approve phase catalogue; Approve release waves; Approve blocked gates; Approve parallel tracks; Approve roadmap exceptions.
**Exit Gate**
- No missing module; No circular phase dependency; No unsafe early implementation; Risks have owners; Roadmap is approved.
---
# 21. Phase 06 – Implementation Prompts

**Objective**
Create one prompt per implementation phase.
**Prompt Requirements**
- Enterprise-grade; Production-ready; Architecture-driven; Module-specific; Self-contained.
- Fully executable; Scalable; Maintainable; Secure.
**Prompt Coverage**
- Objective; Scope; Out of scope; Architecture; Repositories.
- Data; APIs; Events; Security; Testing.
- Deliverables; Acceptance.
**Exit Gate**
- Every roadmap phase has a prompt; Prompts use canonical sources; Prompts do not conflict; Prompt traceability is complete.
---
# 22. Phase 07 – Prompt Engineering

**Objective**
Audit implementation prompts.
**Review Areas**
- Completeness; Clarity; Correct ownership; Correct dependencies; Security coverage.
- Tenant coverage; Branch coverage; Failure handling; Testing coverage; Scope control.
**Rejection Conditions**
- Generic instructions; Missing owner; Missing isolation; Missing acceptance; Cross-service private access.
- Unapproved scope; Hidden assumptions.
**Exit Gate**
- All prompts pass review; Critical ambiguity is zero; Dependencies are verified; Execution order is frozen.
---
# 23. Phase 08 – Platform Setup

**Objective**
Create the shared technical platform.
**Dependencies**
- Phases 00–07 approved; Architecture ADRs approved; Package policy approved.
**Scope**
- Gateway foundation; Service bootstrap standard; Configuration validation; MongoDB connection standard; Redis connection standard.
- BullMQ foundation; Structured logging; Correlation; Error standard; Health and readiness.
- Object-storage adapter foundation; Audit publishing foundation; Flutter app foundations.
**Deliverables**
- Runnable backend foundation; Runnable Flutter foundations; Shared technical packages; Local integration environment; Baseline CI gates.
**Exit Gate**
- All apps build; Health checks pass; Config fails safely; Logs redact secrets; Local transaction testing works.
- Shared boundaries are enforced.
---
# 24. Phase 09 – Authentication

**Objective**
Implement trusted identity and sessions.
**Dependencies**
- Platform setup; Identity policy; Tenant-login ADR.
**Scope**
- Tenant-user login; Platform login; Password hashing; Access sessions; Refresh rotation.
- Logout; Password reset; OTP lifecycle; Account lockout; Session revocation.
**Security Focus**
- Generic credential errors; Token replay detection; Brute-force limits; Secure browser handling; Secure mobile storage.
- Secret redaction.
**Exit Gate**
- Session tests pass; Lockout tests pass; Rotation tests pass; Reset revokes sessions; Platform context is separate.
---
# 25. Phase 10 – Tenants

**Objective**
Implement tenant lifecycle and isolation.
**Dependencies**
- Authentication; Tenant architecture ADR; Subscription policies.
**Scope**
- Tenant registration; Identity verification; Tenant status; Plan assignment; Entitlements.
- Business settings foundation; Default terminology; Initial configuration; Suspension; Reactivation.
**Isolation Focus**
- Trusted tenant context; Tenant-scoped storage; Tenant cache keys; Tenant event context; Tenant job context.
- Tenant file prefixes.
**Exit Gate**
- Two-tenant tests pass; Suspension blocks access; Entitlements enforce limits; Onboarding is atomic; Context never trusts the client.
---
# 26. Phase 11 – Branches

**Objective**
Implement branch lifecycle.
**Dependencies**
- Tenant lifecycle; Tenant entitlements; Branch-scope policy.
**Scope**
- First branch confirmation; Branch creation; Branch updates; Branch activation; Branch deactivation.
- Branch contact; Branch timezone; Branch switching context.
**Isolation Focus**
- Branch belongs to tenant; Branch access needs assignment; Branch switch clears state; Inactive branch blocks new work; Historical references remain.
**Exit Gate**
- Cross-branch tests pass; Plan branch limit works; Inactive branch rules pass; Branch context is trusted.
---
# 27. Phase 12 – Users and RBAC

**Objective**
Implement staff access control.
**Dependencies**
- Authentication; Tenants; Branches; Approved RBAC matrix.
**Scope**
- User profiles; Tenant memberships; Invitations; Activation; Deactivation.
- Default roles; Custom roles; Permissions; Branch assignments; Last-Owner protection.
**Security Focus**
- Deny by default; No privilege escalation; Tenant-bound invitations; Branch-bound permissions; Prompt permission invalidation.
- Platform roles remain separate.
**Exit Gate**
- Permission matrix passes; Invitation replay fails; Last Owner is protected; Stale access is revoked; Branch assignment is enforced.
---
# 28. Phase 13 – Customers

**Objective**
Implement customer management.
**Dependencies**
- Tenants; Branches; Users and RBAC.
**Scope**
- Customer profiles; Walk-in handling; Customer types; Search-ready attributes; Tenant-wide customer visibility.
- Branch creation context; Order history projection; Payment history projection; Outstanding balance projection.
**Data Focus**
- Minimize personal data; Allow shared family numbers; Protect system aggregates; Preserve customer snapshots; Reconcile balance drift.
**Exit Gate**
- Tenant isolation passes; Walk-in flow passes; Aggregate protection passes; Customer search is scoped.
---
# 29. Phase 14 – Services and Item Categories

**Objective**
Implement the tenant catalog.
**Dependencies**
- Tenants; Branches; Users and RBAC.
**Scope**
- Services; Item categories; Pricing types; Unit types; Base pricing.
- Tax defaults; Branch availability; Active and inactive status; Business-type defaults.
**Data Focus**
- Catalog is tenant-owned; Branch references stay in tenant; Referenced items are not hard deleted; Future price changes do not alter history.
**Exit Gate**
- Catalog isolation passes; Branch availability passes; Default seeding passes; Deactivation rules pass.
---
# 30. Phase 15 – Orders and Delivery

**Objective**
Implement the core operational workflow.
**Dependencies**
- Customers; Catalog; Users and RBAC; Branches; Financial policy.
**Scope**
- Order creation; Walk-in snapshots; Item capture; Pricing snapshots; Discounts and tax.
- Atomic numbering; Expected completion; Status workflow; Status history; Staff assignments.
- Cancellation; Customer pickup; Home delivery; Proof of delivery.
**Integrity Focus**
- Server calculates totals; Status transitions are controlled; Finalized orders are protected; Cancellation requires reason; Delivery respects payment policy.
- Every transition is traceable.
**Exit Gate**
- Pricing tests pass; Concurrency numbering passes; Workflow matrix passes; Assignment security passes; Delivery completion passes.
---
# 31. Phase 16 – Payments and Receipts

**Objective**
Implement settlement and correction.
**Dependencies**
- Orders; Users and RBAC; Tenant payment settings; Approved financial policy.
**Scope**
- Advance payments; Partial payments; Final payments; Multiple methods; Payment numbering.
- Outstanding balance; Payment status; Refunds; Adjustments; Reversals.
- Receipts.
**Integrity Focus**
- Idempotent capture; No hard deletion; Additive correction; Refund eligibility; Transaction references.
- Cash-payment events; Complete audit evidence.
**Exit Gate**
- Split payment passes; Duplicate capture is safe; Refund limits pass; Order balance reconciles; Receipt numbering is unique.
---
# 32. Phase 17 – Notifications

**Objective**
Implement reliable messaging.
**Dependencies**
- Platform queues; Tenant entitlements; Users and customers; Order and payment events.
**Scope**
- In-app notifications; Read state; Message templates; WhatsApp eligibility; Provider adapter.
- Queue dispatch; Retry; Failure status; Operational alerts.
**Reliability Focus**
- Business actions stay non-blocking; In-app remains available; Provider limits are respected; Consent is verified; Duplicate events do not duplicate messages.
**Exit Gate**
- Retry policy passes; Failed provider is visible; Entitlement enforcement passes; User feed isolation passes; Duplicate suppression passes.
---
# 33. Phase 18 – Expenses and Cash Registers

**Objective**
Implement branch expense and cash control.
**Dependencies**
- Branches; Users and RBAC; Payments; Tenant timezone; Cash policy.
**Scope**
- Expense categories; Expenses; Attachments; Payment method; Register opening.
- Cash receipts; Cash expenses; Refunds; Additions; Withdrawals.
- Expected closing; Actual closing; Variance; Register history.
**Integrity Focus**
- One register per business date; Blind cash count; Variance note; Closed register protection; Reconciliation.
- Audit evidence.
**Exit Gate**
- Closing formula passes; Duplicate opening fails; Closed period is protected; Variance alert works; Cash totals reconcile.
---
# 34. Phase 19 – Reports

**Objective**
Implement trusted business reports.
**Dependencies**
- Customer events; Order events; Payment events; Expense events; Cash-register events.
**Scope**
- Sales report; Payment report; Expense report; Cash-flow report; Order report.
- Outstanding report; Branch filters; Date filters; CSV export; Async large export.
**Integrity Focus**
- Use frozen transaction values; Keep tenant scope; Keep branch scope; Trace totals to sources; Rebuild projections.
- Monitor freshness.
**Exit Gate**
- Control totals match; Isolation tests pass; Export format passes; Large export is asynchronous; Projection lag is visible.
---
# 35. Phase 20 – Dashboard

**Objective**
Implement role-aware operational visibility.
**Dependencies**
- Report projections; Search-ready status; Tenant and branch context; RBAC.
**Scope**
- Owner dashboard; Branch dashboard; Staff dashboard; Cashier dashboard; Platform dashboard.
- Daily KPIs; Overdue work; Expected deliveries; Sales summary; Cash summary.
- Outstanding summary.
**Performance Focus**
- Pre-aggregated values; Bounded refresh; Visible data freshness; Role-specific cards; Branch-safe filters.
**Exit Gate**
- Dashboard loads within target; Role visibility passes; Branch filters pass; KPI totals match reports.
---
# 36. Phase 21 – Search

**Objective**
Implement secure operational search.
**Dependencies**
- Customer events; Catalog events; Order events; Tenant and branch context.
**Scope**
- Customer search; Order search; Service search; Item-category search; Exact identifiers.
- Prefix matching; Mobile suffix matching; Search projections; Projection rebuild.
**Security Focus**
- Tenant scope is mandatory; Branch scope is applied; Unauthorized fields are excluded; Search errors do not leak existence; Indexes are rebuildable.
**Exit Gate**
- Isolation tests pass; Typical latency passes; Rebuild process passes; Stale projection is visible.
---
# 37. Phase 22 – Settings and Audit

**Objective**
Complete tenant configuration and audit visibility.
**Dependencies**
- Tenant settings foundation; Audit publishing foundation; Events from all modules; RBAC.
**Scope**
- Business settings; Tax settings; Payment methods; Number prefixes; Branding.
- Receipt footer; Overpayment policy; Delivery-on-unpaid policy; Tenant audit query; Platform audit separation.
- Audit retention; Audit archival.
**Integrity Focus**
- Settings changes are audited; Audit is append-only; Non-Owners cannot change settings; Tenant audit cannot cross tenant; Sensitive values are excluded.
**Exit Gate**
- Settings propagation passes; Audit completeness passes; Audit mutation fails; Retention policy passes; Access matrix passes.
---
# 38. Phase 23 – Testing and Hardening

**Objective**
Prove product quality.
**Dependencies**
- Product phases 08–22 complete; Test environments ready; Threat model approved.
**Test Tracks**
- Unit; Contract; Integration; End to end; Tenant isolation.
- Branch isolation; RBAC; Financial accuracy; Concurrency; Idempotency.
- Resilience; Performance; Accessibility; Flutter compatibility; Backup and restore.
**Hardening Tracks**
- Dependency security; Secret scanning; Abuse controls; File safety; Logging redaction.
- Rate limits; Session security; Provider callback security.
**Exit Gate**
- No critical defect; No high security defect; Isolation suite passes; Financial suite passes; Performance targets pass.
- Recovery tests pass.
---
# 39. Phase 24 – Deployment

**Objective**
Prepare controlled production deployment.
**Dependencies**
- Testing gate passed; Provider selected; Region selected; Capacity approved; Recovery approved.
**Scope**
- Production topology; Network boundaries; Managed MongoDB; Managed Redis; Object storage.
- Secret manager; Observability; Backend containers; Flutter web hosting; Mobile release setup.
- CI/CD promotion; Rollback.
**Exit Gate**
- Staging deploy passes; Smoke tests pass; Rollback is proven; Backup is proven; Alerts are active.
- Runbooks are approved.
---
# 40. Phase 25 – Release

**Objective**
Approve and launch the product.
**Dependencies**
- Deployment gate passed; Product approval; Security approval; Operations approval; Support readiness.
**Scope**
- Release candidate; Final regression; Data readiness; Provider readiness; Store submission.
- Web release; Backend release; Monitoring window; Incident staffing; Customer communication.
- Known limitations.
**Exit Gate**
- Go-live approval recorded; Production checks pass; No blocking defect; Support is active; Rollback remains available.
- Release evidence is complete.
---
# 41. Dependency Map

## 32.1 Hard Dependencies

- Phase 08 needs Phases 05–07; Phase 09 needs Phase 08; Phase 10 needs Phase 09; Phase 11 needs Phase 10; Phase 12 needs Phases 09–11.
- Phase 13 needs Phase 12; Phase 14 needs Phase 12; Phase 15 needs Phases 13–14; Phase 16 needs Phase 15; Phase 17 needs Phase 08 and domain events.
- Phase 18 needs Phases 12 and 16; Phase 19 needs Phases 13–18; Phase 20 needs Phase 19; Phase 21 needs Phases 13–15; Phase 22 needs audit events from all modules.
- Phase 23 needs Phases 08–22; Phase 24 needs Phase 23; Phase 25 needs Phase 24.
## 32.2 Parallel Work

Allowed:
- Customer and catalog after RBAC; Notification foundation after platform setup; Search foundation after event standards; Flutter foundations during platform setup; Report projection design during domain work.
- Audit consumer work during each domain phase.
Blocked:
- Orders before customer and catalog; Payments before orders; Cash registers before payments; Reports before stable events; Dashboard before report projections.
- Release before hardening.
---
# 42. Cross-Cutting Workstreams

## 33.1 Security

Every phase includes:
- Threat review; Tenant checks; Branch checks; Permission checks; Sensitive-data review.
- Log-redaction review; Security tests.
## 33.2 Data

Every domain phase includes:
- Ownership; Lifecycle; Retention; Index strategy; Concurrency.
- Migration; Backup impact; Reconciliation.
## 33.3 Events and Jobs

Every event producer includes:
- Outbox; Version; Tenant context; Branch context; Correlation.
- Idempotency; Replay safety.
Every job includes:
- Owner; Queue; Tenant context; Retry; Dead letter.
- Alert; Recovery.
## 33.4 Flutter

Every user-facing phase includes:
- Web responsibility; Mobile responsibility; Loading state; Empty state; Error state.
- Forbidden state; Accessibility; Localization; Responsive behavior; Cache isolation.
## 33.5 Audit

Every critical phase includes:
- Actor; Tenant; Branch; Action; Target.
- Correlation; Result; Safe old/new summary.
---
# 43. Quality Gates

## 34.1 Entry Gate

Before a phase starts:
- Dependencies are complete; Prompt is approved; Scope is clear; Owner is assigned; Risks are reviewed.
- Test plan is ready; Environment is ready; Required decisions are approved.
## 34.2 Development Gate

Before review:
- In-scope work is complete; Formatting passes; Linting passes; Type checks pass; Unit tests pass.
- Documentation is updated; No secret is present; No unrelated change is mixed.
## 34.3 Integration Gate

Before phase completion:
- Contract tests pass; Integration tests pass; Isolation tests pass; Failure tests pass; Observability is present.
- Migration is verified; Rollback is documented.
## 34.4 Completion Gate

Before downstream work:
- Acceptance criteria pass; Security review passes; Completion evidence is factual; Files are listed; Commands are listed.
- Limitations are listed; Risks are updated; Next-phase notes are ready.
---
# 44. Milestone Plan

## Milestone 1 – Planning Approved

Includes:
- Phases 00–07.
Success:
- Canonical roadmap approved; Prompts approved; Critical planning gaps closed.
## Milestone 2 – Secure Platform

Includes:
- Phases 08–12.
Success:
- Identity works; Tenant isolation works; Branch isolation works; RBAC works.
## Milestone 3 – Operational MVP

Includes:
- Phases 13–18.
Success:
- Customer-to-delivery flow works; Payments reconcile; Cash closes; Notifications work.
## Milestone 4 – Managed ERP

Includes:
- Phases 19–22.
Success:
- Reports reconcile; Dashboard is useful; Search is secure; Audit is complete.
## Milestone 5 – Production Release

Includes:
- Phases 23–25.
Success:
- Quality is proven; Deployment is safe; Release is approved.
---
# 45. Risk Controls

| Risk | Roadmap control |
|---|---|
| Tenant leakage | Isolation foundation before domains |
| Branch leakage | Branch and RBAC before operations |
| Financial error | Policy approval before orders and payments |
| Duplicate payments | Idempotency in payment phase |
| Event drift | Outbox foundation and reconciliation |
| Report mismatch | Reports after stable events |
| Audit gaps | Audit foundation in platform setup |
| Provider outage | Async notifications and fallback |
| Premature services | Consolidated deployment option |
| Release instability | Dedicated hardening phase |
| Documentation drift | Phase completion documentation |
| Scope expansion | Phase out-of-scope gates |
## 36.1 Roadmap Escalation

Escalate when:
- Ownership changes; A phase adds a new service; A phase changes tenant rules; A phase changes financial rules; A phase changes public contracts.
- A phase adds regulated data; A phase changes production topology; A dependency cannot meet its gate.
---
# 46. Documentation Deliverables

Each implementation phase updates:
- Module architecture; Business rules; Data ownership; API contracts; Event contracts.
- Job contracts; Security controls; RBAC matrix; Environment variables; Operational runbooks.
- Testing evidence; Completion report.
Documentation must match implemented behavior. Placeholders are not completion evidence.
---
# 47. Roadmap Acceptance Criteria

- [ ] Phase 00–25 catalogue is approved.
- [ ] Every phase has one objective.
- [ ] Every module has one owner.
- [ ] Every phase has dependencies.
- [ ] Every phase has deliverables.
- [ ] Every phase has an exit gate.
- [ ] Planning gates precede implementation.
- [ ] Authentication precedes tenant data.
- [ ] Tenant context precedes branches.
- [ ] Branches and RBAC precede operations.
- [ ] Customer and catalog precede orders.
- [ ] Orders precede payments.
- [ ] Payments precede cash reconciliation.
- [ ] Stable events precede reports.
- [ ] Reports precede dashboards.
- [ ] Hardening precedes deployment.
- [ ] Deployment precedes release.
- [ ] Tenant isolation spans every phase.
- [ ] Branch isolation spans branch data.
- [ ] Financial controls span every money phase.
- [ ] Audit spans every critical phase.
- [ ] Flutter work is included where needed.
- [ ] Security testing is continuous.
- [ ] Completion evidence is mandatory.
- [ ] No source implementation exists in this roadmap.
---
# 48. Final Roadmap Decision

The roadmap is complete for Phase 04 review. The delivery order is architecture-safe. The module order is dependency-safe. The critical business path is clear. The security path is clear. The financial path is clear. The Flutter path is clear. The assurance path is clear. The roadmap now moves to Phase 05 Roadmap Audit. Technical implementation remains blocked until Phases 05–07 pass. No code, API, schema, UI, event logic, queue logic, or deployment script is implemented here.
