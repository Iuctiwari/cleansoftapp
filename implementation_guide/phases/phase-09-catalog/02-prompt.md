# Phase 09 — Catalog Implementation Prompt (`src/catalog/`)

```
Implement the Catalog module for Nexoraa CleanSoft (NestJS/MongoDB), covering services, service 
categories, effective pricing, and item categories. This module is the tenant's configurable 
price list; Order Management reads from it and snapshots values at order-creation time — it 
never reads live prices from an order after creation.

INTERNAL SERVICE INTERFACES (official requirements for this phase)

SVC-CATALOG-001 — resolveEffectivePricing(tenantId, serviceId, branchId, effectiveDate)
  Resolves the effective service pricing for a service based on tenant, branch, and effective 
  date. Used internally by Order Management when creating order line items.

SVC-CATALOG-002 — validateCatalogReference(tenantId, serviceId, itemCategoryId, branchId)
  Validates that a Service and Item Category belong to the requesting tenant, are Active, are 
  available for the selected branch, and are allowed to be referenced by Order Management.

SVC-CATALOG-003 — seedDefaultCatalog(tenantId, businessType)
  Seeds the default Catalog during Tenant Onboarding according to the selected business type. 
  Creates the default Service Categories, Services, Pricing, and Item Categories for the tenant.

Tax rounding and discount allocation remain deferred functionality: store raw tax/discount 
inputs as given; do not compute a rounded or allocated result server-side.

1. SCHEMAS

   serviceCategories
     tenantId*, name*, code* (unique per tenant), description, status (Active/Inactive), 
     branchIds[] (empty = all branches), createdBy, createdAt, updatedAt, version.
     Index: {tenantId, code} unique.

   services
     tenantId*, categoryId (ref serviceCategories, nullable), serviceName*, code* (unique per 
     tenant), pricingType* (PerItem/PerKg/PerPair/PerHour/Fixed/Custom), estimatedTimeMins, 
     branchIds[] (empty = all branches, validated against tenant), status (Active/Inactive), 
     createdBy, createdAt, updatedAt, version.
     Index: {tenantId, code} unique, {tenantId, status}.
     NOTE: services does not store basePrice/taxPct directly — see servicePricing.

   servicePricing (effective-dated price/tax records — source of truth for money)
     tenantId*, serviceId* (ref services), branchId (nullable = tenant-wide), pricingType* 
     (mirrors service.pricingType for query convenience), basePrice* (>=0), taxPct (Default 0), 
     effectiveFrom* (date), effectiveTo (nullable = open-ended), status (Active/Inactive), 
     createdBy, createdAt, version.
     Invariant: no two Active rows for the same {tenantId, serviceId, branchId, pricingType} may 
     have overlapping [effectiveFrom, effectiveTo) windows. Enforce via a pre-save check plus a 
     compound index; reject overlapping inserts with 409.
     Index: {tenantId, serviceId, branchId, effectiveFrom}.

   itemCategories
     tenantId*, name* (e.g. "Shirt", "Smartphone" — business-type agnostic), category 
     (grouping label), unitType* (Piece/Kg/Pair/Hour), defaultServiceId (ref services, nullable), 
     defaultPrice (Default 0 — convenience default only, not authoritative; actual price still 
     resolved via servicePricing at order time), status (Active/Inactive), createdBy, createdAt, 
     updatedAt, version.
     Index: {tenantId, status}.

   All four collections: tenantId is immutable after creation. code fields unique within tenant 
   only, never globally.

2. ROUTES

   GET    /services/categories              List categories (filter branch/status)
   POST   /services/categories               Create category
   PATCH  /services/categories/:id           Update/deactivate category

   GET    /services                          List services (filter branch/category/status)
   POST   /services                          Create service (no price — set via pricing 
                                              sub-resource)
   GET    /services/:id                      Retrieve service + its current effective pricing
   PATCH  /services/:id                      Update service metadata (name/category/branches/
                                              status) — not price
   DELETE /services/:id                      Deactivate (409 if referenced by a non-cancelled 
                                              order; never hard-delete in that case)

   POST   /services/:id/pricing              Create a new effective-dated pricing row (validates 
                                              no overlap; does not touch existing/past rows)
   GET    /services/:id/pricing              List pricing history for the service
   GET    /services/:id/quote                Resolve current effective price/tax for a given 
                                              branch + date (default: now); returns 
                                              { serviceId, servicePricingId, version, basePrice, 
                                              taxPct, effectiveFrom, effectiveTo } — this is the 
                                              payload Orders snapshots onto an order line item. 
                                              Returns raw inputs only — no computed/rounded 
                                              totals.

   GET    /item-categories                   List item categories (filter branch/status)
   POST   /item-categories                   Create item category
   PATCH  /item-categories/:id               Update item category / status
   DELETE /item-categories/:id               Deactivate (409 if referenced by a non-cancelled 
                                              order)

3. RULES
   - tenantId is immutable and scoped on every query; no service method accepts an unscoped find.
   - code unique within tenant for categories, services (not globally).
   - servicePricing rows for the same {serviceId, branchId, pricingType} must never have 
     overlapping effective windows — validated at write time, not just by index.
   - The /quote endpoint always resolves against effective UTC time and the requested branch's 
     business context; it returns immutable identifiers (servicePricingId + version) so Orders 
     can prove exactly which pricing row was snapshotted, even after later price changes.
   - Inactive or branch-unavailable services/item categories are excluded from new-order pickers 
     (validateCatalogReference rejects them) but remain fully readable for historical order 
     display — never hard-deleted while referenced.
   - branchIds on any catalog entity must be validated as belonging to the same tenant; reject 
     cross-tenant branch references with 400.
   - Tax rounding and discount allocation logic are deferred functionality — store exactly the 
     inputs given (basePrice, taxPct) and let the consuming module (Orders) decide how to 
     compute; do not invent a rounding/allocation algorithm here.
   - Prices are never client-authoritative: order-item unitPrice must always come from a 
     server-side /quote call at order-creation time, never trusted from client-supplied input.
   - All create/update/deactivate actions write an audit log entry (module='catalog', 
     old/new value, actor, tenantId) via the existing AuditService.

4. RBAC

   | Action                                   | Owner | Branch Manager | Staff | Cashier |
   |--------------------------------------------|:-----:|:---------------:|:-----:|:-------:|
   | List/read (categories, services, pricing, item categories) | ✅ | ✅ | ✅ | ✅ |
   | Quote access                                | ✅    | ✅              | ✅    | ✅      |
   | Create Category                             | ✅    | ✅              | ❌    | ❌      |
   | Update Category                             | ✅    | ✅              | ❌    | ❌      |
   | Create Service                              | ✅    | ✅              | ❌    | ❌      |
   | Update Service                              | ✅    | ✅              | ❌    | ❌      |
   | Create Pricing                              | ✅    | ✅              | ❌    | ❌      |
   | Update Pricing                              | ✅    | ✅              | ❌    | ❌      |
   | Create Item Category                        | ✅    | ✅              | ❌    | ❌      |
   | Update Item Category                        | ✅    | ✅              | ❌    | ❌      |
   | Deactivate Service                          | ✅    | ✅              | ❌    | ❌      |
   | Deactivate Item Category                    | ✅    | ✅              | ❌    | ❌      |

   Owner and Branch Manager have identical, full CRUD permissions across the entire Catalog 
   module, including deactivation of Services and Item Categories. Staff and Cashier have 
   read-only access plus Quote access; neither can create, update, or deactivate any catalog 
   entity.

5. INTEGRATIONS
   - Tenant Onboarding (Module 2): calls SVC-CATALOG-003 seedDefaultCatalog() inside the tenant 
     registration transaction, atomically with tenant+branch+Owner creation.
   - Order Management (Module 6): calls GET /services/:id/quote (or SVC-CATALOG-001 internally) 
     at order-item creation to snapshot unitPrice/taxPct + servicePricingId/version onto the 
     order line; calls SVC-CATALOG-002 to validate the referenced service/item category is 
     Active and tenant-owned before allowing the line item.
   - Audit Service: every mutating catalog action logs through it.

6. BUILD ORDER
   a. Schemas + tenant/branch-scoping guards + uniqueness/overlap invariants.
   b. Category + Service + Item Category CRUD (metadata only, no pricing yet).
   c. servicePricing sub-resource: create + list + overlap validation.
   d. /quote resolution endpoint, returning immutable snapshot payload.
   e. RBAC guards across all routes per the matrix above.
   f. Audit logging on every mutation.
   g. SVC-CATALOG-001/002/003 internal interfaces, wired as a reference integration into Tenant 
      Onboarding (seeding) and one Orders call site (quote + validate) — document the pattern.
   h. Deactivation guards (409 on referenced-by-order attempts) for services and item categories.

7. TESTING
   - Unit: overlap-window validation for servicePricing (adjacent, contained, partial-overlap 
     cases); tenant-code uniqueness; quote resolution picks the correct effective row for a 
     given date/branch.
   - Integration: seedDefaultCatalog produces a working starter catalog per businessType; 
     deactivating a referenced service returns 409, non-referenced deactivates cleanly; a 
     service price change does not alter previously issued quotes/snapshots.
   - Security: cross-tenant branchId rejected (400); Staff/Cashier blocked from mutating routes 
     (403); tenant isolation on every list/get.
   - Regression: after a new servicePricing row is added, /quote for a historical date still 
     resolves the old row, not the new one.

OUT OF SCOPE (do not build yet)
   - Orders, inventory, loyalty logic.
   - Any hard-coded industry-specific catalog beyond the seed-template mechanism (seeding is 
     data-driven per businessType, not hard-coded branching logic).
   - Direct branch collection persistence access from this module (branch validation happens via 
     a service call/lookup, never a raw cross-collection write).
   - Client-authoritative prices (Orders must always call /quote; never trust a client-sent 
     unitPrice).
   - Tax rounding / discount allocation computation (deferred) — store inputs only.

ACCEPTANCE CRITERIA
   - [ ] Service Categories, Services, Service Pricing, and Item Categories are implemented and 
     fully functional per the schemas and routes above.
   - [ ] Tenant isolation is enforced on every query; branchIds are validated against the 
     requesting tenant.
   - [ ] RBAC is enforced exactly per the matrix: Owner and Branch Manager have full CRUD 
     including deactivation; Staff and Cashier have read-only + Quote access only.
   - [ ] Service and category codes remain unique within a tenant.
   - [ ] servicePricing windows never overlap for the same {serviceId, branchId, pricingType}.
   - [ ] The Quote endpoint always returns the correct effective pricing for the requested 
     branch and date, with immutable servicePricingId/version identifiers.
   - [ ] Orders always snapshot pricing at creation time and never reference live catalog 
     prices after the fact.
   - [ ] Inactive or branch-unavailable Services and Item Categories cannot be selected for new 
     Orders, but remain readable for historical order display.
   - [ ] Catalog seeding (SVC-CATALOG-003) runs correctly and atomically during Tenant 
     Onboarding based on the selected business type.
   - [ ] Audit logs are created for every catalog create/update/deactivate action.
   - [ ] Tenant Onboarding and Order Management integrations work end-to-end.
   - [ ] All Unit, Integration, Security, and Regression tests pass.
   - [ ] The module compiles without TypeScript errors.
   - [ ] The implementation follows SOLID principles, Clean Architecture, and existing NestJS 
     project conventions, and integrates seamlessly into the existing codebase without breaking 
     any existing functionality.
```