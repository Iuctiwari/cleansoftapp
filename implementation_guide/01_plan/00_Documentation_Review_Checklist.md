# Layer 1 Documentation Review Checklist

## Document control

| Field | Value |
|---|---|
| Project | Nexoraa CleanSoft ERP |
| Layer | 1 — Plan |
| Status | Layer 1 approved for architecture migration |
| Last reviewed | 2026-07-28 |
| Review trigger | Re-run whenever any Layer 1 file changes materially |

## Source authority used for this migration

This layer migrates existing information; it does not replace product decisions with new ones.

1. `ERP-PLANNING/phase-prompts/PHASE_1_SOFTWARE_IDEA.md` — product vision and business problem.
2. `ERP-PLANNING/phase-prompts/PHASE_2_SYSTEM_PLANNING.md` — approved planning baseline, scope, actors, workflows, architecture constraints, NFR targets, risks, and assumptions.
3. `ERP-PLANNING/phase-prompts/PHASE_3_PLAN_AUDIT.md` — conflicts, gaps, unresolved product decisions, and readiness findings.
4. `ERP-PLANNING/phase-prompts/PHASE_4_IMPLEMENTATION_ROADMAP.md` — canonical phase catalogue, module sequence, quality gates, and MVP delivery waves.
5. `ERP-PLANNING/phase-prompts/PHASE_5_ROADMAP_AUDIT.md` — roadmap gaps and conditional approval.
6. Module prompts `PHASE_9_AUTH.md` through `PHASE_17_NOTIFICATIONS.md` — detailed module intent, invariants, API candidates, data candidates, testing, and acceptance material.
7. Repository implementation and manifests — evidence of current state only, not a source for inventing future product behavior.

The original documents remain in place during this review gate. Their implementation-level material will be migrated into Layer 2 contracts and Layer 3 phase briefs before any retirement or removal is proposed.

## Completion checklist

| Order | File | Completion | Review notes |
|---:|---|---|---|
| 01 | `01_Project_Vision.md` | Complete | Vision, users, problem, workflow, value, and source boundaries captured |
| 02 | `02_Product_Requirements.md` | Complete | MVP, post-MVP, future, and out-of-scope boundaries separated |
| 03 | `03_User_Personas.md` | Complete | Platform, tenant, operational, customer, support, and engineer personas captured |
| 04 | `04_User_Journeys.md` | Complete | Core and cross-cutting journeys mapped to stable FR IDs |
| 05 | `05_Functional_Requirements.md` | Complete | Testable requirements grouped by module with stable IDs |
| 06 | `06_NonFunctional_Requirements.md` | Complete | Every item labeled Stated, Inferred, or Gap |
| 07 | `07_Product_Modules.md` | Complete | Ownership boundaries and informal dependency preview captured |
| 08 | `08_Project_Glossary.md` | Complete | Canonical domain terms defined once |
| 09 | `09_Assumptions_and_Risks.md` | Complete, review required | Existing assumptions separated from risks |
| 10 | `10_Open_Questions.md` | Complete, review required | Stakeholder decisions separated from engineering assumptions |

## Consistency checks

- [x] MVP, post-MVP, and future scope are not blended.
- [x] Web-client scope removed from the current plan because `apps/web-frontend` was intentionally removed; the historical source discrepancy is recorded as `R-15`.
- [x] Tenant isolation is backend-enforced in every relevant requirement.
- [x] Branch scope is explicit for operational data.
- [x] Financial corrections are additive and finalized records are not silently rewritten.
- [x] Authentication, authorization, audit, event, projection, and recovery concepts remain represented.
- [x] Functional requirements use unique `FR-<MODULE>-<N>` IDs.
- [x] Assumptions use `A-N`, risks use `R-N`, and open questions use `OQ-N`.
- [x] No architecture decision has been silently created in Layer 1.
- [x] No source code, business logic, or configuration was changed.

## Readiness assessment

Layer 1 is structurally complete. The assumptions/open-question classification review gate was approved by the user on 2026-07-28. Layer 2 and Layer 3 were then permitted to proceed. Individual unresolved `OQ-*` items still block the affected implementation phases; approval to proceed with documentation did not silently answer them.

Known blockers carried from the existing audits:

- Commercial plan names and limits are not approved.
- Financial rounding, discount, refund, overpayment, and cash-register policies require decisions.
- Consent, retention, deletion, residency, and production-locale decisions remain open.
- Several legacy phase prompt filenames conflict with their contents.
- The old planning baseline still refers to a Flutter web application that has been removed.
