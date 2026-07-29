# Project Glossary

| Term | Canonical definition |
|---|---|
| Active branch | A branch permitted to accept new operational work. Inactive branches may remain historically queryable. |
| Active tenant | A tenant whose coordinated onboarding and valid subscription/lifecycle state permit business operations. |
| Additive correction | A new record that corrects or reverses a prior financial fact without rewriting the original. |
| Allowed branches | The immutable-at-request-time set of branches derived from active membership and assignments. |
| Audit evidence | Append-only evidence of a critical action, distinct from operational logs. |
| Branch | A tenant operating location. Orders, payments, deliveries, expenses, and registers are normally branch-scoped. |
| Business date | The operational date calculated using the approved tenant/branch timezone, not simply UTC calendar date. |
| Cash register | A branch record for opening cash, cash movements, expected/actual cash, variance, and close state for one business date. |
| Catalog | Tenant-configured services, item/service categories, prices, duration, tax/discount inputs, and branch availability. |
| Causation ID | Identifier of the action/event that caused another event or job. |
| Consumer | A module that reads a declared service or event contract. |
| Contract | A versioned boundary defining inputs, outputs, errors, ownership, compatibility, producer, and consumers. |
| Correlation ID | Identifier connecting one user/business operation across requests, services, events, jobs, logs, and errors. |
| Customer | A tenant-associated service recipient. A walk-in flow may use a lightweight snapshot instead of a persistent customer. |
| Dead-letter state | Observable terminal holding state for poison work after bounded retries. |
| Delivery | Pickup/home-delivery work owned by the order domain, including receiver/proof where required. |
| Derived projection | Rebuildable search/report/dashboard/customer-balance data created from authoritative records/events. |
| Entitlement | A subscription-controlled capability or limit enforced by the backend. |
| Event | A versioned fact about an already committed change; it is not a remote command. |
| Finalized record | A business record whose historical truth cannot be silently rewritten, such as a successful payment, receipt, closed register, or audit record. |
| Gateway | The only public backend entry point and the boundary for common request controls and context propagation. |
| Idempotency | Guarantee that valid retries of a harmful-duplicate operation produce one business effect. |
| Internal context | Authenticated service-to-service identity, tenant, branch, actor, correlation, and entitlement information. |
| Minor units | Integer currency representation such as paise for INR, paired with an ISO currency code. |
| Module owner | The single module/service authorized to write authoritative data for a business capability. |
| Order | The governed record of customer/walk-in work, item/service snapshots, totals, assignment, lifecycle, settlement, and delivery. |
| Outbox | Pending events recorded in the same consistency boundary as the authoritative domain change. |
| Owner | Tenant-wide administrative role, distinct from platform Super Admin. |
| Platform context | Authorization context for SaaS/platform operations that carries no implicit tenant access. |
| Policy | Tenant-configurable business rule, such as overpayment or delivery-with-balance, independently enforced by the backend. |
| Producer | The owning module that emits an event or provides a service contract. |
| Proof of delivery | Approved receiver confirmation, signature, photograph, OTP, or equivalent evidence attached to delivery completion. |
| Reconciliation | Comparison/recalculation that detects drift between authoritative records and balances/projections without silently hiding discrepancies. |
| Restricted data | Credentials, tokens, OTPs, financial details, and audit evidence requiring strongest controls. |
| Role | Named permission grouping. Role does not replace explicit tenant and branch scope checks. |
| Service business | A business centered on receiving a request/item, performing work, collecting payment, and completing/returning/delivering the outcome. |
| Snapshot | Historical copy of authoritative customer/catalog/price/tax/discount information stored with a transaction. |
| Source of truth | The authoritative domain-owned record. Derived projections and clients are not sources of truth. |
| Staff | Operational tenant user limited to assigned branches/work and permitted actions. |
| Super Admin | Platform-only role for tenant/platform governance, not an unrestricted tenant role. |
| Tenant | An independent business workspace whose data and configuration are isolated from every other business. |
| Tenant isolation | Backend-enforced separation across all data paths, derived systems, files, telemetry, recovery, and support tooling. |
| Walk-in | Approved fast customer flow using minimal data or an order snapshot without forcing a persistent customer record. |

