# User Personas

## P-01 — Platform Super Administrator

- **Context:** Operates the SaaS platform, not a tenant business.
- **Goals:** Govern tenant lifecycle, plans, platform health, and approved support operations.
- **Pain points:** Cross-tenant operations are high risk; platform work must not imply access to tenant financial or audit data.
- **Permission ceiling:** Platform-only context. No implicit tenant membership or unrestricted tenant access.

## P-02 — Tenant Owner

- **Context:** Owns or administrates an entire service business.
- **Goals:** Configure the tenant, manage branches and staff, monitor operations, reconcile money, and view tenant-wide reports and audit evidence.
- **Pain points:** Fragmented data, weak branch visibility, manual reconciliation, and limited accountability.
- **Permission ceiling:** Entire tenant, subject to protected system invariants, subscription entitlements, separation-of-duties rules, and immutable history.

## P-03 — Branch Manager

- **Context:** Runs one or more explicitly assigned branches.
- **Goals:** Manage branch operations, permitted staff, workload, order progress, and branch reports.
- **Pain points:** Delays, staff coordination, incomplete status data, and branch-specific reconciliation.
- **Permission ceiling:** Assigned branches only. Cannot grant Owner-level access or access outside assigned branches.

## P-04 — Operational Staff Member

- **Context:** Performs assigned service work.
- **Goals:** See required customer/order information, understand assigned work, and record accurate progress.
- **Pain points:** Unclear assignments, manual handoffs, repeated questions, and missing notes.
- **Permission ceiling:** Assigned branches and work only; no financial administration.

## P-05 — Cashier

- **Context:** Handles point-of-service order entry and money.
- **Goals:** Find customers quickly, create correct orders, collect partial/full payments, issue receipts, and reconcile branch cash.
- **Pain points:** Busy counters, duplicate customers, calculation mistakes, duplicate payments, and unexplained cash variance.
- **Permission ceiling:** Assigned branches and permitted financial actions. Refunds, large discounts, discrepancies, and register reopening follow approval policy.

## P-06 — Delivery-Assigned Staff

- **Context:** Handles customer pickup or home delivery tasks.
- **Goals:** See assigned delivery information, record receiver/proof, and complete handoff reliably.
- **Pain points:** Missing address/contact information, unpaid-order policy uncertainty, and weak proof.
- **Permission ceiling:** Assigned deliveries and the minimum customer/order information needed to complete them.

## P-07 — Customer

- **Context:** Requests a service and receives the completed item or outcome.
- **Goals:** Fast intake, accurate pricing, clear status, trustworthy receipts, convenient payment, and reliable completion/delivery.
- **Pain points:** Repeated calls, unclear status, billing ambiguity, lost items, and inconsistent service history.
- **Permission ceiling:** No internal ERP access in MVP; receives approved notifications, receipts, and proof. A self-service portal is post-MVP.

## P-08 — Support and Operations Specialist

- **Context:** Diagnoses platform or tenant incidents.
- **Goals:** Restore service safely, investigate correlated evidence, and help without exposing unnecessary tenant data.
- **Pain points:** Incomplete observability and dangerous standing access.
- **Permission ceiling:** Separately governed, approved, time-bound, least-privilege, and audited support access.

## P-09 — Engineer or Reviewer

- **Context:** Implements or validates a module using this guide.
- **Goals:** Find stable requirements, contracts, ownership, dependencies, acceptance criteria, and current status without guessing.
- **Pain points:** Conflicting phase names, placeholder canonical files, duplicated instructions, and missing traceability.
- **Permission ceiling:** Repository and environment access granted by engineering policy; no production data or secrets by default.

