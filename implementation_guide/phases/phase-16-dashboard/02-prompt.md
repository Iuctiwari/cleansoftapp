# Phase 16 — Modular Dashboard Implementation Prompt

## Phase Information

- **Phase number:** 16
- **Phase name:** Dashboard
- **Primary contract:** `SVC-DASHBOARD-001`
- **Primary route:** `GET /api/v1/dashboard`
- **Requirements:** `FR-DASHBOARD-01` through `FR-DASHBOARD-03`
- **Status:** Implementation prompt

## Execution Contract

You are the implementation agent for Nexoraa CleanSoft Phase 16. Work from the repository root and execute this prompt end to end.

Implement one modular, permission-driven dashboard backend. Do not create separate backend endpoints or duplicated dashboard implementations for each role. The authenticated context, tenant scope, branch assignments, permissions, requested filters, and available source data determine the returned KPIs, charts, widgets, drill-downs, and quick actions.

The repository is the source of truth. Before changing files, inspect the current tree, `git status`, accepted ADRs, contracts, prior completion evidence, implementation, and tests. Preserve unrelated work. Prefer accepted architecture decisions and executable contracts over stale prose.

Implement only Phase 16. Do not begin Phase 17 or build Flutter dashboard widgets in this phase.

## Mandatory Reading

Read these files completely before implementation:

- `implementation_guide/README.md`
- `implementation_guide/architecture/00-ARCHITECTURE.md`
- `implementation_guide/architecture/00-MASTER-PLAN.md`
- `implementation_guide/architecture/API-CONTRACTS.md`
- `implementation_guide/architecture/AUDIT-LOG.md`
- `implementation_guide/architecture/CODING-STANDARDS.md`
- `implementation_guide/architecture/CONTRACTS.md`
- `implementation_guide/architecture/DATA-MODEL.md`
- `implementation_guide/architecture/DECISIONS.md`
- `implementation_guide/architecture/DEPENDENCY-GRAPH.md`
- `implementation_guide/architecture/OBSERVABILITY.md`
- `implementation_guide/architecture/PROJECT_STATE.md`
- `implementation_guide/architecture/TESTING-STRATEGY.md`
- `implementation_guide/01_plan/05_Functional_Requirements.md`
- `implementation_guide/01_plan/06_NonFunctional_Requirements.md`
- `implementation_guide/01_plan/08_Project_Glossary.md`
- `implementation_guide/01_plan/10_Open_Questions.md`
- `implementation_guide/phases/phase-15-reports-exports/01-plan.md`
- `implementation_guide/phases/phase-15-reports-exports/04-status.md`
- `implementation_guide/phases/phase-16-dashboard/01-plan.md`
- All relevant source, schemas, tests, READMEs, contracts, and completion evidence in directories touched by this phase

Verify Report, Authentication, Tenant, Branch, User/RBAC, Subscription, Order, Customer, Catalog/Service, Payment, Expense/Register, Delivery, Notification, Audit, and Job integrations through their public contracts. Never access another service’s private MongoDB collections.

## Overall Purpose

Provide each authenticated user with a secure, current, explainable overview of the platform or business operations they are permitted to see.

The dashboard must:

- Present role-appropriate operational and financial information.
- Enforce tenant, branch, role, and permission scope server-side.
- Return only authorized dashboard components and actions.
- Use governed Report contracts or approved rebuildable projections.
- Reconcile financial and operational totals with corresponding reports.
- Expose freshness, lineage, checkpoint, and degraded state.
- Support tenant, branch, and date filters only within the caller’s allowed scope.
- Provide stable component keys so a frontend can render the response dynamically.
- Meet the first-useful-result performance target when verified against representative capacity.

## Architecture Decision

Build one modular dashboard, not six separate role pages.

The backend must:

1. Authenticate the caller.
2. Resolve platform, tenant, branch, and permission scope.
3. Validate requested filters against that scope.
4. Select components from an allowlisted dashboard catalogue.
5. Query governed Report contracts or approved dashboard projections.
6. Remove components, fields, drill-downs, and actions the caller cannot use.
7. Return a stable, typed `DashboardView`.

The future frontend must render only the components returned by the backend. Frontend hiding is not authorization. Phase 16 supplies the backend contract and metadata required for dynamic rendering; Phase 17 owns actual Flutter components.

## Responsibility Boundaries

### Dashboard Owns

- Permission-aware component catalogue and composition.
- Dashboard response contracts.
- Dashboard-specific rebuildable projection/cache when justified.
- Filter validation and scope-aware query orchestration.
- Freshness, lineage, checkpoint, and degradation metadata.
- Safe component ordering, layout hints, and drill-down metadata.
- Dashboard performance, observability, and reconciliation tests.

### Dashboard Does Not Own

- Tenant, subscription, user, branch, order, customer, service, payment, expense, delivery, notification, audit, or job source records.
- Financial calculations that differ from governed Report definitions.
- Mutations behind quick actions.
- Permission assignment or role management.
- Report generation ownership.
- Arbitrary user-authored formulas or unrestricted custom dashboards.
- Forecasting, AI insights, or speculative recommendations.
- Flutter/web dashboard UI implementation.

Quick actions are authorized navigation/action descriptors only. The owning service must reauthorize and execute every resulting command.

## Dependencies

Verify before implementation:

- Authenticated actor and optional platform-operator context.
- Tenant membership, status, and scope.
- Assigned branch scope.
- Effective RBAC permissions.
- `SVC-REPORT-001` query behavior, lineage, and freshness.
- Stable report definitions for every requested KPI or chart.
- Platform subscription and health contracts for Super Admin components.
- Notification and audit activity contracts.
- Rebuildable projection and cache conventions from `ADR-012`.

If a required source contract does not exist, omit or mark the affected component unavailable with an explicit reason. Do not query private collections or invent a number to make the dashboard appear complete.

## Dashboard Personas

Roles are default presets, not the final authorization boundary. Effective permissions can add or remove individual components within an approved ceiling.

### 1. Platform Super Admin

**Purpose:** Monitor and manage the entire SaaS platform.

This view is platform-scoped and must never be granted through ordinary tenant roles.

| Component | Allowed catalogue |
|---|---|
| KPI cards | Total Tenants; Active Tenants; Trial Tenants; Expired Subscriptions; Total Users; Total Branches; Platform Revenue; Platform Health |
| Charts | Tenant Growth; Subscription Distribution; Platform Revenue Trend; Active User Trend |
| Widgets | Recent Tenant Registrations; Expiring Subscriptions; Platform Notifications; Failed Background Jobs; System Health; Recent Platform Activity |
| Quick actions | Create Tenant; Manage Subscription Plans; Suspend or Activate Tenant; View Platform Logs; Manage Global Settings |

Do not include tenant business revenue, expense, customer, or order details unless a separately authorized support workflow explicitly permits them.

### 2. Tenant Owner

**Purpose:** Provide an authorized overview of business performance across all accessible branches.

| Component | Allowed catalogue |
|---|---|
| KPI cards | Today’s Orders; Active Orders; Completed Orders; Cancelled Orders; Today’s Revenue; Outstanding Payments; Today’s Expenses; Net Profit; Total Customers; Total Services; Active Employees |
| Charts | Revenue vs Expenses; Orders Trend; Branch Performance; Top Services; Payment Method Distribution; Customer Growth |
| Widgets | Recent Orders; Recent Payments; Pending Deliveries; Pending Expenses; Notifications; Employee Activity; Branch Performance Summary |
| Quick actions | Create Order; Add Customer; Add Service; Add Branch; View Reports; Manage Settings |

Tenant-wide aggregation is allowed only when the caller has tenant-wide visibility. Otherwise, aggregate only permitted branches and state the applied scope.

### 3. Branch Manager

**Purpose:** Monitor and manage daily operations for assigned branches.

| Component | Allowed catalogue |
|---|---|
| KPI cards | Today’s Orders; Active Orders; Ready for Delivery; Pending Deliveries; Today’s Revenue; Today’s Expenses; Active Customers; Assigned Employees |
| Charts | Daily Revenue; Service Performance; Employee Performance; Orders by Status; Customer Growth |
| Widgets | Pending Orders; Employee Activity; Pending Approvals; Recent Payments; Branch Notifications |
| Quick actions | Create Order; Assign Employee; Record Expense; Manage Services; View Branch Reports |

The response must remain restricted to assigned branches even if a valid identifier for another branch is supplied.

### 4. Cashier

**Purpose:** Support billing and authorized payment collection.

| Component | Allowed catalogue |
|---|---|
| KPI cards | Today’s Payments; Pending Payments; Outstanding Amount; Cash Collection; UPI Collection; Card Collection; Total Transactions |
| Charts | Payment Method Distribution; Hourly Collections; Daily Collection Trend |
| Widgets | Pending Bills; Recent Payments; Payment History; Recent Customers; Payment Notifications |
| Quick actions | Collect Payment; Print Receipt; Search Customer; View Payment History |

Return only the minimum customer and payment information required for permitted cashier duties. Never expose payment credentials or unrestricted customer history.

### 5. Service Staff

**Purpose:** Help employees manage assigned service work.

| Component | Allowed catalogue |
|---|---|
| KPI cards | Assigned Orders; Orders Completed Today; Pending Tasks; Overdue Tasks; In Progress Orders |
| Charts | Daily Productivity; Service Completion Rate; Workload Distribution |
| Widgets | Assigned Orders; Priority Orders; Orders Due Today; Recent Updates; Notifications |
| Quick actions | Update Order Status; View Assigned Orders; Add Service Notes; View Schedule |

Restrict order, customer, schedule, workload, and productivity data to the caller’s assignment and permissions.

### 6. Delivery Executive

**Purpose:** Support assigned delivery and collection operations.

| Component | Allowed catalogue |
|---|---|
| KPI cards | Assigned Deliveries; Delivered Today; Pending Deliveries; Failed Deliveries; OTP Pending Deliveries |
| Charts | Delivery Success Rate; Daily Delivery Trend; Delivery Status Distribution |
| Widgets | Delivery Queue; Today’s Deliveries; Pending OTP Verification; Customer Contact Information; Delivery Notifications |
| Quick actions | Start Delivery; Verify OTP; Upload Delivery Proof; Complete Delivery; Report Delivery Issue |

Return customer contact information only for currently assigned deliveries and only while operationally required. Never return OTP secrets, verification codes, or unrestricted customer profiles in dashboard payloads.

## Common Permission-Based Component Groups

The catalogue may expose these groups when supported by governed sources and effective permissions:

- **Business:** Revenue, Orders, Customers, Services, Payments, Expenses, Profit.
- **Operations:** Pending, Processing, Ready, Completed, Delivered, and Cancelled Orders.
- **Employees:** Assigned Tasks, Completed Tasks, Activity, Productivity.
- **Financial:** Daily Revenue, Outstanding Payments, Collection Summary, Expense Summary.
- **Delivery:** Pending, Completed, Failed Deliveries, Delivery Success Rate.
- **Notifications:** System Alerts, Pending Approvals, Order, Payment, Delivery, Subscription, and Business Alerts.
- **Recent activity:** Orders, Payments, Customers, Deliveries, Employee Actions, Notifications.

Sharing a component key across personas must reuse one definition and one governed calculation. Do not create role-specific formulas for the same KPI.

## Component Catalogue

Define every component in an allowlisted, versioned catalogue with:

- Stable key and contract version.
- Type: `kpi`, `chart`, `widget`, or `action`.
- Label/message key rather than hard-coded presentation copy where localization applies.
- Required permissions.
- Allowed platform/tenant/branch/assignment scopes.
- Supported filters and date granularity.
- Report/source contract and governed metric definition.
- Value type, unit, currency, and formatting hint.
- Freshness threshold and degraded behavior.
- Safe drill-down route/resource and required permission.
- Layout hints such as priority and preferred size.
- Data classification and redaction policy.

Unknown component keys must not execute arbitrary queries.

## `DashboardView` Contract

Return a typed response containing:

- Contract version.
- Dashboard preset/persona.
- Effective scope type and authorized tenant/branch identifiers.
- Applied timezone, business date, date range, and filters.
- `asOf`, projection checkpoint, freshness status, and source lag.
- Component groups in stable display order.
- Each component’s stable key, type, state, value/dataset, unit, and display metadata.
- Optional trend only when supported by governed comparable-period data.
- Source report/metric identity and safe lineage.
- Permitted drill-down descriptor.
- Permitted quick-action descriptor.
- Component-level unavailable, stale, partial, or degraded reason.
- Response correlation ID.

Do not return internal query text, private collection names, sensitive logs, secret configuration, unauthorized identifiers, or raw exception details.

## API Requirements

Implement:

`GET /api/v1/dashboard`

Supported bounded query inputs:

- Authorized `tenantId` only for platform operators with explicit tenant-view permission.
- `branchId` or approved multiple-branch selection.
- Date or bounded date range.
- Approved timezone/business-date behavior.
- Optional component groups or stable component keys.
- Optional locale/display metadata accepted by repository conventions.

Rules:

- Resolve authorization before selecting or querying components.
- Validate filters against each component and effective scope.
- Ignore no unauthorized scope silently; reject it with the standard safe authorization response.
- Deduplicate source queries across components.
- Support partial success only with explicit component states and overall degradation metadata.
- Apply bounded timeouts and cancellation.
- Use ETag/cache-control semantics only when identity and tenant/branch partitions are safe.
- Never cache one actor’s privileged response for another actor.

Do not add separate `/owner-dashboard`, `/cashier-dashboard`, or other persona endpoints.

## Data and Calculation Rules

- Query `SVC-REPORT-001` or an approved dashboard projection.
- Never read private domain collections.
- Never duplicate or subtly modify governed financial formulas.
- Use integer minor units for money and include currency.
- Never aggregate different currencies without an approved conversion contract.
- Use approved tenant/branch timezone and business-date rules.
- Define Today consistently with the corresponding report.
- Net Profit must use the governed report definition; omit it if the definition is unresolved.
- Platform Revenue means SaaS subscription revenue, not tenant business revenue.
- Trends require a defined comparable period and complete source data.
- Ratios must define numerator, denominator, zero-denominator behavior, and rounding.
- Recent lists must be bounded and stably sorted.
- Health values must come from an approved health aggregation, not guessed from one dependency.
- All totals must reconcile with governed reports for the same scope, filters, and checkpoint.

## Authorization and Security

- Enforce platform-versus-tenant identity boundaries.
- Enforce tenant isolation in queries, projections, caches, logs, and metrics.
- Enforce branch and assignment scope for every component.
- Evaluate effective permissions server-side for cards, charts, widgets, drill-downs, and actions.
- Apply data minimization to customer, employee, delivery, payment, subscription, and platform activity data.
- Prevent component-key injection, filter injection, NoSQL injection, and unbounded queries.
- Prevent inference through totals, trends, empty states, timing differences, or drill-down metadata.
- Redact sensitive fields from logs, traces, errors, and activity widgets.
- Audit privileged platform views and material dashboard configuration/catalogue changes.
- Quick-action descriptors never bypass owning-service authorization.
- Deny by default when permission, scope, lineage, or source classification is unclear.

## Freshness and Degraded Behavior

Every data component must expose one of:

- `fresh`
- `stale`
- `partial`
- `unavailable`

Include source `asOf`, checkpoint, and measured lag. Never label cached or delayed data as live.

When a source is unavailable:

- Return unaffected authorized components when safe.
- Mark affected components explicitly.
- Do not substitute zero for unknown.
- Do not serve data beyond its approved stale threshold.
- Preserve correlation details for operators without leaking internals to users.

## Performance and Caching

- Target first useful dashboard data within two seconds only under a documented representative workload.
- Define component-query budgets, payload limits, list limits, and maximum date ranges.
- Batch compatible Report queries and avoid N+1 service calls.
- Use bounded parallelism, timeouts, and cancellation.
- Partition caches by actor class, permissions/version, tenant, branch set, date/filter, locale, and contract version.
- Invalidate or expire caches after membership, permission, tenant status, branch assignment, or source-checkpoint changes.
- Measure cold, warm, full, partial, and degraded responses.
- Do not sacrifice authorization, accuracy, freshness, or reconciliation for latency.

## Observability

- Emit structured redacted logs with correlation and causation IDs.
- Measure request count, latency, error rate, cache behavior, component failures, source latency, freshness lag, payload size, and reconciliation drift.
- Trace dashboard-to-report calls without recording sensitive result data.
- Alert on persistent stale projections, high source failure, authorization anomalies, cache partition failures, and report/dashboard mismatch.
- Provide health/readiness checks according to repository conventions.

## Testing Requirements

### Unit Tests

- Persona preset and component-catalogue selection.
- Permission intersection and deny-by-default behavior.
- Platform, tenant, branch, and assignment scope resolution.
- Filter validation.
- Response composition and stable ordering.
- Money, ratio, trend, timezone, and empty-state handling.
- Fresh, stale, partial, and unavailable states.
- Cache-key partitioning and invalidation.

### Contract and Integration Tests

- `SVC-DASHBOARD-001` and `GET /api/v1/dashboard`.
- `SVC-REPORT-001` query batching, lineage, freshness, and failure behavior.
- Authentication, Tenant, Branch, User/RBAC, Subscription, Notification, Audit, and health integrations.
- Owner, Manager, Cashier, Service Staff, Delivery Executive, and Platform Super Admin presets.
- Reconciliation of each KPI with its governed report at the same checkpoint.
- Safe partial response when one source fails.

### Security Tests

- Cross-tenant and cross-branch access.
- Tenant role attempting Platform Super Admin components.
- Unauthorized component, action, drill-down, and filter requests.
- Service Staff and Delivery Executive assignment isolation.
- Cashier customer/payment data minimization.
- OTP, payment, subscription, log, and personal-data protection.
- Cache leakage across users, permissions, tenants, and branches.
- Component/filter injection and oversized requests.

### Performance and Reliability Tests

- Cold and warm dashboard response.
- Representative full owner and platform views.
- Concurrent branch-scoped requests.
- Report slowdown, timeout, partial failure, recovery, and stale projection.
- Payload and query-count budgets.
- First useful result target under the documented `OQ-28` capacity assumptions.

Run format, lint, type-check, unit, integration, security, performance, and build commands for every touched workspace. Never report a skipped, unavailable, or failed check as passed.

## Implementation Sequence

1. Inspect repository state and validate Phase 15 Report dependencies.
2. Map each requested component to a governed source, metric, permission, scope, and freshness policy.
3. Mark unsupported components unavailable; do not invent missing source contracts.
4. Define the versioned component catalogue and `DashboardView`.
5. Implement platform, tenant, branch, and assignment scope resolution.
6. Implement permission-driven component selection.
7. Implement bounded Report query orchestration and response composition.
8. Implement freshness, lineage, partial failure, and reconciliation behavior.
9. Implement secure partitioned caching where justified.
10. Implement the single dashboard route and gateway contract.
11. Add observability, audit hooks, and safe operational controls.
12. Add unit, contract, integration, security, reliability, and performance tests.
13. Document the API, catalogue, permissions, metric lineage, caching, and Phase 17 rendering contract.
14. Run all relevant validation and inspect the final diff.
15. Update Phase 16 completion evidence factually.
16. Stop without implementing Phase 17.

## Acceptance Criteria

- [ ] One modular dashboard API serves all supported personas.
- [ ] The backend returns only authorized components, data, drill-downs, and actions.
- [ ] Platform Super Admin access is isolated from tenant roles.
- [ ] Tenant, branch, and assignment boundaries are enforced.
- [ ] Owner, Manager, Cashier, Service Staff, and Delivery Executive presets match their permitted operational needs.
- [ ] Common components reuse one governed metric definition.
- [ ] Dashboard totals reconcile with corresponding Reports for identical scope and checkpoint.
- [ ] Every component exposes lineage and freshness.
- [ ] Stale, partial, unavailable, and unknown data are explicit and never represented as current zero values.
- [ ] Quick actions are descriptors and owning services reauthorize all mutations.
- [ ] No private domain collection is read.
- [ ] No independent financial formula, mixed-currency total, forecasting, or AI insight is introduced.
- [ ] Cache entries cannot leak across actors, permissions, tenants, branches, or assignments.
- [ ] Sensitive platform, customer, employee, payment, delivery, and OTP data are protected.
- [ ] First useful result and payload/query budgets are measured under representative workloads.
- [ ] Unit, contract, integration, security, reliability, performance, lint, type-check, and build gates pass.
- [ ] Documentation describes only implemented and verified behavior.
- [ ] No Flutter dashboard UI or unrelated phase work is included.

## Completion Instructions

1. Map every acceptance criterion to implementation, tests, documentation, or measured evidence.
2. Record exact validation commands and honest outcomes.
3. List exact files created and modified.
4. Record supported and unavailable components with reasons.
5. Record metric definitions, source reports, lineage, freshness thresholds, and reconciliation evidence.
6. Record permission, cache-partition, security, and degradation decisions.
7. Record measured performance workloads and results.
8. Record known limitations with impact, owner, and next safe action.
9. Verify the diff contains no secrets, sensitive fixtures, private database access, or unrelated changes.
10. Update the matching Phase 16 status/completion evidence.
11. Stop after Phase 16.
